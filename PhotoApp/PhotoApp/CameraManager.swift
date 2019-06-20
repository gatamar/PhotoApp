//
//  CameraManager.swift
//  PhotoApp
//
//  Created by Olha Pavliuk on 5/23/19.
//  Copyright © 2019 Olha Pavliuk. All rights reserved.
//

import Foundation
import AVFoundation

protocol LineOutputDelegate: class {
    func displayLines(_ lines: [Line?])
}

class CameraManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, FrameProcessorDelegate {
    
    private var captureSession: AVCaptureSession?
    private var device: AVCaptureDevice?
    private var input: AVCaptureDeviceInput?
    private var videoDataOutput: AVCaptureVideoDataOutput?
    private var videoLayer: AVSampleBufferDisplayLayer?
    weak var lineOutput: LineOutputDelegate?
    
    init(with layer: AVSampleBufferDisplayLayer) {
        videoLayer = layer
        super.init()
        if initCamera() {
            setOrientation(AVCaptureVideoOrientation.portrait)
            startCapturing()
        } else {
            print("ERROR: Can't init camera!")
        }
    }

    private func initCamera() -> Bool {
        captureSession = AVCaptureSession()
        captureSession?.beginConfiguration()

        videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput?.videoSettings = [kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA] as [String: Any]
        videoDataOutput?.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        captureSession?.addOutput(videoDataOutput!)
        captureSession?.sessionPreset = .photo

        let devices = AVCaptureDevice.devices()
        for device in devices {
            if device.hasMediaType(AVMediaType.video) && device.position == AVCaptureDevice.Position.back {
                self.device = device
                break
            }
        }

        guard let device = self.device else {
            return false
        }

        do {
            input = try AVCaptureDeviceInput(device: device)
        } catch {
            return false
        }

        captureSession?.addInput(input!)
        captureSession?.commitConfiguration()

        return true
    }

    private func startCapturing() {
        self.captureSession?.startRunning()
    }

    private func stopCapturing() {
        self.captureSession?.stopRunning()
    }

    private func setOrientation(_ orientation: AVCaptureVideoOrientation) {
        let connection = videoDataOutput?.connection(with: AVMediaType.video)
        captureSession?.beginConfiguration()
        connection?.videoOrientation = orientation
        captureSession?.commitConfiguration()
    }

    var algoIsRunning: Bool = false
    var frameCount: Int = 0
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        autoreleasepool {
            guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                return
            }

            frameCount = (frameCount + 1) % 5
            
            if !algoIsRunning && frameCount == 0 {
                let frameProcessor = FrameProcessor(delegate: self)!
                frameProcessor.aspectFillSize = videoLayer!.frame.size
                
                //let opaquePointer = Unmanaged<CVPixelBuffer>.passRetained(pixelBuffer).toOpaque()
                //let pixelBufferRetained = Unmanaged<CVPixelBuffer>.passRetained(pixelBuffer).toOpaque()
                
                frameProcessor.detectLines3(pixelBuffer)
                algoIsRunning = true
            }
            
            videoLayer!.enqueue(sampleBuffer)
            videoLayer!.setNeedsDisplay()
        }
    }
    
    func onLinesDetected(_ lines: [Line]!) {
        lineOutput?.displayLines(lines)
        algoIsRunning = false
    }
}

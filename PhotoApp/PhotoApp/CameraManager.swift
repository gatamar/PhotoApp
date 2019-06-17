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
    private var sessionQueue: dispatch_queue_serial_t
    weak var lineOutput: LineOutputDelegate?
    
    init(with layer: AVSampleBufferDisplayLayer) {
        sessionQueue = dispatch_queue_serial_t(label: "capture session queue")
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
        sessionQueue.async {
            self.captureSession?.startRunning()
        }
    }

    private func stopCapturing() {
        sessionQueue.async {
            self.captureSession?.stopRunning()
        }
    }

    private func setOrientation(_ orientation: AVCaptureVideoOrientation) {
        let connection = videoDataOutput?.connection(with: AVMediaType.video)
        captureSession?.beginConfiguration()
        connection?.videoOrientation = orientation
        captureSession?.commitConfiguration()
    }

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        autoreleasepool {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                return
            }

            let lockResult = CVPixelBufferLockBaseAddress(pixelBuffer, [])
            assert( lockResult == kCVReturnSuccess )
            
            let width = Int32(CVPixelBufferGetWidth(pixelBuffer))
            let height = Int32(CVPixelBufferGetHeight(pixelBuffer))
            let bytesPerRow = Int32(CVPixelBufferGetBytesPerRow(pixelBuffer))
            let dataSize = CVPixelBufferGetDataSize(pixelBuffer)
            
            let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
            let baseAddressTyped = baseAddress?.bindMemory(to: UInt8.self, capacity: dataSize)
            
            let frameProcessor = FrameProcessor(delegate: self)
            frameProcessor?.applySimpleFilter(baseAddressTyped, withWidth: width, andHeight: height, andBytesPerRow: bytesPerRow)
            
            CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
            
            videoLayer!.enqueue(sampleBuffer)
            videoLayer!.setNeedsDisplay()
        }
    }
    
    func onLinesDetected(_ lines: [Line]!) {
        lineOutput?.displayLines(lines)
    }
}

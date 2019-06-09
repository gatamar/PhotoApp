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

class CameraManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {

    var captureSession: AVCaptureSession?
    var device: AVCaptureDevice?
    var input: AVCaptureDeviceInput?
    var videoDataOutput: AVCaptureVideoDataOutput?
    var videoLayer: AVSampleBufferDisplayLayer?
    var sessionQueue: dispatch_queue_serial_t
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
            let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)

            guard imageBuffer != nil else {
                return
            }

            let srcPtr = Unmanaged.passUnretained(imageBuffer!).toOpaque()
            let pixelBuffer = Unmanaged<CVPixelBuffer>.fromOpaque(srcPtr).takeUnretainedValue()

            let detector = ContourDetector()
            let lines = detector.detectLines(pixelBuffer)!

            lineOutput?.displayLines(lines)

            videoLayer?.enqueue(sampleBuffer)
            videoLayer?.setNeedsDisplay()
        }
    }
}

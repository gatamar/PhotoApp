//
//  CameraManager.swift
//  PhotoApp
//
//  Created by Olha Pavliuk on 5/23/19.
//  Copyright © 2019 Olha Pavliuk. All rights reserved.
//

import Foundation
import AVFoundation

protocol LineOutputDelegate {
    func displayLines(_ lines: [Line?]) -> Void
}

class CameraManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var captureSession: AVCaptureSession?
    var device: AVCaptureDevice?
    var input: AVCaptureDeviceInput?
    var videoDataOutput: AVCaptureVideoDataOutput?
    var videoLayer: AVSampleBufferDisplayLayer?
    var lineOutput: LineOutputDelegate?
    
    init(with layer: AVSampleBufferDisplayLayer) {
        super.init()
        
        self.videoLayer = layer
        initCameraController()
        setOrientation(orientation: AVCaptureVideoOrientation.portrait)
        startCapturing()
    }
    
    func initCameraController() {
        self.captureSession = AVCaptureSession()
        self.captureSession?.beginConfiguration()
        
        self.videoDataOutput = AVCaptureVideoDataOutput()
        self.videoDataOutput?.videoSettings = ["kCVPixelBufferPixelFormatTypeKey": "BGRA"]
        self.videoDataOutput?.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        self.captureSession?.addOutput(self.videoDataOutput!)
        self.captureSession?.sessionPreset = .photo
        
        let devices = AVCaptureDevice.devices()
        for device in devices {
            if device.hasMediaType(AVMediaType.video) && device.position == AVCaptureDevice.Position.back {
                self.device = device
                break
            }
        }
        
        do {
            self.input = try AVCaptureDeviceInput(device: self.device!)
        } catch {
            assert(false)
        }
        
        self.captureSession?.addInput(self.input!)
        self.captureSession?.commitConfiguration()
        
        do {
            try self.device?.lockForConfiguration()
            // set exposure mode
            // set locked mode
        }
        catch {
            
        }
        self.device?.unlockForConfiguration()
    }
    
    func startCapturing() {
        self.captureSession?.startRunning()
    }
    
    func stopCapturing() {
        self.captureSession?.stopRunning()
    }
    
    // TODO: fancy swift getter/setter
    func setOrientation(orientation: AVCaptureVideoOrientation) {
        let conn = self.videoDataOutput?.connection(with: AVMediaType.video)
        self.captureSession?.beginConfiguration()
        conn?.videoOrientation = orientation
        self.captureSession?.commitConfiguration()
    }

    // TODO: not-ARC
    func releaseCapturingDevice() {
        self.stopCapturing()
        self.captureSession = nil
        self.videoDataOutput = nil
        self.input = nil
        self.device = nil
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // TODO: add autorelease pool here
        
        let imageBuffer : CVPixelBuffer? = CMSampleBufferGetImageBuffer(sampleBuffer)
        let srcPtr = Unmanaged.passUnretained(imageBuffer!).toOpaque()
        let pixelBuffer = Unmanaged<CVPixelBuffer>.fromOpaque(srcPtr).takeUnretainedValue()
        
        let detector = ContourDetector()
        let lines = detector.detectLines(pixelBuffer)
        self.lineOutput?.displayLines(lines!)
        
        self.videoLayer?.enqueue(sampleBuffer)
        self.videoLayer?.setNeedsDisplay()
    }
}

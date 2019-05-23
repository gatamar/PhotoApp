//
//  ViewController.swift
//  PhotoApp
//
//  Created by Olha Pavliuk on 5/23/19.
//  Copyright © 2019 Olha Pavliuk. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    var videoLayer: AVSampleBufferDisplayLayer?
    var cameraManager: CameraManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initVideoLayer()
        initCameraManager()
    }

    func initVideoLayer() {
        if self.videoLayer == nil {
            let topToolbarHeight = 50 as CGFloat
            let bottomToolbarHeight = 50 as CGFloat
            let viewFrame = self.view.frame
            let videoLayerFrame = CGRect(x: 0, y: topToolbarHeight, width: viewFrame.width, height: viewFrame.height-(topToolbarHeight+bottomToolbarHeight))
            self.videoLayer = AVSampleBufferDisplayLayer()
            self.videoLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            self.videoLayer?.frame = videoLayerFrame
            
            self.view.layer.addSublayer(self.videoLayer!)
        }
    }

    func initCameraManager() {
        // TODO: fix constructor naming
        self.cameraManager = CameraManager(with: self.videoLayer!)
    }
}


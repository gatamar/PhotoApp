//
//  ViewController.swift
//  PhotoApp
//
//  Created by Olha Pavliuk on 5/23/19.
//  Copyright © 2019 Olha Pavliuk. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, LineOutputDelegate {

    var videoLayer: AVSampleBufferDisplayLayer?
    private var edgesLayer: CAShapeLayer?
    private var cameraManager: CameraManager?

    override func viewDidLoad() {
        super.viewDidLoad()
        initVideoLayer()
        initCameraManager()
    }

    private func initVideoLayer() {
        if videoLayer == nil {
            let topToolbarHeight: CGFloat = 50
            let bottomToolbarHeight: CGFloat = 50
            let viewFrame = view.frame
            let videoLayerFrame = CGRect(x: 0,
                                         y: topToolbarHeight,
                                         width: viewFrame.width,
                                         height: viewFrame.height-(topToolbarHeight+bottomToolbarHeight))
            videoLayer = AVSampleBufferDisplayLayer()
            videoLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoLayer?.frame = videoLayerFrame

            view.layer.addSublayer(videoLayer!)
        }
    }

    private func initCameraManager() {
        cameraManager = CameraManager(with: videoLayer!)
        cameraManager!.lineOutput = self
    }

    func displayLines(_ lines: [Line?]) {

        if edgesLayer == nil {
            let layer = CAShapeLayer()
            layer.frame = videoLayer!.bounds
            layer.lineWidth = 1.5
            layer.fillColor = nil
            layer.strokeColor = UIColor.white.cgColor
            layer.opacity = 1.0
            layer.isOpaque = true
            edgesLayer = layer
            videoLayer!.addSublayer(edgesLayer!)
        }

        let path = CGMutablePath()
        for line in lines {
            path.move(to: line!.p1)
            path.addLine(to: line!.p2)
        }

        edgesLayer?.path = path
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}

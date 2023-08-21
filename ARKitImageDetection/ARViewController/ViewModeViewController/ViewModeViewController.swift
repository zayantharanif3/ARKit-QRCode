//
//  ViewModeViewController.swift
//  ARKitImageDetection
//
//  Created by Zayan Tharani on 8/18/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import UIKit
import ARKit
import SceneKit

class ViewModeViewController: UIViewController, ARSCNViewDelegate {
    @IBOutlet weak var sceneView: ARSCNView!

    var barcodeDetector: BarcodeDetector = BarcodeDetector()
    var trackingQRCode = false
    var baseNode: SCNNode?
    var movableNode: SCNNode?
    var qrContent: QRCodeContent?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        sceneView.session.delegate = self
        barcodeDetector.delegate = self
    }
    
    /// Creates a new AR configuration to run on the `session`.
    /// - Tag: ARReferenceImage-Loading
    func resetTracking(withImages images: [ARReferenceImage] = []) {
        trackingQRCode = !images.isEmpty
        let configuration = ARWorldTrackingConfiguration()
        configuration.detectionImages = Set(images)
        configuration.maximumNumberOfTrackedImages = 1
        session.run(configuration)
        statusViewController.scheduleMessage("Look around to detect images", inSeconds: 7.5, messageType: .contentPlacement)
        
        updateQueue.asyncAfter(deadline: DispatchTime.now() + 5) {
            self.trackingQRCode = false
        }
    }
}

extension ViewModeViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        barcodeDetector.search(in: frame.capturedImage)
    }
}

extension ViewModeViewController: BarcodeDetectorDelegate {
    func barcodeFound(image: ARReferenceImage, content: QRCodeContent) {
        qrContent = content
        if !trackingQRCode {
//            resetTracking(withImages: [image])
        }
    }
}

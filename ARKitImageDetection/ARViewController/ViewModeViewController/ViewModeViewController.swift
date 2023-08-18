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

class ViewModeViewController: UIViewController {
    var barcodeDetector: BarcodeDetector = BarcodeDetector()
    var trackingQRCode = false
    var baseNode: SCNNode?
    var movableNode: SCNNode?
    var qrContent: QRCodeContent?

    
    override func viewDidLoad() {
        super.viewDidLoad()
//        sceneView.delegate = self
//        sceneView.session.delegate = self
//        barcodeDetector.delegate = self
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

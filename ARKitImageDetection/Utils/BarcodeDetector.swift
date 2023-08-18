//
//  BarcodeDetector.swift
//  VisualixFramework
//
//  Created by Frank Hallett on 2023-07-24.
//  Copyright © 2023 Visualix. All rights reserved.
//

import UIKit
import Vision
import CoreImage
import ARKit

/// - Tag: RectangleDetector
class BarcodeDetector {
    
    private var currentCameraImage: CVPixelBuffer!
    
    private var updateTimer: Timer?
    
    /// The number of times per second to check for rectangles.
    /// - Tag: UpdateInterval
    private var updateInterval: TimeInterval = 0.1
    
    /// - Tag: IsBusy
    private var isBusy = false
    
    weak var delegate: BarcodeDetectorDelegate?
    
    /// - Tag: InitializeVisionTimer
    init() {
        //TODO rely on this to be called with image to decode
//        self.updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
//            if let capturedImage = ViewController.instance?.sceneView.session.currentFrame?.capturedImage {
//                self?.search(in: capturedImage)
//            }
//        }
    }
    
    
    

    /// Search for rectangles in the camera's pixel buffer,
    ///  if a search is not already running.
    /// - Tag: SerializeVision
    public func search(in pixelBuffer: CVPixelBuffer) {
        guard !isBusy else { return }
        isBusy = true
 
        // Remember the current image.
        currentCameraImage = pixelBuffer
        
        // Note that the pixel buffer's orientation doesn't change even when the device rotates.
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
        
        // Create a Vision barcode detection request for running on the GPU.
        let request = VNDetectBarcodesRequest { request, error in
            self.completedVisionRequest(request, error: error)
        }
        
        //limit to qr
//        request.symbologies = [.qr]

        // You leverage the `usesCPUOnly` flag of `VNRequest` to decide whether your Vision requests are processed on the CPU or GPU.
        // This sample disables `usesCPUOnly` because rectangle detection isn't very taxing on the GPU. You may benefit by enabling
        // `usesCPUOnly` if your app does a lot of rendering, or runs a complicated neural network.
        request.usesCPUOnly = false
        
        DispatchQueue.global().async {
            do {
                try handler.perform([request])
            } catch {
                print("Error: Barcode detection failed - vision request failed.")
                self.isBusy = false
            }
        }
    }
    
    /// Check for a barcode result.
    /// If one is found, crop the camera image and correct its perspective.
    /// - Tag: CropCameraImage
    private func completedVisionRequest(_ request: VNRequest?, error: Error?) {
        defer {
            isBusy = false
        }
        // Only proceed if a rectangular image was detected.
        guard let barcode = request?.results?.first as? VNBarcodeObservation else {
            guard let error = error else { return }
            print("Error: Barcode detection failed - Vision request returned an error. \(error.localizedDescription)")
            return
        }
        guard let filter = CIFilter(name: "CIPerspectiveCorrection") else {
            print("Error: Barcode detection failed - Could not create perspective correction filter.")
            return
        }
        
        //extract out the barcode image detected
        let width = CGFloat(CVPixelBufferGetWidth(currentCameraImage))
        let height = CGFloat(CVPixelBufferGetHeight(currentCameraImage))
        let topLeft = CGPoint(x: barcode.topLeft.x * width, y: barcode.topLeft.y * height)
        let topRight = CGPoint(x: barcode.topRight.x * width, y: barcode.topRight.y * height)
        let bottomLeft = CGPoint(x: barcode.bottomLeft.x * width, y: barcode.bottomLeft.y * height)
        let bottomRight = CGPoint(x: barcode.bottomRight.x * width, y: barcode.bottomRight.y * height)
        
        filter.setValue(CIVector(cgPoint: topLeft), forKey: "inputTopLeft")
        filter.setValue(CIVector(cgPoint: topRight), forKey: "inputTopRight")
        filter.setValue(CIVector(cgPoint: bottomLeft), forKey: "inputBottomLeft")
        filter.setValue(CIVector(cgPoint: bottomRight), forKey: "inputBottomRight")
        let ciImage = CIImage(cvPixelBuffer: currentCameraImage).oriented(.up)
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        
        //get the extracted image from coreimage
        guard let perspectiveImage: CIImage = filter.value(forKey: kCIOutputImageKey) as? CIImage else {
            print("Error: Barcode detection failed - perspective correction filter has no output image.")
            return
        }
        
//        guard let jsonstring = barcode.payloadStringValue?.replacingOccurrences(of: "\\", with: ""),
//              let jsondata = jsonstring.data(using: .utf8),
//              let qr = try? JSONDecoder().decode(QRCodeContent.self, from: jsondata)
//        else { return }
        
        guard let referenceImagePixelBuffer = perspectiveImage.toPixelBuffer(pixelFormat: kCVPixelFormatType_32BGRA) else {
            print("Error: Could not convert barcode content into an ARReferenceImage.")
            return
        }
        
        // Defaults to 10x10
        let referenceImage = ARReferenceImage(referenceImagePixelBuffer, orientation: .up, physicalWidth: CGFloat(0.1))
        delegate?.barcodeFound(image: referenceImage, content: QRCodeContent(width: 0.1))
    }   

}

protocol BarcodeDetectorDelegate: AnyObject {
    func barcodeFound(image: ARReferenceImage, content: QRCodeContent)
}

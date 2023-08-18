//
//  Util.swift
//  VisualixFramework
//
//  Created by Frank Hallett on 2023-07-24.
//  Copyright © 2023 Visualix. All rights reserved.
//
import Foundation
import ARKit
import CoreML
import VideoToolbox

extension CIImage {
    
    /// Returns a pixel buffer of the image's current contents.
    func toPixelBuffer(pixelFormat: OSType) -> CVPixelBuffer? {
        var buffer: CVPixelBuffer?
        let options = [
            kCVPixelBufferCGImageCompatibilityKey as String: NSNumber(value: true),
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: NSNumber(value: true)
        ]
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         Int(extent.size.width),
                                         Int(extent.size.height),
                                         pixelFormat,
                                         options as CFDictionary, &buffer)
        
        if status == kCVReturnSuccess, let device = MTLCreateSystemDefaultDevice(), let pixelBuffer = buffer {
            let ciContext = CIContext(mtlDevice: device)
            ciContext.render(self, to: pixelBuffer)
        } else {
            print("Error: Converting CIImage to CVPixelBuffer failed.")
        }
        return buffer
    }
    
    /// Returns a copy of this image scaled to the argument size.
    func resize(to size: CGSize) -> CIImage? {
        return self.transformed(by: CGAffineTransform(scaleX: size.width / extent.size.width,
                                                      y: size.height / extent.size.height))
    }
}

extension CVPixelBuffer {
    
    /// Returns a Core Graphics image from the pixel buffer's current contents.
    func toCGImage() -> CGImage? {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(self, options: nil, imageOut: &cgImage)
        
        if cgImage == nil { print("Error: Converting CVPixelBuffer to CGImage failed.") }
        return cgImage
    }
}

extension MLMultiArray {
    /// Zeros out all indexes in the array except for the argument index, which is set to one.
    func setOnlyThisIndexToOne(_ index: Int) {
        if index > self.count - 1 {
            print("Error: Invalid index #\(index)")
            return
        }
        for i in 0...self.count - 1 {
            self[i] = Double(0) as NSNumber
        }
        self[index] = Double(1) as NSNumber
    }
}

extension float4x4 {
    init(translation vector: float3) {
        self.init(float4(1, 0, 0, 0),
                  float4(0, 1, 0, 0),
                  float4(0, 0, 1, 0),
                  float4(vector.x, vector.y, vector.z, 1))
    }
}

extension simd_float4x4 {
    var eulerAngles: simd_float3 {
        simd_float3(
            x: asin(-self[2][1]),
            y: atan2(self[2][0], self[2][2]),
            z: atan2(self[0][1], self[1][1])
        )
    }
}

extension SCNNode {
    func centerAlign() {
        let (min, max) = boundingBox
        let extents = float3(max) - float3(min)
        simdPivot = float4x4(translation: ((extents / 2) + float3(min)))
    }
}

extension SCNVector3 {
    func XZDistanceTo(other: SCNVector3) -> Float {
        let deltaX = self.x - other.x
        let deltaZ = self.y - other.y
        let distance = sqrt(deltaX * deltaX + deltaZ * deltaZ)
        return distance
    }
    
    /**
     * Subtracts two SCNVector3 vectors and returns the result as a new SCNVector3.
     */
    static func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3Make(left.x - right.x, left.y - right.y, left.z - right.z)
    }
    
    
    /**
     * Calculates the distance between two SCNVector3. Pythagoras!
     */
    func distance(to vector: SCNVector3) -> Float {
        return (self - vector).length()
    }
    
    /**
     * Returns the length (magnitude) of the vector described by the SCNVector3
     */
    func length() -> Float {
        return sqrt(x*x + y*y + z*z)
    }
    
}

extension CGPoint {
    mutating func rotatePoint(aroundOrigin origin: CGPoint, byDegrees: CGFloat) {
        let dx = self.x - origin.x
        let dy = self.y - origin.y
        let radius = sqrt(dx * dx + dy * dy)
        let azimuth = atan2(dy, dx) // in radians
        let newAzimuth = azimuth + byDegrees * .pi / 180 // convert it to radians
        let x = origin.x + radius * cos(newAzimuth)
        let y = origin.y + radius * sin(newAzimuth)
        self.x = x
        self.y = y
    }

}

/// Creates a SceneKit node with plane geometry, to the argument size, rotation, and material contents.
func createPlaneNode(size: CGSize, rotation: Float, contents: Any?) -> SCNNode {
    let plane = SCNPlane(width: size.width, height: size.height)
    plane.firstMaterial?.diffuse.contents = contents
    let planeNode = SCNNode(geometry: plane)
    
    planeNode.eulerAngles.x = rotation
    return planeNode
}

extension UIViewController {
    func showAlert(alertTitle: String, alertMessage: String? = nil, actions: [UIAlertAction] = [UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil)]) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: alertTitle, message: alertMessage ?? "", preferredStyle: UIAlertController.Style.alert)
            for action in actions {
                alert.addAction(action)
            }
            alert.accessibilityRespondsToUserInteraction = false

            self.present(alert, animated: true, completion: nil)
        }
    }
}


class Helper {
    static var directionVector: SCNVector3 = SCNVector3Zero
}

/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 Main view controller for the AR experience.
 */

import ARKit
import SceneKit
import UIKit

class RecordViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var blurView: UIVisualEffectView!
    var barcodeDetector: BarcodeDetector = BarcodeDetector()
    var trackingQRCode = false
    var baseNode: SCNNode?
    var movableNode: SCNNode?
    var qrContent: QRCodeContent?
    
    /// The view controller that displays the status and "restart experience" UI.
    lazy var statusViewController: StatusViewController = {
        return children.lazy.compactMap({ $0 as? StatusViewController }).first!
    }()
    
    /// A serial queue for thread safety when modifying the SceneKit node graph.
    let updateQueue = DispatchQueue(label: Bundle.main.bundleIdentifier! +
                                    ".serialSceneKitQueue")
    
    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        return sceneView.session
    }
    
    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.session.delegate = self
        barcodeDetector.delegate = self
        
        // Hook up status view controller callback(s).
        statusViewController.restartExperienceHandler = { [unowned self] in
            self.restartExperience()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Prevent the screen from being dimmed to avoid interuppting the AR experience.
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Start the AR experience
        resetTracking()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        session.pause()
    }
    
    // MARK: - Session management (Image detection setup)
    
    /// Prevents restarting the session while a restart is in progress.
    var isRestartAvailable = true
    
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
    
    // MARK: - ARSCNViewDelegate (Image detection results)
    /// - Tag: ARImageAnchor-Visualizing
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        let referenceImage = imageAnchor.referenceImage
        
        // Our flow will stop when we have base node and movable node
        guard baseNode == nil || movableNode == nil else {
            return
        }
        
        updateQueue.async {
            self.session.setWorldOrigin(relativeTransform: node.simdTransform)
            // Create a plane to visualize the initial position of the detected image.
            let plane = SCNBox(width: referenceImage.physicalSize.width,
                               height: referenceImage.physicalSize.height, length: 0.1, chamferRadius: 0)
            plane.firstMaterial?.diffuse.contents = UIColor.lightGray
            plane.firstMaterial?.isDoubleSided = true
            
            
            let planeNode = SCNNode(geometry: plane)
            planeNode.opacity = 0.7
            
            /*
             `SCNPlane` is vertically oriented in its local coordinate space, but
             `ARImageAnchor` assumes the image is horizontal in its local space, so
             rotate the plane to match.
             */
            planeNode.eulerAngles.x = -.pi / 2
            
            /*
             Image anchors are not tracked after initial detection, so create an
             animation that limits the duration for which the plane visualization appears.
             */
            
            planeNode.runAction(self.imageHighlightAction)
            
            // Add the plane visualization to the scene.
            node.addChildNode(planeNode)
            self.sceneView.scene.rootNode.addChildNode(planeNode)
        }
    
        DispatchQueue.main.async {
            let imageName = referenceImage.name ?? ""
            self.statusViewController.cancelAllScheduledMessages()
            self.statusViewController.showMessage("Detected image \(self.qrContent?.width ?? -1) meters")
            
            // This is first time a QR Code is found. This MUST be base node
            if self.baseNode == nil {
                self.baseNode = node
                self.baseNode?.name = QRCodeType.base.rawValue
            } else {
                // Second QR Code MUST be movable node
                self.movableNode = node
                self.movableNode?.name = QRCodeType.movable.rawValue
                self.findDistance()
                self.saveDirectionVector()
            }
        }
    }
    
    func findDistance() {
        guard let movableNode, let baseNode else { return }
        let positionA = movableNode.worldPosition
        let positionB = baseNode.worldPosition
        let distance = positionA.distance(to: positionB)
        
        self.statusViewController.showMessage("Distance “\(distance)”")
    }
    
    func saveDirectionVector() {
        guard let movableNode, let baseNode else { return }
        let dirVector = movableNode.position - baseNode.position
        Helper.directionVector = dirVector
    }
    
    var imageHighlightAction: SCNAction {
        return .sequence([
            .wait(duration: 0.25),
            .fadeOpacity(to: 0.85, duration: 0.25),
            .fadeOpacity(to: 0.15, duration: 0.25),
            .fadeOpacity(to: 0.85, duration: 0.25),
        ])
    }
}

extension RecordViewController: BarcodeDetectorDelegate {
    func barcodeFound(image: ARReferenceImage, content: QRCodeContent) {
        qrContent = content
        if !trackingQRCode {
            resetTracking(withImages: [image])
        }
    }
}


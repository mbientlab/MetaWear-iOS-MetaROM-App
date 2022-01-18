//
//  SkeletonView.swift
//  MetaClinic
//
//  Created by Stephen Schiffli on 6/4/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

import SceneKit

class SkeletonView: SCNView {
    let scnScene: SCNScene = SCNScene(named: "arm.scnassets/free3Dmodel.scn")!
    var upperNode: SCNNode?
    var lowerNode: SCNNode?
    var fullCameraNode: SCNNode!
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    func setupScene() {
        scene = scnScene
        delegate = self
        //isPlaying = true
        allowsCameraControl = true
    }
    
    func setupConfig(config: JointConfig) {
        upperNode = scnScene.rootNode.childNode(withName: config.upper.nodeName, recursively: true)!
        lowerNode = scnScene.rootNode.childNode(withName: config.lower.nodeName, recursively: true)!
        applyAll(orientations: config.handPosition)
        applyAll(orientations: config.palmPosition)
        
        pointOfView?.camera?.fieldOfView = config.defaultCamera.fieldOfView
        pointOfView?.position = config.defaultCamera.position
        pointOfView?.orientation = config.defaultCamera.orientation
        
        /*DispatchQueue.main.async {
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                guard let _self = self else {
                    timer.invalidate()
                    return
                }
                print("\ndefaultCamera: CameraPosition(")
                print("fieldOfView: \(_self.pointOfView!.camera!.fieldOfView),")
                print("position: \(_self.pointOfView!.position.desc),")
                print("orientation: \(_self.pointOfView!.orientation.desc))")
            }
        }*/
    }
    
    func applyAll(orientations: [String: GLKQuaternion]) {
        orientations.forEach {
            scnScene.rootNode.childNode(withName: $0.key, recursively: true)?.orientation = SCNQuaternion($0.value)
        }
    }
}

extension SkeletonView: SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
    }
}

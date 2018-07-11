//
//  GameViewController.swift
//  Swappy Road
//
//  Created by Swapnil Chauhan on 11/07/18.
//  Copyright © 2018 Swapnil Chauhan. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import SpriteKit

import AVFoundation
 var bgSoundPlayer:AVAudioPlayer? //add this

enum GameState {
    case menu , playing ,gameOver
}

class GameViewController: UIViewController {

    var scene: SCNScene!
    var sceneView: SCNView!
    var gameHud: GameHUD!
    var gameState = GameState.menu
    var score = 0
    
    var cameraNode = SCNNode()
    var lightNode = SCNNode()
    var playerNode = SCNNode()
    var collisionNode = CollisionNode()
    
    var mapNode = SCNNode()
    var lanes = [LaneNode]()
    var laneCount = 0
    
    //Moving the Character
    var jumpForwardAction: SCNAction?
    var jumpRightAction: SCNAction?
    var jumpLeftAction: SCNAction?
    var jumpBackwardAction: SCNAction?
    
    //Moving the Cars
    var driveRightAction: SCNAction?
    var driveLeftAction: SCNAction?
    
    var dieAction: SCNAction?
    
    var frontBlocked = false
    var rightBlocked = false
    var leftBlocked = false
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(GameViewController.playBackgroundSound(_:)), name: NSNotification.Name(rawValue: "PlayBackgroundSound"), object: nil) //add this to play audio
        
        let dictToSend: [String: String] = ["fileToPlay": "music" ]  //would play a file named "MusicOrWhatever.mp3"
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "PlayBackgroundSound"), object: self, userInfo:dictToSend)
        initialiseGame()
        
    }
    
    @objc func playBackgroundSound(_ notification: Notification) {
        
        //get the name of the file to play from the data passed in with the notification
        let name = (notification as NSNotification).userInfo!["fileToPlay"] as! String
        
        
        //if the bgSoundPlayer already exists, stop it and make it nil again
        if (bgSoundPlayer != nil){
            
            bgSoundPlayer!.stop()
            bgSoundPlayer = nil
            
            
        }
        
        //as long as name has at least some value, proceed...
        if (name != ""){
            
            //create a URL variable using the name variable and tacking on the "mp3" extension
            let fileURL:URL = Bundle.main.url(forResource:name, withExtension: "mp3")!
            
            //basically, try to initialize the bgSoundPlayer with the contents of the URL
            do {
                bgSoundPlayer = try AVAudioPlayer(contentsOf: fileURL)
            } catch _{
                bgSoundPlayer = nil
                
            }
            
            bgSoundPlayer!.volume = 0.75 //set the volume anywhere from 0 to 1
            bgSoundPlayer!.numberOfLoops = -1 // -1 makes the player loop forever
            bgSoundPlayer!.prepareToPlay() //prepare for playback by preloading its buffers.
            bgSoundPlayer!.play() //actually play
            
        }
        
        
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch gameState {
        case .menu:
            setupGestures()
            gameHud = GameHUD(size: sceneView.bounds.size, menu: false)
            sceneView.overlaySKScene = gameHud
            sceneView.overlaySKScene?.isUserInteractionEnabled = false
            gameState = .playing
        default:
            break
        }
    }
    
    func resetGame() {
        scene.rootNode.enumerateChildNodes { (node, _) in
            node.removeFromParentNode()
        }
        scene = nil
        gameState = .menu
        UserDefaults.standard.set(score, forKey: "RecentScore")
        score = 0
        laneCount = 0
        lanes = [LaneNode]()
        initialiseGame()
    }
    
    func initialiseGame() {
        setupScene()
        setupPlayer()
        setupCollisionNode()
        setupFloor()
        setupCamera()
        setupLights()
        setupActions()
        setupTraffic()
    }
    
    func setupScene() {
        sceneView = (view as! SCNView)
        sceneView.delegate = self
        
        scene = SCNScene()
        scene.physicsWorld.contactDelegate = self
        sceneView.present(scene, with: .crossFade(withDuration: 0.3), incomingPointOfView: nil, completionHandler: nil)
        
        DispatchQueue.main.async {
            self.gameHud = GameHUD(size: self.sceneView.bounds.size, menu: true)
            self.sceneView.overlaySKScene = self.gameHud
            self.sceneView.overlaySKScene?.isUserInteractionEnabled = false
        }
        
        scene.rootNode.addChildNode(mapNode)
        
        for _ in 0..<10 {
            createNewLane(initial: true)
        }
        
        for _ in 0..<10 {
            createNewLane(initial: false)
        }
        
    }
    
    func setupPlayer() {
        guard let playerScene = SCNScene(named: "art.scnassets/Chicken.scn") else {return}
        if let player = playerScene.rootNode.childNode(withName: "player", recursively: true)
        {
            playerNode = player
            playerNode.position = SCNVector3(0,0.3,0)
            scene.rootNode.addChildNode(playerNode)
        }
        
    }
    
    func setupFloor() {
        let floor = SCNFloor()
        floor.firstMaterial?.diffuse.contents = UIImage(named: "art.scnassets/darkgrass.png")
        floor.firstMaterial?.diffuse.wrapS = .repeat
        floor.firstMaterial?.diffuse.wrapT = .repeat
        floor.firstMaterial?.diffuse.contentsTransform = SCNMatrix4MakeScale(12.5, 12.5, 12.5)
        floor.reflectivity = 0.0
        let floorNode = SCNNode(geometry: floor)
        scene.rootNode.addChildNode(floorNode)
    }
    
    func setupCamera() {
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 10, 0)
        cameraNode.eulerAngles = SCNVector3(x: -toRadians(angle: 60),y: toRadians(angle: 20),z: 0)
        scene.rootNode.addChildNode(cameraNode)
    }
    
    func setupLights() {
        let ambientNode = SCNNode()
        ambientNode.light = SCNLight()
        ambientNode.light?.type = .ambient
        
        let directionalNode = SCNNode()
        directionalNode.light = SCNLight()
        directionalNode.light?.type = .directional
        directionalNode.light?.castsShadow = true
        directionalNode.light?.shadowColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
        directionalNode.position = SCNVector3(-5,5,0)
        directionalNode.eulerAngles = SCNVector3(0,-toRadians(angle: 90),-toRadians(angle: 45))
        
        lightNode.addChildNode(ambientNode)
        lightNode.addChildNode(directionalNode)
        lightNode.position = cameraNode.position
        scene.rootNode.addChildNode(lightNode)
    }
    
    
    func setupCollisionNode() {
        
        collisionNode = CollisionNode()
        collisionNode.position = playerNode.position
        scene.rootNode.addChildNode(collisionNode)
        
    }
    
    func setupGestures() {
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeUp.direction = .up
        sceneView.addGestureRecognizer(swipeUp)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeRight.direction = .right
        sceneView.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeLeft.direction = .left
        sceneView.addGestureRecognizer(swipeLeft)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeDown.direction = .down
        sceneView.addGestureRecognizer(swipeDown)
        
    }
    
    func setupActions() {
        let moveUpAction = SCNAction.move(by: SCNVector3(0,1,0), duration: 0.1)
        let moveDownAction = SCNAction.move(by: SCNVector3(0,-1,0), duration: 0.1)
        moveUpAction.timingMode = .easeOut
        moveDownAction.timingMode = .easeIn
        
        let jumpAction = SCNAction.sequence([moveUpAction,moveDownAction])
        
        let moveForwardAction = SCNAction.move(by: SCNVector3(0,0,-1), duration: 0.2)
        let moveBackwardAction = SCNAction.move(by: SCNVector3(0,0,1), duration: 0.2)
        let moveRightAction = SCNAction.move(by: SCNVector3(1,0,0), duration: 0.2)
        let moveLeftAction = SCNAction.move(by: SCNVector3(-1,0,0), duration: 0.2)
        
        let turnForwardAction = SCNAction.rotateTo(x: 0, y: toRadians(angle: 180), z: 0, duration: 0.2, usesShortestUnitArc: true)
        
        let turnBackwardAction = SCNAction.rotateTo(x: 0, y: toRadians(angle: 360), z: 0, duration: 0.2, usesShortestUnitArc: true)

        let turnRightAction = SCNAction.rotateTo(x: 0, y: toRadians(angle: 90), z: 0, duration: 0.2, usesShortestUnitArc: true)
        
        let turnLeftAction = SCNAction.rotateTo(x: 0, y: toRadians(angle: -90), z: 0, duration: 0.2, usesShortestUnitArc: true)
        
        jumpForwardAction = SCNAction.group([turnForwardAction,jumpAction,moveForwardAction])
        jumpBackwardAction = SCNAction.group([turnBackwardAction,jumpAction,moveBackwardAction])
        jumpRightAction = SCNAction.group([turnRightAction,jumpAction,moveRightAction])
        jumpLeftAction = SCNAction.group([turnLeftAction,jumpAction,moveLeftAction])
        
        
        driveRightAction = SCNAction.repeatForever(SCNAction.move(by: SCNVector3(2.0,0,0), duration: 1.0))
        driveLeftAction = SCNAction.repeatForever(SCNAction.move(by: SCNVector3(-2.0,0,0), duration: 1.0))
        
        dieAction = SCNAction.moveBy(x: 0, y: 5, z: 0, duration: 1.0)
    }
    
    func setupTraffic() {
        for lane in lanes {
            if let trafficNode = lane.trafficNode {
                addActions(for: trafficNode)
            }
        }
    }
    
    func jumpForward() {
        
        if let action = jumpForwardAction {
            addLanes()
            playerNode.runAction(action) {
                self.checkBlocks()
                self.score += 1
                self.gameHud.pointsLabel?.text = "\(self.score)"
            }
        }
        
    }
    
    func jumpBackward() {
        /*if let action = jumpBackwardAction {
            playerNode.runAction(action)
        }*/
        
    }
    
    func updatePositions() {
        
        collisionNode.position = playerNode.position
        
        let diffX = (playerNode.position.x + 1 - cameraNode.position.x)
        let diffZ = (playerNode.position.z + 2 - cameraNode.position.z)
        
        cameraNode.position.x += diffX
        cameraNode.position.z += diffZ
        lightNode.position = cameraNode.position
        
    }
    
    func updateTraffic() {
        
        for lane in lanes {
            guard let trafficNode = lane.trafficNode else {
                continue
            }
            for vehicle in trafficNode.childNodes {
                if vehicle.position.x > 10 {
                    vehicle.position.x = -10
                } else if vehicle.position.x < -10 {
                    vehicle.position.x = 10
                }
            }
        }
        
    }
    
    func addLanes() {
        for _ in 0...1 {
            createNewLane(initial: false)
        }
        removeUnusedLanes()
    }
    
    func removeUnusedLanes() {
        
        for child in mapNode.childNodes {
            if !sceneView.isNode(child , insideFrustumOf: cameraNode ) && child.worldPosition.z > playerNode.worldPosition.z{
                child.removeFromParentNode()
                lanes.removeFirst()
            }
        }
        
    }
    
    func createNewLane(initial: Bool) {
        let type = randomBool(odds: 3) || initial == true ? LaneType.grass : LaneType.road
        
        let lane = LaneNode(type: type, width: 21)
        lane.position = SCNVector3(0,0,5 - Float(laneCount))
        laneCount+=1
        lanes.append(lane)
        mapNode.addChildNode(lane)
        
        if let trafficNode = lane.trafficNode {
            addActions(for: trafficNode)
        }
    }
    
    func addActions(for trafficNode: TrafficNode)
    {
        guard let driveAction = trafficNode.directionRight ? driveRightAction : driveLeftAction else {return}
        
        driveAction.speed = 1/CGFloat(trafficNode.type + 1) + 1
        
        for vehicle in trafficNode.childNodes {
            vehicle.removeAllActions()
            vehicle.runAction(driveAction)
        }
        
    }
    
    func gameOver() {
        DispatchQueue.main.async {
            if let gestureRecognizer = self.sceneView.gestureRecognizers {
                for recognizer in gestureRecognizer {
                    self.sceneView.removeGestureRecognizer(recognizer)
                }
            }
        }
        gameState = .gameOver
        if let action = dieAction {
            playerNode.runAction(action) {
                self.resetGame()
            }
            /*playerNode.runAction(action , completionHandeler:{
                self.resetGame()
            })*/
        }
    }
    
}

extension GameViewController: SCNSceneRendererDelegate{
    
    func renderer(_ renderer: SCNSceneRenderer, didApplyAnimationsAtTime time: TimeInterval) {
        updatePositions()
        updateTraffic()
    }
    
}

extension GameViewController: SCNPhysicsContactDelegate {
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        guard let categoryA = contact.nodeA.physicsBody?.categoryBitMask , let categoryB = contact.nodeB.physicsBody?.categoryBitMask else {return}
        
        let mask = categoryA | categoryB
        
        switch mask {
        case PhysicsCategory.chicken | PhysicsCategory.vehicle :
            gameOver()
        case PhysicsCategory.vegetation | PhysicsCategory.collisionTestFront :
            frontBlocked = true
        case PhysicsCategory.vegetation | PhysicsCategory.collisionTestRight :
            rightBlocked = true
        case PhysicsCategory.vegetation | PhysicsCategory.collisionTestLeft :
            leftBlocked = true
        default:
            break
        }
    }
    
}


extension GameViewController {
    
    @objc func handleSwipe(_ sender: UISwipeGestureRecognizer) {
     
        switch sender.direction {
        case UISwipeGestureRecognizer.Direction.up:
            if !frontBlocked{
            jumpForward()
            }
        case UISwipeGestureRecognizer.Direction.down:
            jumpBackward()
        case UISwipeGestureRecognizer.Direction.right:
            if playerNode.position.x < 10 && !rightBlocked{
                if let action = jumpRightAction {
                    playerNode.runAction(action, completionHandler: {
                        self.checkBlocks()
                    })
                }
            }
        case UISwipeGestureRecognizer.Direction.left:
            if playerNode.position.x > -10 && !leftBlocked{
                if let action = jumpLeftAction {
                    playerNode.runAction(action, completionHandler: {
                        self.checkBlocks()
                    })
                }
            }
        default:
            break
        }
        
    }
    func checkBlocks() {
        
        if scene.physicsWorld.contactTest(with: collisionNode.front.physicsBody!, options: nil).isEmpty {
            frontBlocked = false
        }
        if scene.physicsWorld.contactTest(with: collisionNode.right.physicsBody!, options: nil).isEmpty {
            rightBlocked = false
        }
        if scene.physicsWorld.contactTest(with: collisionNode.left.physicsBody!, options: nil).isEmpty {
            leftBlocked = false
        }
    }
    
}


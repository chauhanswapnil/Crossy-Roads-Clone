//
//  GameHUD.swift
//  Swappy Road
//
//  Created by Swapnil Chauhan on 11/07/18.
//  Copyright © 2018 Swapnil Chauhan. All rights reserved.
//

import SpriteKit

class GameHUD: SKScene {

    var logoLabel: SKLabelNode?
    var pointsLabel: SKLabelNode?
    var tapToPlayLabel: SKLabelNode?
    var recentLabel: SKLabelNode?
    var highScoreLabel: SKLabelNode?
    
    //var unmuted = SKSpriteNode(imageNamed: "unmuted")
    //var muted = SKSpriteNode (imageNamed: "muted")
    
    init(size: CGSize, menu: Bool) {
        super.init(size: size)
        
        if menu {
            addMenuLabels()
        }
        else {
            addPointsLabel()
        }
    }
    
    func addMenuLabels() {
        
        logoLabel = SKLabelNode(fontNamed: "8BITWONDERNominal")
        tapToPlayLabel = SKLabelNode(fontNamed: "8BITWONDERNominal")
        recentLabel = SKLabelNode(fontNamed: "8BITWONDERNominal")
        highScoreLabel = SKLabelNode(fontNamed: "8BITWONDERNominal")
        
        guard let logoLabel = logoLabel ,let tapToPlayLabel  = tapToPlayLabel , let recentLabel = recentLabel , let highScoreLabel = highScoreLabel else {return}
        
        logoLabel.text = "Swappy Road"
        logoLabel.fontSize = 32.0
        logoLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(logoLabel)
        
        tapToPlayLabel.text = "Tap to Play"
        tapToPlayLabel.fontSize = 20.0
        tapToPlayLabel.position = CGPoint(x: frame.midX, y: frame.midY - logoLabel.frame.size.height-10)
        addChild(tapToPlayLabel)
        
        if UserDefaults.standard.integer(forKey: "RecentScore") > UserDefaults.standard.integer(forKey: "HighScore") {
            UserDefaults.standard.set(UserDefaults.standard.integer(forKey: "RecentScore"), forKey: "HighScore")
        }
        
        recentLabel.text = "Recent Score : \(UserDefaults.standard.integer(forKey: "RecentScore"))"
        recentLabel.fontSize = 12.0
        recentLabel.horizontalAlignmentMode = .left
        recentLabel.position = CGPoint(x: frame.minX , y: frame.maxY - recentLabel.frame.size.height * 2)
        addChild(recentLabel)
        
        //highScoreLabel.text = "High Score:"
        highScoreLabel.text = "High Score : \(UserDefaults.standard.integer(forKey: "HighScore"))"
        highScoreLabel.fontSize = 12.0
        highScoreLabel.horizontalAlignmentMode = .left
        highScoreLabel.position = CGPoint(x: frame.minX , y: frame.maxY - recentLabel.frame.size.height * 4)
        addChild(highScoreLabel)
        
        
        
    }
    
    func addPointsLabel() {
        
        pointsLabel = SKLabelNode(fontNamed: "8BITWONDERNominal")
        guard let pointsLabel = pointsLabel else {return}
        pointsLabel.text = "0"
        pointsLabel.fontSize = 40.0
        pointsLabel.position = CGPoint(x: frame.minX + pointsLabel.frame.size.width , y: frame.maxY - pointsLabel.frame.size.height * 2)
        addChild(pointsLabel)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

import SpriteKit
import GameplayKit

struct PhysicsCategory {
    static let bird:      UInt32 = 0x1 << 0
    static let object:    UInt32 = 0x1 << 1
    static let scoreZone: UInt32 = 0x1 << 2
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    private var bird = SKSpriteNode()
    private var gameStarted = false
    private var gameOver = false
    private var score = 0
    
    private var scoreBackground: SKShapeNode!
    private var scoreLabel:      SKLabelNode!
    private var centerScoreLabel: SKLabelNode!
    
    private let pipeSpeed: CGFloat         = 200
    private let pipeXScale: CGFloat        = 0.15
    private let horizontalSpacing: CGFloat = 80
    
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0, dy: -10)
        backgroundColor = .cyan
        
        setupScoreboard()
        
        centerScoreLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        centerScoreLabel.text = "0"
        centerScoreLabel.fontSize = 72
        centerScoreLabel.fontColor = .black
        centerScoreLabel.position = CGPoint(x: frame.midX, y: frame.midY + 460)
        centerScoreLabel.zPosition = 200
        addChild(centerScoreLabel)
        
        //Game objects
        createBird()
        createGround()
    }
    
    private func setupScoreboard() {
        let bgSize = CGSize(width: 120, height: 60)
        scoreBackground = SKShapeNode(rectOf: bgSize, cornerRadius: 12)
        scoreBackground.fillColor   = .white
        scoreBackground.strokeColor = .black
        scoreBackground.lineWidth   = 2
        scoreBackground.zPosition   = 100
        
        let xPos = CGFloat(20) + bgSize.width/2
        let yPos = frame.height - CGFloat(20) - bgSize.height/2
        scoreBackground.position = CGPoint(x: xPos, y: yPos)
        addChild(scoreBackground)
        
        scoreLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        scoreLabel.fontSize             = 36
        scoreLabel.fontColor            = .black
        scoreLabel.verticalAlignmentMode   = .center
        scoreLabel.horizontalAlignmentMode = .center
        scoreLabel.text                 = "0"
        scoreLabel.zPosition            = 101
        scoreLabel.position             = scoreBackground.position
        addChild(scoreLabel)
    }
    
    // Bird
    private func createBird() {
        bird = SKSpriteNode(imageNamed: "pixelbird")
        bird.setScale(0.15)
        bird.position = CGPoint(x: frame.midX, y: frame.midY)
        
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height/2)
        bird.physicsBody?.affectedByGravity = false
        bird.physicsBody?.isDynamic = true
        bird.physicsBody?.allowsRotation = false
        bird.physicsBody?.linearDamping = 0
        bird.physicsBody?.usesPreciseCollisionDetection = true
        
        bird.physicsBody?.categoryBitMask    = PhysicsCategory.bird
        bird.physicsBody?.collisionBitMask   = PhysicsCategory.object
        bird.physicsBody?.contactTestBitMask = PhysicsCategory.object
        
        addChild(bird)
    }
    
    // Ground
    private func createGround() {
        let ground = SKNode()
        ground.position = CGPoint(x: 0, y: -1000)
        ground.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: frame.width, height: 1))
        ground.physicsBody?.affectedByGravity = false
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = PhysicsCategory.object
        addChild(ground)
    }
    
    //Pipes & Scoring on Removal
    private func createPipes() {
        guard !gameOver else { return }
        
        let pipePair = SKNode()
        pipePair.position = CGPoint(x: frame.width + 10, y: 0)
        pipePair.zPosition = -1
        
        // Random vertical offset
        let gapHeight: CGFloat = 250
        let maxVar = frame.height / 4
        let yOffset = CGFloat(arc4random_uniform(UInt32(maxVar))) - maxVar/2
        
        // Top pipe
        let topPipe = SKSpriteNode(imageNamed: "pixelpipe")
        topPipe.setScale(pipeXScale)
        topPipe.zRotation = .pi
        topPipe.position = CGPoint(
            x: 0,
            y: frame.midY + topPipe.frame.height/2 + gapHeight/2 + yOffset
        )
        topPipe.physicsBody = SKPhysicsBody(rectangleOf: topPipe.frame.size)
        topPipe.physicsBody?.isDynamic = false
        topPipe.physicsBody?.categoryBitMask    = PhysicsCategory.object
        topPipe.physicsBody?.contactTestBitMask = PhysicsCategory.bird
        pipePair.addChild(topPipe)
        
        // Bottom pipe
        let bottomPipe = SKSpriteNode(imageNamed: "pixelpipe")
        bottomPipe.setScale(pipeXScale)
        bottomPipe.position = CGPoint(
            x: 0,
            y: frame.midY - bottomPipe.frame.height/2 - gapHeight/2 + yOffset
        )
        bottomPipe.physicsBody = SKPhysicsBody(rectangleOf: bottomPipe.frame.size)
        bottomPipe.physicsBody?.isDynamic = false
        bottomPipe.physicsBody?.categoryBitMask    = PhysicsCategory.object
        bottomPipe.physicsBody?.contactTestBitMask = PhysicsCategory.bird
        pipePair.addChild(bottomPipe)
        
        // Score zone
        let scoreNode = SKNode()
        scoreNode.position = CGPoint(x: 0, y: frame.midY + yOffset)
        let scoreNodeSize = CGSize(width: 5, height: gapHeight)
        scoreNode.physicsBody = SKPhysicsBody(rectangleOf: scoreNodeSize)
        scoreNode.physicsBody?.isDynamic = false
        scoreNode.physicsBody?.categoryBitMask = PhysicsCategory.scoreZone
        scoreNode.physicsBody?.contactTestBitMask = PhysicsCategory.bird
        scoreNode.physicsBody?.collisionBitMask = 0
        pipePair.addChild(scoreNode)
        
        // Move left
        let extraDistance: CGFloat = 300
        let totalDistance = frame.width + extraDistance + topPipe.frame.width
        let duration = TimeInterval(totalDistance / pipeSpeed)
        let moveAction = SKAction.moveBy(x: -totalDistance, y: 0, duration: duration)
        let removeAction = SKAction.removeFromParent()
        
        pipePair.run(.sequence([moveAction, removeAction]))
        addChild(pipePair)
    }
    
    //Touch & Start
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if gameOver {
            restart()
            return
        }
        
        if !gameStarted {
            gameStarted = true
            bird.physicsBody?.affectedByGravity = true
            
            let sample = SKSpriteNode(imageNamed: "pixelpipe")
            let pipeWidth = sample.frame.width * pipeXScale
            let desiredDist = (frame.width + 10 + pipeWidth + horizontalSpacing)*0.45
            let interval = TimeInterval(desiredDist / pipeSpeed)
            
            let spawn = SKAction.run { [weak self] in self?.createPipes() }
            let delay = SKAction.wait(forDuration: interval)
            let loop  = SKAction.repeatForever(.sequence([spawn, delay]))
            run(loop, withKey: "spawnPipes")
        }
        
        // Jump impulse
        if let body = bird.physicsBody {
            body.velocity = CGVector(dx: 0, dy: 0)
            body.applyImpulse(CGVector(dx: 0, dy: 100))
        }
    }
    
    //Collision Handling
    func didBegin(_ contact: SKPhysicsContact) {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB

        if (bodyA.categoryBitMask == PhysicsCategory.scoreZone && bodyB.categoryBitMask == PhysicsCategory.bird) ||
           (bodyB.categoryBitMask == PhysicsCategory.scoreZone && bodyA.categoryBitMask == PhysicsCategory.bird) {

            if let scoreNode = (bodyA.categoryBitMask == PhysicsCategory.scoreZone) ? bodyA.node : bodyB.node {
                scoreNode.removeFromParent()
                
                guard !gameOver else { return }
                score += 1
                
                // Update both score displays
                scoreLabel.text = "\(score)"
                centerScoreLabel.text = "\(score)"
                
                centerScoreLabel.run(SKAction.sequence([
                    SKAction.scale(to: 1.2, duration: 0.1),
                    SKAction.scale(to: 1.0, duration: 0.1)
                ]))
            }
            return
        }
        
        if (bodyA.categoryBitMask == PhysicsCategory.object && bodyB.categoryBitMask == PhysicsCategory.bird) ||
           (bodyB.categoryBitMask == PhysicsCategory.object && bodyA.categoryBitMask == PhysicsCategory.bird) {
            triggerGameOver()
        }
    }
    
    //Game Over
    private func triggerGameOver() {
        guard !gameOver else { return }
        gameOver = true

        removeAction(forKey: "spawnPipes")
        children.forEach { $0.removeAllActions() }

        let goLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        goLabel.text      = "Game Over!"
        goLabel.fontSize  = 50
        goLabel.fontColor = .black
        goLabel.position  = CGPoint(x: frame.midX, y: frame.midY + 300)
        goLabel.zPosition = 200
        addChild(goLabel)
        
        let scoreLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        scoreLabel.text      = "Score: \(self.score)"
        scoreLabel.fontSize  = 50
        scoreLabel.fontColor = .black
        scoreLabel.position  = CGPoint(x: frame.midX, y: frame.midY + 230)
        scoreLabel.zPosition = 200
        addChild(scoreLabel)
        
        let tapLabel = SKLabelNode(fontNamed: "Helvetica")
        tapLabel.text      = "Tap to restart"
        tapLabel.fontSize  = 40
        tapLabel.fontColor = .black
        tapLabel.position  = CGPoint(x: frame.midX, y: frame.midY + 180)
        tapLabel.zPosition = 200
        addChild(tapLabel)
    }
    
    //Restart Game
    private func restart() {
        // Remove all nodes
        self.removeAllChildren()
        
        // Reset game state
        gameStarted = false
        gameOver = false
        score = 0
        centerScoreLabel.text = "0"
        
        // Set up the game again
        setupScoreboard()
        createBird()
        createGround()
    }
    
    override func update(_ currentTime: TimeInterval) {
    }
}

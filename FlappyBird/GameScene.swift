//
//  GameScene.swift
//  FlappyBird
//
//  Created by 山口 彰太 on 2019/11/12.
//  Copyright © 2019 shouta.yamaguchi4. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {

    var scrollNode: SKNode!
    var wallNode:SKNode!
    var bird:SKSpriteNode!

    // 衝突判定カテゴリー
    let birdCategory: UInt32 = 1 << 0    // 0...00001
    let groundCategory: UInt32 = 1 << 1  // 0...00010
    let wallCategory: UInt32 = 1 << 2    // 0...00100
    let scoreCategory: UInt32 = 1 << 3   // 0...01000

    // スコア
    var score = 0
    var scoreLabelNode: SKLabelNode!
    var bestScoreLabelNode: SKLabelNode!
    let userDefaults: UserDefaults = UserDefaults.standard
    let BEST_SCORE_KEY = "BEST"

    // SKView上にシーンが表示された時に呼ばれる
    override func didMove(to view: SKView) {

        // 重力設定
        physicsWorld.gravity = CGVector(dx: 0, dy: -4)
        physicsWorld.contactDelegate = self

        // 背景色
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)

        // スクロールするSpriteの親Node
        scrollNode = SKNode()
        addChild(scrollNode)

        wallNode = SKNode()
        scrollNode.addChild(wallNode)

        setupGround()
        setupCloud()
        setupWall()
        setupBird()

        setupScoreLabel()
    }

    // 画面をタップした時に呼ばれる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollNode.speed > 0 {
            // 鳥の速度0に
            bird.physicsBody?.velocity = CGVector.zero
            // 鳥に縦方向の力を与える
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
        } else if bird.speed == 0 {
            restart()
        }
    }

    // SKPhysicsContactDelegateのメソッド。衝突したときに呼ばれる
    func didBegin(_ contact: SKPhysicsContact) {
        // ゲームオーバー時何もしない
        if scrollNode.speed <= 0 {
            return
        }

        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory
            || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            // スコア用の物体と衝突した
            print("ScoreUp")
            score += 1
            scoreLabelNode.text = "Score:\(score)"

            // ベストスコア更新か確認
            var bestScore = userDefaults.integer(forKey: BEST_SCORE_KEY)
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                userDefaults.set(bestScore, forKey: BEST_SCORE_KEY)
                userDefaults.synchronize()
            }
        } else {
            // 壁か地面と衝突
            print("GameOver")
            // スクロール停止
            scrollNode.speed = 0
            bird.physicsBody?.collisionBitMask = groundCategory
            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration: 1)
            bird.run(roll, completion: {
                self.bird.speed = 0
            })
        }
    }

    func restart() {
        score = 0
        scoreLabelNode.text = "Score:\(score)"

        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0

        wallNode.removeAllChildren()

        bird.speed = 1
        scrollNode.speed = 1
    }

    func setupGround() {
        // 地面の画像読み込み
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = .nearest

        // 必要な枚数計算
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2
        // スクロールするアクション作成
        // 左方向に画像一枚分スクロール
        let moveGround = SKAction.moveBy(
            x: -groundTexture.size().width, y: 0, duration: 5)
        // 元の位置に戻す
        let resetGround = SKAction.moveBy(
            x: groundTexture.size().width, y: 0, duration: 0)
        // 左にスクロール->元の位置->左にスクロールとループ
        let repeatScrollGround = SKAction.repeatForever(
            SKAction.sequence([moveGround, resetGround]))

        // groundのスプライトを配置
        for i in 0..<needNumber {
            let sprite = SKSpriteNode(texture: groundTexture)
            // スプライト表示位置を指定
            sprite.position = CGPoint(
                x: groundTexture.size().width / 2 + groundTexture.size().width * CGFloat(i),
                y: groundTexture.size().height / 2
            )
            // スプライトにアクション設定
            sprite.run(repeatScrollGround)
            // スプライトに物理演算設定
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            // 衝突カテゴリ設定
            sprite.physicsBody?.categoryBitMask = groundCategory
            // 衝突時動かないよう設定
            sprite.physicsBody?.isDynamic = false
            // スプライト追加
            scrollNode.addChild(sprite)
        }
    }

    func setupCloud() {
        // 雲の画像読み込み
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest

        // 必要な枚数
        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width + 2)
        // スクロールアクション
        // 左方向に画像一枚分スクロール
        let moveCloud = SKAction.moveBy(
            x: -cloudTexture.size().width, y: 0, duration: 20)
        // 元の位置
        let resetCloud = SKAction.moveBy(
            x: cloudTexture.size().width, y: 0, duration: 0)
        // 上記アクション繰り返し
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))

        // スプライト配置
        for i in 0..<needCloudNumber {
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100 // 一番後ろに表示させる

            // スプライト位置
            sprite.position = CGPoint(
                x: cloudTexture.size().width / 2 + cloudTexture.size().width * CGFloat(i),
                y: self.size.height - cloudTexture.size().height / 2
            )
            // スプライトアニメーション設定
            sprite.run(repeatScrollCloud)
            // スプライト追加
            scrollNode.addChild(sprite)
        }
    }

    func setupWall() {
        // 壁画像読み込み
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear

        // 移動する距離
        let movingDistance = CGFloat(
            self.frame.size.width + wallTexture.size().width)

        // 画面外まで移動するアクション
        let moveWall = SKAction.moveBy(
            x: -movingDistance, y: 0, duration: 4)
        // 自身を取り除くアクション
        let removeWall = SKAction.removeFromParent()

        // 上記アニメーションを順に実行
        let wallAnimation = SKAction.sequence([moveWall, removeWall])

        // 鳥画像サイズ
        let birdSize = SKTexture(imageNamed: "bird_a").size()
        // 鳥が通り抜ける隙間(鳥の3倍)
        let slit_length = birdSize.height * 3
        // 隙間位置の上下
        let random_y_range = birdSize.height * 3

        // 下の壁のY軸下限位置(中央位置から下方向の最大振れ幅で下の壁を表示する位置)を計算
        let groundSize = SKTexture(imageNamed: "ground").size()
        let center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
        let under_wall_lowest_y = center_y - slit_length / 2 - wallTexture.size().height / 2 - random_y_range / 2

        let createWallAnimation = SKAction.run({
            // 壁関連のノードをのせるノード
            let wall = SKNode()
            wall.position = CGPoint(
                x: self.frame.size.width + wallTexture.size().width / 2, y: 0)
            wall.zPosition = -50
            // 0~random_y_rangeまでのランダム値生成
            let random_y = CGFloat.random(in: 0..<random_y_range)
            // y軸の下限にランダム値を足して、下の壁のyを決定
            let under_wall_y = under_wall_lowest_y + random_y

            // 下壁生成
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0, y: under_wall_y)
            // 下壁に物理演算設定
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory
            // 衝突時動かないように
            under.physicsBody?.isDynamic = false
            wall.addChild(under)

            // 上壁
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(
                x: 0, y: under_wall_y + wallTexture.size().height + slit_length)
            // 下壁に物理演算設定
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory
            // 衝突時動かないように
            upper.physicsBody?.isDynamic = false
            wall.addChild(upper)

            // スコアアップ用のノード
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + birdSize.width / 2, y: self.frame.height / 2)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.isDynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
            wall.addChild(scoreNode)

            wall.run(wallAnimation)
            self.wallNode.addChild(wall)
        })

        // 次の壁作成までの待ち時間
        let wateAnimation = SKAction.wait(forDuration: 2)
        // 壁作成->時間待ち->壁作成 無限
        let repeatForeverAnimation = SKAction.repeatForever(
            SKAction.sequence([createWallAnimation, wateAnimation])
        )

        wallNode.run(repeatForeverAnimation)
    }

    func setupBird() {
        // 鳥の画像2種類読み込む
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear

        // 2種類のテクスチャを交互に変更するアニメーション
        let texturesAnimation = SKAction.animate(
            with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(texturesAnimation)

        // スプライト作成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(
            x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        // 物理演算追加
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2)
        // 衝突時回転させない
        bird.physicsBody?.allowsRotation = false
        // 衝突のカテゴリ設定
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory
        // アニメーション設定
        bird.run(flap)
        // スプライト追加
        addChild(bird)
    }

    func setupScoreLabel() {
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        scoreLabelNode.zPosition = 100
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)

        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        bestScoreLabelNode.zPosition = 100
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left

        let bestScore = userDefaults.integer(forKey: BEST_SCORE_KEY)
        bestScoreLabelNode.text = "BEST Score:\(bestScore)"
        self.addChild(bestScoreLabelNode)
    }
}

//
//  ViewController.swift
//  FlappyBird
//
//  Created by 山口 彰太 on 2019/11/12.
//  Copyright © 2019 shouta.yamaguchi4. All rights reserved.
//

import UIKit
import SpriteKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        // SKViewに型を変換
        let skView = self.view as! SKView
        // FPS表示
        skView.showsFPS = true
        // Node数表示
        skView.showsNodeCount = true
        // Viewと同じサイズでシーンを作成
        let scene = GameScene(size: skView.frame.size)
        // ViewにSceneを表示
        skView.presentScene(scene)
    }

    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }

}


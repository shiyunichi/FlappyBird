//
//  GameScene.swift
//  FlappyBird
//
//  Created by Shunichi Nukaga on 2022/06/20.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate{
    
    var scrollNode:SKNode!
    var wallNode:SKNode!
    var itemNode:SKNode!
    var bird:SKSpriteNode!
    var buckgroundMusic:SKAudioNode!
    
    //衝突判定カテゴリー
    let birdCategory: UInt32 = 1 << 0       //0...00001
    let groundCategory: UInt32 = 1 << 1     //0...00010
    let wallCategory: UInt32 = 1 << 2       //0...00100
    let scoreCategory: UInt32 =  1 << 3     //0...01000
    let itemCategory: UInt32 = 1 << 4       //0...10000
    
    //スコア用
    var score = 0
    var itemScore = 0
    var scoreLabelNode:SKLabelNode!
    var itemScoreLabelNode:SKLabelNode!
    var bestScoreLabelNode:SKLabelNode!
    let userDefaults:UserDefaults = UserDefaults.standard

    //SKView上にシーンが表示された時に呼ばれるメソッド
    override func didMove(to view: SKView) {
        
        //重力を設定
        physicsWorld.gravity = CGVector(dx: 0, dy: -4)
        physicsWorld.contactDelegate = self
        
        //背景色を設定
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)
        
        //スクロールするスプライトの親ノード
        scrollNode = SKNode()
        addChild(scrollNode)
        
        //壁用のノード
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
        //item用のノード
        itemNode = SKNode()
        scrollNode.addChild(itemNode)
        
        //各種スプライトを生成する処理をメソッドに分割
        setupGround()
        setupCloud()
        setupWall()
        setupItem()
        setupBird()
        
        //スコア表示ラベルの設定
        setupScoreLabel()
        
        //BGMを再生する
        let buckgroundMusic = SKAudioNode(fileNamed: "BGM11Loop.wav")
        
        addChild(buckgroundMusic)
        
        
    
    } //override func didMove
        
    func setupGround(){
        //地面の画像を読み込む
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = .nearest
        
        //必要な枚数を計算
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2
        
        //スクロールするアクションを作成
        //左方向に画像一枚分スクロールさせるアクション
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5)
        
        //元の位置に戻すアクション
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)
        
        //左にスクロール→元の位置→左にスクロールと無限に繰り返すアクション
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))
        
        //groundのスプライトを配置する
        for i in 0..<needNumber{
            let sprite = SKSpriteNode(texture: groundTexture)
            
            //スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: groundTexture.size().width / 2 + groundTexture.size().width * CGFloat(i),
                y: groundTexture.size().height / 2
            )
            
            //スプライトにアクションを設定する
            sprite.run(repeatScrollGround)
            
            //スプライトに物理体を設定する
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            
            //衝突のカテゴリー設定
            sprite.physicsBody?.categoryBitMask = groundCategory
            
            //衝突の時に動かないように設定する
            sprite.physicsBody?.isDynamic = false
            
            //スプライトを追加する
            scrollNode.addChild(sprite)
            
        }
        
    } //setupGround()
    
    func setupCloud(){
        
        //雲の画像を読み込む
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest
        
        //必要な枚数を計算
        let needNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2
        
        //スクロールするアクションを作成
        //左方向に画像一枚分スクロールさせるアクション
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width, y: 0, duration: 20)
        
        //元の位置に戻すアクション
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0)
        
        //左にスクロール→元の位置→左にスクロールと無限に繰り返すアクション
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))
        
        //groundのスプライトを配置する
        for i in 0..<needNumber{
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100
            
            //スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: cloudTexture.size().width / 2 + cloudTexture.size().width * CGFloat(i),
                y: self.size.height - cloudTexture.size().height / 2
            )
            
            //スプライトにアクションを設定する
            sprite.run(repeatScrollCloud)
            
            //スプライトを追加する
            scrollNode.addChild(sprite)
        }
        
    } //setupCloud()
    
    func setupWall(){
        
        //壁の画像を読み込む
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear
        
        //移動する距離を計算
        let movingDistance = self.frame.size.width + wallTexture.size().width
        
        //画面外まで移動するアクションを作成
        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration: 4)
        
        //自身を取り除くアクションを作成
        let removeWall = SKAction.removeFromParent()
        
        //２つのアニメーションを順に実行するアクションを作成
        let wallAnimation = SKAction.sequence([moveWall, removeWall])
        
        //鳥の画像サイズを取得
        let birdSize = SKTexture(imageNamed: "bird_a").size()
        
        //鳥が通り抜ける隙間の大きさを鳥のサイズの4倍とする
        let slit_length = birdSize.height * 4
        
        //隙間位置の上下の振れ幅を60ptとする
        let random_y_range: CGFloat = 60
        
        //空の中央位置（y座標）を取得
        let groundSize = SKTexture(imageNamed: "ground").size()
        let sky_center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
        
        //空の中央位置を基準にして下側の壁の中央位置を取得
        let under_wall_center_y = sky_center_y - slit_length / 2 - wallTexture.size().height / 2
        
        //壁を生成するアクションを作成
        let createWallAnimation = SKAction.run ({
            //壁をまとめるノードを作成
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0)
            wall.zPosition = -50
            
            //下側の壁の中央位置にランダム値を足して、下側の壁の表示位置を決定する
            let random_y = CGFloat.random(in: -random_y_range...random_y_range)
            let under_wall_y = under_wall_center_y + random_y
            
            //下側の壁を作成
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0, y: under_wall_y)
            
            //下側の壁に物理体を設定する
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory
            //衝突時に動かないよう設定する
            under.physicsBody?.isDynamic = false
            
            //壁をまとめるノードに下側の壁を追加
            wall.addChild(under)
            
            //上側の壁を作成
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0, y: under_wall_y + wallTexture.size().height + slit_length)
            
            //上側の壁に物理体を設定する
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory
            //衝突時に動かないよう設定する
            upper.physicsBody?.isDynamic = false
            
            //壁をまとめるノードに上側の壁を追加
            wall.addChild(upper)
            
            //スコアカウント用の透明な壁を作成
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + birdSize.width / 2, y: self.frame.height / 2)
            //透明な壁に物理体を設定する
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.isDynamic = false
            //壁をまとめるノードに透明な壁を追加
            wall.addChild(scoreNode)
            
            //壁をまとめるノードにアニメーションを設定
            wall.run(wallAnimation)
            
            //壁を表示するノードに今回作成した壁を追加
            self.wallNode.addChild(wall)
        })
            
        //次の壁作成までの時間待ちのアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        //壁を作成→時間待ち→壁を作成を無限に繰り返すアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))
        // // 壁を表示するノードに壁の作成を無限に繰り返すアクションを設定
        wallNode.run(repeatForeverAnimation)
        
    }//setupWall()
    
    func setupItem(){
        
        //itemの画像を読み込む
        let itemTexture = SKTexture(imageNamed: "coin")
        itemTexture.filteringMode = .linear
        
        //移動する距離を計算
        let movingDestance = self.frame.size.width + itemTexture.size().width
        
        //画面外まで移動するアクションを作成
        let moveItem = SKAction.moveBy(x: -movingDestance, y: 0, duration: 4)
        
        //自身を取り除くアクションを作成
        let removeItem = SKAction.removeFromParent()
        
        //2つのアニメーションを順に実行するアクションを作成
        let itemAnimation =  SKAction.sequence([moveItem, removeItem])
        
        //item位置の上下の振れ幅の設定
        let random_y_renge: CGFloat = 100
        
        //空の中央位置（y座標）を獲得
        let groundSize = SKTexture(imageNamed: "ground").size()
        let sky_center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
        
        
        let item_senter_y = sky_center_y - itemTexture.size().height / 2
        
        //itemを生成するアクションを作成
        let createItemAmimation = SKAction.run({
            let item = SKNode()
            item.position = CGPoint(x: self.frame.size.width + itemTexture.size().width / 2, y: 0)
            item.zPosition = -50
           
           //y座標の位置をランダムに設定する
            let random_y = CGFloat.random(in: -random_y_renge...random_y_renge)
            let item_y = item_senter_y + random_y
            
            //壁と壁の間のx座標の距離を算出する
            let item_x = self.frame.width / 2
            
            let coin = SKSpriteNode(texture: itemTexture)
            coin.position = CGPoint(x: item_x / 2 + 5 , y: item_y)
            
            //コインに物理体を設定する
            coin.physicsBody = SKPhysicsBody(circleOfRadius: coin.size.height / 2)
            //コインは重力の影響を受けないようにする
            coin.physicsBody?.affectedByGravity = false
            
            coin.physicsBody?.categoryBitMask = self.itemCategory
            coin.physicsBody?.isDynamic = false
            
           //print(coin.position)
            
            item.addChild(coin)
            
            item.run(itemAnimation)
            
            self.itemNode.addChild(item)
        })
        
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createItemAmimation, waitAnimation]))
        
        itemNode.run(repeatForeverAnimation)
        
    }
    
    func setupBird(){
        //鳥の２枚の画像を読み込む
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear
        
        //2種類のテクスチャを交互に変更するアニメーションを作成
        let texturesAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(texturesAnimation)
        
        //スプライトを作成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        
        //物理体を設定
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2)
        
        //カテゴリー設定
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory | itemCategory
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory | scoreCategory | itemCategory
        
        //衝突した時に回転させない
        bird.physicsBody?.allowsRotation = false
        
        //アニメーションを設定
        bird.run(flap)
        
        //スプライトを追加する
        addChild(bird)
        
    }//setupBird()
    
    func setupScoreLabel(){
        //スコア表示を作成
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        scoreLabelNode.zPosition = 100 //一番手前に表示する
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)
        
        //アイテムスコア表示を作成
        itemScore = 0
        itemScoreLabelNode = SKLabelNode()
        itemScoreLabelNode.fontColor = UIColor.black
        itemScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        itemScoreLabelNode.zPosition = 100 //一番手前に表示する
        itemScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        itemScoreLabelNode.text = "ItemScore:\(itemScore)"
        self.addChild(itemScoreLabelNode)
        
        //ベストスコアを表示
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.height - 120)
        bestScoreLabelNode.zPosition = 100 //一番手前に表示する
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        bestScoreLabelNode.text = "Best Score:\(bestScore)"
        self.addChild(bestScoreLabelNode)
    }
    
    //SKPhysicsContactDelegateのメソッド。衝突した時に呼ばれる
    func didBegin(_ contact: SKPhysicsContact) {
        //ゲームオーバーの時には何もしない
        if scrollNode.speed <= 0{
            return
        }
        
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
           
            //スコアカウント用の透明な壁と衝突した
            print("--- 隙間通過 ---")
            score += 1
            scoreLabelNode.text = "Score:\(score)"
            
            //ベストスコア更新か確認する
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score + itemScore > bestScore{
                bestScore = score + itemScore
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                userDefaults.set(bestScore, forKey: "BEST")
                userDefaults.synchronize()
            }
            
        }else if (contact.bodyA.categoryBitMask & itemCategory) == itemCategory || (contact.bodyB.categoryBitMask & itemCategory) == itemCategory {
            
            contact.bodyA.categoryBitMask = 0
            contact.bodyB.categoryBitMask = 0
            
            self.removeChildren(in: [itemNode!])
            
            //itemと衝突した
            print("---coinに衝突---")
            itemScore += 1
            itemScoreLabelNode.text = "ItemScore:\(itemScore)"
            
            
            //衝突時の効果音を鳴らす
            let actionSound = SKAction.playSoundFileNamed("Coin.wav", waitForCompletion: true)
            self.run(actionSound)
            
            //ベストスコア更新か確認する
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score + itemScore > bestScore{
                bestScore = score + itemScore
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                userDefaults.set(bestScore, forKey: "BEST")
                userDefaults.synchronize()
            }
            
            
        }else{
            //壁か地面と衝突した
            print("GameOver")
            
            //スクロールを停止させる
            scrollNode.speed = 0
            
            //衝突後は地面と反発するのみとする（リスタートするまで壁と反発させない）
            bird.physicsBody?.collisionBitMask = groundCategory
            
            //衝突後１秒間、鳥をくるくる回転させる
            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration: 1)
            bird.run(roll, completion: {
                self.bird.speed = 0
            })
        }
        
    }//didBegin
    
    func restart(){
        //スコアを０にする
        score = 0
        itemScore = 0
        scoreLabelNode.text = "Score:\(score)"
        itemScoreLabelNode.text = "ItemScore:\(itemScore)"
        
        //鳥を初期位置に戻し、壁と地面の両方に反発するように戻す
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0
        
        //全ての壁を取り除く
        wallNode.removeAllChildren()
        //全てのコインを取り除く
        itemNode.removeAllChildren()
        //鳥の羽ばたきを戻す
        bird.speed = 1
        
        //スクロールを再開させる
        scrollNode.speed = 1
        
    }//restart
    
    //画面をタップした時に呼ばれる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollNode.speed > 0{
            
            //鳥の速度をゼロにする
            bird.physicsBody?.velocity = CGVector.zero
        
            //鳥に縦方向の力を与える
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
        }else if bird.speed == 0{
            restart()
        }
    }
        
}

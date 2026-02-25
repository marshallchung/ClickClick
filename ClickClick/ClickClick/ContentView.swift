//
//  ContentView.swift
//  ClickClick
//
//  Created by Marshall Chung on 2026/2/25.
//

import SwiftUI
internal import Combine

// 定義遊戲的所有狀態
enum GameState {
    case ready      // 準備開始
    case starting   // 倒數中
    case playing    // 遊玩中
    case paused     // 暫停
    case gameOver   // 遊戲結束
}

struct ContentView: View {
    // 遊戲狀態控制
    @State private var gameState: GameState = .ready
    
    // 遊戲數據
    @State private var score: Int = 0
    @State private var timeRemaining: Int = 30
    @State private var countdown: Int = 3
    
    // 記錄目前「紅色區域」的編號 (0, 1, 2, 3)
    @State private var targetArea: Int = Int.random(in: 0...3)
    
    // 計時器 (每秒觸發一次)
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // 背景底色
            Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all)
            
            // --- 遊戲主畫面 ---
            VStack(spacing: 20) {
                // 頂部資訊列 (分數、時間、暫停按鈕)
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("分數：\(score)")
                            .font(.system(size: 50, weight: .bold))
                        Text("時間：\(timeRemaining) 秒")
                            .font(.system(size: 40, weight: .medium))
                            // 時間小於等於5秒時變紅色提醒
                            .foregroundColor(timeRemaining <= 5 && gameState == .playing ? .red : .primary)
                    }
                    
                    Spacer()
                    
                    // 暫停按鈕
                    Button(action: {
                        if gameState == .playing {
                            gameState = .paused
                        }
                    }) {
                        Image(systemName: "pause.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.primary)
                    }
                    // 只有在遊玩中此按鈕才有實際作用跟顯示
                    .opacity(gameState == .playing ? 1 : 0)
                    .disabled(gameState != .playing)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                Spacer()
                
                // 遊戲區塊：2x2 十字四等分
                VStack(spacing: 15) {
                    HStack(spacing: 15) {
                        createButton(areaIndex: 0)
                        createButton(areaIndex: 1)
                    }
                    HStack(spacing: 15) {
                        createButton(areaIndex: 2)
                        createButton(areaIndex: 3)
                    }
                }
                .padding()
                
                Spacer()
                Spacer()
            }
            // 顯示選單時稍微模糊背景，讓視覺更聚焦在選單上
            .blur(radius: (gameState == .playing || gameState == .starting) ? 0 : 5)
            
            // --- 狀態遮罩與跳出選單 ---
            if gameState != .playing {
                // 半透明黑色遮罩擋住後面遊戲區
                Color.black.opacity(0.6)
                    .edgesIgnoringSafeArea(.all)
            }
            
            switch gameState {
            case .ready:
                VStack(spacing: 30) {
                    Text("ClickClick")
                        .font(.system(size: 50, weight: .black))
                        .foregroundColor(.white)
                    
                    Button(action: {
                        startGame()
                    }) {
                        menuButtonText("開始遊戲", color: .blue)
                    }
                }
                
            case .starting:
                // 倒數 3 秒畫面
                Text("\(countdown)")
                    .font(.system(size: 120, weight: .bold))
                    .foregroundColor(.white)
                
            case .paused:
                VStack(spacing: 30) {
                    Text("遊戲暫停")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                    
                    VStack(spacing: 15) {
                        Button(action: {
                            gameState = .playing
                        }) {
                            menuButtonText("繼續", color: .green)
                        }
                        
                        Button(action: {
                            startGame()
                        }) {
                            menuButtonText("重新開始", color: .red)
                        }
                    }
                }
                
            case .gameOver:
                VStack(spacing: 30) {
                    Text("時間到！")
                        .font(.system(size: 60, weight: .black))
                        .foregroundColor(.red)
                    
                    Text("最終得分：\(score)")
                        .font(.system(size: 60, weight: .black))
                        .foregroundColor(.yellow)
                    
                    Button(action: {
                        startGame()
                    }) {
                        menuButtonText("重新開始", color: .blue)
                    }
                }
                
            case .playing:
                EmptyView()
            }
        }
        // 計時器邏輯
        .onReceive(timer) { _ in
            switch gameState {
            case .starting:
                if countdown > 1 {
                    countdown -= 1
                    // 短震動，增加倒數感
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                } else {
                    // 倒數結束，開始遊戲
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    gameState = .playing
                    timeRemaining = 30
                }
            case .playing:
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    // 30 秒結束，時間到顯示結算畫面
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                    gameState = .gameOver
                }
            default:
                break
            }
        }
    }
    
    // --- 輔助函式 ---
    
    // 遊戲按鈕區塊
    func createButton(areaIndex: Int) -> some View {
        Rectangle()
            .fill(areaIndex == targetArea ? Color.red : Color.gray.opacity(0.3))
            .aspectRatio(1.0, contentMode: .fit)
            .cornerRadius(15)
            // 點下(Touch Down)就觸發
            .onLongPressGesture(minimumDuration: 0.0) {
                // 【重要】加上判斷：只有在「遊玩中」才能點擊得分
                guard gameState == .playing else { return }
                
                if areaIndex == targetArea {
                    // 1. 觸發震動回饋
                    let generator = UIImpactFeedbackGenerator(style: .heavy)
                    generator.impactOccurred()
                    
                    // 2. 加 1 分
                    score += 1
                    
                    // 3. 更換紅色區域，保證下一次不重複
                    var newTarget = Int.random(in: 0...3)
                    while newTarget == targetArea {
                        newTarget = Int.random(in: 0...3)
                    }
                    targetArea = newTarget
                    
                } else {
                    // 點錯扣 1 分
                    score -= 1
                }
            }
    }
    
    // 選單按鈕的共用外觀
    func menuButtonText(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.title2.bold())
            .foregroundColor(.white)
            .frame(width: 200, height: 60)
            .background(color)
            .cornerRadius(15)
            .shadow(radius: 5)
    }
    
    // 初始化並開始遊戲
    func startGame() {
        score = 0
        timeRemaining = 30
        countdown = 3
        targetArea = Int.random(in: 0...3)
        gameState = .starting
    }
}

#Preview {
    ContentView()
}

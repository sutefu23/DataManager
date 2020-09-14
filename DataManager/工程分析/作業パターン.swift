//
//  作業パターン.swift
//  DataManager
//
//  Created by manager on 2020/09/10.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

/// 材料生成
enum Pattern1 {
    case 原稿入力レーザー
    case 原稿レーザー
    case 原稿入力レーザータレパン
    case 原稿入力レーザー照合
    case 原稿ルーター
    case 原稿タレパン
    case 原稿フィルム
}

enum Pattern2 {
    case 切文字
    case 加工
    case オブジェ
    case 腐蝕
    case 印刷
    case 立ち上がり半田裏加工
    case 立ち上がり溶接裏加工
}

enum Pattern3 {
    case 表面仕上
    case 研磨表面仕上
    case 表面仕上塗装乾燥炉
    case 表面仕上塗装拭き取り
}


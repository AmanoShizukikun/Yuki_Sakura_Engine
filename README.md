# Yuki_Sakura_Engine

[![GitHub Repo stars](https://img.shields.io/github/stars/AmanoShizukikun/Yuki_Sakura_Engine?style=social)](https://github.com/AmanoShizukikun/Yuki_Sakura_Engine/stargazers)
[![GitHub last commit](https://img.shields.io/github/last-commit/AmanoShizukikun/Yuki_Sakura_Engine)](https://github.com/AmanoShizukikun/Yuki_Sakura_Engine/commits/main)
[![GitHub release](https://img.shields.io/github/v/release/AmanoShizukikun/Yuki_Sakura_Engine)](https://github.com/AmanoShizukikun/Yuki_Sakura_Engine/releases)

\[ 中文 | [English](https://github.com/AmanoShizukikun/Yuki_Sakura_Engine/blob/main/assets/docs/README_en.md) | [日本語](https://github.com/AmanoShizukikun/Yuki_Sakura_Engine/blob/main/assets/docs/README_jp.md) \]

## 簡介
「雪櫻引擎 Yuki_Sakura_Engine」是由 Processing 4 撰寫的簡易 Galgame 遊戲引擎。

## 公告

## 近期變動
### 1.0.0 PRE (2025 年 6 月 16 日)
![t2i](https://github.com/AmanoShizukikun/Yuki_Sakura_Engine/blob/main/assets/preview/1.0.0.jpg)
### 重要變更
- 【重大】首個發布版本。
### 新增功能
- 【新增】簡易的引擎示範 Demo.pde (將透過 Patch 補丁更新不列入引擎版本)。
- 【新增】調適 OSD 可即時查看遊戲幀數，畫面寬度及當前引擎模式。
- 【新增】多特效場景切換系統，畫面特效系統。
- 【更新】自動播放功能，確保角色說完話才進入下一個節點。
- 【更新】智能素材加載功能，會自動判斷腳本中的物件自動加載資源。
### 已知問題
- 【問題】引擎運行較率低，在高分辨率視窗下會出現卡頓。
- 【問題】缺乏容錯能力，用錯誤的腳本運行遊戲引擎會當機。
- 【錯誤】由於透過角色名成判斷說話對象高光，可能判斷非英文語言時會出現錯誤。

[所有發行版本](https://github.com/AmanoShizukikun/Yuki_Sakura_Engine/blob/main/assets/docs/Changelog.md)

## 快速開始
> [!NOTE]
> Processing 為必要安裝項。
### 環境設置
- **Processing 4.4.4**
  - 下載: https://github.com/processing/processing4/releases/download/processing-1304-4.4.4/processing-4.4.4-windows-x64.msi

> [!TIP]
> 請按照當前以下說明安裝對應的 Processing 套件。
### 安裝倉庫
> [!IMPORTANT]
> 此為必要步驟。
```shell
git clone https://github.com/AmanoShizukikun/Yuki_Sakura_Engine.git
cd Yuki_Sakura_Engine
```
## 必要套件
```shell
Minim 2.2.2
Video Library for Processing 4
```

## 待辦事項
- [ ] **高優先度：**
  - [x] 快速安裝指南。
  - [ ] 使用指南(wiki)。

- [ ] **功能:**
  - 程式
    - [x] 文字對話框。
    - [x] 分支選項。
    - [x] 多特效場景切換系統。
    - [x] 標題功能。
    - [x] 存檔系統。
    - [x] 畫面縮放功能。
    - [x] BGM切換功能。
    - [x] 自動播放功能。
    - [x] 快轉功能。

## 致謝
特別感謝以下項目和貢獻者：

### 項目
- [processing4](https://github.com/processing/processing4)

### 貢獻者
<a href="https://github.com/AmanoShizukikun/Yuki_Sakura_Engine/graphs/contributors" target="_blank">
  <img src="https://contrib.rocks/image?repo=AmanoShizukikun/Yuki_Sakura_Engine" />
</a>

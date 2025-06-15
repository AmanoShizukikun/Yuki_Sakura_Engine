// 導入庫
import ddf.minim.*;
import processing.video.*;

// 遊戲狀態
GameState gameState;
DialogueSystem dialogueSystem;
CharacterManager characterManager;
BackgroundManager backgroundManager;
SaveSystem saveSystem;
AudioManager audioManager;
SettingsManager settingsManager;
GameConfig gameConfig;
TitleScreen titleScreen; 

// Logo影片變數
Movie logoMovie;
boolean logoPlaying = false;
boolean logoFinished = false;
long logoStartTime = 0;
boolean gameInitialized = false;

// 遊戲狀態
enum GameMode {
  LOGO,
  TITLE,
  GAME,
  SETTINGS,
  LOAD_GAME
}

GameMode currentMode = GameMode.LOGO;

// 性能優化變數
PGraphics uiBuffer;
PGraphics dialogueBuffer;
boolean uiNeedsUpdate = true;
boolean dialogueNeedsUpdate = true;
int targetFPS = 60;

// 視窗縮放相關變數
int lastWidth = 1280;
int lastHeight = 720;
boolean windowResized = false;

// 引擎資訊
void printEngineInfo() {
  println("=== 引擎資訊 ===");
  println("名稱: 雪櫻引擎 Yuki_Sakura_Engine");
  println("版本: 1.0.0");
  println("作者: 天野靜樹");
}

void setup() {
  size(1280, 720);
  surface.setResizable(true);
  printEngineInfo();
  gameConfig = new GameConfig();
  loadGameConfig();
  gameConfig.printGameInfo();
  println("\n=== 系統資訊 ===");
  if (surface instanceof processing.awt.PSurfaceAWT) {
    processing.awt.PSurfaceAWT awtSurface = (processing.awt.PSurfaceAWT) surface;
    java.awt.Canvas canvas = (java.awt.Canvas) awtSurface.getNative();
    java.awt.Window window = javax.swing.SwingUtilities.getWindowAncestor(canvas);
    if (window instanceof java.awt.Frame) {
      java.awt.Frame frame = (java.awt.Frame) window;
      frame.setTitle(gameConfig.getGameTitle());
      frame.setAlwaysOnTop(false);
    }
  }
  frameRate(targetFPS);
  uiBuffer = createGraphics(width, height);
  dialogueBuffer = createGraphics(width, height);
  try {
    initializeLogo();
  } catch (Exception e) {
    println("遊戲初始化失敗: " + e.getMessage());
    e.printStackTrace();
    initializeGame();
  }
}

void loadGameConfig() {
  try {
    configureGameSettings(gameConfig);
    println("遊戲配置載入完成: " + gameConfig.getGameTitle());
  } catch (Exception e) {
    println("載入遊戲配置時出錯，使用預設值: " + e.getMessage());
  }
}

// 遊戲配置類
class GameConfig {
  private String gameTitle = "雪櫻引擎 Ver 1.0.0 Unknown Project";
  private String gameVersion = "Unknown";
  private String gameAuthor = "Unknown";
  private String gameDescription = "Unknown";
  String getGameTitle() { return gameTitle; }
  String getGameVersion() { return gameVersion; }
  String getGameAuthor() { return gameAuthor; }
  String getGameDescription() { return gameDescription; }
  void setGameTitle(String title) { 
    if (title != null && !title.trim().isEmpty()) {
      this.gameTitle = title.trim();
    }
  }
  void setGameVersion(String version) { 
    if (version != null && !version.trim().isEmpty()) {
      this.gameVersion = version.trim();
    }
  }
  void setGameAuthor(String author) { 
    if (author != null && !author.trim().isEmpty()) {
      this.gameAuthor = author.trim();
    }
  }
  void setGameDescription(String description) { 
    if (description != null && !description.trim().isEmpty()) {
      this.gameDescription = description.trim();
    }
  }
  
  // 顯示遊戲資訊
  void printGameInfo() {
    println("\n=== 遊戲資訊 ===");
    println("標題: " + gameTitle);
    println("版本: " + gameVersion);
    println("作者: " + gameAuthor);
    println("描述: " + gameDescription);
  }
}

// 檢查視窗是否被縮放
void checkWindowResize() {
  if (width != lastWidth || height != lastHeight) {
    windowResized = true;
    lastWidth = width;
    lastHeight = height;
    uiBuffer = createGraphics(width, height);
    dialogueBuffer = createGraphics(width, height);
    if (characterManager != null) {
      characterManager.updateAllCharacterPositions();
    }
    uiNeedsUpdate = true;
    dialogueNeedsUpdate = true;
    println("視窗已縮放至: " + width + "x" + height);
  }
}

// Logo初始化函數
void initializeLogo() {
  try {
    delay(100);
    File logoFile = new File(sketchPath("data/logo/logo.mp4"));
    if (!logoFile.exists()) {
      println("Logo影片檔案不存在: " + logoFile.getAbsolutePath());
      initializeGame();
      return;
    }
    println("嘗試載入Logo影片: ");
    println(logoFile.getAbsolutePath());
    logoMovie = new Movie(this, logoFile.getAbsolutePath());
    delay(50);
    if (logoMovie != null) {
      logoMovie.volume(0.5);
      logoMovie.play();
      logoPlaying = true;
      logoFinished = false;
      logoStartTime = millis();
      currentMode = GameMode.LOGO;
      println("Logo載入成功");
    } else {
      println("Logo影片物件創建失敗");
      initializeGame();
    } 
  } catch (Exception e) {
    println("Logo影片載入失敗: " + e.getMessage());
    e.printStackTrace();
    try {
      println("嘗試使用相對路徑載入Logo影片");
      logoMovie = new Movie(this, "data/logo/logo.mp4");
      if (logoMovie != null) {
        logoMovie.play();
        logoPlaying = true;
        logoFinished = false;
        logoStartTime = millis();
        currentMode = GameMode.LOGO;
        println("Logo影片備用載入成功");
      } else {
        throw new RuntimeException("備用載入也失敗");
      }
    } catch (Exception e2) {
      println("Logo影片備用載入也失敗: " + e2.getMessage());
      initializeGame();
    }
  }
}

// 遊戲初始化函數
void initializeGame() {
  if (gameInitialized) return;
  try {
    gameState = new GameState();
    dialogueSystem = new DialogueSystem();
    characterManager = new CharacterManager();
    backgroundManager = new BackgroundManager();
    saveSystem = new SaveSystem();
    audioManager = new AudioManager(this);
    settingsManager = new SettingsManager();
    titleScreen = new TitleScreen(); 
    createStoryScript();
    PFont font = createFont("Microsoft JhengHei", 30);
    textFont(font);
    settingsManager.loadSettings();
    gameInitialized = true;
    logoFinished = true;
    logoPlaying = false;
    currentMode = GameMode.TITLE; 
    println("遊戲初始化成功！");
    println("================");
  } catch (Exception e) {
    println("遊戲初始化失敗: " + e.getMessage());
    e.printStackTrace();
  }
}

void draw() {
  checkWindowResize();
  switch(currentMode) {
    case LOGO:
      if (logoPlaying && !logoFinished && !gameInitialized) {
        drawLogo();
        return;
      } else if (!gameInitialized) {
        initializeGame();
        return;
      } else {
        currentMode = GameMode.TITLE;
      }
      break;
    case TITLE:
      if (!gameInitialized) {
        background(0);
        fill(255);
        textAlign(CENTER);
        textSize(24);
        text("載入中...", width/2, height/2);
        return;
      }
      if (audioManager != null) {
        audioManager.update();
      }
      titleScreen.display();
      break;
    case GAME:
      drawGame();
      break;
    case SETTINGS:
      if (audioManager != null) {
        audioManager.update();
      }
      titleScreen.display(); 
      if (settingsManager != null) {
        settingsManager.display();
      }
      break;
    case LOAD_GAME:
      if (audioManager != null) {
        audioManager.update();
      }
      titleScreen.display();
      if (saveSystem != null) {
        saveSystem.display();
      }
      break;
  }
  
  // 顯示FPS（調試用）
  if (keyPressed && key == 'f') {
    fill(255, 255, 0);
    textAlign(LEFT);
    textSize(12);
    text("FPS: " + int(frameRate), 10, height - 20);
    text("視窗尺寸: " + width + "x" + height, 10, height - 40);
    text("模式: " + currentMode, 10, height - 60);
  }
  
  // 重置縮放標記
  windowResized = false;
}

// 遊戲畫面繪製
void drawGame() {
  if (!gameInitialized) return;
  background(0);
  if (audioManager != null) {
    audioManager.update();
  }
  if (backgroundManager != null) {
    backgroundManager.display();
  }
  if (characterManager != null) {
    characterManager.update();
    characterManager.display();
  }
  if (dialogueSystem != null) {
    dialogueSystem.display();
    if (dialogueSystem.showingMenu) {
      dialogueSystem.drawMenu();
    }
  }
  if (settingsManager != null && settingsManager.showingSettings) {
    settingsManager.display();
  }
  if (saveSystem != null && saveSystem.showingSaveMenu) {
    saveSystem.display();
  }
}

// Logo繪製函數
void drawLogo() {
  background(0);
  if (logoMovie != null && logoMovie.available()) {
    logoMovie.read();
  }
  if (logoMovie != null) {
    pushMatrix();
    float logoScale = min(width / (float)logoMovie.width, height / (float)logoMovie.height);
    translate(width/2, height/2);
    scale(logoScale);
    imageMode(CENTER);
    image(logoMovie, 0, 0);
    popMatrix();
    checkLogoCompletion();
  }
}

// Logo完成狀態檢查
void checkLogoCompletion() {
  if (logoMovie != null) {
    try {
      if (!logoMovie.isPlaying()) {
        finishLogo();
        return;
      }
    } catch (Exception e) {
      println("檢查Logo狀態時出錯: " + e.getMessage());
      finishLogo();
    }
  }
}

// 完成Logo播放
void finishLogo() {
  logoPlaying = false;
  if (logoMovie != null) {
    try {
      logoMovie.stop();
      logoMovie.dispose();
    } catch (Exception e) {
      println("清理Logo影片時出錯: " + e.getMessage());
    }
    logoMovie = null;
  }
  println("Logo播放結束");
}

void mousePressed() {
  switch(currentMode) {
    case LOGO:
      if (logoPlaying && !gameInitialized) {
        println("用戶點擊跳過Logo");
        finishLogo();
        return;
      }
      break;
    case TITLE:
      if (titleScreen != null) {
        titleScreen.handleClick(mouseX, mouseY);
      }
      break;
    case GAME:
      if (!gameInitialized) return;
      if (settingsManager.showingSettings) {
        settingsManager.handleClick(mouseX, mouseY);
      } else if (saveSystem.showingSaveMenu) {
        saveSystem.handleClick(mouseX, mouseY);
      } else {
        dialogueSystem.handleClick(mouseX, mouseY);
      }
      break;
    case SETTINGS:
      if (settingsManager != null) {
        settingsManager.handleClick(mouseX, mouseY);
      }
      break;
    case LOAD_GAME:
      if (saveSystem != null) {
        saveSystem.handleClick(mouseX, mouseY);
      }
      break;
  }
}

void keyPressed() {
  switch(currentMode) {
    case LOGO:
      if (logoPlaying && !gameInitialized) {
        println("用戶跳過Logo");
        finishLogo();
        return;
      }
      break;
    case TITLE:
      if (key == ESC) {
        key = 0; 
      }
      break;
    case GAME:
      if (!gameInitialized) return;
      if (settingsManager.showingSettings || saveSystem.showingSaveMenu) {
        if (key == ESC) {
          settingsManager.showingSettings = false;
          saveSystem.showingSaveMenu = false;
          key = 0; 
        }
        return;
      }
      
      // Ctrl 快轉功能
      if (keyCode == CONTROL) {
        dialogueSystem.setFastForward(true);
        return;
      }
      if (key == ' ' || key == ENTER) {
        dialogueSystem.nextDialogue();
      } else if (dialogueSystem.showingChoices && key >= '1' && key <= '9') {
        int choiceIndex = key - '1';
        if (choiceIndex < dialogueSystem.currentNode.choices.size()) {
          dialogueSystem.selectChoice(choiceIndex);
        }
      } else if (key == ESC) {
        dialogueSystem.toggleMenu();
        key = 0;
      } else if (key == 's' || key == 'S') {
        if (keyPressed && (keyCode == CONTROL || keyCode == 157)) { // Ctrl+S
          saveSystem.quickSave();
        }
      } else if (key == 'l' || key == 'L') {
        if (keyPressed && (keyCode == CONTROL || keyCode == 157)) { // Ctrl+L
          saveSystem.quickLoad();
        }
      }
      break;
      
    case SETTINGS:
      if (key == ESC) {
        currentMode = GameMode.TITLE;
        settingsManager.showingSettings = false;
        key = 0;
      }
      break;
      
    case LOAD_GAME:
      if (key == ESC) {
        currentMode = GameMode.TITLE;
        saveSystem.showingSaveMenu = false;
        key = 0;
      }
      break;
  }
}

// 開始新遊戲
void startNewGame() {
  currentMode = GameMode.GAME;
  gameState = new GameState();
  dialogueSystem.currentNodeId = "start";
  dialogueSystem.currentNode = null;
  dialogueSystem.showingChoices = false;
  dialogueSystem.showingMenu = false;
  dialogueSystem.showingHistory = false;
  dialogueSystem.autoPlay = false;
  dialogueSystem.textDisplayIndex = 0;
  dialogueSystem.textComplete = false;
  characterManager.clearAllCharacters();
  characterManager.activeCharacters.clear();
  backgroundManager.setBackground("default");
  audioManager.playBGM("default");
  for (int i = 0; i < dialogueSystem.choiceHover.length; i++) {
    dialogueSystem.choiceHover[i] = false;
  }
  dialogueSystem.hoveredChoice = -1;
  println("開始新遊戲");
}

// 返回標題畫面
void returnToTitle() {
  currentMode = GameMode.TITLE;
  if (audioManager != null) {
    audioManager.playBGM("title");
  }
  println("返回標題畫面");
}

void movieEvent(Movie m) {
  m.read();
}

// 當放開 Ctrl 鍵時停止快轉
void keyReleased() {
  if (keyCode == CONTROL) {
    dialogueSystem.setFastForward(false);
  }
}

// 程式結束時清理資源
void exit() {
  if (audioManager != null) {
    audioManager.dispose();
  }
  super.exit();
}

// 標題畫面類
class TitleScreen {
  PImage titleBackground;
  String[] menuItems = {"開始遊戲", "讀取存檔", "系統設定", "結束遊戲"};
  int hoveredItem = -1;
  float titleAlpha = 0;
  long titleStartTime;
  
  TitleScreen() {
    titleStartTime = millis();
    loadTitleBackground();
    if (audioManager != null) {
      audioManager.playBGM("title");
    }
  }
  
  void loadTitleBackground() {
    try {
      titleBackground = loadImage("data/backgrounds/title.png");
      if (titleBackground == null) {
        titleBackground = loadImage("data/backgrounds/title.jpg");
      }
      if (titleBackground != null) {
        println("✓ 標題背景載入成功");
      } else {
        println("⚠ 標題背景載入失敗，使用預設背景");
      }
    } catch (Exception e) {
      println("⚠ 標題背景載入失敗: " + e.getMessage());
      titleBackground = null;
    }
  }
  
  void display() {
    if (titleBackground != null) {
      imageMode(CORNER);
      image(titleBackground, 0, 0, width, height);
    } else {
      drawDefaultBackground();
    }
    float elapsed = millis() - titleStartTime;
    titleAlpha = constrain(elapsed / 2000.0 * 255, 0, 255);
    fill(255, 255, 255, titleAlpha);
    textAlign(CENTER);
    textSize(48);
    text(gameConfig.getGameTitle(), width/2, height/4);
    drawMenuItems();
    fill(150, 150, 150, titleAlpha * 0.6);
    textAlign(CENTER);
    textSize(12);
    text("© 2025 Amano Shizuki. All rights reserved.", width/2, height - 30);
  }
  
  void drawDefaultBackground() {
    for (int i = 0; i <= height; i++) {
      float inter = map(i, 0, height, 0, 1);
      color c = lerpColor(color(10, 20, 40), color(40, 60, 100), inter);
      stroke(c);
      line(0, i, width, i);
    }
    noStroke();
    fill(255, 192, 203, 100);
    for (int i = 0; i < 20; i++) {
      float x = (noise(frameCount * 0.01 + i) - 0.5) * width * 1.5 + width/2;
      float y = (noise(frameCount * 0.008 + i + 100) - 0.5) * height * 1.5 + height/2;
      float size = noise(i + 200) * 15 + 5;
      ellipse(x, y, size, size);
    }
  }
  
  void drawMenuItems() {
    float menuY = height * 0.6;
    float itemSpacing = 60;
    hoveredItem = -1;
    for (int i = 0; i < menuItems.length; i++) {
      float y = menuY + i * itemSpacing;
      if (mouseX >= width/2 - 120 && mouseX <= width/2 + 120 &&
          mouseY >= y - 25 && mouseY <= y + 25) {
        hoveredItem = i;
      }
      if (hoveredItem == i) {
        fill(100, 150, 255, 100);
        rect(width/2 - 120, y - 25, 240, 50, 10);
        stroke(100, 150, 255, 150);
        strokeWeight(2);
        noFill();
        rect(width/2 - 120, y - 25, 240, 50, 10);
        noStroke();
      }
      if (hoveredItem == i) {
        fill(255, 255, 255, titleAlpha);
      } else {
        fill(220, 220, 220, titleAlpha * 0.9);
      }
      textAlign(CENTER);
      textSize(24);
      text(menuItems[i], width/2, y + 8);
    }
  }
  
  void handleClick(int mouseX, int mouseY) {
    float menuY = height * 0.6;
    float itemSpacing = 60;
    for (int i = 0; i < menuItems.length; i++) {
      float y = menuY + i * itemSpacing;
      if (mouseX >= width/2 - 120 && mouseX <= width/2 + 120 &&
          mouseY >= y - 25 && mouseY <= y + 25) {
        if (audioManager != null) {
          audioManager.playSFX("menu_click");
        }
        handleMenuSelection(i);
        return;
      }
    }
  }
  
  void handleMenuSelection(int selectedIndex) {
    switch(selectedIndex) {
      case 0:
        println("選擇：開始新遊戲");
        startNewGame();
        break;
        
      case 1:
        println("選擇：讀取存檔");
        currentMode = GameMode.LOAD_GAME;
        if (saveSystem != null) {
          saveSystem.showSaveMenu(false);
        }
        break;
        
      case 2:
        println("選擇：系統設定");
        currentMode = GameMode.SETTINGS;
        if (settingsManager != null) {
          settingsManager.showingSettings = true;
        }
        break;
        
      case 3:
        println("選擇：結束遊戲");
        exit();
        break;
        
      default:
        println("未知的選單選項: " + selectedIndex);
        break;
    }
  }
}

// 遊戲狀態管理器
class GameState {
  int currentChapter = 1;
  String currentChapterName = "Chapter 1";
  int friendshipPoints = 0;
  int lovePoints = 0;
  boolean metHeroine = false;
  String playerName = "主角";
  ArrayList<String> visitedNodes;
  ArrayList<String> dialogueHistory;
  boolean autoMode = false;
  boolean skipMode = false;
  
  GameState() {
    visitedNodes = new ArrayList<String>();
    dialogueHistory = new ArrayList<String>();
  }
  
  void addFriendship(int points) {
    friendshipPoints += points;
  }
  
  void addLove(int points) {
    lovePoints += points;
  }
  
  void setChapter(int chapter, String name) {
    currentChapter = chapter;
    currentChapterName = name;
    println("章節更新: 第 " + chapter + " 章 - " + name);
  }
  
  void addToHistory(String nodeId, String dialogueText) {
    visitedNodes.add(nodeId);
    dialogueHistory.add(dialogueText);
  }
  
  boolean hasVisited(String nodeId) {
    return visitedNodes.contains(nodeId);
  }
}

// 對話節點類
class DialogueNode {
  String speaker;
  String text;
  String background;
  String characterImage;
  String characterPosition;
  String characterEmotion;
  ArrayList<Choice> choices;
  String nextNode;
  String voiceFile;
  String soundEffect;
  String transition;
  ArrayList<SceneCommand> commands;
  
  DialogueNode(String speaker, String text, String bg, String charImg, String pos, String emotion) {
    this.speaker = speaker;
    this.text = text;
    this.background = bg;
    this.characterImage = charImg;
    this.characterPosition = pos;
    this.characterEmotion = emotion;
    this.choices = new ArrayList<Choice>();
    this.commands = new ArrayList<SceneCommand>();
  }
  
  void addChoice(String text, String nextNode, int friendshipChange, int loveChange) {
    choices.add(new Choice(text, nextNode, friendshipChange, loveChange));
  }
  
  void setVoice(String voiceFile) {
    this.voiceFile = voiceFile;
  }
  
  void setAudio(String voice, String se) {
    this.voiceFile = voice;
    this.soundEffect = se;
  }
  
  void setTransition(String trans) {
    this.transition = trans;
  }
  
  // 場景指令方法
  void addCommand(String commandType, String target, String... parameters) {
    commands.add(new SceneCommand(commandType, target, parameters));
  }
  
  // 添加角色
  void addCharacter(String character, String position, String emotion) {
    addCommand("ADD_CHARACTER", character, position, emotion);
  }
  
  // 移除角色
  void removeCharacter(String character) {
    addCommand("REMOVE_CHARACTER", character);
  }
  
  // 更新角色情感
  void updateCharacterEmotion(String character, String emotion) {
    addCommand("UPDATE_EMOTION", character, emotion);
  }
  
  // 更新角色位置
  void updateCharacterPosition(String character, String position) {
    addCommand("UPDATE_POSITION", character, position);
  }
  
  // 設置章節
  void setChapter(int chapter, String name) {
    addCommand("SET_CHAPTER", "game", String.valueOf(chapter), name);
  }
  
  // 清除所有角色
  void clearAllCharacters() {
    addCommand("CLEAR_ALL_CHARACTERS", "all");
  }
}

// 場景指令類別
class SceneCommand {
  String commandType;
  String target;
  String[] parameters;
  SceneCommand(String commandType, String target, String... parameters) {
    this.commandType = commandType;
    this.target = target;
    this.parameters = parameters;
  }
}

// 選擇類
class Choice {
  String text;
  String nextNode;
  int friendshipChange;
  int loveChange;
  
  Choice(String text, String nextNode, int friendship, int love) {
    this.text = text;
    this.nextNode = nextNode;
    this.friendshipChange = friendship;
    this.loveChange = love;
  }
}

// 對話系統
class DialogueSystem {
  HashMap<String, DialogueNode> nodes;
  String currentNodeId;
  DialogueNode currentNode;
  boolean showingChoices = false;
  int selectedChoice = 0;
  int hoveredChoice = -1;
  boolean[] choiceHover;
  
  boolean showingMenu = false;
  boolean showingHistory = false;
  int textDisplayIndex = 0;
  int textSpeed = 2;
  boolean textComplete = false;
  long lastTextUpdate = 0;
  
  // 自動播放相關
  boolean autoPlay = false;
  long autoPlayTimer = 0;
  int autoPlayDelay = 3000; 
  
  // 快轉相關
  boolean fastForward = false;
  int normalTextSpeed = 2;
  int fastTextSpeed = 10;
  long fastForwardTimer = 0;
  int fastForwardDelay = 20;
  
  // 語音自動播放狀態檢查
  long voiceCheckTimer = 0;
  int voiceCheckInterval = 100;
  boolean waitingForVoice = false;
  
  // 縮放和響應式設計相關
  float baseWidth = 1280;
  float baseHeight = 720;
  float scaleX = 1.0;
  float scaleY = 1.0;
  float scaleFactor = 1.0;
  
  // 淡入淡出效果
  boolean fadeToBlack = false;
  float fadeAlpha = 0;
  long fadeStartTime = 0;
  float fadeDuration = 1000;
  
  // 螢幕震動效果
  boolean screenShake = false;
  float shakeIntensity = 0;
  float shakeDecay = 0.9;
  long shakeStartTime = 0;
  float shakeDuration = 500;
  PVector shakeOffset;
  
  // 場景名稱翻譯映射
  HashMap<String, String> sceneDisplayNames;
  
  // 引擎設定
  EngineSettings engineSettings;
  
  DialogueSystem() {
    nodes = new HashMap<String, DialogueNode>(200);
    currentNodeId = "start";
    choiceHover = new boolean[10];
    normalTextSpeed = textSpeed;
    shakeOffset = new PVector(0, 0);
    sceneDisplayNames = new HashMap<String, String>();
    engineSettings = new EngineSettings();
    updateScale();
  }
  
  // 場景名稱設定方法（由腳本調用）
  void setSceneDisplayName(String sceneName, String displayName) {
    if (sceneName != null && displayName != null) {
      sceneDisplayNames.put(sceneName.trim(), displayName.trim());
    }
  }
  
  // 批量設定場景名稱
  void setSceneDisplayNames(HashMap<String, String> sceneNames) {
    if (sceneNames != null) {
      sceneDisplayNames.putAll(sceneNames);
    }
  }
  
  // 清除場景名稱映射
  void clearSceneDisplayNames() {
    sceneDisplayNames.clear();
  }
  
  // 通用場景名稱獲取方法
  String getSceneDisplayName(String sceneName) {
    if (sceneName == null || sceneName.trim().isEmpty()) {
      return "Unknown";
    }
    String trimmedSceneName = sceneName.trim();
    if (sceneDisplayNames.containsKey(trimmedSceneName)) {
      return sceneDisplayNames.get(trimmedSceneName);
    }
    return trimmedSceneName;
  }
  
  // 引擎設定類
  class EngineSettings {
    boolean showDebugInfo = false;
    boolean enableAutoSceneMusic = true;
    boolean enableVoiceSkip = true;
    boolean enableChoiceHotkeys = true;
    String defaultLanguage = "zh-TW";
    int maxHistoryItems = 100;
    boolean enableScreenEffects = true;
    color dialogueBoxColor = color(0, 0, 0, 200);
    color nameBoxColor = color(50, 50, 100, 220);
    color choiceBoxColor = color(40, 40, 60, 180);
    color choiceHoverColor = color(100, 150, 255, 200);
    float textRevealSpeed = 0.05;
    float uiAnimationSpeed = 0.08;
    float fadeSpeed = 0.02;
  }
  
  // 更新縮放比例
  void updateScale() {
    scaleX = width / baseWidth;
    scaleY = height / baseHeight;
    scaleFactor = min(scaleX, scaleY);
  }
  
  // 縮放座標轉換
  float scaleX(float x) {
    return x * scaleX;
  }
  
  float scaleY(float y) {
    return y * scaleY;
  }
  
  float scaleSize(float size) {
    return size * scaleFactor;
  }
  
  // 響應式字體大小
  void setResponsiveTextSize(float baseSize) {
    textSize(scaleSize(baseSize));
  }
  
  void clearNodes() {
    nodes.clear();
    currentNode = null;
    currentNodeId = "start";
  }
  
  void addNode(String id, DialogueNode node) {
    nodes.put(id, node);
  }
  
  void setFastForward(boolean enabled) {
    fastForward = enabled;
    if (fastForward) {
      textSpeed = fastTextSpeed;
      fastForwardTimer = millis();
      if (currentNode != null && !textComplete) {
        textComplete = true;
        textDisplayIndex = currentNode.text.length();
      }
    } else {
      textSpeed = normalTextSpeed;
    }
  }
  
  void display() {
    // 更新縮放比例
    updateScale();
    boolean matrixPushed = false;
    if (screenShake && engineSettings.enableScreenEffects) {
      updateScreenShake();
      pushMatrix();
      matrixPushed = true;
      translate(shakeOffset.x, shakeOffset.y);
    }
    try {
      if (currentNode == null && nodes.containsKey(currentNodeId)) {
        currentNode = nodes.get(currentNodeId);
        updateScene();
        resetTextDisplay();
      }
      if (characterManager != null) {
        characterManager.update();
      }
      if (currentNode != null) {
        updateTextDisplay();
        drawDialogueBox();
        drawStatusBar();
        drawUIButtons();
        if (showingChoices && currentNode.choices.size() > 0) {
          updateChoiceHover();
          drawChoices();
        } else {
          if (fastForward && textComplete) {
            if (millis() - fastForwardTimer > fastForwardDelay) {
              nextDialogue();
              fastForwardTimer = millis();
            }
          } else {
            handleAutoPlay();
          }
        }
      }
      if (showingHistory) {
        drawHistory();
      }
      if (fadeToBlack && engineSettings.enableScreenEffects) {
        updateFadeEffect();
        drawFadeOverlay();
      }
    } catch (Exception e) {
      println("DialogueSystem顯示錯誤: " + e.getMessage());
      e.printStackTrace();
    } finally {
      if (matrixPushed) {
        popMatrix();
      }
    }
  }
  
  // 更新螢幕震動
  void updateScreenShake() {
    long elapsed = millis() - shakeStartTime;
    if (elapsed > shakeDuration) {
      screenShake = false;
      shakeOffset.set(0, 0);
      return;
    }
    float progress = elapsed / shakeDuration;
    float currentIntensity = shakeIntensity * (1 - progress);
    shakeOffset.x = random(-currentIntensity, currentIntensity);
    shakeOffset.y = random(-currentIntensity, currentIntensity);
  }
  
  // 更新淡入淡出效果
  void updateFadeEffect() {
    long elapsed = millis() - fadeStartTime;
    float progress = elapsed / fadeDuration;
    if (progress >= 1.0) {
      fadeToBlack = false;
      fadeAlpha = 0;
    } else {
      fadeAlpha = 255 * sin(progress * PI);
    }
  }
  
  // 繪製淡入淡出覆蓋層
  void drawFadeOverlay() {
    fill(0, fadeAlpha);
    rect(0, 0, width, height);
  }
  
  // 專門處理自動播放的方法
  void handleAutoPlay() {
    if (!autoPlay || !textComplete || showingChoices || fastForward) {
      return;
    }
    long currentTime = millis();
    if (currentTime - voiceCheckTimer > voiceCheckInterval) {
      voiceCheckTimer = currentTime;
      updateVoiceWaitingStatus();
    }
    if (canAutoAdvance()) {
      nextDialogue();
    }
  }
  
  void updateVoiceWaitingStatus() {
    if (audioManager == null) {
      waitingForVoice = false;
      return;
    }
    if (audioManager.voiceAutoPlay) {
      if (audioManager.isVoicePlaying()) {
        waitingForVoice = true;
      } else if (!audioManager.isVoiceFinished()) {
        waitingForVoice = true;
      } else {
        waitingForVoice = false;
      }
    } else {
      waitingForVoice = false;
    }
  }
  boolean canAutoAdvance() {
    long currentTime = millis();
    if (waitingForVoice) {
      return false;
    }
    if (currentTime - autoPlayTimer < autoPlayDelay) {
      return false;
    }
    return true;
  }
  
  String getAutoPlayStatusText() {
    if (!autoPlay) {
      return "";
    }
    if (waitingForVoice) {
      if (audioManager != null && audioManager.isVoicePlaying()) {
        return "語音播放中...";
      } else {
        return "等待語音完成...";
      }
    }
    
    long remainingTime = autoPlayDelay - (millis() - autoPlayTimer);
    if (remainingTime > 0) {
      return "自動播放";
    }
    return "自動播放";
  }
  color getAutoPlayStatusColor() {
    if (!autoPlay) {
      return color(255);
    }
    if (waitingForVoice) {
      if (audioManager != null && audioManager.isVoicePlaying()) {
        return color(100, 255, 100, abs(sin(millis() * 0.008)) * 255);
      } else {
        return color(255, 255, 100, abs(sin(millis() * 0.012)) * 255);
      }
    }
    long remainingTime = autoPlayDelay - (millis() - autoPlayTimer);
    if (remainingTime > 0) {
      return color(150, 255, 150, abs(sin(millis() * 0.005)) * 255);
    }
    return color(150, 255, 150, abs(sin(millis() * 0.015)) * 255);
  }
  
  void updateTextDisplay() {
    if (!textComplete && millis() - lastTextUpdate > (100 / textSpeed)) {
      textDisplayIndex++;
      if (textDisplayIndex >= currentNode.text.length()) {
        textComplete = true;
      }
      lastTextUpdate = millis();
    }
  }
  
  void resetTextDisplay() {
    textDisplayIndex = 0;
    textComplete = false;
    lastTextUpdate = millis();
    autoPlayTimer = millis();
    waitingForVoice = false;
    if (audioManager != null) {
      audioManager.resetVoiceState();
    }
  }
  
  // 響應式狀態欄繪製
  void drawStatusBar() {
    float barX = scaleX(10);
    float barY = scaleY(10);
    float barWidth = scaleX(350);
    float barHeight = scaleY(65);
    fill(0, 0, 0, 150);
    rect(barX, barY, barWidth, barHeight, scaleSize(8));
    stroke(100, 150, 200, 120);
    strokeWeight(scaleSize(1));
    noFill();
    rect(barX, barY, barWidth, barHeight, scaleSize(8));
    noStroke();
    
    // 顯示章節信息
    if (gameState != null) {
      fill(255, 220, 100);
      textAlign(LEFT);
      setResponsiveTextSize(14);
      text("第" + gameState.currentChapter + "章：" + gameState.currentChapterName, 
           barX + scaleX(10), barY + scaleY(20));
    }
    
    // 顯示場景信息
    fill(180, 200, 255);
    setResponsiveTextSize(11);
    String sceneDisplayName = getSceneDisplayName(backgroundManager != null ? backgroundManager.currentBackground : "unknown");
    text("場景：" + sceneDisplayName, 
         barX + scaleX(10), barY + scaleY(37));
    
    // 顯示狀態
    fill(150, 255, 150);
    textAlign(RIGHT);
    setResponsiveTextSize(10);
    float statusX = barX + barWidth - scaleX(10);
    if (fastForward) {
      text("快轉", statusX, barY + scaleY(25));
    }
    if (autoPlay) {
      text("自動", statusX, barY + scaleY(37));
    }
    if (gameState != null && gameState.skipMode) {
      text("跳過", statusX, barY + scaleY(50));
    }
    
    // 調試信息
    if (engineSettings.showDebugInfo) {
      fill(120, 120, 120);
      textAlign(RIGHT);
      setResponsiveTextSize(9);
      text("節點: " + (gameState != null ? gameState.visitedNodes.size() : 0), statusX, barY + scaleY(20));
    }
  }
  
  // 響應式UI按鈕繪製
  void drawUIButtons() {
    float buttonX = width - scaleX(100);
    float buttonY = scaleY(20);
    float buttonWidth = scaleX(80);
    float buttonHeight = scaleY(25);
    float spacing = scaleY(30);
    String[] buttonLabels = {"選單", "歷史", "自動", "存檔"};
    color[] buttonColors = {
      color(50, 50, 100, 150),
      color(50, 100, 50, 150),
      color(autoPlay ? 100 : 50, autoPlay ? 150 : 50, 50, 150),
      color(100, 80, 50, 150)
    };
    for (int i = 0; i < buttonLabels.length; i++) {
      fill(buttonColors[i]);
      rect(buttonX, buttonY + i * spacing, buttonWidth, buttonHeight, scaleSize(4));
      fill(255);
      textAlign(CENTER);
      setResponsiveTextSize(11);
      text(buttonLabels[i], buttonX + buttonWidth/2, buttonY + i * spacing + scaleY(17));
    }
  }
  
  // 響應式選單繪製
  void drawMenu() {
    fill(0, 0, 0, 200);
    rect(0, 0, width, height);
    float menuWidth = scaleX(300);
    float menuHeight = scaleY(400);
    float menuX = (width - menuWidth) / 2;
    float menuY = (height - menuHeight) / 2;
    fill(40, 40, 60);
    rect(menuX, menuY, menuWidth, menuHeight, scaleSize(10));
    stroke(100, 100, 150);
    strokeWeight(scaleSize(2));
    noFill();
    rect(menuX, menuY, menuWidth, menuHeight, scaleSize(10));
    noStroke();
    fill(255, 255, 100);
    textAlign(CENTER);
    setResponsiveTextSize(20);
    text("遊戲選單", menuX + menuWidth/2, menuY + scaleY(40));
    String[] menuItems = {
      "繼續遊戲", "存檔", "讀檔", "設定", "對話歷史", "返回標題", "結束遊戲"
    };
    for (int i = 0; i < menuItems.length; i++) {
      float itemY = menuY + scaleY(80 + i * 45);
      fill(60, 60, 80);
      if (mouseX >= menuX + scaleX(20) && mouseX <= menuX + menuWidth - scaleX(20) &&
          mouseY >= itemY - scaleY(20) && mouseY <= itemY + scaleY(20)) {
        fill(80, 80, 120); 
      }
      rect(menuX + scaleX(20), itemY - scaleY(20), menuWidth - scaleX(40), scaleY(35), scaleSize(5));
      fill(255);
      textAlign(CENTER);
      setResponsiveTextSize(16);
      text(menuItems[i], menuX + menuWidth/2, itemY + scaleY(5));
    }
  }
  
  // 響應式歷史繪製
  void drawHistory() {
    fill(0, 0, 0, 220);
    rect(0, 0, width, height);
    float historyWidth = width - scaleX(100);
    float historyHeight = height - scaleY(100);
    float historyX = scaleX(50);
    float historyY = scaleY(50);
    fill(30, 30, 50);
    rect(historyX, historyY, historyWidth, historyHeight, scaleSize(10));
    fill(255, 255, 100);
    textAlign(CENTER);
    setResponsiveTextSize(18);
    text("對話歷史", width/2, historyY + scaleY(40));
    int maxDisplay = min(engineSettings.maxHistoryItems, 15);
    if (gameState != null && gameState.dialogueHistory.size() > 0) {
      int startIndex = max(0, gameState.dialogueHistory.size() - maxDisplay);
      fill(255);
      textAlign(LEFT);
      setResponsiveTextSize(14);
      for (int i = startIndex; i < gameState.dialogueHistory.size(); i++) {
        String dialogue = gameState.dialogueHistory.get(i);
        String wrappedDialogue = wrapText(dialogue, int(historyWidth - scaleX(40)));
        text(wrappedDialogue, historyX + scaleX(20), historyY + scaleY(80 + (i - startIndex) * 30));
      }
    }
    float closeButtonX = width - scaleX(150);
    float closeButtonY = historyY + scaleY(10);
    fill(100, 50, 50);
    rect(closeButtonX, closeButtonY, scaleX(80), scaleY(30), scaleSize(5));
    fill(255);
    textAlign(CENTER);
    setResponsiveTextSize(12);
    text("關閉", closeButtonX + scaleX(40), closeButtonY + scaleY(20));
  }
  
  void toggleMenu() {
    showingMenu = !showingMenu;
    if (audioManager != null) {
      audioManager.playSFX("menu_click");
    }
  }
  
  // 響應式選擇懸停更新
  void updateChoiceHover() {
    for (int i = 0; i < choiceHover.length; i++) {
      choiceHover[i] = false;
    }
    hoveredChoice = -1;
    if (!showingChoices || currentNode.choices.size() == 0) {
      return;
    }
    float choiceY = height - scaleY(330);
    for (int i = 0; i < currentNode.choices.size(); i++) {
      float y1 = choiceY + i * scaleY(55);
      float y2 = y1 + scaleY(45);
      if (mouseX >= scaleX(100) && mouseX <= width - scaleX(100) && 
          mouseY >= y1 && mouseY <= y2) {
        hoveredChoice = i;
        choiceHover[i] = true;
        break;
      }
    }
  }
  
  void updateScene() {
    if (currentNode.background != null) {
      backgroundManager.setBackground(currentNode.background);
    }
    executeSceneCommands();
    if (currentNode.characterImage != null) {
      characterManager.addCharacter(currentNode.characterImage, currentNode.characterPosition, currentNode.characterEmotion);
    }
    setSpeakerHighlight();
    if (audioManager != null) {
      audioManager.resetVoiceState();
      if (currentNode.voiceFile != null) {
        audioManager.playVoice(currentNode.voiceFile);
        if (audioManager.voiceAutoPlay) {
          waitingForVoice = true;
        }
      }
    }
    
    if (gameState != null) {
      gameState.addToHistory(currentNodeId, currentNode.speaker + ": " + currentNode.text);
    }
  }

  // 完整的指令執行器
  void executeSceneCommands() {
    for (SceneCommand command : currentNode.commands) {
      executeCommand(command);
    }
  }

  void executeCommand(SceneCommand command) {
    if (command == null) {
      println("⚠ 場景指令為null，跳過執行");
      return;
    }
    if (command.commandType == null || command.commandType.trim().isEmpty()) {
      println("⚠ 場景指令類型為null或空，跳過執行");
      return;
    }
    switch(command.commandType) {
      case "ADD_CHARACTER":
        if (command.target != null && !command.target.trim().isEmpty() && 
            command.parameters != null && command.parameters.length >= 2) {
          String position = command.parameters[0];
          String emotion = command.parameters[1];
          characterManager.addCharacter(command.target, position, emotion);
        } else {
          println("⚠ ADD_CHARACTER 指令參數不足或為null");
        }
        break;
      case "REMOVE_CHARACTER":
        if (command.target != null && !command.target.trim().isEmpty()) {
          characterManager.removeCharacter(command.target);
        } else {
          println("⚠ REMOVE_CHARACTER 指令目標為null或空");
        }
        break;
      case "UPDATE_EMOTION":
        if (command.target != null && !command.target.trim().isEmpty() && 
            command.parameters != null && command.parameters.length >= 1) {
          String emotion = command.parameters[0];
          characterManager.updateCharacterEmotion(command.target, emotion);
        } else {
          println("⚠ UPDATE_EMOTION 指令參數不足或為null");
        }
        break;
      case "UPDATE_POSITION":
        if (command.target != null && !command.target.trim().isEmpty() && 
            command.parameters != null && command.parameters.length >= 1) {
          String position = command.parameters[0];
          characterManager.updateCharacterPosition(command.target, position);
        } else {
          println("⚠ UPDATE_POSITION 指令參數不足或為null");
        }
        break;
      case "SET_CHAPTER":
        if (command.parameters != null && command.parameters.length >= 2) {
          try {
            int chapter = Integer.parseInt(command.parameters[0]);
            String name = command.parameters[1];
            if (gameState != null) {
              gameState.setChapter(chapter, name);
            }
          } catch (NumberFormatException e) {
            println("⚠ SET_CHAPTER 章節數字格式錯誤: " + command.parameters[0]);
          }
        } else {
          println("⚠ SET_CHAPTER 指令參數不足或為null");
        }
        break;
      case "CLEAR_ALL_CHARACTERS":
        if (characterManager != null) {
          characterManager.clearAllCharacters();
        }
        break;
      case "PLAY_SFX":
        if (command.parameters != null && command.parameters.length >= 1 && audioManager != null) {
          audioManager.playSFX(command.parameters[0]);
        }
        break;
      case "FADE_TO_BLACK":
        if (engineSettings.enableScreenEffects) {
          fadeToBlack = true;
          fadeStartTime = millis();
          if (command.parameters != null && command.parameters.length >= 1) {
            try {
              fadeDuration = Float.parseFloat(command.parameters[0]);
            } catch (NumberFormatException e) {
              fadeDuration = 1000;
            }
          } else {
            fadeDuration = 1000;
          }
          println("執行淡入淡出效果，持續時間: " + fadeDuration + "ms");
        }
        break;
      case "SCREEN_SHAKE":
        if (engineSettings.enableScreenEffects) {
          screenShake = true;
          shakeStartTime = millis();
          if (command.parameters != null && command.parameters.length >= 1) {
            try {
              shakeIntensity = Float.parseFloat(command.parameters[0]);
            } catch (NumberFormatException e) {
              shakeIntensity = 10; 
            }
          } else {
            shakeIntensity = 10;
          }
          if (command.parameters != null && command.parameters.length >= 2) {
            try {
              shakeDuration = Float.parseFloat(command.parameters[1]);
            } catch (NumberFormatException e) {
              shakeDuration = 500; // 0.5秒
            }
          } else {
            shakeDuration = 500;
          }
          println("執行螢幕震動效果，強度: " + shakeIntensity + ", 持續時間: " + shakeDuration + "ms");
        }
        break;
      case "CHANGE_BGM":
        if (command.parameters != null && command.parameters.length >= 1 && audioManager != null) {
          audioManager.playBGM(command.parameters[0]);
          println("更換BGM: " + command.parameters[0]);
        }
        break;
      case "STOP_BGM":
        if (audioManager != null) {
          audioManager.stopBGM();
          println("停止BGM");
        }
        break;
      case "SET_VOLUME":
        if (command.parameters != null && command.parameters.length >= 2 && audioManager != null) {
          String volumeType = command.parameters[0];
          try {
            float volume = Float.parseFloat(command.parameters[1]);
            switch(volumeType) {
              case "master":
                audioManager.setMasterVolume(volume);
                break;
              case "music":
                audioManager.setMusicVolume(volume);
                break;
              case "sfx":
                audioManager.setSFXVolume(volume);
                break;
              case "voice":
                audioManager.setVoiceVolume(volume);
                break;
            }
            println("設置" + volumeType + "音量: " + volume);
          } catch (NumberFormatException e) {
            println("音量設置錯誤: " + command.parameters[1]);
          }
        }
        break;
      case "WAIT":
        if (command.parameters != null && command.parameters.length >= 1) {
          try {
            int waitTime = Integer.parseInt(command.parameters[0]);
            autoPlayDelay += waitTime;
            println("增加等待時間: " + waitTime + "ms");
          } catch (NumberFormatException e) {
            println("等待時間格式錯誤: " + command.parameters[0]);
          }
        }
        break;
      case "SET_TEXT_SPEED":
        if (command.parameters != null && command.parameters.length >= 1) {
          try {
            int speed = Integer.parseInt(command.parameters[0]);
            textSpeed = constrain(speed, 1, 10);
            normalTextSpeed = textSpeed;
            println("設置文字速度: " + speed);
          } catch (NumberFormatException e) {
            println("文字速度格式錯誤: " + command.parameters[0]);
          }
        }
        break;
      case "SAVE_CHECKPOINT":
        if (saveSystem != null) {
          saveSystem.saveGame(0);
          println("自動存檔檢查點");
        }
        break;
      case "UNLOCK_CG":
        if (command.parameters != null && command.parameters.length >= 1) {
          println("解鎖CG: " + command.parameters[0]);
        }
        break;
        
      case "SET_FLAG":
        if (command.parameters != null && command.parameters.length >= 2) {
          String flagName = command.parameters[0];
          String flagValue = command.parameters[1];
          println("設置標誌: " + flagName + " = " + flagValue);
        }
        break;
        
      case "SET_SCENE_NAME":
        if (command.parameters != null && command.parameters.length >= 2) {
          String sceneName = command.parameters[0];
          String displayName = command.parameters[1];
          setSceneDisplayName(sceneName, displayName);
          println("設置場景名稱: " + sceneName + " -> " + displayName);
        }
        break;
      default:
        println("未知的場景指令: " + command.commandType);
        break;
    }
  }

  void setSpeakerHighlight() {
    if (currentNode.speaker != null && !isSystemSpeaker(currentNode.speaker)) {
      characterManager.setSpeaker(currentNode.speaker);
    }
  }

  boolean isSystemSpeaker(String speaker) {
    if (speaker == null) return true; // null 視為系統說話者
    String[] systemSpeakers = {"旁白", "主角", "系統", "narrator", "protagonist", "system"};
    for (String systemSpeaker : systemSpeakers) {
      if (speaker.equals(systemSpeaker)) {
        return true;
      }
    }
    return false;
  }
  
  // 響應式對話框繪製
  void drawDialogueBox() {
    float boxX = scaleX(50);
    float boxY = height - scaleY(230);
    float boxWidth = width - scaleX(100);
    float boxHeight = scaleY(180);
    
    fill(engineSettings.dialogueBoxColor);
    rect(boxX, boxY, boxWidth, boxHeight, scaleSize(10));
    stroke(255, 255, 255, 150);
    strokeWeight(scaleSize(2));
    noFill();
    rect(boxX, boxY, boxWidth, boxHeight, scaleSize(10));
    noStroke();
    
    float nameBoxX = boxX + scaleX(10);
    float nameBoxY = boxY - scaleY(20);
    float nameBoxWidth = scaleX(150);
    float nameBoxHeight = scaleY(25);
    
    fill(engineSettings.nameBoxColor);
    rect(nameBoxX, nameBoxY, nameBoxWidth, nameBoxHeight, scaleSize(5));
    
    // 語音播放指示器
    if (audioManager != null && audioManager.voiceAutoPlay) {
      if (audioManager.isVoicePlaying()) {
        fill(255, 100, 100, abs(sin(millis() * 0.01)) * 255);
        ellipse(boxX - scaleX(5), nameBoxY + nameBoxHeight/2, scaleSize(8), scaleSize(8));
        
        if (audioManager.currentVoice != null) {
          try {
            float duration = audioManager.currentVoice.length();
            float position = audioManager.currentVoice.position();
            if (duration > 0) {
              float progress = position / duration;
              fill(255, 100, 100, 150);
              rect(boxX - scaleX(15), nameBoxY - scaleY(5), progress * scaleX(20), scaleY(3));
              stroke(255, 100, 100, 200);
              strokeWeight(scaleSize(1));
              noFill();
              rect(boxX - scaleX(15), nameBoxY - scaleY(5), scaleX(20), scaleY(3));
              noStroke();
            }
          } catch (Exception e) {
            // 忽略錯誤
          }
        }
      }
    }
    
    fill(255, 200, 100);
    textAlign(LEFT);
    setResponsiveTextSize(16);
    text(currentNode.speaker, nameBoxX + scaleX(10), nameBoxY + scaleY(17));
    
    fill(255);
    setResponsiveTextSize(20);
    String displayText = currentNode.text.substring(0, min(textDisplayIndex, currentNode.text.length()));
    String wrappedText = wrapText(displayText, int(boxWidth - scaleX(40)));
    text(wrappedText, boxX + scaleX(20), boxY + scaleY(30));
    
    // 狀態提示
    if (fastForward) {
      fill(255, 255, 100, abs(sin(millis() * 0.01)) * 255);
      textAlign(RIGHT);
      setResponsiveTextSize(11);
      text("快轉中", boxX + boxWidth - scaleX(20), boxY + boxHeight - scaleY(40));
    } else if (!showingChoices && textComplete) {
      String statusText = getAutoPlayStatusText();
      if (!statusText.isEmpty()) {
        fill(getAutoPlayStatusColor());
        textAlign(RIGHT);
        setResponsiveTextSize(11);
        text(statusText, boxX + boxWidth - scaleX(20), boxY + boxHeight - scaleY(25));
      } else {
        fill(200, 200, 100, abs(sin(millis() * 0.005)) * 255);
        textAlign(RIGHT);
        setResponsiveTextSize(15);
        text("▼", boxX + boxWidth - scaleX(20), boxY + boxHeight - scaleY(10));
      }
    }
  }
  
  // 響應式選擇繪製
  void drawChoices() {
    float choiceY = height - scaleY(330);
    
    fill(200, 200, 255);
    textAlign(CENTER);
    setResponsiveTextSize(13);
    text("請選擇回應", width/2, choiceY - scaleY(15));
    
    for (int i = 0; i < currentNode.choices.size(); i++) {
      Choice choice = currentNode.choices.get(i);
      float y = choiceY + i * scaleY(55);
      float choiceWidth = width - scaleX(200);
      float choiceHeight = scaleY(45);
      float choiceX = scaleX(100);
      
      noStroke();
      if (choiceHover[i]) {
        fill(engineSettings.choiceHoverColor);
        stroke(200, 220, 255);
        strokeWeight(scaleSize(2));
      } else {
        fill(engineSettings.choiceBoxColor);
        stroke(120, 120, 140);
        strokeWeight(scaleSize(1));
      }
      rect(choiceX, y, choiceWidth, choiceHeight, scaleSize(8));
      noStroke();
      
      // 選項編號圓圈
      fill(80, 80, 120, 200);
      float circleSize = scaleSize(22);
      ellipse(choiceX + scaleX(25), y + choiceHeight/2, circleSize, circleSize);
      
      fill(255);
      textAlign(CENTER);
      setResponsiveTextSize(12);
      text(i + 1, choiceX + scaleX(25), y + choiceHeight/2 + scaleY(5));
      
      fill(255);
      textAlign(LEFT);
      setResponsiveTextSize(14);
      String wrappedChoice = wrapText(choice.text, int(choiceWidth - scaleX(80)));
      text(wrappedChoice, choiceX + scaleX(50), y + choiceHeight/2 + scaleY(5));
    }
  }
  
  // 響應式點擊處理
  void handleClick(int x, int y) {
    if (showingMenu) {
      handleMenuClick(x, y);
      return;
    }
    if (showingHistory) {
      float closeButtonX = width - scaleX(150);
      float closeButtonY = scaleY(60);
      if (x >= closeButtonX && x <= closeButtonX + scaleX(80) && 
          y >= closeButtonY && y <= closeButtonY + scaleY(30)) {
        showingHistory = false;
      }
      return;
    }
    
    // UI按鈕處理
    float buttonX = width - scaleX(100);
    float buttonWidth = scaleX(80);
    float buttonHeight = scaleY(25);
    float spacing = scaleY(30);
    
    if (x >= buttonX && x <= buttonX + buttonWidth) {
      for (int i = 0; i < 4; i++) {
        float buttonY = scaleY(20) + i * spacing;
        if (y >= buttonY && y <= buttonY + buttonHeight) {
          switch(i) {
            case 0: toggleMenu(); break;
            case 1: showingHistory = !showingHistory; break;
            case 2: 
              autoPlay = !autoPlay;
              autoPlayTimer = millis();
              waitingForVoice = false;
              break;
            case 3: 
              if (saveSystem != null) {
                saveSystem.showSaveMenu(true);
              }
              break;
          }
          return;
        }
      }
    }
    
    // 選擇處理
    if (showingChoices && currentNode.choices.size() > 0) {
      float choiceY = height - scaleY(330);
      for (int i = 0; i < currentNode.choices.size(); i++) {
        float y1 = choiceY + i * scaleY(55);
        float y2 = y1 + scaleY(45);
        if (y >= y1 && y <= y2 && x >= scaleX(100) && x <= width - scaleX(100)) {
          selectChoice(i);
          return;
        }
      }
    } else {
      // 對話推進處理
      if (audioManager != null && audioManager.isVoicePlaying() && audioManager.voiceInterruptible && engineSettings.enableVoiceSkip) {
        audioManager.stopVoice();
        waitingForVoice = false;
        if (!textComplete) {
          textComplete = true;
          textDisplayIndex = currentNode.text.length();
        } else {
          nextDialogue();
        }
      } else if (!textComplete) {
        textComplete = true;
        textDisplayIndex = currentNode.text.length();
      } else {
        nextDialogue();
      }
    }
  }
  
  void handleMenuClick(int x, int y) {
    float menuWidth = scaleX(300);
    float menuHeight = scaleY(400);
    float menuX = (width - menuWidth) / 2;
    float menuY = (height - menuHeight) / 2;
    
    if (audioManager != null) {
      audioManager.playSFX("menu_click");
    }
    
    if (x < menuX || x > menuX + menuWidth || y < menuY || y > menuY + menuHeight) {
      showingMenu = false;
      return;
    }
    
    for (int i = 0; i < 7; i++) {
      float itemY = menuY + scaleY(80 + i * 45);
      if (x >= menuX + scaleX(20) && x <= menuX + menuWidth - scaleX(20) &&
          y >= itemY - scaleY(20) && y <= itemY + scaleY(20)) {
        handleMenuSelection(i);
        break;
      }
    }
  }

  void handleMenuSelection(int index) {
    switch(index) {
      case 0: 
        showingMenu = false;
        println("繼續遊戲");
        break;
      case 1: 
        if (saveSystem != null) {
          saveSystem.showSaveMenu(true);
        }
        showingMenu = false;
        println("開啟存檔選單");
        break;
      case 2: 
        if (saveSystem != null) {
          saveSystem.showSaveMenu(false);
        }
        showingMenu = false;
        println("開啟讀檔選單");
        break;
      case 3: 
        if (settingsManager != null) {
          settingsManager.showingSettings = true;
        }
        showingMenu = false;
        println("開啟設定選單");
        break;
      case 4: 
        showingHistory = true;
        showingMenu = false;
        println("開啟對話歷史");
        break;
      case 5: 
        if (confirmReturnToTitle()) {
          returnToTitle();
        }
        showingMenu = false;
        break;
      case 6:
        if (confirmExit()) {
          exit();
        }
        showingMenu = false;
        break;
    }
  }

  boolean confirmReturnToTitle() {
    println("請求返回標題畫面");
    return true;
  }

  boolean confirmExit() {
    println("請求結束遊戲");
    return true; 
  }
  
  void selectChoice(int choiceIndex) {
    if (choiceIndex >= 0 && choiceIndex < currentNode.choices.size()) {
      if (audioManager != null) {
        audioManager.playSFX("choice_select");
      }
      Choice choice = currentNode.choices.get(choiceIndex);
      if (gameState != null) {
        gameState.addFriendship(choice.friendshipChange);
        gameState.addLove(choice.loveChange);
        println("好感度變化 - 友誼: " + choice.friendshipChange + ", 愛情: " + choice.loveChange);
        println("當前數值 - 友誼: " + gameState.friendshipPoints + ", 愛情: " + gameState.lovePoints);
      }
      currentNodeId = choice.nextNode;
      currentNode = null;
      showingChoices = false;
      for (int i = 0; i < choiceHover.length; i++) {
        choiceHover[i] = false;
      }
      hoveredChoice = -1;
    }
  }
  
  void nextDialogue() {
    if (currentNode.choices.size() > 0) {
      showingChoices = true;
    } else if (currentNode.nextNode != null) {
      currentNodeId = currentNode.nextNode;
      currentNode = null;
      showingChoices = false;
    }
    autoPlayTimer = millis();
    fastForwardTimer = millis();
    waitingForVoice = false;
    
    if (audioManager != null) {
      audioManager.resetVoiceState();
    }
  }
  
  // 響應式文字換行
  String wrapText(String text, int maxWidth) {
    if (text == null || text.isEmpty()) return "";
    
    String[] chars = text.split("");
    String result = "";
    String currentLine = "";
    
    for (String ch : chars) {
      String testLine = currentLine + ch;
      if (textWidth(testLine) > maxWidth && currentLine.length() > 0) {
        result += currentLine + "\n";
        currentLine = ch;
      } else {
        currentLine = testLine;
      }
    }
    result += currentLine;
    return result;
  }
  
  // 新增：腳本接口方法
  void scriptSetSceneDisplayName(String sceneName, String displayName) {
    setSceneDisplayName(sceneName, displayName);
  }
  
  void scriptSetSceneDisplayNames(HashMap<String, String> sceneNames) {
    setSceneDisplayNames(sceneNames);
  }
  
  void scriptEnableDebugInfo(boolean enable) {
    engineSettings.showDebugInfo = enable;
  }
  
  void scriptSetTextSpeed(int speed) {
    textSpeed = constrain(speed, 1, 10);
    normalTextSpeed = textSpeed;
  }
  
  void scriptSetAutoPlayDelay(int delay) {
    autoPlayDelay = max(delay, 500); // 最少0.5秒
  }
  
  void scriptEnableScreenEffects(boolean enable) {
    engineSettings.enableScreenEffects = enable;
  }
  
  void scriptSetMaxHistoryItems(int maxItems) {
    engineSettings.maxHistoryItems = max(maxItems, 10); // 最少10項
  }
  
  // 新增：獲取引擎狀態
  boolean isAutoPlayActive() {
    return autoPlay;
  }
  
  boolean isFastForwardActive() {
    return fastForward;
  }
  
  boolean isVoiceWaiting() {
    return waitingForVoice;
  }
  
  String getCurrentNodeId() {
    return currentNodeId;
  }
  
  boolean hasChoices() {
    return showingChoices && currentNode != null && currentNode.choices.size() > 0;
  }
  
  int getChoiceCount() {
    return (currentNode != null) ? currentNode.choices.size() : 0;
  }
}

// 存檔系統
class SaveSystem {
  boolean showingSaveMenu = false;
  boolean isSaving = true;
  JSONArray saveSlots;
  int maxSaves = 9;
  
  SaveSystem() {
    saveSlots = new JSONArray();
    loadSaveSlots();
  }
  
  void showSaveMenu(boolean saving) {
    showingSaveMenu = true;
    isSaving = saving;
  }
  
  void display() {
    fill(0, 0, 0, 200);
    rect(0, 0, width, height);
    float menuWidth = 600;
    float menuHeight = 500;
    float menuX = (width - menuWidth) / 2;
    float menuY = (height - menuHeight) / 2;
    fill(40, 40, 60);
    rect(menuX, menuY, menuWidth, menuHeight, 10);
    fill(255, 255, 100);
    textAlign(CENTER);
    textSize(20);
    text(isSaving ? "存檔" : "讀檔", menuX + menuWidth/2, menuY + 40);
    for (int i = 0; i < maxSaves; i++) {
      float slotX = menuX + 20 + (i % 3) * 180;
      float slotY = menuY + 70 + (i / 3) * 120;
      fill(60, 60, 80);
      if (mouseX >= slotX && mouseX <= slotX + 160 &&
          mouseY >= slotY && mouseY <= slotY + 100) {
        fill(80, 80, 120);
      }
      rect(slotX, slotY, 160, 100, 5);
      JSONObject saveData = (i < saveSlots.size()) ? saveSlots.getJSONObject(i) : null;
      fill(255);
      textAlign(LEFT);
      textSize(12);
      text("存檔 " + (i + 1), slotX + 10, slotY + 20);
      if (saveData != null) {
        text("章節: " + saveData.getInt("chapter"), slotX + 10, slotY + 40);
        text("場景: " + saveData.getString("scene"), slotX + 10, slotY + 60);
        text("時間: " + saveData.getString("date"), slotX + 10, slotY + 80);
      } else {
        fill(150);
        text("空的存檔槽", slotX + 10, slotY + 50);
      }
    }
    fill(100, 50, 50);
    rect(menuX + menuWidth - 80, menuY + 10, 60, 30, 5);
    fill(255);
    textAlign(CENTER);
    textSize(12);
    text("關閉", menuX + menuWidth - 50, menuY + 30);
  }
  
	void handleClick(int x, int y) {
		float menuWidth = 600;
		float menuHeight = 500;
		float menuX = (width - menuWidth) / 2;
		float menuY = (height - menuHeight) / 2;
		if (x >= menuX + menuWidth - 80 && x <= menuX + menuWidth - 20 &&
				y >= menuY + 10 && y <= menuY + 40) {
			showingSaveMenu = false;
			if (currentMode == GameMode.LOAD_GAME) {
				currentMode = GameMode.TITLE;
			}
			return;
		}
		for (int i = 0; i < maxSaves; i++) {
			float slotX = menuX + 20 + (i % 3) * 180;
			float slotY = menuY + 70 + (i / 3) * 120;
			if (x >= slotX && x <= slotX + 160 &&
					y >= slotY && y <= slotY + 100) {
				if (isSaving) {
					saveGame(i);
				} else {
					loadGame(i);
					if (currentMode == GameMode.LOAD_GAME) {
						currentMode = GameMode.GAME;
					}
				}
				showingSaveMenu = false;
				break;
			}
		}
	}
  
  void saveGame(int slot) {
    JSONObject saveData = new JSONObject();
    saveData.setString("nodeId", dialogueSystem.currentNodeId);
    saveData.setInt("chapter", gameState.currentChapter);
    saveData.setString("chapterName", gameState.currentChapterName);
    saveData.setInt("friendship", gameState.friendshipPoints);
    saveData.setInt("love", gameState.lovePoints);
    saveData.setString("scene", backgroundManager.currentBackground);
    saveData.setString("date", day() + "/" + month() + "/" + year() + " " + hour() + ":" + minute());
    while (saveSlots.size() <= slot) {
      saveSlots.append(new JSONObject());
    }
    saveSlots.setJSONObject(slot, saveData);
    saveJSONArray(saveSlots, "data/saves.json");
    println("遊戲已存檔到槽位 " + (slot + 1));
  }
  
  void loadGame(int slot) {
    if (slot < saveSlots.size()) {
      JSONObject saveData = saveSlots.getJSONObject(slot);
      if (saveData != null && saveData.hasKey("nodeId")) {
        dialogueSystem.currentNodeId = saveData.getString("nodeId");
        dialogueSystem.currentNode = null;
        gameState.currentChapter = saveData.getInt("chapter");
        gameState.currentChapterName = saveData.getString("chapterName");
        gameState.friendshipPoints = saveData.getInt("friendship");
        gameState.lovePoints = saveData.getInt("love");
        backgroundManager.setBackground(saveData.getString("scene"));
        println("遊戲已讀取槽位 " + (slot + 1));
      }
    }
  }
  
  void quickSave() {
    saveGame(0);
    println("快速存檔完成");
  }
  
  void quickLoad() {
    loadGame(0);
    println("快速讀檔完成");
  }
  
  void loadSaveSlots() {
    try {
      saveSlots = loadJSONArray("data/saves.json");
      if (saveSlots == null) {
        saveSlots = new JSONArray();
      }
    } catch (Exception e) {
      saveSlots = new JSONArray();
      println("存檔檔案不存在，建立新的存檔系統");
    }
  }
}

// 設定管理器
class SettingsManager {
  boolean showingSettings = false;
  float masterVolume = 0.8;
  float musicVolume = 0.8;
  float sfxVolume = 0.8;
  float voiceVolume = 0.9;
  int textSpeed = 2;
  boolean fullscreen = false;
  boolean voiceAutoPlay = true;
  
  // 儲存原始視窗尺寸
  int windowedWidth = 1280;
  int windowedHeight = 720;
  
  void display() {
    fill(0, 0, 0, 200);
    rect(0, 0, width, height);
    float menuWidth = 400;
    float menuHeight = 550; 
    float menuX = (width - menuWidth) / 2;
    float menuY = (height - menuHeight) / 2;
    fill(40, 40, 60);
    rect(menuX, menuY, menuWidth, menuHeight, 10);
    fill(255, 255, 100);
    textAlign(CENTER);
    textSize(20);
    text("遊戲設定", menuX + menuWidth/2, menuY + 40);
    float yPos = menuY + 80;
    drawSlider("主音量", masterVolume, menuX + 20, yPos);
    yPos += 60;
    drawSlider("音樂音量", musicVolume, menuX + 20, yPos);
    yPos += 60;
    drawSlider("音效音量", sfxVolume, menuX + 20, yPos);
    yPos += 60;
    drawSlider("語音音量", voiceVolume, menuX + 20, yPos);
    yPos += 60;
    drawSlider("文字速度", textSpeed / 5.0, menuX + 20, yPos);
    yPos += 60;
    
    // 語音自動播放開關
    fill(255);
    textAlign(LEFT);
    textSize(14);
    text("語音自動播放", menuX + 20, yPos);
    fill(voiceAutoPlay ? 100 : 50, voiceAutoPlay ? 150 : 50, 50);
    rect(menuX + 300, yPos - 15, 60, 25, 5);
    fill(255);
    textAlign(CENTER);
    textSize(12);
    text(voiceAutoPlay ? "開啟" : "關閉", menuX + 330, yPos - 2);
    yPos += 40;
    
    // 全螢幕模式
    fill(255);
    textAlign(LEFT);
    textSize(14);
    text("全螢幕模式", menuX + 20, yPos);
    fill(fullscreen ? 100 : 50, fullscreen ? 150 : 50, 50);
    rect(menuX + 300, yPos - 15, 60, 25, 5);
    fill(255);
    textAlign(CENTER);
    textSize(12);
    text(fullscreen ? "開啟" : "關閉", menuX + 330, yPos - 2);
    fill(100, 50, 50);
    rect(menuX + menuWidth - 80, menuY + 10, 60, 30, 5);
    fill(255);
    textAlign(CENTER);
    textSize(12);
    text("關閉", menuX + menuWidth - 50, menuY + 30);
  }
  
  void drawSlider(String label, float value, float x, float y) {
    fill(255);
    textAlign(LEFT);
    textSize(14);
    text(label, x, y);
    fill(80, 80, 80);
    rect(x + 120, y - 10, 200, 10, 5);
    fill(100, 150, 255);
    rect(x + 120, y - 10, 200 * value, 10, 5);
    fill(255);
    ellipse(x + 120 + 200 * value, y - 5, 15, 15);
    textAlign(RIGHT);
    text(int(value * 100) + "%", x + 350, y);
  }
  
	void handleClick(int x, int y) {
		float menuWidth = 400;
		float menuHeight = 550;
		float menuX = (width - menuWidth) / 2;
		float menuY = (height - menuHeight) / 2;
		if (x >= menuX + menuWidth - 80 && x <= menuX + menuWidth - 20 &&
				y >= menuY + 10 && y <= menuY + 40) {
			showingSettings = false;
			saveSettings();
			if (currentMode == GameMode.SETTINGS) {
				currentMode = GameMode.TITLE;
			}
			return;
		}
    float sliderX = menuX + 120;
    float sliderWidth = 200;
    if (x >= sliderX && x <= sliderX + sliderWidth) {
      float value = (x - sliderX) / sliderWidth;
      value = constrain(value, 0, 1);
      
      float yPos = menuY + 80;
      if (y >= yPos - 15 && y <= yPos + 15) {
        masterVolume = value;
        audioManager.setMasterVolume(value);
      }
      yPos += 60;
      if (y >= yPos - 15 && y <= yPos + 15) {
        musicVolume = value;
        audioManager.setMusicVolume(value);
      }
      yPos += 60;
      if (y >= yPos - 15 && y <= yPos + 15) {
        sfxVolume = value;
        audioManager.setSFXVolume(value);
      }
      yPos += 60;
      if (y >= yPos - 15 && y <= yPos + 15) {
        voiceVolume = value;
        audioManager.setVoiceVolume(value);
      }
      yPos += 60;
      if (y >= yPos - 15 && y <= yPos + 15) {
        textSpeed = int(value * 5) + 1;
        dialogueSystem.textSpeed = textSpeed;
      }
    }
    
    // 語音自動播放開關
    float voiceAutoPlayY = menuY + 380;
    if (x >= menuX + 300 && x <= menuX + 360 &&
        y >= voiceAutoPlayY - 15 && y <= voiceAutoPlayY + 10) {
      voiceAutoPlay = !voiceAutoPlay;
      audioManager.voiceAutoPlay = voiceAutoPlay;
      if (!voiceAutoPlay) {
        audioManager.stopVoice();
      }
    }
    
    // 全螢幕切換
    float fullscreenY = menuY + 420;
    if (x >= menuX + 300 && x <= menuX + 360 &&
        y >= fullscreenY - 15 && y <= fullscreenY + 10) {
      toggleFullscreen();
    }
  }

  // 全螢幕切換函數
  void toggleFullscreen() {
    fullscreen = !fullscreen;
    if (fullscreen) {
      windowedWidth = width;
      windowedHeight = height;
      try {
        java.awt.DisplayMode displayMode = java.awt.GraphicsEnvironment.getLocalGraphicsEnvironment()
          .getDefaultScreenDevice().getDisplayMode();
        int screenWidth = displayMode.getWidth();
        int screenHeight = displayMode.getHeight();
        if (surface instanceof processing.awt.PSurfaceAWT) {
          processing.awt.PSurfaceAWT awtSurface = (processing.awt.PSurfaceAWT) surface;
          java.awt.Canvas canvas = (java.awt.Canvas) awtSurface.getNative();
          java.awt.Window window = javax.swing.SwingUtilities.getWindowAncestor(canvas);
          if (window instanceof java.awt.Frame) {
            java.awt.Frame frame = (java.awt.Frame) window;
            frame.dispose();
            frame.setUndecorated(true);
            frame.setVisible(true);
            frame.setLocation(0, 0);
            frame.setSize(screenWidth, screenHeight);
            frame.setExtendedState(java.awt.Frame.MAXIMIZED_BOTH);
            frame.toFront();
            frame.requestFocus();
            println("已切換到全螢幕模式: " + screenWidth + "x" + screenHeight);
          }
        }
        surface.setSize(screenWidth, screenHeight);
      } catch (Exception e) {
        println("全螢幕切換失敗: " + e.getMessage());
        fullscreen = false;
      }
      
    } else {
      try {
        if (surface instanceof processing.awt.PSurfaceAWT) {
          processing.awt.PSurfaceAWT awtSurface = (processing.awt.PSurfaceAWT) surface;
          java.awt.Canvas canvas = (java.awt.Canvas) awtSurface.getNative();
          java.awt.Window window = javax.swing.SwingUtilities.getWindowAncestor(canvas);
          if (window instanceof java.awt.Frame) {
            java.awt.Frame frame = (java.awt.Frame) window;
            frame.dispose();
            frame.setUndecorated(false);
            frame.setExtendedState(java.awt.Frame.NORMAL);
            frame.setVisible(true);
            frame.setSize(windowedWidth, windowedHeight);
            java.awt.Dimension screenSize = java.awt.Toolkit.getDefaultToolkit().getScreenSize();
            int x = (screenSize.width - windowedWidth) / 2;
            int y = (screenSize.height - windowedHeight) / 2;
            frame.setLocation(x, y);
            frame.toFront();
            frame.requestFocus();
            println("已切換到視窗模式: " + windowedWidth + "x" + windowedHeight);
          }
        }
        surface.setSize(windowedWidth, windowedHeight);
      } catch (Exception e) {
        println("視窗模式切換失敗: " + e.getMessage());
        fullscreen = true;
      }
    }
    delay(50);
    if (uiBuffer != null) {
      uiBuffer = createGraphics(width, height);
    }
    if (dialogueBuffer != null) {
      dialogueBuffer = createGraphics(width, height);
    }
    if (characterManager != null) {
      characterManager.updateAllCharacterPositions();
    }
    uiNeedsUpdate = true;
    dialogueNeedsUpdate = true;
    saveSettings();
  }
  
  void saveSettings() {
    JSONObject settings = new JSONObject();
    settings.setFloat("masterVolume", masterVolume);
    settings.setFloat("musicVolume", musicVolume);
    settings.setFloat("sfxVolume", sfxVolume);
    settings.setFloat("voiceVolume", voiceVolume);
    settings.setInt("textSpeed", textSpeed);
    settings.setBoolean("fullscreen", fullscreen);
    settings.setBoolean("voiceAutoPlay", voiceAutoPlay);
    saveJSONObject(settings, "data/settings.json");
  }
  
  void loadSettings() {
    try {
      JSONObject settings = loadJSONObject("data/settings.json");
      if (settings != null) {
        masterVolume = settings.getFloat("masterVolume", 0.8);
        musicVolume = settings.getFloat("musicVolume", 0.8);
        sfxVolume = settings.getFloat("sfxVolume", 0.8);
        voiceVolume = settings.getFloat("voiceVolume", 0.9);
        textSpeed = settings.getInt("textSpeed", 2);
        fullscreen = settings.getBoolean("fullscreen", false);
        voiceAutoPlay = settings.getBoolean("voiceAutoPlay", true);
        dialogueSystem.textSpeed = textSpeed;
        if (audioManager != null) {
          audioManager.voiceAutoPlay = voiceAutoPlay;
        }
      }
    } catch (Exception e) {
      println("設定檔案不存在，使用預設設定");
    }
  }
}

// 音訊管理器 - 通用版本
class AudioManager {
  Minim minim;
  AudioPlayer currentBGM;
  AudioPlayer currentVoice;
  HashMap<String, AudioPlayer> bgmTracks;
  HashMap<String, AudioPlayer> sfxSounds;
  HashMap<String, AudioPlayer> voiceTracks;
  ArrayList<String> attemptedVoiceLoads; // 記錄已嘗試載入的語音
  ArrayList<String> attemptedBGMLoads;   // 記錄已嘗試載入的BGM
  
  // 音量控制
  float masterVolume = 0.8;
  float musicVolume = 0.8;
  float sfxVolume = 0.8;
  float voiceVolume = 0.9;
  
  // BGM 相關
  String currentBGMName = "";
  boolean isFading = false;
  float fadeStartTime = 0;
  float fadeDuration = 2000;
  AudioPlayer nextBGM = null;
  
  // 語音播放控制
  boolean voiceAutoPlay = true;
  boolean voiceInterruptible = true;
  
  // 語音狀態追蹤
  boolean voiceIsPlaying = false;
  boolean voiceFinished = true;
  
  // 音訊格式支援
  String[] supportedAudioFormats = {"wav", "mp3"};
  
  // 場景BGM映射（可動態擴展）
  HashMap<String, String> sceneBGMMapping;
  boolean autoBGMEnabled = true; // 是否啟用自動BGM切換
  
  // 修復構造函數 - PAppet 改為 PApplet
  AudioManager(PApplet parent) {
    minim = new Minim(parent);
    bgmTracks = new HashMap<String, AudioPlayer>();
    sfxSounds = new HashMap<String, AudioPlayer>();
    voiceTracks = new HashMap<String, AudioPlayer>();
    attemptedVoiceLoads = new ArrayList<String>();
    attemptedBGMLoads = new ArrayList<String>();
    sceneBGMMapping = new HashMap<String, String>();
    
    loadBasicAudioFiles();
    initializeSceneBGMMapping();
    println("音訊管理器初始化完成");
  }
  
  // 初始化場景BGM映射（通用映射）
  void initializeSceneBGMMapping() {
    // 通用場景映射，可以被腳本動態覆蓋
    sceneBGMMapping.put("default", "default");
    sceneBGMMapping.put("title", "title");
    println("場景BGM映射初始化完成");
  }
  
  // 動態添加場景BGM映射
  void addSceneBGMMapping(String sceneName, String bgmName) {
    if (sceneName != null && bgmName != null) {
      sceneBGMMapping.put(sceneName.trim(), bgmName.trim());
      println("添加場景BGM映射: " + sceneName + " -> " + bgmName);
    }
  }
  
  // 移除場景BGM映射
  void removeSceneBGMMapping(String sceneName) {
    if (sceneName != null && sceneBGMMapping.containsKey(sceneName)) {
      sceneBGMMapping.remove(sceneName);
      println("移除場景BGM映射: " + sceneName);
    }
  }
  
  // 載入基礎音訊檔案（只載入必要的系統音效）
  void loadBasicAudioFiles() {
    try {
      println("開始載入基礎音訊檔案...");
      
      // 載入基礎系統BGM（必需的）
      loadBGMTrack("title", "data/music/title");
      loadBGMTrack("default", "data/music/default");
      
      // 載入基礎音效（系統必需）
      loadSFXTrack("choice_select", "data/sfx/choice_select");
      loadSFXTrack("menu_click", "data/sfx/menu_click");
      loadSFXTrack("button_hover", "data/sfx/button_hover");
      loadSFXTrack("notification", "data/sfx/notification");
      loadSFXTrack("error", "data/sfx/error");
      loadSFXTrack("save", "data/sfx/save");
      loadSFXTrack("load", "data/sfx/load");
      
      println("基礎音訊檔案載入完成！載入了 " + bgmTracks.size() + " 個BGM、" + sfxSounds.size() + " 個音效");
      
    } catch (Exception e) {
      println("基礎音訊載入錯誤: " + e.getMessage());
      println("請確認 data/music/ 和 data/sfx/ 資料夾中有對應的檔案");
    }
  }
  
  // 自動載入BGM檔案（根據需要載入）
  AudioPlayer loadBGMIfNeeded(String bgmName) {
    if (bgmName == null || bgmName.trim().isEmpty()) {
      return null;
    }
    
    String bgmKey = bgmName.trim();
    
    // 如果已經載入過，直接返回
    if (bgmTracks.containsKey(bgmKey)) {
      return bgmTracks.get(bgmKey);
    }
    
    // 如果已經嘗試過載入但失敗，返回null避免重複嘗試
    if (attemptedBGMLoads.contains(bgmKey)) {
      return null;
    }
    
    // 標記為已嘗試載入
    attemptedBGMLoads.add(bgmKey);
    
    // 嘗試載入BGM檔案
    return loadBGMFile(bgmKey);
  }
  
  // 載入BGM檔案的核心方法
  AudioPlayer loadBGMFile(String bgmName) {
    String[] bgmPaths = {
      "data/bgm/" + bgmName, 
      "data/audio/bgm/" + bgmName,
    };
    for (String basePath : bgmPaths) {
      for (String format : supportedAudioFormats) {
        String filePath = basePath + "." + format;
        try {
          AudioPlayer bgm = minim.loadFile(filePath);
          if (bgm != null) {
            bgmTracks.put(bgmName, bgm);
            println("✓ 載入BGM: " + bgmName + " (" + filePath + ")");
            return bgm;
          }
        } catch (Exception e) {
        }
      }
    }
    println("⚠ 找不到BGM檔案: " + bgmName + " (已嘗試多種路徑和格式)");
    return null;
  }
  
  // 自動載入語音檔案
  AudioPlayer loadVoiceIfNeeded(String voiceName) {
    if (voiceName == null || voiceName.trim().isEmpty()) {
      return null;
    }
    String voiceKey = voiceName.trim();
    if (voiceTracks.containsKey(voiceKey)) {
      return voiceTracks.get(voiceKey);
    }
    if (attemptedVoiceLoads.contains(voiceKey)) {
      return null;
    }
    attemptedVoiceLoads.add(voiceKey);
    return loadVoiceFile(voiceKey);
  }
  
  // 載入語音檔案的核心方法
  AudioPlayer loadVoiceFile(String voiceName) {
    String[] voicePaths = {
      "data/voice/" + voiceName, 
      "data/voices/" + voiceName,
      "data/audio/voice/" + voiceName,
    };
    if (voiceName.contains("_")) {
      String[] parts = voiceName.split("_");
      if (parts.length >= 2) {
        String characterName = parts[0];
        String[] characterPaths = {
          "data/voice/" + characterName + "/" + voiceName,
          "data/voices/" + characterName + "/" + voiceName,
          "data/audio/voice/" + characterName + "/" + voiceName
        };
        String[] allPaths = new String[voicePaths.length + characterPaths.length];
        System.arraycopy(characterPaths, 0, allPaths, 0, characterPaths.length);
        System.arraycopy(voicePaths, 0, allPaths, characterPaths.length, voicePaths.length);
        voicePaths = allPaths;
      }
    }
    
    // 嘗試所有路徑和格式組合
    for (String basePath : voicePaths) {
      for (String format : supportedAudioFormats) {
        String filePath = basePath + "." + format;
        try {
          AudioPlayer voice = minim.loadFile(filePath);
          if (voice != null) {
            voiceTracks.put(voiceName, voice);
            println("✓ 載入語音: " + voiceName + " (" + filePath + ")");
            return voice;
          }
        } catch (Exception e) {
        }
      }
    }
    
    println("⚠ 找不到語音檔案: " + voiceName + " (已嘗試多種路徑和格式)");
    return null;
  }
  
  // 播放語音 - 自動載入版本
  void playVoice(String voiceName) {
    if (!voiceAutoPlay || voiceName == null || voiceName.trim().isEmpty()) {
      voiceFinished = true;
      return;
    }
    
    // 停止當前語音
    if (currentVoice != null && currentVoice.isPlaying()) {
      currentVoice.pause();
      currentVoice.rewind();
    }
    
    // 嘗試載入語音
    AudioPlayer voice = loadVoiceIfNeeded(voiceName);
    if (voice != null) {
      currentVoice = voice;
      currentVoice.rewind();
      currentVoice.setGain(calculateGain(voiceVolume));
      currentVoice.play();
      
      voiceIsPlaying = true;
      voiceFinished = false;
      
      println("播放語音: " + voiceName);
    } else {
      println("⚠ 語音檔案不存在，遊戲繼續: " + voiceName);
      voiceFinished = true;
    }
  }
  
  // 停止語音
  void stopVoice() {
    if (currentVoice != null && currentVoice.isPlaying()) {
      currentVoice.pause();
      currentVoice.rewind();
    }
    voiceIsPlaying = false;
    voiceFinished = true;
  }
  
  // 檢查語音是否播放中
  boolean isVoicePlaying() {
    if (currentVoice == null) {
      return false;
    }
    return currentVoice.isPlaying();
  }
  
  // 語音完成檢查
  boolean isVoiceFinished() {
    return voiceFinished;
  }
  
  // 重置語音狀態
  void resetVoiceState() {
    voiceIsPlaying = false;
    voiceFinished = true;
  }
  
  // 更新方法
  void update() {
    updateBGMFading();
    updateVoiceStatus();
  }
  
  // 更新語音狀態
  void updateVoiceStatus() {
    if (voiceIsPlaying && currentVoice != null) {
      if (!currentVoice.isPlaying()) {
        voiceIsPlaying = false;
        voiceFinished = true;
        println("語音播放完畢");
      }
    }
  }
  
  // 載入BGM的通用方法（手動載入）
  void loadBGMTrack(String name, String baseFilePath) {
    if (bgmTracks.containsKey(name)) {
      return;
    }
    for (String format : supportedAudioFormats) {
      String filePath = baseFilePath + "." + format;
      try {
        AudioPlayer track = minim.loadFile(filePath);
        if (track != null) {
          bgmTracks.put(name, track);
          println("✓ 載入BGM: " + name + " (" + filePath + ")");
          return;
        }
      } catch (Exception e) {
      }
    }
    println("⚠ BGM載入失敗: " + name + " (已嘗試多種格式)");
  }
  
  // 載入音效的通用方法
  void loadSFXTrack(String name, String baseFilePath) {
    if (sfxSounds.containsKey(name)) {
      return;
    }
    for (String format : supportedAudioFormats) {
      String filePath = baseFilePath + "." + format;
      try {
        AudioPlayer track = minim.loadFile(filePath);
        if (track != null) {
          sfxSounds.put(name, track);
          println("✓ 載入音效: " + name + " (" + filePath + ")");
          return;
        }
      } catch (Exception e) {
      }
    }
    println("⚠ 音效載入失敗: " + name + " (已嘗試多種格式)");
  }
  
  // BGM播放
  void playBGM(String trackName) {
    if (trackName == null || trackName.trim().isEmpty()) {
      println("⚠ BGM名稱為空，跳過播放");
      return;
    }
    trackName = trackName.trim();
    if (trackName.equals(currentBGMName) && currentBGM != null && currentBGM.isPlaying()) {
      println("BGM已在播放: " + trackName);
      return;
    }
    println("嘗試播放BGM: " + trackName);
    
    // 嘗試載入BGM
    AudioPlayer newTrack = loadBGMIfNeeded(trackName);
    if (newTrack == null) {
      println("⚠ 找不到BGM: " + trackName + "，使用預設BGM");
      if (!trackName.equals("title") && bgmTracks.containsKey("title")) {
        newTrack = bgmTracks.get("title");
        trackName = "title";
        println("使用title作為備用BGM");
      } else {
        println("⚠ 無可用BGM，遊戲繼續");
        return;
      }
    }
    if (currentBGM != null && currentBGM.isPlaying()) {
      startCrossFade(newTrack, trackName);
    } else {
      playNewBGM(newTrack, trackName);
    }
  }
  
  void startCrossFade(AudioPlayer newTrack, String trackName) {
    nextBGM = newTrack;
    isFading = true;
    fadeStartTime = millis();
    nextBGM.rewind();
    nextBGM.setGain(calculateGain(0));
    nextBGM.loop();
    println("開始淡入淡出: " + currentBGMName + " → " + trackName);
  }
  
  void playNewBGM(AudioPlayer newTrack, String trackName) {
    currentBGM = newTrack;
    currentBGMName = trackName;
    currentBGM.rewind();
    currentBGM.setGain(calculateGain(musicVolume));
    currentBGM.loop();
    println("播放BGM: " + trackName);
  }
  
  // 更新BGM淡入淡出
  void updateBGMFading() {
    if (isFading && currentBGM != null && nextBGM != null) {
      float elapsed = millis() - fadeStartTime;
      float progress = elapsed / fadeDuration;
      if (progress >= 1.0) {
        currentBGM.pause();
        currentBGM = nextBGM;
        currentBGMName = getBGMName(nextBGM);
        nextBGM = null;
        isFading = false;
        currentBGM.setGain(calculateGain(musicVolume));
        println("BGM切換完成: " + currentBGMName);
      } else {
        float fadeOutVolume = musicVolume * (1.0 - progress);
        float fadeInVolume = musicVolume * progress;
        currentBGM.setGain(calculateGain(fadeOutVolume));
        nextBGM.setGain(calculateGain(fadeInVolume));
      }
    }
  }
  
  // 播放音效
  void playSFX(String soundName) {
    if (soundName == null || soundName.trim().isEmpty()) {
      return;
    }
    soundName = soundName.trim();
    if (!sfxSounds.containsKey(soundName)) {
      loadSFXTrack(soundName, "data/sfx/" + soundName);
    }
    AudioPlayer sfx = sfxSounds.get(soundName);
    if (sfx != null) {
      sfx.rewind();
      sfx.setGain(calculateGain(sfxVolume));
      sfx.play();
    } else {
      println("⚠ 找不到音效: " + soundName + "，遊戲繼續");
    }
  }
  
  // 根據場景自動播放BGM
  void playSceneBGM(String sceneName) {
    if (!autoBGMEnabled || sceneName == null || sceneName.trim().isEmpty()) {
      return;
    }
    sceneName = sceneName.trim();
    String bgmName = null;
    if (sceneBGMMapping.containsKey(sceneName)) {
      bgmName = sceneBGMMapping.get(sceneName);
      println("找到場景BGM映射: " + sceneName + " -> " + bgmName);
    } else {
      bgmName = sceneName;
      println("使用場景名稱作為BGM: " + sceneName);
    }
    if (bgmName != null && !bgmName.trim().isEmpty()) {
      if (!bgmName.equals(currentBGMName)) {
        println("準備播放場景BGM: " + bgmName);
        playBGM(bgmName);
      } else {
        println("場景BGM已在播放: " + bgmName);
      }
    } else {
      println("⚠ 場景 " + sceneName + " 沒有對應的BGM配置");
    }
  }
    
  // 停止當前BGM
  void stopBGM() {
    if (currentBGM != null && currentBGM.isPlaying()) {
      currentBGM.pause();
      println("停止BGM: " + currentBGMName);
    }
    currentBGMName = "";
  }
  
  // 暫停當前BGM
  void pauseBGM() {
    if (currentBGM != null && currentBGM.isPlaying()) {
      currentBGM.pause();
      println("暫停BGM: " + currentBGMName);
    }
  }
  
  // 恢復BGM播放
  void resumeBGM() {
    if (currentBGM != null && !currentBGM.isPlaying()) {
      currentBGM.play();
      println("恢復BGM: " + currentBGMName);
    }
  }
  
  // 設置BGM淡入淡出時間
  void setFadeDuration(float duration) {
    fadeDuration = max(duration, 50);
  }
  
  // 啟用/停用自動BGM切換
  void setAutoBGMEnabled(boolean enabled) {
    autoBGMEnabled = enabled;
    println("自動BGM切換: " + (enabled ? "啟用" : "停用"));
  }
  
  // 工具方法
  String getBGMName(AudioPlayer track) {
    for (String name : bgmTracks.keySet()) {
      if (bgmTracks.get(name) == track) {
        return name;
      }
    }
    return "unknown";
  }
  
  float calculateGain(float volume) {
    if (volume <= 0.001) return -80;
    float gain = 20 * log(volume * masterVolume) / log(10);
    return constrain(gain, -80, 6);
  }
  
  // 音量控制方法
  void setMasterVolume(float vol) {
    masterVolume = constrain(vol, 0, 1);
    updateAllVolumes();
  }
  
  void setMusicVolume(float vol) {
    musicVolume = constrain(vol, 0, 1);
    updateBGMVolume();
  }
  
  void setSFXVolume(float vol) {
    sfxVolume = constrain(vol, 0, 1);
  }
  
  void setVoiceVolume(float vol) {
    voiceVolume = constrain(vol, 0, 1);
    if (currentVoice != null) {
      currentVoice.setGain(calculateGain(voiceVolume));
    }
  }
  
  void updateBGMVolume() {
    if (currentBGM != null) {
      currentBGM.setGain(calculateGain(musicVolume));
    }
  }
  
  void updateAllVolumes() {
    updateBGMVolume();
    if (currentVoice != null) {
      currentVoice.setGain(calculateGain(voiceVolume));
    }
  }
  
  // 語音控制方法
  void toggleVoiceAutoPlay() {
    voiceAutoPlay = !voiceAutoPlay;
    if (!voiceAutoPlay) {
      stopVoice();
    }
    println("語音自動播放: " + (voiceAutoPlay ? "開啟" : "關閉"));
  }
  
  void setVoiceInterruptible(boolean interruptible) {
    voiceInterruptible = interruptible;
  }
  
  // 管理方法
  void clearVoiceCache() {
    for (AudioPlayer voice : voiceTracks.values()) {
      if (voice.isPlaying()) {
        voice.pause();
      }
      voice.close();
    }
    voiceTracks.clear();
    attemptedVoiceLoads.clear();
    currentVoice = null;
    voiceIsPlaying = false;
    voiceFinished = true;
    println("語音快取已清理");
  }
  
  void clearBGMCache() {
    ArrayList<String> basicBGMs = new ArrayList<String>();
    basicBGMs.add("title");
    basicBGMs.add("default");
    ArrayList<String> toRemove = new ArrayList<String>();
    for (String bgmName : bgmTracks.keySet()) {
      if (!basicBGMs.contains(bgmName)) {
        toRemove.add(bgmName);
      }
    }
    
    for (String bgmName : toRemove) {
      AudioPlayer bgm = bgmTracks.get(bgmName);
      if (bgm != currentBGM) {
        bgm.close();
        bgmTracks.remove(bgmName);
      }
    }
    
    // 清理嘗試載入記錄
    attemptedBGMLoads.clear();
    for (String basicBGM : basicBGMs) {
      if (bgmTracks.containsKey(basicBGM)) {
        attemptedBGMLoads.add(basicBGM);
      }
    }
    println("BGM快取已清理，保留基本BGM");
  }
  
  void preloadBGMsForScene(String sceneName) {
    if (sceneName == null || sceneName.trim().isEmpty()) {
      return;
    }
    println("預載入場景BGM: " + sceneName);
    String bgmName = sceneBGMMapping.get(sceneName);
    if (bgmName != null) {
      loadBGMIfNeeded(bgmName);
    } else {
      loadBGMIfNeeded(sceneName);
    }
  }
  
  void preloadVoicesForCharacter(String characterName) {
    if (characterName == null || characterName.trim().isEmpty()) {
      return;
    }
    println("預載入角色語音: " + characterName);
    String[] commonVoiceNumbers = {"001", "002", "003", "004", "005"};
    for (String number : commonVoiceNumbers) {
      String voiceName = characterName + "_" + number;
      loadVoiceIfNeeded(voiceName);
    }
  }
  
  // 獲取當前播放狀態
  String getCurrentBGMName() {
    return currentBGMName;
  }
  
  boolean isBGMPlaying() {
    return currentBGM != null && currentBGM.isPlaying();
  }
  
  float getBGMPosition() {
    if (currentBGM != null) {
      try {
        return currentBGM.position();
      } catch (Exception e) {
        return 0;
      }
    }
    return 0;
  }
  
  float getBGMLength() {
    if (currentBGM != null) {
      try {
        return currentBGM.length();
      } catch (Exception e) {
        return 0;
      }
    }
    return 0;
  }
  
  // 腳本接口方法
  void scriptAddSceneBGM(String sceneName, String bgmName) {
    addSceneBGMMapping(sceneName, bgmName);
  }
  
  void scriptPlayBGM(String bgmName) {
    playBGM(bgmName);
  }
  
  void scriptStopBGM() {
    stopBGM();
  }
  
  void scriptPauseBGM() {
    pauseBGM();
  }
  
  void scriptResumeBGM() {
    resumeBGM();
  }
  
  void scriptSetBGMVolume(float volume) {
    setMusicVolume(volume);
  }
  
  void scriptPlaySFX(String sfxName) {
    playSFX(sfxName);
  }
  
  void scriptPlayVoice(String voiceName) {
    playVoice(voiceName);
  }
  
  void scriptStopVoice() {
    stopVoice();
  }
  
  // 資源清理
  void dispose() {
    println("清理音訊資源...");
    if (currentBGM != null) {
      currentBGM.close();
    }
    if (currentVoice != null) {
      currentVoice.close();
    }
    for (AudioPlayer track : bgmTracks.values()) {
      track.close();
    }
    for (AudioPlayer sfx : sfxSounds.values()) {
      sfx.close();
    }
    for (AudioPlayer voice : voiceTracks.values()) {
      voice.close();
    }
    bgmTracks.clear();
    sfxSounds.clear();
    voiceTracks.clear();
    attemptedVoiceLoads.clear();
    attemptedBGMLoads.clear();
    sceneBGMMapping.clear();
    
    minim.stop();
    println("音訊資源清理完成");
  }
}

// 角色管理器
class CharacterManager {
  HashMap<String, PImage> characterImages;
  HashMap<String, CharacterDisplay> activeCharacters;
  ArrayList<String> attemptedLoads;
  CharacterManager() {
    characterImages = new HashMap<String, PImage>();
    activeCharacters = new HashMap<String, CharacterDisplay>();
    attemptedLoads = new ArrayList<String>();
    println("角色管理器初始化完成");
  }
  
  // 自動載入角色圖片
  PImage loadCharacterImageIfNeeded(String character, String emotion) {
    if (character == null || emotion == null) {
      return null;
    }
    String imageKey = character + "_" + emotion;
    if (characterImages.containsKey(imageKey)) {
      return characterImages.get(imageKey);
    }
    if (attemptedLoads.contains(imageKey)) {
      return null;
    }
    attemptedLoads.add(imageKey);
    return loadCharacterImage(character, emotion);
  }
  
  // 載入角色圖片的核心方法
  PImage loadCharacterImage(String character, String emotion) {
    String imageKey = character + "_" + emotion;
    String[] formats = {"png", "jpg", "jpeg"};
    String[] paths = {
      "data/characters/" + character + "/" + character + "_" + emotion,
      "data/characters/" + character + "_" + emotion,
      "data/characters/" + character + "/" + emotion,
    };
    for (String basePath : paths) {
      for (String format : formats) {
        String filePath = basePath + "." + format;
        try {
          PImage image = loadImage(filePath);
          if (image != null && image.width > 0 && image.height > 0) {
            characterImages.put(imageKey, image);
            println("✓ 載入角色圖片: " + imageKey + " (" + filePath + ")");
            return image;
          }
        } catch (Exception e) {
        }
      }
    }
    println("⚠ 找不到角色圖片: " + imageKey + " (已嘗試多種路徑和格式)");
    return null;
  }
  
  // 新增角色到場景
  void addCharacter(String character, String position, String emotion) {
    if (character == null) {
      println("⚠ 角色名稱為空，忽略操作");
      return;
    }
    if (position == null || position.trim().isEmpty()) {
      position = "center";
    }
    if (emotion == null || emotion.trim().isEmpty()) {
      emotion = "normal";
    }
    String key = character;
    if (activeCharacters.containsKey(key)) {
      CharacterDisplay charDisplay = activeCharacters.get(key);
      charDisplay.updateEmotion(emotion);
      if (!charDisplay.position.equals(position)) {
        charDisplay.updatePosition(position);
      }
      charDisplay.setActive(true);
      charDisplay.targetAlpha = 255; 
    } else {
      CharacterDisplay newChar = new CharacterDisplay(character, position, emotion);
      activeCharacters.put(key, newChar);
      newChar.playEnterAnimation();
      println("添加角色: " + character + " (" + position + ", " + emotion + ")");
    }
  }

  // 確保角色顯示
  void ensureCharacterVisible(String character, String position, String emotion) {
    if (character == null) return;
    if (activeCharacters.containsKey(character)) {
      CharacterDisplay charDisplay = activeCharacters.get(character);
      if (emotion != null && !emotion.trim().isEmpty()) {
        charDisplay.updateEmotion(emotion);
      }
      if (position != null && !position.trim().isEmpty()) {
        charDisplay.updatePosition(position);
      }
      charDisplay.setActive(true);
      charDisplay.targetAlpha = 255; 
    } else {
      String finalPosition = (position != null && !position.trim().isEmpty()) ? position : "center";
      String finalEmotion = (emotion != null && !emotion.trim().isEmpty()) ? emotion : "normal";
      addCharacter(character, finalPosition, finalEmotion);
    }
  }
  
  // 移除角色
  void removeCharacter(String character) {
    if (character == null) return;
    
    String key = character;
    if (activeCharacters.containsKey(key)) {
      CharacterDisplay charDisplay = activeCharacters.get(key);
      charDisplay.playExitAnimation();
      println("移除角色: " + character);
    } else {
      println("⚠ 嘗試移除不存在的角色: " + character);
    }
  }
  
  // 清空所有角色
  void clearAllCharacters() {
    if (activeCharacters.size() == 0) {
      println("沒有角色需要清除");
      return;
    }
    for (CharacterDisplay charDisplay : activeCharacters.values()) {
      charDisplay.playExitAnimation();
    }
    println("清空所有角色 (共 " + activeCharacters.size() + " 個)");
  }
  
  // 設置說話者高亮
  void setSpeaker(String speaker) {
    if (speaker == null) return;
    
    boolean foundSpeaker = false;
    for (String key : activeCharacters.keySet()) {
      CharacterDisplay charDisplay = activeCharacters.get(key);
      if (key.equals(speaker)) {
        charDisplay.setActive(true);
        foundSpeaker = true;
      } else {
        charDisplay.setActive(false);
      }
    }
    if (!foundSpeaker && !isSystemSpeaker(speaker)) {
      for (CharacterDisplay charDisplay : activeCharacters.values()) {
        charDisplay.setActive(true);
      }
      println("⚠ 說話者不在場景中: " + speaker + "，重置所有角色為正常狀態");
    }
  }
  
  // 判斷是否為系統說話者
  boolean isSystemSpeaker(String speaker) {
    String[] systemSpeakers = {"旁白", "主角", "系統", "narrator", "protagonist", "system"};
    for (String systemSpeaker : systemSpeakers) {
      if (speaker.equals(systemSpeaker)) {
        return true;
      }
    }
    return false;
  }

  // 批量角色操作
  void updateCharacterEmotion(String character, String emotion) {
    if (character == null || emotion == null) return;
    
    if (activeCharacters.containsKey(character)) {
      activeCharacters.get(character).updateEmotion(emotion);
    } else {
      println("⚠ 嘗試更新不存在角色的情感: " + character);
    }
  }
  
  void updateCharacterPosition(String character, String position) {
    if (character == null || position == null) return;
    
    if (activeCharacters.containsKey(character)) {
      activeCharacters.get(character).updatePosition(position);
    } else {
      println("⚠ 嘗試更新不存在角色的位置: " + character);
    }
  }
  
  void setCharacterVisibility(String character, boolean visible) {
    if (character == null) return;
    
    if (activeCharacters.containsKey(character)) {
      CharacterDisplay charDisplay = activeCharacters.get(character);
      charDisplay.targetAlpha = visible ? 255 : 0;
    } else {
      println("⚠ 嘗試設置不存在角色的可見性: " + character);
    }
  }
  
  // 多角色場景轉換
  void transitionToMultiCharacter(String newCharacter, String newPosition, String newEmotion, String existingCharacter, String existingNewPosition) {
    if (existingCharacter != null && existingNewPosition != null && activeCharacters.containsKey(existingCharacter)) {
      CharacterDisplay existingChar = activeCharacters.get(existingCharacter);
      existingChar.updatePosition(existingNewPosition);
    }
    if (newCharacter != null && newPosition != null && newEmotion != null) {
      addCharacter(newCharacter, newPosition, newEmotion);
    }
  }
  
  void update() {
    ArrayList<String> toRemove = new ArrayList<String>();
    for (String key : activeCharacters.keySet()) {
      CharacterDisplay charDisplay = activeCharacters.get(key);
      charDisplay.update();
      if (charDisplay.shouldRemove()) {
        toRemove.add(key);
      }
    }
    for (String key : toRemove) {
      activeCharacters.remove(key);
      println("角色已移除: " + key);
    }
  }
  
  void display() {
    if (activeCharacters.size() == 0) {
      return;
    }
    
    // 按位置分組角色
    ArrayList<CharacterDisplay> leftChars = new ArrayList<CharacterDisplay>();
    ArrayList<CharacterDisplay> centerChars = new ArrayList<CharacterDisplay>();
    ArrayList<CharacterDisplay> rightChars = new ArrayList<CharacterDisplay>();
    ArrayList<CharacterDisplay> otherChars = new ArrayList<CharacterDisplay>();
    
    for (CharacterDisplay charDisplay : activeCharacters.values()) {
      switch(charDisplay.position) {
        case "left":
        case "far_left":
          leftChars.add(charDisplay);
          break;
        case "right":
        case "far_right":
          rightChars.add(charDisplay);
          break;
        case "center":
          centerChars.add(charDisplay);
          break;
        default:
          otherChars.add(charDisplay);
          break;
      }
    }
    
    // 繪製順序：左→右→其他→中（確保中央角色在最前面）
    for (CharacterDisplay charDisplay : leftChars) {
      charDisplay.display();
    }
    for (CharacterDisplay charDisplay : rightChars) {
      charDisplay.display();
    }
    for (CharacterDisplay charDisplay : otherChars) {
      charDisplay.display();
    }
    for (CharacterDisplay charDisplay : centerChars) {
      charDisplay.display();
    }
  }

  void updateAllCharacterPositions() {
    for (CharacterDisplay charDisplay : activeCharacters.values()) {
      charDisplay.calculatePosition();
    }
  }
  
  // 獲取當前活躍角色列表
  ArrayList<String> getActiveCharacters() {
    return new ArrayList<String>(activeCharacters.keySet());
  }
  
  // 檢查角色是否存在
  boolean hasCharacter(String character) {
    return character != null && activeCharacters.containsKey(character);
  }
  
  // 獲取角色當前狀態
  String getCharacterEmotion(String character) {
    if (hasCharacter(character)) {
      return activeCharacters.get(character).emotion;
    }
    return null;
  }
  
  String getCharacterPosition(String character) {
    if (hasCharacter(character)) {
      return activeCharacters.get(character).position;
    }
    return null;
  }
  
  // 角色顯示類
  class CharacterDisplay {
    String character;
    String position;
    String emotion;
    
    float x, y;
    float targetX, targetY;
    float currentX, currentY;
    float alpha;
    float targetAlpha;
    float scale;
    float targetScale;
    
    boolean isActive;
    boolean isEntering;
    boolean isExiting;
    boolean shouldRemove;
    
    float animationSpeed = 0.08;
    float bobAmount = 2;
    float bobSpeed = 0.003;
    float bobOffset;
    
    long lastEmotionChange = 0;
    float emotionChangeAlpha = 0;

    color defaultColor;
    
    CharacterDisplay(String character, String position, String emotion) {
      this.character = (character != null && !character.trim().isEmpty()) ? character.trim() : "Unknown";
      this.position = (position != null && !position.trim().isEmpty()) ? position.trim() : "center";
      this.emotion = (emotion != null && !emotion.trim().isEmpty()) ? emotion.trim() : "normal";
      this.isActive = true;
      this.alpha = 0;
      this.targetAlpha = 255;
      this.scale = 0.8;
      this.targetScale = 1.0;
      this.shouldRemove = false;
      this.bobOffset = random(TWO_PI);
      this.defaultColor = generateCharacterColor(this.character);
      calculatePosition();
      boolean isLeftPosition = this.position.equals("left") || this.position.equals("far_left");
      this.currentX = targetX + (isLeftPosition ? -100 : 100);
      this.currentY = targetY + 50;
    }
    color generateCharacterColor(String characterName) {
      if (characterName == null || characterName.isEmpty()) {
        characterName = "default";
      }
      int hash = 0;
      for (int i = 0; i < characterName.length(); i++) {
        hash = hash * 31 + characterName.charAt(i);
      }
      hash = abs(hash);
      
      float hue = (hash % 360);
      colorMode(HSB, 360, 100, 100);
      color c = color(hue, 70, 85);
      colorMode(RGB, 255);
      return c;
    }
    
    void calculatePosition() {
      if (this.position == null) {
        this.position = "center";
        println("⚠ 角色位置為null，設為預設位置 center: " + this.character);
      }
      switch(this.position) {
        case "left":
          targetX = width * 0.25;
          break;
        case "center":
          targetX = width * 0.5;
          break;
        case "right":
          targetX = width * 0.75;
          break;
        case "far_left":
          targetX = width * 0.15;
          break;
        case "far_right":
          targetX = width * 0.85;
          break;
        default:
          targetX = width * 0.5;
          println("⚠ 未知的角色位置: " + this.position + "，使用預設位置 center");
          this.position = "center";
          break;
      }
      targetY = height * 1.35;
    }
    
    void updatePosition(String newPosition) {
      if (newPosition == null || newPosition.trim().isEmpty()) {
        println("⚠ 新位置參數為空或null，忽略位置更新: " + this.character);
        return;
      }
      String safeNewPosition = newPosition.trim();
      if (!safeNewPosition.equals(this.position)) {
        this.position = safeNewPosition;
        calculatePosition();
        playMoveAnimation();
        println("角色 " + character + " 移動到位置: " + safeNewPosition);
      }
    }
    void updateEmotion(String newEmotion) {
      if (newEmotion == null || newEmotion.trim().isEmpty()) {
        println("⚠ 新情感參數為空或null，忽略情感更新: " + this.character);
        return;
      }
      String safeNewEmotion = newEmotion.trim();
      if (!safeNewEmotion.equals(this.emotion)) {
        this.emotion = safeNewEmotion;
        lastEmotionChange = millis();
        emotionChangeAlpha = 1.0;
        playEmotionChangeAnimation();
        println("角色 " + character + " 情感變化: " + safeNewEmotion);
      }
    }
    
    void setActive(boolean active) {
      this.isActive = active;
      if (active) {
        targetAlpha = 255; // 說話者完全不透明
        targetScale = 1.02; // 稍微放大突出
      } else {
        targetAlpha = 225; // 非說話者稍微透明
        targetScale = 0.98; // 稍微縮小
      }
    }
    
    void playEnterAnimation() {
      isEntering = true;
      alpha = 0;
      targetAlpha = 255;
      scale = 0.8;
      targetScale = 1.0;
    }
    
    void playExitAnimation() {
      isExiting = true;
      targetAlpha = 0;
      targetScale = 0.8;
      targetY += 50;
    }
    
    void playMoveAnimation() {
      targetScale = 1.02;
    }
    
    void playEmotionChangeAnimation() {
      targetScale = 1.02;
    }
    
    boolean shouldRemove() {
      return shouldRemove;
    }
    
    void update() {
      currentX = lerp(currentX, targetX, animationSpeed);
      currentY = lerp(currentY, targetY, animationSpeed);
      alpha = lerp(alpha, targetAlpha, animationSpeed);
      scale = lerp(scale, targetScale, animationSpeed);
      if (isActive) {
        y = currentY + sin(millis() * bobSpeed + bobOffset) * bobAmount;
      } else {
        y = currentY;
      }
      x = currentX;
      
      // 情感變化動畫
      if (emotionChangeAlpha > 0) {
        emotionChangeAlpha -= 0.02;
        if (emotionChangeAlpha <= 0) {
          emotionChangeAlpha = 0;
          targetScale = isActive ? 1.02 : 0.98;
        }
      }
      
      // 退場動畫檢查
      if (isExiting && alpha < 5) {
        shouldRemove = true;
      }
      
      // 進場動畫完成檢查
      if (isEntering && abs(alpha - targetAlpha) < 5 && abs(scale - targetScale) < 0.05) {
        isEntering = false;
      }
    }
    
  void display() {
    PImage charImage = loadCharacterImageIfNeeded(character, emotion);
    boolean matrixPushed = false;
    try {
      pushMatrix();
      matrixPushed = true;
      translate(x, y);
      scale(scale);
      float displayAlpha = alpha;
      if (emotionChangeAlpha > 0) {
        displayAlpha = min(255, alpha + emotionChangeAlpha * 100);
      }
      tint(255, displayAlpha);
      if (charImage != null) {
        displayCharacterImage(charImage);
      } else {
        drawFallbackCharacter();
      }
      noTint();
    } catch (Exception e) {
      println("角色顯示錯誤: " + character + " - " + e.getMessage());
    } finally {
      if (matrixPushed) {
        popMatrix();
      }
    }
  }
    
    void displayCharacterImage(PImage charImage) {
      imageMode(CENTER);
      float sourceWidth = charImage.width;
      float sourceHeight = charImage.height;
      float displayHeight = height * 1.2;
      float displayWidth = (sourceWidth / sourceHeight) * displayHeight;
      if (displayWidth > width * 1.2) {
        displayWidth = width * 1.2;
        displayHeight = (sourceHeight / sourceWidth) * displayWidth;
      }
      image(charImage, 0, -displayHeight/2 + 50, displayWidth, displayHeight);
    }
    
    void drawFallbackCharacter() {
      stroke(100);
      strokeWeight(2);
      fill(red(defaultColor), green(defaultColor), blue(defaultColor), alpha);
      rectMode(CENTER);
      rect(0, 0, 80, 200, 10);
      fill(255, alpha);
      textAlign(CENTER);
      textSize(12);
      text(character, 0, 120);
      if (emotion != null && !emotion.equals("normal")) {
        textSize(10);
        text("(" + emotion + ")", 0, 135);
      }
      if (keyPressed && key == 'd') {
        textSize(8);
        text(position, 0, 150);
        text("Alpha: " + int(alpha), 0, 165);
        text("Active: " + isActive, 0, 180);
      }
      noStroke();
      rectMode(CORNER);
    }
  }
}

// 背景管理器 
class BackgroundManager {
  String currentBackground = "default";
  HashMap<String, PImage> backgroundImages;
  ArrayList<String> attemptedLoads;
  
  // 轉場系統
  boolean isTransitioning = false;
  String transitionType = "fade";
  float transitionProgress = 0;
  float transitionDuration = 600;
  long transitionStartTime = 0;
  PImage fromBackground = null;
  PImage toBackground = null;
  
  // 場景特寫系統
  boolean isShowingCloseup = false;
  CloseupCamera closeupCamera;
  
  // 響應式設計
  boolean autoFitScreen = true;
  
  BackgroundManager() {
    backgroundImages = new HashMap<String, PImage>();
    attemptedLoads = new ArrayList<String>();
    closeupCamera = new CloseupCamera();
    
    println("背景管理器初始化完成 (專業場景特寫系統)");
  }
  
  // === 核心背景切換API ===
  
  void setBackground(String backgroundName) {
    setBackground(backgroundName, "fade", 500);
  }
  
  void setBackground(String backgroundName, String transition) {
    setBackground(backgroundName, transition, 800);
  }
  
  void setBackground(String backgroundName, String transition, float duration) {
    if (backgroundName == null || backgroundName.trim().isEmpty()) {
      println("⚠ 背景名稱為空");
      return;
    }
    backgroundName = backgroundName.trim();
    if (backgroundName.equals(currentBackground) && !isTransitioning) {
      return;
    }
    PImage newBG = loadBackgroundIfNeeded(backgroundName);
    if (newBG == null) {
      println("⚠ 背景載入失敗: " + backgroundName);
      return;
    }
    startTransition(backgroundName, newBG, transition, duration);
    if (audioManager != null) {
      audioManager.playSceneBGM(backgroundName);
    }
    println("背景切換: " + currentBackground + " -> " + backgroundName + " (" + transition + ")");
  }
  
  // === 場景特寫API ===
  
  void startCloseup(String backgroundName, float zoom, float duration) {
    startCloseup(backgroundName, 0.5, 0.5, 0.5, 0.5, zoom, duration);
  }
  
  void startCloseup(String backgroundName, float startX, float startY, float endX, float endY, float zoom, float duration) {
    PImage closeupBG = loadBackgroundIfNeeded(backgroundName);
    if (closeupBG == null) {
      println("⚠ 特寫背景載入失敗: " + backgroundName);
      return;
    }
    
    closeupCamera.startCloseup(closeupBG, startX, startY, endX, endY, zoom, duration);
    isShowingCloseup = true;
    
    println("開始場景特寫: " + backgroundName + " 縮放:" + zoom + " 持續:" + duration + "ms");
  }
  
  void startPanning(String backgroundName, float fromX, float fromY, float toX, float toY, float zoom, float duration) {
    startCloseup(backgroundName, fromX, fromY, toX, toY, zoom, duration);
  }

  void startKenBurnsEffect(String backgroundName, float startZoom, float endZoom, float duration) {
    PImage closeupBG = loadBackgroundIfNeeded(backgroundName);
    if (closeupBG == null) {
      println("⚠ Ken Burns效果背景載入失敗: " + backgroundName);
      return;
    }
    float startX = random(0.2, 0.8);
    float startY = random(0.2, 0.8);
    float endX = random(0.2, 0.8);
    float endY = random(0.2, 0.8);
    closeupCamera.startKenBurns(closeupBG, startX, startY, endX, endY, startZoom, endZoom, duration);
    isShowingCloseup = true;
    println("開始Ken Burns效果: " + backgroundName + " 從" + startZoom + "到" + endZoom + " 持續:" + duration + "ms");
  }
  
  // 震動效果
  void startShakeEffect(float intensity, float duration) {
    closeupCamera.startShake(intensity, duration);
    println("開始震動效果: 強度" + intensity + " 持續:" + duration + "ms");
  }
  
  // 呼吸效果
  void startBreathingEffect(String backgroundName, float intensity, float speed) {
    PImage breathBG = loadBackgroundIfNeeded(backgroundName);
    if (breathBG == null) {
      println("⚠ 呼吸效果背景載入失敗: " + backgroundName);
      return;
    }
    closeupCamera.startBreathing(breathBG, intensity, speed);
    isShowingCloseup = true;
    println("開始呼吸效果: " + backgroundName + " 強度:" + intensity + " 速度:" + speed);
  }
  
  void stopCloseup() {
    if (isShowingCloseup) {
      closeupCamera.stop();
      isShowingCloseup = false;
      println("結束場景特寫");
    }
  }
  
  void stopCloseup(float fadeOutDuration) {
    if (isShowingCloseup) {
      closeupCamera.fadeOut(fadeOutDuration);
    }
  }
  
  // 場景特寫攝影機
  class CloseupCamera {
    PImage sourceImage;
    boolean isActive = false;
    boolean isAnimating = false;
    boolean isFadingOut = false;
    
    // 攝影機位置和縮放
    float currentX, currentY, currentZoom;
    float targetX, targetY, targetZoom;
    float startX, startY, startZoom;
    float endX, endY, endZoom;
    
    // 動畫控制
    long animationStartTime;
    float animationDuration;
    float alpha = 255;
    float targetAlpha = 255;
    
    // 淡出控制
    float fadeOutDuration = 1000;
    long fadeOutStartTime = 0;
    
    // Ken Burns 效果
    boolean isKenBurns = false;
    
    // 震動效果
    boolean isShaking = false;
    float shakeIntensity = 0;
    float shakeDuration = 0;
    long shakeStartTime = 0;
    PVector shakeOffset;
    
    // 呼吸效果
    boolean isBreathing = false;
    float breathingIntensity = 0.02;
    float breathingSpeed = 0.002;
    float breathingOffset = 0;
    
    // 緩動類型
    String easingType = "easeInOut";
    CloseupCamera() {
      shakeOffset = new PVector(0, 0);
    }
    void startCloseup(PImage image, float startX, float startY, float endX, float endY, float zoom, float duration) {
      startCloseup(image, startX, startY, endX, endY, 1.0, zoom, duration, "easeInOut");
    }
    void startCloseup(PImage image, float startX, float startY, float endX, float endY, float startZoom, float endZoom, float duration, String easing) {
      this.sourceImage = image;
      this.startX = constrain(startX, 0, 1);
      this.startY = constrain(startY, 0, 1);
      this.endX = constrain(endX, 0, 1);
      this.endY = constrain(endY, 0, 1);
      this.startZoom = max(startZoom, 0.1);
      this.endZoom = max(endZoom, 0.1);
      this.animationDuration = max(duration, 100);
      this.easingType = (easing != null) ? easing : "easeInOut";
      
      // 初始化位置
      this.currentX = this.startX;
      this.currentY = this.startY;
      this.currentZoom = this.startZoom;
      this.targetZoom = this.endZoom;
      
      // 重置所有效果狀態
      resetEffects();
      
      // 開始動畫
      this.isActive = true;
      this.isAnimating = true;
      this.animationStartTime = millis();
      this.alpha = 255;
      this.targetAlpha = 255;
    }
    
    // Ken Burns 效果啟動
    void startKenBurns(PImage image, float startX, float startY, float endX, float endY, float startZoom, float endZoom, float duration) {
      startCloseup(image, startX, startY, endX, endY, startZoom, endZoom, duration, "easeInOut");
      this.isKenBurns = true;
    }
    
    // 震動效果啟動
    void startShake(float intensity, float duration) {
      this.isShaking = true;
      this.shakeIntensity = intensity;
      this.shakeDuration = duration;
      this.shakeStartTime = millis();
      this.shakeOffset.set(0, 0);
    }
    
    // 呼吸效果啟動
    void startBreathing(PImage image, float intensity, float speed) {
      this.sourceImage = image;
      this.isBreathing = true;
      this.breathingIntensity = intensity;
      this.breathingSpeed = speed;
      this.breathingOffset = 0;
      
      // 設置基本參數
      this.currentX = 0.5;
      this.currentY = 0.5;
      this.currentZoom = 1.0;
      
      resetEffects();
      this.isActive = true;
      this.alpha = 255;
      this.targetAlpha = 255;
    }
    
    // 重置所有效果
    void resetEffects() {
      this.isKenBurns = false;
      this.isShaking = false;
      this.isBreathing = false;
      this.isAnimating = false;
      this.isFadingOut = false;
    }
    
    void update() {
      if (!isActive) return;
      
      // 處理淡出
      if (isFadingOut) {
        updateFadeOut();
        return;
      }
      
      // 處理震動效果
      if (isShaking) {
        updateShake();
      }
      
      // 處理呼吸效果
      if (isBreathing) {
        updateBreathing();
      }
      
      // 處理一般動畫
      if (isAnimating) {
        updateAnimation();
      }
    }
    
    // 更新淡出效果
    void updateFadeOut() {
      long elapsed = millis() - fadeOutStartTime;
      float progress = elapsed / fadeOutDuration;
      
      if (progress >= 1.0) {
        stop();
        return;
      }
      float easedProgress = applyEasing(progress, "easeOut");
      alpha = 255 * (1 - easedProgress);
    }
    
    // 更新震動效果
    void updateShake() {
      long elapsed = millis() - shakeStartTime;
      if (elapsed > shakeDuration) {
        isShaking = false;
        shakeOffset.set(0, 0);
        return;
      }
      float progress = elapsed / shakeDuration;
      float currentIntensity = shakeIntensity * (1 - progress);
      shakeOffset.x = random(-currentIntensity, currentIntensity);
      shakeOffset.y = random(-currentIntensity, currentIntensity);
    }
    
    // 更新呼吸效果
    void updateBreathing() {
      breathingOffset += breathingSpeed;
      
      // 使用sin波生成呼吸效果
      float breathMultiplier = 1.0 + sin(breathingOffset) * breathingIntensity;
      currentZoom = breathMultiplier;
    }
    
    // 更新一般動畫
    void updateAnimation() {
      long elapsed = millis() - animationStartTime;
      float progress = elapsed / animationDuration;
      
      if (progress >= 1.0) {
        progress = 1.0;
        if (!isBreathing) {
          isAnimating = false;
        }
      }
      
      // 應用緩動
      float easedProgress = applyEasing(progress, easingType);
      
      // 更新攝影機參數
      if (!isBreathing) { 
        currentZoom = lerp(startZoom, endZoom, easedProgress);
      }
      currentX = lerp(startX, endX, easedProgress);
      currentY = lerp(startY, endY, easedProgress);
    }
    
    // 應用不同類型的緩動函數
    float applyEasing(float t, String type) {
      switch(type) {
        case "linear":
          return t;
        case "easeIn":
          return t * t;
        case "easeOut":
          return 1 - (1 - t) * (1 - t);
        case "easeInOut":
          return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
        case "easeInCubic":
          return t * t * t;
        case "easeOutCubic":
          return 1 - pow(1 - t, 3);
        case "easeInQuart":
          return t * t * t * t;
        case "easeOutQuart":
          return 1 - pow(1 - t, 4);
        case "easeInBack":
          float c1 = 1.70158;
          float c3 = c1 + 1;
          return c3 * t * t * t - c1 * t * t;
        case "easeOutBack":
          float c1_2 = 1.70158;
          float c3_2 = c1_2 + 1;
          return 1 + c3_2 * pow(t - 1, 3) + c1_2 * pow(t - 1, 2);
        case "easeInElastic":
          if (t == 0) return 0;
          if (t == 1) return 1;
          float c4 = (2 * PI) / 3;
          return -pow(2, 10 * (t - 1)) * sin((t - 1.1) * c4);
        case "easeOutElastic":
          if (t == 0) return 0;
          if (t == 1) return 1;
          float c4_2 = (2 * PI) / 3;
          return pow(2, -10 * t) * sin((t - 0.1) * c4_2) + 1;
        case "easeOutBounce":
          float n1 = 7.5625;
          float d1 = 2.75;
          if (t < 1 / d1) {
            return n1 * t * t;
          } else if (t < 2 / d1) {
            return n1 * (t -= 1.5 / d1) * t + 0.75;
          } else if (t < 2.5 / d1) {
            return n1 * (t -= 2.25 / d1) * t + 0.9375;
          } else {
            return n1 * (t -= 2.625 / d1) * t + 0.984375;
          }
        default:
          return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t; // 預設 easeInOut
      }
    }
    
    void display() {
      if (!isActive || sourceImage == null) return;
      pushMatrix();
      if (isShaking) {
        translate(shakeOffset.x, shakeOffset.y);
      }
      
      // 計算顯示參數
      float imgWidth = sourceImage.width;
      float imgHeight = sourceImage.height;
      
      // 計算縮放後的尺寸
      float scaledWidth = width * currentZoom;
      float scaledHeight = height * currentZoom;
      
      // 保持寬高比
      float imgRatio = imgWidth / imgHeight;
      float screenRatio = (float)width / height;
      
      if (imgRatio > screenRatio) {
        scaledHeight = scaledWidth / imgRatio;
      } else {
        scaledWidth = scaledHeight * imgRatio;
      }
      
      // 計算焦點位置
      float focusPixelX = currentX * imgWidth;
      float focusPixelY = currentY * imgHeight;
      
      // 計算顯示位置（使焦點居中）
      float displayX = width/2 - (focusPixelX / imgWidth) * scaledWidth;
      float displayY = height/2 - (focusPixelY / imgHeight) * scaledHeight;
      
      // 應用透明度
      tint(255, alpha);
      
      // 顯示特寫圖片
      imageMode(CORNER);
      image(sourceImage, displayX, displayY, scaledWidth, scaledHeight);
      
      // Ken Burns 效果的邊緣暈化
      if (isKenBurns && alpha > 200) {
        drawVignette();
      }
      noTint();
      popMatrix();
    }
    
    // 繪製暈化效果
    void drawVignette() {
      for (int i = 0; i < width; i += 4) {
        for (int j = 0; j < height; j += 4) {
          float distFromCenter = dist(i, j, width/2, height/2);
          float maxDist = dist(0, 0, width/2, height/2);
          float vignetteAlpha = map(distFromCenter, maxDist * 0.6, maxDist, 0, 80);
          vignetteAlpha = constrain(vignetteAlpha, 0, 80);
          
          if (vignetteAlpha > 0) {
            fill(0, vignetteAlpha);
            noStroke();
            rect(i, j, 4, 4);
          }
        }
      }
    }
    
    // 淡出方法
    void fadeOut(float duration) {
      if (isActive) {
        isFadingOut = true;
        targetAlpha = 0;
        fadeOutDuration = max(duration, 100);
        fadeOutStartTime = millis();
        println("開始淡出，持續時間: " + fadeOutDuration + "ms");
      }
    }
    
    void stop() {
      isActive = false;
      resetEffects();
      sourceImage = null;
      println("場景特寫已停止");
    }
    
    // 設置緩動類型
    void setEasing(String easing) {
      this.easingType = easing;
    }
    
    // 暫停/恢復動畫
    void pauseAnimation() {
      if (isAnimating) {
        println("動畫已暫停");
      }
    }
    
    void resumeAnimation() {
      if (!isAnimating && isActive) {
        animationStartTime = millis();
        isAnimating = true;
        println("動畫已恢復");
      }
    }
    
    // 狀態查詢方法
    boolean isActive() {
      return isActive;
    }
    
    boolean isAnimating() {
      return isAnimating;
    }
    
    boolean isShaking() {
      return isShaking;
    }
    
    boolean isBreathing() {
      return isBreathing;
    }
    
    float getCurrentZoom() {
      return currentZoom;
    }
    
    PVector getCurrentPosition() {
      return new PVector(currentX, currentY);
    }
  }
  
  // 轉場系統
  void startTransition(String targetBGName, PImage targetBG, String transition, float duration) {
    fromBackground = getCurrentBackgroundImage();
    toBackground = targetBG;
    transitionType = transition;
    transitionDuration = max(duration, 100);
    transitionProgress = 0;
    transitionStartTime = millis();
    isTransitioning = true;
    currentBackground = targetBGName;
  }
  
  void updateTransition() {
    if (!isTransitioning) return;
    
    long elapsed = millis() - transitionStartTime;
    transitionProgress = elapsed / transitionDuration;
    
    if (transitionProgress >= 1.0) {
      finishTransition();
    }
  }
  
  void finishTransition() {
    isTransitioning = false;
    transitionProgress = 1.0;
    fromBackground = null;
    toBackground = null;
  }
  
  void drawTransition() {
    if (!isTransitioning || fromBackground == null || toBackground == null) {
      drawCurrentBackground();
      return;
    }
    
    switch(transitionType) {
      case "fade":
        drawFadeTransition();
        break;
      case "slide_left":
        drawSlideTransition(-1, 0);
        break;
      case "slide_right":
        drawSlideTransition(1, 0);
        break;
      case "slide_up":
        drawSlideTransition(0, -1);
        break;
      case "slide_down":
        drawSlideTransition(0, 1);
        break;
      case "wipe_left":
        drawWipeTransition("left");
        break;
      case "wipe_right":
        drawWipeTransition("right");
        break;
      case "wipe_up":
        drawWipeTransition("up");
        break;
      case "wipe_down":
        drawWipeTransition("down");
        break;
      case "circle":
        drawCircleTransition();
        break;
      case "zoom_in":
        drawZoomTransition(true);
        break;
      case "zoom_out":
        drawZoomTransition(false);
        break;
      case "blinds":
        drawBlindsTransition();
        break;
      case "crossfade":
        drawCrossfadeTransition();
        break;
      default:
        drawFadeTransition();
        break;
    }
  }
  
  // 轉場效果
  void drawFadeTransition() {
    float progress = closeupCamera.applyEasing(transitionProgress, "easeInOut");
    imageMode(CORNER);
    
    // 繪製原背景
    tint(255, 255 * (1 - progress));
    drawBackgroundImage(fromBackground);
    
    // 繪製新背景
    tint(255, 255 * progress);
    drawBackgroundImage(toBackground);
    noTint();
  }
  
  void drawSlideTransition(float dirX, float dirY) {
    float progress = closeupCamera.applyEasing(transitionProgress, "easeInOut");
    float offsetX = width * dirX * progress;
    float offsetY = height * dirY * progress;
    imageMode(CORNER);
    boolean matrix1Pushed = false, matrix2Pushed = false;
    
    try {
      pushMatrix();
      matrix1Pushed = true;
      translate(offsetX, offsetY);
      drawBackgroundImage(fromBackground);
      popMatrix();
      matrix1Pushed = false;
      pushMatrix();
      matrix2Pushed = true;
      translate(offsetX - width * dirX, offsetY - height * dirY);
      drawBackgroundImage(toBackground);
      popMatrix();
      matrix2Pushed = false;
    } catch (Exception e) {
      println("滑動轉場錯誤: " + e.getMessage());
    } finally {
      if (matrix1Pushed) popMatrix();
      if (matrix2Pushed) popMatrix();
    }
  }
  
  void drawWipeTransition(String direction) {
    imageMode(CORNER);
    
    // 先繪製原背景
    drawBackgroundImage(fromBackground);
    
    // 創建遮罩繪製新背景
    float progress = closeupCamera.applyEasing(transitionProgress, "easeInOut");
    
    // 計算裁剪區域
    int clipX = 0, clipY = 0, clipW = width, clipH = height;
    
    switch(direction) {
      case "left":
        clipW = (int)(width * progress);
        break;
      case "right":
        clipX = (int)(width * (1 - progress));
        clipW = (int)(width * progress);
        break;
      case "up":
        clipH = (int)(height * progress);
        break;
      case "down":
        clipY = (int)(height * (1 - progress));
        clipH = (int)(height * progress);
        break;
    }
    
    // 使用PGraphics進行裁剪
    PGraphics masked = createGraphics(width, height);
    masked.beginDraw();
    masked.clear();
    masked.image(toBackground, 0, 0, width, height);
    masked.endDraw();
    
    // 只顯示裁剪區域
    copy(masked, clipX, clipY, clipW, clipH, clipX, clipY, clipW, clipH);
  }
  
  void drawCircleTransition() {
    imageMode(CORNER);
    
    // 繪製原背景
    drawBackgroundImage(fromBackground);
    
    // 創建圓形遮罩
    float progress = closeupCamera.applyEasing(transitionProgress, "easeOutCubic");
    float maxRadius = sqrt(width * width + height * height) / 2;
    float radius = maxRadius * progress;
    
    PGraphics mask = createGraphics(width, height);
    mask.beginDraw();
    mask.background(0);
    mask.fill(255);
    mask.noStroke();
    mask.ellipse(width/2, height/2, radius * 2, radius * 2);
    mask.endDraw();
    
    PGraphics maskedBG = createGraphics(width, height);
    maskedBG.beginDraw();
    maskedBG.image(toBackground, 0, 0, width, height);
    maskedBG.endDraw();
    maskedBG.mask(mask);
    
    image(maskedBG, 0, 0);
  }
  
  void drawZoomTransition(boolean zoomIn) {
    imageMode(CENTER);
    float progress = closeupCamera.applyEasing(transitionProgress, "easeInOut");
    
    if (zoomIn) {
      // 新背景正常顯示
      image(toBackground, width/2, height/2, width, height);
      
      // 舊背景放大並淡出
      float scale = 1 + progress * 0.5;
      float alpha = 255 * (1 - progress);
      
      tint(255, alpha);
      image(fromBackground, width/2, height/2, width * scale, height * scale);
      noTint();
    } else {
      // 舊背景正常顯示
      image(fromBackground, width/2, height/2, width, height);
      
      // 新背景縮小並淡入
      float scale = 0.5 + progress * 0.5;
      float alpha = 255 * progress;
      
      tint(255, alpha);
      image(toBackground, width/2, height/2, width * scale, height * scale);
      noTint();
    }
    
    imageMode(CORNER);
  }
  
  void drawBlindsTransition() {
    imageMode(CORNER);
    
    // 繪製原背景
    drawBackgroundImage(fromBackground);
    
    // 百葉窗效果
    float progress = closeupCamera.applyEasing(transitionProgress, "easeInOut");
    int blindCount = 8;
    float blindHeight = height / (float)blindCount;
    
    for (int i = 0; i < blindCount; i++) {
      float y = i * blindHeight;
      float blindProgress = constrain((progress - i * 0.1) * 2, 0, 1);
      
      if (blindProgress > 0) {
        float revealHeight = blindHeight * blindProgress;
        copy(toBackground, 0, (int)y, width, (int)revealHeight, 0, (int)y, width, (int)revealHeight);
      }
    }
  }
  
  void drawCrossfadeTransition() {
    imageMode(CORNER);
    float progress = transitionProgress; // 線性進度
    
    // 繪製原背景
    tint(255, 255 * (1 - progress));
    drawBackgroundImage(fromBackground);
    
    // 混合繪製新背景
    blendMode(ADD);
    tint(255, 255 * progress * 0.5); // 降低亮度避免過曝
    drawBackgroundImage(toBackground);
    blendMode(NORMAL);
    
    noTint();
  }
  
  // === 背景載入系統 ===
  
  PImage loadBackgroundIfNeeded(String backgroundName) {
    if (backgroundImages.containsKey(backgroundName)) {
      return backgroundImages.get(backgroundName);
    }
    
    if (attemptedLoads.contains(backgroundName)) {
      return null; // 避免重複嘗試
    }
    
    attemptedLoads.add(backgroundName);
    return loadBackground(backgroundName);
  }
  
  PImage loadBackground(String backgroundName) {
    String[] formats = {"png", "jpg", "jpeg"};
    String[] paths = {
      "data/backgrounds/",
      "data/bg/",
      "data/images/"
    };
    for (String basePath : paths) {
      for (String format : formats) {
        String filePath = basePath + backgroundName + "." + format;
        try {
          PImage bgImage = loadImage(filePath);
          if (bgImage != null && bgImage.width > 0) {
            backgroundImages.put(backgroundName, bgImage);
            println("✓ 背景載入成功: " + backgroundName + " (" + filePath + ")");
            return bgImage;
          }
        } catch (Exception e) {
        }
      }
    }
    println("⚠ 找不到背景: " + backgroundName);
    return null;
  }
  
  // 顯示方法
  void display() {
    if (isShowingCloseup) {
      closeupCamera.update();
      closeupCamera.display();
    } else if (isTransitioning) {
      updateTransition();
      drawTransition();
    } else {
      drawCurrentBackground();
    }
  }
  
  void drawCurrentBackground() {
    PImage bgImage = backgroundImages.get(currentBackground);
    if (bgImage != null) {
      drawBackgroundImage(bgImage);
    } else {
      drawFallbackBackground();
    }
  }
  
  void drawBackgroundImage(PImage image) {
    if (image == null) return;
    imageMode(CORNER);
    if (autoFitScreen) {
      float scaleX = width / (float)image.width;
      float scaleY = height / (float)image.height;
      float scale = max(scaleX, scaleY);
      float displayWidth = image.width * scale;
      float displayHeight = image.height * scale;
      float offsetX = (width - displayWidth) / 2;
      float offsetY = (height - displayHeight) / 2;
      image(image, offsetX, offsetY, displayWidth, displayHeight);
    } else {
      image(image, 0, 0, width, height);
    }
  }
  
  PImage getCurrentBackgroundImage() {
    return backgroundImages.get(currentBackground);
  }
  
  void drawFallbackBackground() {
    for (int i = 0; i <= height; i++) {
      float inter = map(i, 0, height, 0, 1);
      color c = lerpColor(color(20, 30, 50), color(60, 80, 120), inter);
      stroke(c);
      line(0, i, width, i);
    }
    noStroke();
    fill(255, 150);
    textAlign(CENTER, CENTER);
    textSize(24);
    text("背景: " + currentBackground, width/2, height/2);
    textSize(14);
    text("請將背景圖片放在 data/backgrounds/ 資料夾", width/2, height/2 + 40);
  }
  
  // 進階腳本API
  // Ken Burns 效果
  void scriptStartKenBurns(String backgroundName, float startZoom, float endZoom, float duration) {
    startKenBurnsEffect(backgroundName, startZoom, endZoom, duration);
  }
  
  // 震動效果
  void scriptShakeScreen(float intensity, float duration) {
    startShakeEffect(intensity, duration);
  }
  
  // 呼吸效果
  void scriptStartBreathing(String backgroundName, float intensity, float speed) {
    startBreathingEffect(backgroundName, intensity, speed);
  }
  
  // 高級特寫，可指定緩動
  void scriptAdvancedCloseup(String backgroundName, float startX, float startY, float endX, float endY, float startZoom, float endZoom, float duration, String easing) {
    PImage closeupBG = loadBackgroundIfNeeded(backgroundName);
    if (closeupBG != null) {
      closeupCamera.startCloseup(closeupBG, startX, startY, endX, endY, startZoom, endZoom, duration, easing);
      isShowingCloseup = true;
    }
  }
  
  // 設置緩動類型
  void scriptSetEasing(String easing) {
    closeupCamera.setEasing(easing);
  }
  
  // 暫停/恢復攝影機動畫
  void scriptPauseCamera() {
    closeupCamera.pauseAnimation();
  }
  
  void scriptResumeCamera() {
    closeupCamera.resumeAnimation();
  }
  
  // 腳本API
  
  void scriptSetBackground(String backgroundName) {
    setBackground(backgroundName);
  }
  
  void scriptSetBackground(String backgroundName, String transition, float duration) {
    setBackground(backgroundName, transition, duration);
  }
  
  void scriptStartCloseup(String backgroundName, float zoom, float duration) {
    startCloseup(backgroundName, zoom, duration);
  }
  
  void scriptStartPanning(String backgroundName, float fromX, float fromY, float toX, float toY, float zoom, float duration) {
    startPanning(backgroundName, fromX, fromY, toX, toY, zoom, duration);
  }
  
  void scriptStopCloseup() {
    stopCloseup();
  }
  
  void scriptStopCloseup(float fadeOutDuration) {
    stopCloseup(fadeOutDuration);
  }
  
  // 工具方法
  String getCurrentBackground() {
    return currentBackground;
  }
  
  boolean isTransitioning() {
    return isTransitioning;
  }
  
  boolean isShowingCloseup() {
    return isShowingCloseup;
  }
  
  void setAutoFitScreen(boolean enabled) {
    autoFitScreen = enabled;
  }
  
  ArrayList<String> getAvailableTransitions() {
    ArrayList<String> transitions = new ArrayList<String>();
    transitions.add("fade");
    transitions.add("slide_left");
    transitions.add("slide_right");
    transitions.add("slide_up");
    transitions.add("slide_down");
    transitions.add("wipe_left");
    transitions.add("wipe_right");
    transitions.add("wipe_up");
    transitions.add("wipe_down");
    transitions.add("circle");
    transitions.add("zoom_in");
    transitions.add("zoom_out");
    transitions.add("blinds");
    transitions.add("crossfade");
    return transitions;
  }
  
  ArrayList<String> getAvailableEasings() {
    ArrayList<String> easings = new ArrayList<String>();
    easings.add("linear");
    easings.add("easeIn");
    easings.add("easeOut");
    easings.add("easeInOut");
    easings.add("easeInCubic");
    easings.add("easeOutCubic");
    easings.add("easeInQuart");
    easings.add("easeOutQuart");
    easings.add("easeInBack");
    easings.add("easeOutBack");
    easings.add("easeInElastic");
    easings.add("easeOutElastic");
    easings.add("easeOutBounce");
    return easings;
  }
}
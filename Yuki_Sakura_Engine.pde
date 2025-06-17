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
  backgroundManager.resetForNewGame();
  String firstSceneBackground = getFirstSceneBackground();
  if (firstSceneBackground != null && !firstSceneBackground.equals("default")) {
    backgroundManager.preloadInitialBackground(firstSceneBackground);
    println("✓ 預載入第一個場景背景: " + firstSceneBackground);
  } else {
    backgroundManager.setInitialBackground("default");
  }
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
  for (int i = 0; i < dialogueSystem.choiceHover.length; i++) {
    dialogueSystem.choiceHover[i] = false;
  }
  dialogueSystem.hoveredChoice = -1;
  
  println("開始新遊戲");
}
String getFirstSceneBackground() {
  if (dialogueSystem != null && dialogueSystem.nodes != null) {
    DialogueNode startNode = dialogueSystem.nodes.get("start");
    if (startNode != null && startNode.background != null && 
        !startNode.background.trim().isEmpty()) {
      return startNode.background.trim();
    }
  }
  return null;
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


// 標題畫面
class TitleScreen {
  PImage titleBackground;
  String[] menuItems = {"開始遊戲", "讀取存檔", "系統設定", "結束遊戲"};
  int hoveredItem = -1;
  float titleAlpha = 0;
  long titleStartTime;
  
  // 動畫相關
  float[] buttonOffsetY;
  float[] buttonScales;
  boolean[] buttonVisible;
  
  // 響應式設計基準值
  float baseWidth = 1280;
  float baseHeight = 720;
  
  // 退出確認對話框
  boolean showingExitConfirmation = false;
  float confirmationAlpha = 0;
  long confirmationStartTime = 0;
  int confirmedHoverItem = -1;
  
  // 漸層覆蓋緩存
  PGraphics gradientOverlay;
  boolean gradientOverlayCreated = false;
  
  TitleScreen() {
    titleStartTime = millis();
    loadTitleBackground();
    buttonOffsetY = new float[menuItems.length];
    buttonScales = new float[menuItems.length];
    buttonVisible = new boolean[menuItems.length];
    for (int i = 0; i < menuItems.length; i++) {
      buttonOffsetY[i] = 50;
      buttonScales[i] = 0.8;
      buttonVisible[i] = false;
    }
    if (audioManager != null) {
      audioManager.playBGM("title");
    }
    createGradientOverlay();
  }
  
  // 響應式縮放計算
  float getScaleX() {
    return width / baseWidth;
  }
  
  float getScaleY() {
    return height / baseHeight;
  }
  
  float getUniformScale() {
    return min(getScaleX(), getScaleY());
  }
  
  // 響應式座標轉換
  float scaleX(float x) {
    return x * getScaleX();
  }
  
  float scaleY(float y) {
    return y * getScaleY();
  }
  
  float scaleSize(float size) {
    return size * getUniformScale();
  }
  
  // 響應式字體大小
  void setResponsiveTextSize(float baseSize) {
    textSize(scaleSize(baseSize));
  }
  
  void loadTitleBackground() {
    try {
      titleBackground = loadImage("data/images/bg/title.png");
      if (titleBackground == null) {
        titleBackground = loadImage("data/images/bg/title.jpg");
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
  
  // 創建漸層覆蓋緩存
  void createGradientOverlay() {
    if (gradientOverlay != null) {
      gradientOverlay.dispose();
    }
    
    gradientOverlay = createGraphics(width, height);
    gradientOverlay.beginDraw();
    gradientOverlay.clear();
    
    // 上方漸層
    for (int i = 0; i < height/2; i++) {
      float alpha = map(i, 0, height/2, 80, 0);
      gradientOverlay.stroke(0, alpha);
      gradientOverlay.line(0, i, width, i);
    }
    
    // 下方漸層
    for (int i = height * 3/4; i < height; i++) {
      float alpha = map(i, height * 3/4, height, 0, 120);
      gradientOverlay.stroke(0, alpha);
      gradientOverlay.line(0, i, width, i);
    }
    
    gradientOverlay.noStroke();
    gradientOverlay.endDraw();
    gradientOverlayCreated = true;
  }
  
  // 檢查是否需要重新創建漸層覆蓋
  void checkGradientOverlayUpdate() {
    if (gradientOverlay == null || 
        gradientOverlay.width != width || 
        gradientOverlay.height != height) {
      createGradientOverlay();
    }
  }
  
  void display() {
    checkGradientOverlayUpdate();
    if (titleBackground != null) {
      drawBackgroundWithOverlay();
    } else {
      drawDefaultBackground();
    }
    updateAnimations();
    drawTitle();
    drawMenuButtons();
    drawCopyright();
    if (showingExitConfirmation) {
      drawExitConfirmation();
    }
  }
  
  void drawBackgroundWithOverlay() {
    imageMode(CORNER);
    float scaleX = width / (float)titleBackground.width;
    float scaleY = height / (float)titleBackground.height;
    float scale = max(scaleX, scaleY);
    float displayWidth = titleBackground.width * scale;
    float displayHeight = titleBackground.height * scale;
    float offsetX = (width - displayWidth) / 2;
    float offsetY = (height - displayHeight) / 2;
    tint(255, 220);
    image(titleBackground, offsetX, offsetY, displayWidth, displayHeight);
    noTint();
    if (gradientOverlayCreated && gradientOverlay != null) {
      image(gradientOverlay, 0, 0);
    }
  }
  
  void drawDefaultBackground() {
    for (int i = 0; i <= height; i++) {
      float inter = map(i, 0, height, 0, 1);
      color c = lerpColor(color(15, 25, 45), color(45, 65, 110), inter);
      stroke(c);
      line(0, i, width, i);
    }
    noStroke();
  }
  
  void updateAnimations() {
    float elapsed = millis() - titleStartTime;
    titleAlpha = constrain(elapsed / 2000.0 * 255, 0, 255);
    for (int i = 0; i < menuItems.length; i++) {
      float delay = i * 100 + 1000; 
      if (elapsed > delay) {
        buttonVisible[i] = true;
        buttonOffsetY[i] = lerp(buttonOffsetY[i], 0, 0.08);
        buttonScales[i] = lerp(buttonScales[i], 1.0, 0.08);
      }
      if (hoveredItem == i) {
        buttonScales[i] = lerp(buttonScales[i], 1.05, 0.15);
      } else if (buttonVisible[i]) {
        buttonScales[i] = lerp(buttonScales[i], 1.0, 0.1);
      }
    }
    if (showingExitConfirmation) {
      float confirmElapsed = millis() - confirmationStartTime;
      confirmationAlpha = constrain(confirmElapsed / 300.0 * 255, 0, 255);
    }
  }
  
  // 響應式標題繪製
  void drawTitle() {
    fill(255, 255, 255, titleAlpha);
    textAlign(CENTER);
    setResponsiveTextSize(52);
    text(gameConfig.getGameTitle(), width/2, scaleY(180));
  }
  
  // 響應式選單按鈕
  void drawMenuButtons() {
    float buttonWidth = scaleX(280);
    float buttonHeight = scaleY(55);
    float buttonSpacing = scaleY(20);
    float totalHeight = (buttonHeight + buttonSpacing) * menuItems.length - buttonSpacing;
    float startY = height - scaleY(200) - totalHeight/2;
    hoveredItem = -1;
    for (int i = 0; i < menuItems.length; i++) {
      if (!buttonVisible[i]) continue;
      float x = width/2 - buttonWidth/2;
      float y = startY + i * (buttonHeight + buttonSpacing) + scaleY(buttonOffsetY[i]);
      
      if (mouseX >= x && mouseX <= x + buttonWidth &&
          mouseY >= y && mouseY <= y + buttonHeight) {
        hoveredItem = i;
        break;
      }
    }
    for (int i = 0; i < menuItems.length; i++) {
      if (!buttonVisible[i]) continue;
      float x = width/2 - buttonWidth/2;
      float y = startY + i * (buttonHeight + buttonSpacing) + scaleY(buttonOffsetY[i]);
      pushMatrix();
      translate(x + buttonWidth/2, y + buttonHeight/2);
      scale(buttonScales[i]);
      drawButtonBackground(i, buttonWidth, buttonHeight);
      drawButtonText(i, menuItems[i]);
      popMatrix();
    }
  }
  
  void drawButtonBackground(int index, float w, float h) {
    boolean isHovered = (hoveredItem == index);
    if (isHovered) {
      for (int i = 0; i < h; i++) {
        float inter = map(i, 0, h, 0, 1);
        color c = lerpColor(color(80, 120, 200, 200), color(60, 100, 180, 240), inter);
        fill(c);
        rect(-w/2, -h/2 + i, w, 1);
      }
      stroke(150, 200, 255, 200);
      strokeWeight(scaleSize(3));
      noFill();
      rect(-w/2, -h/2, w, h, scaleSize(12));
      noStroke();
      fill(255, 255, 255, 40);
      rect(-w/2 + scaleSize(2), -h/2 + scaleSize(2), w - scaleSize(4), h/3, scaleSize(10));
    } else {
      for (int i = 0; i < h; i++) {
        float inter = map(i, 0, h, 0, 1);
        color c = lerpColor(color(40, 60, 100, 180), color(20, 40, 80, 220), inter);
        fill(c);
        rect(-w/2, -h/2 + i, w, 1);
      }
      stroke(100, 150, 200, 150);
      strokeWeight(scaleSize(2));
      noFill();
      rect(-w/2, -h/2, w, h, scaleSize(12));
      noStroke();
      fill(255, 255, 255, 20);
      rect(-w/2 + scaleSize(2), -h/2 + scaleSize(2), w - scaleSize(4), h/3, scaleSize(10));
    }
  }
  
  void drawButtonText(int index, String text) {
    boolean isHovered = (hoveredItem == index);
    fill(0, 100);
    textAlign(CENTER, CENTER);
    setResponsiveTextSize(20);
    text(text, scaleSize(2), scaleSize(2));
    if (isHovered) {
      fill(255, 255, 255, 255);
    } else {
      fill(220, 230, 255, 240);
    }
    textAlign(CENTER, CENTER);
    setResponsiveTextSize(20);
    text(text, 0, 0);
  }
  
  void drawExitConfirmation() {
    fill(0, 0, 0, confirmationAlpha * 0.6);
    rect(0, 0, width, height);
    float dialogWidth = scaleX(350);
    float dialogHeight = scaleY(200);
    float dialogX = (width - dialogWidth) / 2;
    float dialogY = (height - dialogHeight) / 2;
    for (int i = 0; i < dialogHeight; i++) {
      float inter = map(i, 0, dialogHeight, 0, 1);
      color c = lerpColor(color(40, 50, 80, confirmationAlpha), color(20, 30, 60, confirmationAlpha), inter);
      fill(c);
      rect(dialogX, dialogY + i, dialogWidth, 1);
    }
    stroke(150, 200, 255, confirmationAlpha * 0.8);
    strokeWeight(scaleSize(2));
    noFill();
    rect(dialogX, dialogY, dialogWidth, dialogHeight, scaleSize(10));
    noStroke();
    fill(255, 255, 100, confirmationAlpha);
    textAlign(CENTER);
    setResponsiveTextSize(18);
    text("結束遊戲", width/2, dialogY + scaleY(40));
    fill(255, 255, 255, confirmationAlpha);
    setResponsiveTextSize(14);
    text("確定要退出遊戲嗎？", width/2, dialogY + scaleY(80));
    drawConfirmationButtons(dialogX, dialogY, dialogWidth, dialogHeight);
  }
  
  void drawConfirmationButtons(float dialogX, float dialogY, float dialogWidth, float dialogHeight) {
    String[] confirmButtons = {"確定", "取消"};
    float buttonWidth = scaleX(80);
    float buttonHeight = scaleY(35);
    float buttonSpacing = scaleX(20);
    confirmedHoverItem = -1;
    for (int i = 0; i < confirmButtons.length; i++) {
      float buttonX = dialogX + dialogWidth/2 - (buttonWidth + buttonSpacing/2) + i * (buttonWidth + buttonSpacing);
      float buttonY = dialogY + dialogHeight - scaleY(60);
      if (mouseX >= buttonX && mouseX <= buttonX + buttonWidth &&
          mouseY >= buttonY && mouseY <= buttonY + buttonHeight) {
        confirmedHoverItem = i;
        break;
      }
    }
    for (int i = 0; i < confirmButtons.length; i++) {
      float buttonX = dialogX + dialogWidth/2 - (buttonWidth + buttonSpacing/2) + i * (buttonWidth + buttonSpacing);
      float buttonY = dialogY + dialogHeight - scaleY(60);
      boolean isHovered = (confirmedHoverItem == i);
      if (i == 0) { 
        fill(isHovered ? color(200, 80, 80, confirmationAlpha) : color(160, 60, 60, confirmationAlpha));
      } else {
        fill(isHovered ? color(80, 120, 200, confirmationAlpha) : color(60, 100, 180, confirmationAlpha));
      }
      rect(buttonX, buttonY, buttonWidth, buttonHeight, scaleSize(5));
      stroke(isHovered ? color(255, 255, 255, confirmationAlpha) : color(200, 200, 200, confirmationAlpha * 0.7));
      strokeWeight(scaleSize(1));
      noFill();
      rect(buttonX, buttonY, buttonWidth, buttonHeight, scaleSize(5));
      noStroke();
      fill(255, 255, 255, confirmationAlpha);
      textAlign(CENTER, CENTER);
      setResponsiveTextSize(12);
      text(confirmButtons[i], buttonX + buttonWidth/2, buttonY + buttonHeight/2);
    }
  }
  
  // 響應式版權信息
  void drawCopyright() {
    fill(150, 150, 150, titleAlpha * 0.6);
    textAlign(CENTER);
    setResponsiveTextSize(12);
    text("© 2025 " + gameConfig.getGameAuthor() + ". All rights reserved.", 
         width/2, height - scaleY(20));
  }
  
  // 響應式點擊處理
  void handleClick(int mouseX, int mouseY) {
    if (showingExitConfirmation) {
      handleExitConfirmationClick(mouseX, mouseY);
      return;
    }
    float buttonWidth = scaleX(280);
    float buttonHeight = scaleY(55);
    float buttonSpacing = scaleY(20);
    float totalHeight = (buttonHeight + buttonSpacing) * menuItems.length - buttonSpacing;
    float startY = height - scaleY(200) - totalHeight/2;
    for (int i = 0; i < menuItems.length; i++) {
      if (!buttonVisible[i]) continue;
      float x = width/2 - buttonWidth/2;
      float y = startY + i * (buttonHeight + buttonSpacing) + scaleY(buttonOffsetY[i]);
      if (mouseX >= x && mouseX <= x + buttonWidth &&
          mouseY >= y && mouseY <= y + buttonHeight) {
        if (audioManager != null) {
          audioManager.playSFX("menu_click");
        }
        buttonScales[i] = 0.95;
        handleMenuSelection(i);
        return;
      }
    }
  }
  
  void handleExitConfirmationClick(int mouseX, int mouseY) {
    float dialogWidth = scaleX(350);
    float dialogHeight = scaleY(200);
    float dialogX = (width - dialogWidth) / 2;
    float dialogY = (height - dialogHeight) / 2;
    if (mouseX < dialogX || mouseX > dialogX + dialogWidth ||
        mouseY < dialogY || mouseY > dialogY + dialogHeight) {
      cancelExitConfirmation();
      return;
    }
    float buttonWidth = scaleX(80);
    float buttonHeight = scaleY(35);
    float buttonSpacing = scaleX(20);
    for (int i = 0; i < 2; i++) {
      float buttonX = dialogX + dialogWidth/2 - (buttonWidth + buttonSpacing/2) + i * (buttonWidth + buttonSpacing);
      float buttonY = dialogY + dialogHeight - scaleY(60);
      if (mouseX >= buttonX && mouseX <= buttonX + buttonWidth &&
          mouseY >= buttonY && mouseY <= buttonY + buttonHeight) {
        if (audioManager != null) {
          audioManager.playSFX("menu_click");
        }
        if (i == 0) { // 確定
          confirmExit();
        } else { // 取消
          cancelExitConfirmation();
        }
        break;
      }
    }
  }
  
  void showExitConfirmation() {
    showingExitConfirmation = true;
    confirmationStartTime = millis();
    confirmationAlpha = 0;
    println("顯示退出確認對話框");
  }
  
  void cancelExitConfirmation() {
    showingExitConfirmation = false;
    confirmationAlpha = 0;
    confirmedHoverItem = -1;
    println("取消退出確認");
  }
  
  void confirmExit() {
    println("確認退出遊戲");
    if (audioManager != null) {
      audioManager.playSFX("game_exit");
      new Thread(() -> {
        try {
          Thread.sleep(1000);
        } catch (InterruptedException e) {
        }
        if (audioManager != null) {
          audioManager.dispose();
        }
        if (settingsManager != null) {
          settingsManager.saveSettings();
        }
        System.exit(0);
      }).start();
    } else {
      if (settingsManager != null) {
        settingsManager.saveSettings();
      }
      System.exit(0);
    }
  }
  
  void handleMenuSelection(int selectedIndex) {
    switch(selectedIndex) {
      case 0:
        println("選擇：開始新遊戲");
        if (audioManager != null) {
          audioManager.playSFX("game_start");
        }
        startNewGame();
        break;
        
      case 1:
        println("選擇：讀取存檔");
        if (audioManager != null) {
          audioManager.playSFX("load_save");
        }
        currentMode = GameMode.LOAD_GAME;
        if (saveSystem != null) {
          saveSystem.showSaveMenu(false);
        }
        break;
        
      case 2:
        println("選擇：系統設定");
        if (audioManager != null) {
          audioManager.playSFX("system_setting");
        }
        currentMode = GameMode.SETTINGS;
        if (settingsManager != null) {
          settingsManager.showingSettings = true;
        }
        break;
        
      case 3:
        println("選擇：結束遊戲");
        if (audioManager != null) {
          audioManager.playSFX("menu_click");
        }
        showExitConfirmation();
        break;
        
      default:
        println("未知的選單選項: " + selectedIndex);
        break;
    }
  }

  void dispose() {
    if (gradientOverlay != null) {
      gradientOverlay.dispose();
      gradientOverlay = null;
      gradientOverlayCreated = false;
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
    executeSceneCommands();
    if (currentNode.background != null && !currentNode.background.trim().isEmpty()) {
      if (!backgroundManager.isInitialized) {
        backgroundManager.setInitialBackground(currentNode.background);
      } else {
        backgroundManager.setBackground(currentNode.background);
      }
    }
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
        if (command.target != null && !command.target.trim().isEmpty() && audioManager != null) {
          String sfxName = command.target.trim();
          println("執行PLAY_SFX指令: " + sfxName);
          AudioPlayer sfx = audioManager.forceLoadSFXForCommand(sfxName);
          if (sfx != null) {
            audioManager.playSFX(sfxName);
            println("✓ 音效播放成功: " + sfxName);
          } else {
            println("⚠ 音效載入失敗: " + sfxName);
          }
        } else {
          println("⚠ PLAY_SFX 指令參數不足或AudioManager為null");
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
      case "RETURN_TO_TITLE":
        returnToTitle();
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
    if (speaker == null) return true; 
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
  
  // 腳本接口方法
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
    autoPlayDelay = max(delay, 1000);
  }
  
  void scriptEnableScreenEffects(boolean enable) {
    engineSettings.enableScreenEffects = enable;
  }
  
  void scriptSetMaxHistoryItems(int maxItems) {
    engineSettings.maxHistoryItems = max(maxItems, 10); 
  }
  
  // 獲取引擎狀態
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
  JSONArray saveSlots;
  int maxSavesPerPage = 6;
  int totalPages = 3;
  int maxSaves = maxSavesPerPage * totalPages;
  int currentPage = 0;
  
  // UI相關
  float menuAlpha = 0;
  float targetMenuAlpha = 0;
  boolean[] slotHovers;
  int selectedSlot = -1;
  
  // 分頁系統
  String[] tabNames = {"存檔", "讀檔"};
  int currentTab = 0;
  
  // 遊戲狀態檢查
  boolean isGameRunning = false;
  boolean canSave = false;
  
  // 響應式設計基準值
  float baseWidth = 1280;
  float baseHeight = 720;
  
  // 縮圖相關
  HashMap<Integer, PImage> saveScreenshots;
  int screenshotWidth = 1280;
  int screenshotHeight = 720;
  
  // 時間格式
  java.text.SimpleDateFormat timeFormat;
  
  // UI佈局參數
  float panelWidth, panelHeight, panelX, panelY;
  float slotWidth, slotHeight, slotSpacingX, slotSpacingY;
  float contentY, contentWidth, contentHeight;
  float headerHeight, footerHeight;
  
  // 頁面按鈕相關
  boolean[] pageButtonHovers;
  float pageButtonY, pageButtonHeight, pageButtonWidth, pageButtonSpacing;
  
  // 動作按鈕區域
  float actionButtonAreaY, actionButtonAreaHeight;
  
  // 視窗尺寸追蹤
  int lastWindowWidth = 0;
  int lastWindowHeight = 0;
  
  SaveSystem() {
    saveSlots = new JSONArray();
    slotHovers = new boolean[maxSaves];
    pageButtonHovers = new boolean[totalPages];
    saveScreenshots = new HashMap<Integer, PImage>();
    timeFormat = new java.text.SimpleDateFormat("yyyy.MM.dd HH:mm:ss");
    loadSaveSlots();
    loadScreenshots();
    updateUILayout();
    lastWindowWidth = width;
    lastWindowHeight = height;
    println("存檔系統初始化完成");
  }
  
  // 檢查遊戲狀態
  void updateGameState() {
    isGameRunning = (currentMode == GameMode.GAME);
    canSave = isGameRunning && 
              dialogueSystem != null && 
              dialogueSystem.currentNodeId != null && 
              !dialogueSystem.currentNodeId.isEmpty() &&
              gameState != null;
    if (!isGameRunning && showingSaveMenu && currentTab == 0) {
      currentTab = 1;
      selectedSlot = -1;
      println("檢測到從標題頁面進入，自動切換到讀檔模式");
    }
  }
  
  void checkWindowSizeChange() {
    if (width != lastWindowWidth || height != lastWindowHeight) {
      lastWindowWidth = width;
      lastWindowHeight = height;
      updateUILayout();
      println("存檔系統UI已根據視窗尺寸更新: " + width + "x" + height);
    }
  }
  
  // UI佈局計算
  void updateUILayout() {
    panelWidth = min(scaleX(1050), width * 0.95);
    panelHeight = min(scaleY(720), height * 0.95);
    panelX = (width - panelWidth) / 2;
    panelY = (height - panelHeight) / 2;
    headerHeight = scaleY(100); 
    footerHeight = scaleY(100); 
    actionButtonAreaHeight = scaleY(50);
    contentY = panelY + headerHeight;
    contentWidth = panelWidth - scaleX(30);
    contentHeight = panelHeight - headerHeight - footerHeight - scaleY(10);
    float availableWidth = contentWidth - scaleX(60);
    float availableHeight = contentHeight - scaleY(30);
    slotSpacingX = scaleX(18);
    slotSpacingY = scaleY(20);
    slotWidth = (availableWidth - slotSpacingX * 2) / 3;
    slotHeight = (availableHeight - slotSpacingY * 1) / 2;
    slotWidth = constrain(slotWidth, scaleX(240), scaleX(320));
    slotHeight = constrain(slotHeight, scaleY(180), scaleY(280));
    
    // 頁面按鈕佈局
    pageButtonWidth = scaleX(45);
    pageButtonHeight = scaleY(32);
    pageButtonSpacing = scaleX(12);
    pageButtonY = panelY + panelHeight - footerHeight + scaleY(20);
    
    // 動作按鈕區域
    actionButtonAreaY = panelY + panelHeight - actionButtonAreaHeight - scaleY(8);
    println("UI佈局更新: 面板" + (int)panelWidth + "x" + (int)panelHeight + 
            " 槽位" + (int)slotWidth + "x" + (int)slotHeight +
            " 內容區域:" + (int)contentWidth + "x" + (int)contentHeight);
  }
  
  // 響應式設計方法
  float getScaleX() {
    return width / baseWidth;
  }
  float getScaleY() {
    return height / baseHeight;
  }
  float getUniformScale() {
    return min(getScaleX(), getScaleY());
  }
  float scaleX(float x) {
    return x * getScaleX();
  }
  float scaleY(float y) {
    return y * getScaleY();
  }
  float scaleSize(float size) {
    return size * getUniformScale();
  }
  void setResponsiveTextSize(float baseSize) {
    textSize(scaleSize(baseSize));
  }
  
  // 智能文字換行方法
  String smartWrapText(String text, float maxWidth, float fontSize, int maxLines) {
    if (text == null || text.isEmpty()) return "";
    setResponsiveTextSize(fontSize);
    String[] paragraphs = text.split("\n");
    ArrayList<String> allLines = new ArrayList<String>();
    for (String paragraph : paragraphs) {
      if (paragraph.trim().isEmpty()) {
        allLines.add("");
        continue;
      }
      ArrayList<String> wrappedLines = wrapParagraph(paragraph, maxWidth);
      allLines.addAll(wrappedLines);
    }
    StringBuilder result = new StringBuilder();
    int displayLines = min(allLines.size(), maxLines);
    for (int i = 0; i < displayLines; i++) {
      result.append(allLines.get(i));
      if (i < displayLines - 1) {
        result.append("\n");
      }
    }
    if (allLines.size() > maxLines && displayLines > 0) {
      String lastLine = allLines.get(maxLines - 1);
      while (textWidth(lastLine + "...") > maxWidth && lastLine.length() > 0) {
        lastLine = lastLine.substring(0, lastLine.length() - 1);
      }
      if (result.length() > 0) {
        String[] resultLines = result.toString().split("\n");
        StringBuilder finalResult = new StringBuilder();
        for (int i = 0; i < resultLines.length - 1; i++) {
          finalResult.append(resultLines[i]).append("\n");
        }
        finalResult.append(lastLine).append("...");
        return finalResult.toString();
      }
    }
    return result.toString();
  }
  
  // 單個段落智能換行
  ArrayList<String> wrapParagraph(String paragraph, float maxWidth) {
    ArrayList<String> lines = new ArrayList<String>();
    if (paragraph.trim().isEmpty()) {
      lines.add("");
      return lines;
    }
    String[] words = splitIntoWords(paragraph);
    String currentLine = "";
    for (String word : words) {
      String testLine = currentLine.isEmpty() ? word : currentLine + word;
      if (textWidth(testLine) > maxWidth) {
        if (!currentLine.isEmpty()) {
          lines.add(currentLine);
          currentLine = word;
        } else {
          currentLine = forceBreakLongWord(word, maxWidth, lines);
        }
      } else {
        currentLine = testLine;
      }
    }
    if (!currentLine.isEmpty()) {
      lines.add(currentLine);
    }
    return lines;
  }
  
  // 智能分詞
  String[] splitIntoWords(String text) {
    ArrayList<String> words = new ArrayList<String>();
    StringBuilder currentWord = new StringBuilder();
    for (int i = 0; i < text.length(); i++) {
      char c = text.charAt(i);
      if (Character.isWhitespace(c)) {
        if (currentWord.length() > 0) {
          words.add(currentWord.toString());
          currentWord.setLength(0);
        }
        words.add(String.valueOf(c));
      } else if (isCJKCharacter(c)) {
        if (currentWord.length() > 0 && !isCJKCharacter(currentWord.charAt(currentWord.length() - 1))) {
          words.add(currentWord.toString());
          currentWord.setLength(0);
        }
        currentWord.append(c);
        words.add(currentWord.toString());
        currentWord.setLength(0);
      } else {
        if (currentWord.length() > 0 && isCJKCharacter(currentWord.charAt(currentWord.length() - 1))) {
          words.add(currentWord.toString());
          currentWord.setLength(0);
        }
        currentWord.append(c);
      }
    }
    if (currentWord.length() > 0) {
      words.add(currentWord.toString());
    }
    
    return words.toArray(new String[0]);
  }
  
  boolean isCJKCharacter(char c) {
    return (c >= 0x4E00 && c <= 0x9FFF) ||
           (c >= 0x3400 && c <= 0x4DBF) ||
           (c >= 0x3040 && c <= 0x309F) ||
           (c >= 0x30A0 && c <= 0x30FF) ||
           (c >= 0xAC00 && c <= 0xD7AF);
  }
  
  String forceBreakLongWord(String word, float maxWidth, ArrayList<String> lines) {
    if (textWidth(word) <= maxWidth) {
      return word;
    }
    StringBuilder currentPart = new StringBuilder();
    for (int i = 0; i < word.length(); i++) {
      char c = word.charAt(i);
      String testPart = currentPart.toString() + c;
      if (textWidth(testPart) > maxWidth) {
        if (currentPart.length() > 0) {
          lines.add(currentPart.toString());
          currentPart.setLength(0);
        }
        currentPart.append(c);
      } else {
        currentPart.append(c);
      }
    }
    return currentPart.toString();
  }
  
  void showSaveMenu(boolean saving) {
    updateGameState(); 
    showingSaveMenu = true;
    if (saving && canSave) {
      currentTab = 0; 
    } else if (saving && !canSave) {
      currentTab = 1; 
      println("⚠ 當前無法存檔，自動切換到讀檔模式");
    } else {
      currentTab = 1; 
    }
    selectedSlot = -1;
    updateUILayout();
  }
  
  void display() {
    if (!showingSaveMenu) return;
    updateGameState();
    checkWindowSizeChange();
    updateAnimations();
    fill(0, 0, 0, menuAlpha * 0.7);
    rect(0, 0, width, height);
    drawMainPanel();
    drawTabs();
    drawSaveSlots();
    drawPageButtons();
    drawCloseButton();
    drawActionButtons();
    if (!canSave && currentTab == 0) {
      drawNoGameStateWarning();
    }
  }
  
  // 繪製無遊戲狀態警告
  void drawNoGameStateWarning() {
    float warningWidth = scaleX(400);
    float warningHeight = scaleY(120);
    float warningX = (width - warningWidth) / 2;
    float warningY = panelY + panelHeight/2 - warningHeight/2;
    fill(0, 0, 0, menuAlpha * 0.8);
    rect(warningX, warningY, warningWidth, warningHeight, scaleSize(10));
    stroke(255, 200, 100, menuAlpha);
    strokeWeight(scaleSize(2));
    noFill();
    rect(warningX, warningY, warningWidth, warningHeight, scaleSize(10));
    noStroke();
    fill(255, 200, 100, menuAlpha);
    textAlign(CENTER, CENTER);
    setResponsiveTextSize(24);
    text("⚠", warningX + warningWidth/2, warningY + scaleY(30));
    fill(255, 255, 255, menuAlpha);
    setResponsiveTextSize(14);
    text("無遊戲狀態", warningX + warningWidth/2, warningY + scaleY(60));
    setResponsiveTextSize(12);
    text("請先開始遊戲後再進行存檔", warningX + warningWidth/2, warningY + scaleY(80));
    fill(200, 200, 200, menuAlpha * 0.8);
    setResponsiveTextSize(10);
    text("點擊上方「讀檔」頁面載入存檔", warningX + warningWidth/2, warningY + scaleY(100));
  }
  
  void updateAnimations() {
    if (showingSaveMenu) {
      targetMenuAlpha = 255;
    } else {
      targetMenuAlpha = 0;
    }
    menuAlpha = lerp(menuAlpha, targetMenuAlpha, 0.15);
    updateSlotHovers();
    updatePageButtonHovers();
  }
  
  void updateSlotHovers() {
    for (int i = 0; i < slotHovers.length; i++) {
      slotHovers[i] = false;
    }
    float totalSlotsWidth = slotWidth * 3 + slotSpacingX * 2;
    float totalSlotsHeight = slotHeight * 2 + slotSpacingY * 1;
    float slotsStartX = panelX + (panelWidth - totalSlotsWidth) / 2;
    float slotsStartY = contentY + (contentHeight - totalSlotsHeight) / 2;
    for (int i = 0; i < maxSavesPerPage; i++) {
      int globalSlotIndex = currentPage * maxSavesPerPage + i;
      if (globalSlotIndex >= maxSaves) break;
      float col = i % 3;
      float row = i / 3;
      float slotX = slotsStartX + col * (slotWidth + slotSpacingX);
      float slotY = slotsStartY + row * (slotHeight + slotSpacingY);
      boolean isHovered = mouseX >= slotX && mouseX <= slotX + slotWidth &&
                        mouseY >= slotY && mouseY <= slotY + slotHeight;
      slotHovers[globalSlotIndex] = isHovered;
    }
  }
  
  void updatePageButtonHovers() {
    for (int i = 0; i < pageButtonHovers.length; i++) {
      pageButtonHovers[i] = false;
    }
    float totalButtonWidth = totalPages * pageButtonWidth + (totalPages - 1) * pageButtonSpacing;
    float buttonsStartX = panelX + (panelWidth - totalButtonWidth) / 2;
    for (int i = 0; i < totalPages; i++) {
      float buttonX = buttonsStartX + i * (pageButtonWidth + pageButtonSpacing);
      
      boolean isHovered = mouseX >= buttonX && mouseX <= buttonX + pageButtonWidth &&
                        mouseY >= pageButtonY && mouseY <= pageButtonY + pageButtonHeight;
      pageButtonHovers[i] = isHovered;
    }
  }
  
  void drawMainPanel() {
    fill(0, 0, 0, menuAlpha * 0.3);
    rect(panelX + 4, panelY + 4, panelWidth, panelHeight, scaleSize(15));
    fill(35, 40, 55, menuAlpha);
    rect(panelX, panelY, panelWidth, panelHeight, scaleSize(15));
    stroke(120, 140, 180, menuAlpha * 0.8);
    strokeWeight(scaleSize(2));
    noFill();
    rect(panelX, panelY, panelWidth, panelHeight, scaleSize(15));
    noStroke();
    fill(255, 220, 100, menuAlpha);
    textAlign(CENTER);
    setResponsiveTextSize(24);
    text("存檔管理", width/2, panelY + scaleY(25));
    
    // 頁面資訊顯示
    fill(180, 200, 220, menuAlpha * 0.8);
    setResponsiveTextSize(12);
    text("第 " + (currentPage + 1) + " 頁 / 共 " + totalPages + " 頁", width/2, panelY + scaleY(45));
    
    // 標題下方裝飾線
    stroke(255, 220, 100, menuAlpha * 0.6);
    strokeWeight(scaleSize(2));
    float lineY = panelY + scaleY(55);
    float lineWidth = scaleX(150);
    line(width/2 - lineWidth/2, lineY, width/2 + lineWidth/2, lineY);
    noStroke();
  }
  
  void drawTabs() {
    float tabWidth = panelWidth / tabNames.length;
    float tabHeight = scaleY(32);
    float tabY = panelY + scaleY(70);
    for (int i = 0; i < tabNames.length; i++) {
      float tabX = panelX + i * tabWidth;
      boolean isActive = (i == currentTab);
      boolean isHovered = mouseX >= tabX && mouseX <= tabX + tabWidth && 
                         mouseY >= tabY && mouseY <= tabY + tabHeight;
      boolean isDisabled = (i == 0) && !canSave;
      if (isDisabled) {
        fill(20, 25, 35, menuAlpha * 0.5);
      } else if (isActive) {
        fill(70, 110, 190, menuAlpha);
      } else if (isHovered) {
        fill(60, 80, 120, menuAlpha * 0.7);
      } else {
        fill(30, 35, 50, menuAlpha * 0.5);
      }
      rect(tabX, tabY, tabWidth, tabHeight, scaleSize(6));
      if (isDisabled) {
        stroke(60, 70, 90, menuAlpha * 0.4);
        strokeWeight(scaleSize(1));
      } else if (isActive) {
        stroke(150, 200, 255, menuAlpha);
        strokeWeight(scaleSize(2));
      } else {
        stroke(80, 100, 140, menuAlpha * 0.6);
        strokeWeight(scaleSize(1));
      }
      noFill();
      rect(tabX, tabY, tabWidth, tabHeight, scaleSize(6));
      noStroke();
      if (isDisabled) {
        fill(100, 110, 130, menuAlpha * 0.6);
      } else if (isActive) {
        fill(255, 255, 255, menuAlpha);
      } else if (isHovered) {
        fill(200, 220, 255, menuAlpha);
      } else {
        fill(150, 170, 200, menuAlpha);
      }
      textAlign(CENTER, CENTER);
      setResponsiveTextSize(14);
      
      String tabText = tabNames[i];
      if (isDisabled) {
        setResponsiveTextSize(11);
      }
      text(tabText, tabX + tabWidth/2, tabY + tabHeight/2);
    }
  }
  
  void drawSaveSlots() {
    float totalSlotsWidth = slotWidth * 3 + slotSpacingX * 2;
    float totalSlotsHeight = slotHeight * 2 + slotSpacingY * 1;
    float slotsStartX = panelX + (panelWidth - totalSlotsWidth) / 2;
    float slotsStartY = contentY + (contentHeight - totalSlotsHeight) / 2;
    for (int i = 0; i < maxSavesPerPage; i++) {
      int globalSlotIndex = currentPage * maxSavesPerPage + i;
      if (globalSlotIndex >= maxSaves) break;
      float col = i % 3;
      float row = i / 3;
      float slotX = slotsStartX + col * (slotWidth + slotSpacingX);
      float slotY = slotsStartY + row * (slotHeight + slotSpacingY);
      boolean isHovered = slotHovers[globalSlotIndex];
      boolean isSelected = (selectedSlot == globalSlotIndex);
      drawSaveSlot(globalSlotIndex, slotX, slotY, slotWidth, slotHeight, isHovered, isSelected);
    }
  }
  
  void drawPageButtons() {
    if (totalPages <= 1) return;
    float totalButtonWidth = totalPages * pageButtonWidth + (totalPages - 1) * pageButtonSpacing;
    float buttonsStartX = panelX + (panelWidth - totalButtonWidth) / 2;
    for (int i = 0; i < totalPages; i++) {
      float buttonX = buttonsStartX + i * (pageButtonWidth + pageButtonSpacing);
      boolean isActive = (i == currentPage);
      boolean isHovered = pageButtonHovers[i];
      if (isActive) {
        fill(70, 130, 220, menuAlpha);
      } else if (isHovered) {
        fill(60, 90, 150, menuAlpha * 0.8);
      } else {
        fill(40, 50, 80, menuAlpha * 0.6);
      }
      rect(buttonX, pageButtonY, pageButtonWidth, pageButtonHeight, scaleSize(5));
      if (isActive) {
        stroke(150, 200, 255, menuAlpha);
        strokeWeight(scaleSize(2));
      } else if (isHovered) {
        stroke(120, 160, 200, menuAlpha);
        strokeWeight(scaleSize(2));
      } else {
        stroke(80, 100, 130, menuAlpha * 0.6);
        strokeWeight(scaleSize(1));
      }
      noFill();
      rect(buttonX, pageButtonY, pageButtonWidth, pageButtonHeight, scaleSize(5));
      noStroke();
      if (isActive) {
        fill(255, 255, 255, menuAlpha);
      } else if (isHovered) {
        fill(220, 240, 255, menuAlpha);
      } else {
        fill(180, 200, 220, menuAlpha);
      }
      textAlign(CENTER, CENTER);
      setResponsiveTextSize(12);
      text(str(i + 1), buttonX + pageButtonWidth/2, pageButtonY + pageButtonHeight/2);
    }
  }
  
  void drawSaveSlot(int slotIndex, float x, float y, float w, float h, boolean isHovered, boolean isSelected) {
    JSONObject saveData = (slotIndex < saveSlots.size()) ? saveSlots.getJSONObject(slotIndex) : null;
    boolean isEmpty = (saveData == null || !saveData.hasKey("nodeId"));
    boolean isDisabledForSave = (currentTab == 0) && !canSave;
    if (isDisabledForSave) {
      fill(25, 30, 40, menuAlpha * 0.4);
    } else if (isSelected) {
      fill(90, 140, 245, menuAlpha);
    } else if (isHovered) {
      fill(60, 80, 140, menuAlpha * 0.8);
    } else {
      fill(35, 45, 75, menuAlpha * 0.6);
    }
    rect(x, y, w, h, scaleSize(6));
    if (isDisabledForSave) {
      stroke(60, 70, 90, menuAlpha * 0.4);
      strokeWeight(scaleSize(1));
    } else if (isSelected) {
      stroke(200, 220, 255, menuAlpha);
      strokeWeight(scaleSize(2));
    } else if (isHovered) {
      stroke(150, 170, 200, menuAlpha);
      strokeWeight(scaleSize(2));
    } else {
      stroke(80, 100, 130, menuAlpha * 0.6);
      strokeWeight(scaleSize(1));
    }
    noFill();
    rect(x, y, w, h, scaleSize(6));
    noStroke();
    if (isDisabledForSave) {
      fill(120, 130, 150, menuAlpha * 0.6);
    } else {
      fill(255, 255, 255, menuAlpha);
    }
    textAlign(LEFT);
    setResponsiveTextSize(12);
    text("存檔 " + (slotIndex + 1), x + scaleX(8), y + scaleY(15));
    
    if (isDisabledForSave) {
      fill(150, 150, 150, menuAlpha * 0.8);
      textAlign(CENTER, CENTER);
      setResponsiveTextSize(14);
      text("需要遊戲狀態", x + w/2, y + h/2);
    } else if (!isEmpty) {
      drawSaveSlotContent(saveData, slotIndex, x, y, w, h, menuAlpha);
    } else {
      drawEmptySlot(x, y, w, h, menuAlpha);
    }
  }
  
  void drawSaveSlotContent(JSONObject saveData, int slotIndex, float x, float y, float w, float h, float alpha) {
    String timeStr = saveData.getString("date", "未知時間");
    fill(200, 220, 255, alpha);
    textAlign(LEFT);
    setResponsiveTextSize(9);
    text(timeStr, x + scaleX(8), y + scaleY(30));
    float thumbPadding = scaleX(8);
    float thumbW = w - thumbPadding * 2;
    float thumbH = thumbW * (9.0/16.0);
    float thumbX = x + thumbPadding;
    float thumbY = y + scaleY(45);
    float maxThumbH = h - scaleY(90); 
    if (thumbH > maxThumbH) {
      thumbH = maxThumbH;
      thumbW = thumbH * (16.0/9.0);
      thumbX = x + (w - thumbW) / 2; 
    }
    
    // 縮圖背景
    fill(20, 20, 30, alpha);
    rect(thumbX, thumbY, thumbW, thumbH, scaleSize(4));
    
    // 顯示縮圖
    PImage screenshot = saveScreenshots.get(slotIndex);
    if (screenshot != null) {
      drawClippedScreenshot(screenshot, thumbX, thumbY, thumbW, thumbH, alpha);
    } else {
      fill(80, 80, 100, alpha);
      textAlign(CENTER, CENTER);
      setResponsiveTextSize(10);
      text("無縮圖", thumbX + thumbW/2, thumbY + thumbH/2);
    }
    
    // 縮圖邊框
    stroke(100, 120, 150, alpha * 0.5);
    strokeWeight(scaleSize(1));
    noFill();
    rect(thumbX, thumbY, thumbW, thumbH, scaleSize(4));
    noStroke();
    float infoY = thumbY + thumbH + scaleY(10);
    float maxInfoY = y + h - scaleY(15);
    if (infoY < maxInfoY && saveData.hasKey("chapter")) {
      String chapterInfo = "第" + saveData.getInt("chapter") + "章";
      if (saveData.hasKey("chapterName")) {
        String chapterName = saveData.getString("chapterName");
        if (chapterName.length() > 10) {
          chapterName = chapterName.substring(0, 10) + "...";
        }
        chapterInfo += "：" + chapterName;
      }
      fill(180, 200, 255, alpha);
      textAlign(LEFT);
      setResponsiveTextSize(9);
      text(chapterInfo, x + scaleX(8), infoY);
      infoY += scaleY(14);
    }
    
    // 對話內容預覽
    if (infoY < maxInfoY && saveData.hasKey("dialogueText")) {
      String dialogueText = saveData.getString("dialogueText");
      float remainingHeight = maxInfoY - infoY;
      int maxLines = max(2, (int)(remainingHeight / scaleY(12)));
      String wrappedDialogue = smartWrapText(dialogueText, w - scaleX(16), 8, maxLines);
      fill(220, 220, 220, alpha);
      textAlign(LEFT);
      setResponsiveTextSize(8);
      text(wrappedDialogue, x + scaleX(8), infoY);
    }
    
    // 場景信息
    if (saveData.hasKey("scene")) {
      String sceneName = saveData.getString("scene");
      if (dialogueSystem != null) {
        sceneName = dialogueSystem.getSceneDisplayName(sceneName);
      }
      if (sceneName.length() > 8) {
        sceneName = sceneName.substring(0, 8) + "...";
      }
      fill(150, 170, 190, alpha);
      textAlign(RIGHT);
      setResponsiveTextSize(8);
      text("場景：" + sceneName, x + w - scaleX(8), y + h - scaleY(200));
    }
  }
  
  void drawClippedScreenshot(PImage screenshot, float x, float y, float w, float h, float alpha) {
    if (screenshot == null) return;
    float srcW = screenshot.width;
    float srcH = screenshot.height;
    float srcRatio = srcW / srcH;
    float targetRatio = w / h;
    float drawW = w;
    float drawH = h;
    float drawX = x;
    float drawY = y;
    if (srcRatio > targetRatio) {
      drawH = h;
      drawW = drawH * srcRatio;
      drawX = x + (w - drawW) / 2;
    } else {
      drawW = w;
      drawH = drawW / srcRatio;
      drawY = y + (h - drawH) / 2;
    }
    tint(255, alpha);
    imageMode(CORNER);
    pushMatrix();
    clip(x, y, w, h);
    image(screenshot, drawX, drawY, drawW, drawH);
    noClip();
    popMatrix();
    noTint();
  }
  
  void drawEmptySlot(float x, float y, float w, float h, float alpha) {
    fill(120, 120, 140, alpha);
    textAlign(CENTER, CENTER);
    setResponsiveTextSize(14);
    text("空存檔位", x + w/2, y + h/2 - scaleY(10));
    if (currentTab == 0 && canSave) {
      fill(100, 150, 100, alpha);
      setResponsiveTextSize(10);
      text("點擊存檔", x + w/2, y + h/2 + scaleY(15));
    } else if (currentTab == 0 && !canSave) {
      fill(150, 100, 100, alpha);
      setResponsiveTextSize(10);
      text("需要遊戲狀態", x + w/2, y + h/2 + scaleY(15));
    } else {
      fill(150, 100, 100, alpha);
      setResponsiveTextSize(10);
      text("無存檔資料", x + w/2, y + h/2 + scaleY(15));
    }
  }
  
  void drawCloseButton() {
    float buttonSize = scaleSize(30);
    float buttonX = panelX + panelWidth - scaleX(25);
    float buttonY = panelY + scaleY(25);
    boolean isHovered = mouseX >= buttonX - buttonSize/2 && mouseX <= buttonX + buttonSize/2 &&
                       mouseY >= buttonY - buttonSize/2 && mouseY <= buttonY + buttonSize/2;
    if (isHovered) {
      fill(245, 100, 100, menuAlpha);
    } else {
      fill(100, 50, 50, menuAlpha);
    }
    ellipse(buttonX, buttonY, buttonSize, buttonSize);
    stroke(255, 255, 255, menuAlpha);
    strokeWeight(scaleSize(2));
    float iconSize = scaleSize(8);
    line(buttonX - iconSize/2, buttonY - iconSize/2, buttonX + iconSize/2, buttonY + iconSize/2);
    line(buttonX + iconSize/2, buttonY - iconSize/2, buttonX - iconSize/2, buttonY + iconSize/2);
    noStroke();
  }
  
  void drawActionButtons() {
    if (selectedSlot < 0) return;
    float buttonWidth = scaleX(100);
    float buttonHeight = scaleY(35);
    JSONObject saveData = (selectedSlot < saveSlots.size()) ? saveSlots.getJSONObject(selectedSlot) : null;
    boolean isEmpty = (saveData == null || !saveData.hasKey("nodeId"));
    if (currentTab == 0 && canSave) {
      float saveButtonX = panelX + (panelWidth - buttonWidth) / 2;
      boolean saveHovered = mouseX >= saveButtonX && mouseX <= saveButtonX + buttonWidth &&
                          mouseY >= actionButtonAreaY && mouseY <= actionButtonAreaY + buttonHeight;
      
      drawActionButton("存檔", saveButtonX, actionButtonAreaY, buttonWidth, buttonHeight, saveHovered, color(100, 150, 100));
    } else if (currentTab == 1 && !isEmpty) {
      float buttonSpacing = scaleX(20);
      float totalButtonWidth = buttonWidth * 2 + buttonSpacing;
      float buttonsStartX = panelX + (panelWidth - totalButtonWidth) / 2;
      float loadButtonX = buttonsStartX;
      float deleteButtonX = buttonsStartX + buttonWidth + buttonSpacing;
      boolean loadHovered = mouseX >= loadButtonX && mouseX <= loadButtonX + buttonWidth &&
                          mouseY >= actionButtonAreaY && mouseY <= actionButtonAreaY + buttonHeight;
      boolean deleteHovered = mouseX >= deleteButtonX && mouseX <= deleteButtonX + buttonWidth &&
                            mouseY >= actionButtonAreaY && mouseY <= actionButtonAreaY + buttonHeight;
      drawActionButton("讀檔", loadButtonX, actionButtonAreaY, buttonWidth, buttonHeight, loadHovered, color(100, 100, 150));
      drawActionButton("刪除", deleteButtonX, actionButtonAreaY, buttonWidth, buttonHeight, deleteHovered, color(150, 100, 100));
    }
  }
  
  void drawActionButton(String text, float x, float y, float w, float h, boolean isHovered, color baseColor) {
    x = constrain(x, panelX + scaleX(10), panelX + panelWidth - w - scaleX(10));
    y = constrain(y, panelY + scaleY(10), panelY + panelHeight - h - scaleY(10));
    if (isHovered) {
      fill(red(baseColor) + 30, green(baseColor) + 30, blue(baseColor) + 30, menuAlpha);
    } else {
      fill(red(baseColor), green(baseColor), blue(baseColor), menuAlpha);
    }
    rect(x, y, w, h, scaleSize(6));
    stroke(isHovered ? color(255, 255, 255, menuAlpha) : color(200, 200, 200, menuAlpha * 0.7));
    strokeWeight(scaleSize(1));
    noFill();
    rect(x, y, w, h, scaleSize(6));
    noStroke();
    fill(255, 255, 255, menuAlpha);
    textAlign(CENTER, CENTER);
    setResponsiveTextSize(14);
    text(text, x + w/2, y + h/2);
  }
  
  // 點擊處理邏輯
  void handleClick(int x, int y) {
    updateGameState();
    updateUILayout();
    float closeButtonSize = scaleSize(30);
    float closeButtonX = panelX + panelWidth - scaleX(25);
    float closeButtonY = panelY + scaleY(25);
    if (dist(x, y, closeButtonX, closeButtonY) <= closeButtonSize/2) {
      showingSaveMenu = false;
      if (currentMode == GameMode.LOAD_GAME) {
        currentMode = GameMode.TITLE;
      }
      return;
    }
    float tabWidth = panelWidth / tabNames.length;
    float tabHeight = scaleY(32);
    float tabY = panelY + scaleY(70);
    for (int i = 0; i < tabNames.length; i++) {
      float tabX = panelX + i * tabWidth;
      if (x >= tabX && x <= tabX + tabWidth && y >= tabY && y <= tabY + tabHeight) {
        if (i == 0 && !canSave) {
          if (audioManager != null) {
            audioManager.playSFX("system_error");
          }
          println("⚠ 當前無法存檔，請先開始遊戲");
          return;
        }
        if (i != currentTab) {
          currentTab = i;
          selectedSlot = -1;
          if (audioManager != null) {
            audioManager.playSFX("menu_click");
          }
        }
        return;
      }
    }
    if (totalPages > 1) {
      float totalButtonWidth = totalPages * pageButtonWidth + (totalPages - 1) * pageButtonSpacing;
      float buttonsStartX = panelX + (panelWidth - totalButtonWidth) / 2;
      for (int i = 0; i < totalPages; i++) {
        float buttonX = buttonsStartX + i * (pageButtonWidth + pageButtonSpacing);
        if (x >= buttonX && x <= buttonX + pageButtonWidth &&
            y >= pageButtonY && y <= pageButtonY + pageButtonHeight) {
          if (i != currentPage) {
            currentPage = i;
            selectedSlot = -1;
            if (audioManager != null) {
              audioManager.playSFX("menu_click");
            }
          }
          return;
        }
      }
    }
    float totalSlotsWidth = slotWidth * 3 + slotSpacingX * 2;
    float totalSlotsHeight = slotHeight * 2 + slotSpacingY * 1;
    float slotsStartX = panelX + (panelWidth - totalSlotsWidth) / 2;
    float slotsStartY = contentY + (contentHeight - totalSlotsHeight) / 2;
    for (int i = 0; i < maxSavesPerPage; i++) {
      int globalSlotIndex = currentPage * maxSavesPerPage + i;
      if (globalSlotIndex >= maxSaves) break;
      float col = i % 3;
      float row = i / 3;
      float slotX = slotsStartX + col * (slotWidth + slotSpacingX);
      float slotY = slotsStartY + row * (slotHeight + slotSpacingY);
      if (x >= slotX && x <= slotX + slotWidth && y >= slotY && y <= slotY + slotHeight) {
        if (currentTab == 0 && !canSave) {
          if (audioManager != null) {
            audioManager.playSFX("system_error");
          }
          println("⚠ 當前無法存檔，請先開始遊戲");
          return;
        }
        if (selectedSlot == globalSlotIndex) {
          if (currentTab == 0 && canSave) {
            saveGame(globalSlotIndex);
            showingSaveMenu = false;
          } else if (currentTab == 1) {
            JSONObject saveData = (globalSlotIndex < saveSlots.size()) ? saveSlots.getJSONObject(globalSlotIndex) : null;
            boolean isEmpty = (saveData == null || !saveData.hasKey("nodeId"));
            if (!isEmpty) {
              loadGame(globalSlotIndex);
              if (currentMode == GameMode.LOAD_GAME) {
                currentMode = GameMode.GAME;
              }
              showingSaveMenu = false;
            }
          }
        } else {
          selectedSlot = globalSlotIndex;
          if (audioManager != null) {
            audioManager.playSFX("menu_click");
          }
        }
        return;
      }
    }
    if (selectedSlot >= 0) {
      float buttonWidth = scaleX(100);
      float buttonHeight = scaleY(35);
      JSONObject saveData = (selectedSlot < saveSlots.size()) ? saveSlots.getJSONObject(selectedSlot) : null;
      boolean isEmpty = (saveData == null || !saveData.hasKey("nodeId"));
      if (currentTab == 0 && canSave) {
        float saveButtonX = panelX + (panelWidth - buttonWidth) / 2;
        if (x >= saveButtonX && x <= saveButtonX + buttonWidth &&
            y >= actionButtonAreaY && y <= actionButtonAreaY + buttonHeight) {
          saveGame(selectedSlot);
          showingSaveMenu = false;
        }
      } else if (currentTab == 1 && !isEmpty) {
        float buttonSpacing = scaleX(20);
        float totalButtonWidth = buttonWidth * 2 + buttonSpacing;
        float buttonsStartX = panelX + (panelWidth - totalButtonWidth) / 2;
        float loadButtonX = buttonsStartX;
        if (x >= loadButtonX && x <= loadButtonX + buttonWidth &&
            y >= actionButtonAreaY && y <= actionButtonAreaY + buttonHeight) {
          loadGame(selectedSlot);
          if (currentMode == GameMode.LOAD_GAME) {
            currentMode = GameMode.GAME;
          }
          showingSaveMenu = false;
        }
        float deleteButtonX = buttonsStartX + buttonWidth + buttonSpacing;
        if (x >= deleteButtonX && x <= deleteButtonX + buttonWidth &&
            y >= actionButtonAreaY && y <= actionButtonAreaY + buttonHeight) {
          deleteGame(selectedSlot);
        }
      }
    }
  }
  
  void saveGame(int slot) {
    updateGameState();
    if (!canSave) {
      println("⚠ 嘗試存檔但遊戲狀態無效");
      if (audioManager != null) {
        audioManager.playSFX("system_error");
      }
      return;
    }
    
    if (dialogueSystem == null || dialogueSystem.currentNodeId == null || dialogueSystem.currentNodeId.isEmpty()) {
      println("⚠ 對話系統狀態無效，無法存檔");
      if (audioManager != null) {
        audioManager.playSFX("system_error");
      }
      return;
    }
    
    if (gameState == null) {
      println("⚠ 遊戲狀態為空，無法存檔");
      if (audioManager != null) {
        audioManager.playSFX("system_error");
      }
      return;
    }
    
    try {
      JSONObject saveData = new JSONObject();
      saveData.setString("nodeId", dialogueSystem.currentNodeId);
      saveData.setInt("chapter", gameState.currentChapter);
      saveData.setString("chapterName", gameState.currentChapterName);
      saveData.setString("scene", backgroundManager.currentBackground);
      java.util.Date now = new java.util.Date();
      saveData.setString("date", timeFormat.format(now));
      saveData.setLong("timestamp", now.getTime());
      saveData.setInt("windowWidth", width);
      saveData.setInt("windowHeight", height);
      if (dialogueSystem.currentNode != null) {
        String dialogueText = "";
        if (dialogueSystem.currentNode.speaker != null) {
          dialogueText += dialogueSystem.currentNode.speaker + "：";
        }
        if (dialogueSystem.currentNode.text != null) {
          dialogueText += dialogueSystem.currentNode.text;
        }
        saveData.setString("dialogueText", dialogueText);
      }
      if (characterManager != null) {
        JSONArray characters = new JSONArray();
        for (String charName : characterManager.getActiveCharacters()) {
          JSONObject charData = new JSONObject();
          charData.setString("name", charName);
          charData.setString("position", characterManager.getCharacterPosition(charName));
          charData.setString("emotion", characterManager.getCharacterEmotion(charName));
          CharacterManager.CharacterDisplay charDisplay = characterManager.activeCharacters.get(charName);
          if (charDisplay != null) {
            charData.setFloat("alpha", charDisplay.alpha);
            charData.setFloat("targetAlpha", charDisplay.targetAlpha);
            charData.setFloat("scale", charDisplay.scale);
            charData.setFloat("targetScale", charDisplay.targetScale);
            charData.setBoolean("isActive", charDisplay.isActive);
            charData.setFloat("baseY", charDisplay.baseY);
            charData.setFloat("targetX", charDisplay.targetX);
            charData.setFloat("targetY", charDisplay.targetY);
          }
          characters.append(charData);
        }
        saveData.setJSONArray("characters", characters);
      }
      while (saveSlots.size() <= slot) {
        saveSlots.append(new JSONObject());
      }
      saveSlots.setJSONObject(slot, saveData);
      saveScreenshot(slot);
      saveJSONArray(saveSlots, "data/saves.json");
      if (audioManager != null) {
        audioManager.playSFX("save_complete");
      }
      println("遊戲已成功存檔到槽位 " + (slot + 1));
    } catch (Exception e) {
      println("存檔過程中發生錯誤: " + e.getMessage());
      e.printStackTrace();
      if (audioManager != null) {
        audioManager.playSFX("system_error");
      }
    }
  }
  
  void loadGame(int slot) {
    if (slot < saveSlots.size()) {
      JSONObject saveData = saveSlots.getJSONObject(slot);
      if (saveData != null && saveData.hasKey("nodeId")) {
        try {
          currentMode = GameMode.GAME;
          dialogueSystem.currentNodeId = saveData.getString("nodeId");
          dialogueSystem.currentNode = null;
          gameState.currentChapter = saveData.getInt("chapter");
          gameState.currentChapterName = saveData.getString("chapterName");
          dialogueSystem.showingChoices = false;
          dialogueSystem.showingMenu = false;
          dialogueSystem.textDisplayIndex = 0;
          dialogueSystem.textComplete = false;
          if (characterManager != null) {
            characterManager.activeCharacters.clear();
            characterManager.clearAllCharacters();
          }
          String sceneName = saveData.getString("scene", "default");
          if (backgroundManager != null) {
            backgroundManager.setBackground(sceneName);
          }
          if (saveData.hasKey("characters") && characterManager != null) {
            JSONArray characters = saveData.getJSONArray("characters");
            characterManager.updateAllCharacterPositions();
            for (int i = 0; i < characters.size(); i++) {
              JSONObject charData = characters.getJSONObject(i);
              String charName = charData.getString("name");
              String position = charData.getString("position");
              String emotion = charData.getString("emotion");
              characterManager.addCharacter(charName, position, emotion);
              if (characterManager.activeCharacters.containsKey(charName)) {
                CharacterManager.CharacterDisplay charDisplay = characterManager.activeCharacters.get(charName);
                if (charData.hasKey("alpha")) {
                  charDisplay.alpha = charData.getFloat("alpha");
                  charDisplay.targetAlpha = charData.getFloat("targetAlpha", charDisplay.alpha);
                }
                if (charData.hasKey("scale")) {
                  charDisplay.scale = charData.getFloat("scale");
                  charDisplay.targetScale = charData.getFloat("targetScale", charDisplay.scale);
                }
                if (charData.hasKey("isActive")) {
                  charDisplay.isActive = charData.getBoolean("isActive");
                }
                charDisplay.calculatePosition();
                charDisplay.baseY = height * 1.35;
                charDisplay.targetY = charDisplay.baseY;
                charDisplay.currentX = charDisplay.targetX;
                charDisplay.currentY = charDisplay.targetY;
                println("✓ 恢復角色: " + charName + " 位置: " + position + " 情感: " + emotion);
              }
            }
          }
          if (dialogueSystem.currentNode == null && dialogueSystem.nodes.containsKey(dialogueSystem.currentNodeId)) {
            dialogueSystem.currentNode = dialogueSystem.nodes.get(dialogueSystem.currentNodeId);
            dialogueSystem.updateScene();
            dialogueSystem.resetTextDisplay();
          }
          if (audioManager != null) {
            audioManager.playSFX("load_complete");
          }
          println("遊戲已成功讀取槽位 " + (slot + 1));
          uiNeedsUpdate = true;
          dialogueNeedsUpdate = true;
        } catch (Exception e) {
          println("讀檔時發生錯誤: " + e.getMessage());
          e.printStackTrace();
          if (audioManager != null) {
            audioManager.playSFX("system_error");
          }
        }
      } else {
        println("⚠ 存檔槽位 " + (slot + 1) + " 沒有有效資料");
        if (audioManager != null) {
          audioManager.playSFX("system_error");
        }
      }
    }
  }
  
  void deleteGame(int slot) {
    if (slot < saveSlots.size()) {
      try {
        saveSlots.setJSONObject(slot, new JSONObject());
        if (saveScreenshots.containsKey(slot)) {
          saveScreenshots.remove(slot);
        }
        File screenshotFile = new File(sketchPath("data/screenshots/save_" + slot + ".png"));
        if (screenshotFile.exists()) {
          screenshotFile.delete();
        }
        saveJSONArray(saveSlots, "data/saves.json");
        selectedSlot = -1;
        if (audioManager != null) {
          audioManager.playSFX("delete_complete");
        }
        println("已刪除存檔槽位 " + (slot + 1));
      } catch (Exception e) {
        println("刪除存檔時發生錯誤: " + e.getMessage());
        e.printStackTrace();
        if (audioManager != null) {
          audioManager.playSFX("system_error");
        }
      }
    }
  }
  
  void saveScreenshot(int slot) {
    try {
      File screenshotDir = new File(sketchPath("data/screenshots"));
      if (!screenshotDir.exists()) {
        screenshotDir.mkdirs();
      }
      PGraphics screenshot = createGraphics(screenshotWidth, screenshotHeight);
      screenshot.beginDraw();
      screenshot.clear();
      if (backgroundManager != null) {
        PImage currentBG = backgroundManager.getCurrentBackgroundImage();
        if (currentBG != null) {
          drawBackgroundToScreenshot(screenshot, currentBG);
        } else {
          drawFallbackBackgroundToScreenshot(screenshot);
        }
      } else {
        drawFallbackBackgroundToScreenshot(screenshot);
      }
      if (characterManager != null && characterManager.activeCharacters.size() > 0) {
        drawCharactersToScreenshotWithGameLogic(screenshot);
      }
      screenshot.endDraw();
      screenshot.save("data/screenshots/save_" + slot + ".png");
      saveScreenshots.put(slot, screenshot.copy());
      println("存檔縮圖已保存: 槽位 " + (slot + 1) + 
              " 包含 " + (characterManager != null ? characterManager.activeCharacters.size() : 0) + " 個角色");
    } catch (Exception e) {
      println("保存縮圖失敗: " + e.getMessage());
      e.printStackTrace();
    }
  }

  void drawCharactersToScreenshotWithGameLogic(PGraphics buffer) {
    ArrayList<CharacterManager.CharacterDisplay> leftChars = new ArrayList<CharacterManager.CharacterDisplay>();
    ArrayList<CharacterManager.CharacterDisplay> centerChars = new ArrayList<CharacterManager.CharacterDisplay>();
    ArrayList<CharacterManager.CharacterDisplay> rightChars = new ArrayList<CharacterManager.CharacterDisplay>();
    ArrayList<CharacterManager.CharacterDisplay> otherChars = new ArrayList<CharacterManager.CharacterDisplay>();
    for (CharacterManager.CharacterDisplay charDisplay : characterManager.activeCharacters.values()) {
      if (charDisplay.alpha < 10) continue; 
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
    
    // 繪製順序：左→右→其他→中（與引擎中相同）
    for (CharacterManager.CharacterDisplay charDisplay : leftChars) {
      drawSingleCharacterToScreenshotFixed(buffer, charDisplay);
    }
    for (CharacterManager.CharacterDisplay charDisplay : rightChars) {
      drawSingleCharacterToScreenshotFixed(buffer, charDisplay);
    }
    for (CharacterManager.CharacterDisplay charDisplay : otherChars) {
      drawSingleCharacterToScreenshotFixed(buffer, charDisplay);
    }
    for (CharacterManager.CharacterDisplay charDisplay : centerChars) {
      drawSingleCharacterToScreenshotFixed(buffer, charDisplay);
    }
  }

  void drawSingleCharacterToScreenshotFixed(PGraphics buffer, CharacterManager.CharacterDisplay charDisplay) {
    try {
      PImage charImage = characterManager.loadCharacterImageIfNeeded(charDisplay.character, charDisplay.emotion);
      if (charImage == null) {
        return;
      }
      float charX = calculateCharacterXForScreenshotFixed(charDisplay.position);
      float screenshotTargetY = screenshotHeight * 1.35;
      float screenshotDisplayHeight = screenshotHeight * 1.2;
      float charRatio = (float)charImage.width / charImage.height;
      float screenshotDisplayWidth = screenshotDisplayHeight * charRatio;
      float maxCharWidth = screenshotWidth * 1;
      if (screenshotDisplayWidth > maxCharWidth) {
        screenshotDisplayWidth = maxCharWidth;
        screenshotDisplayHeight = screenshotDisplayWidth / charRatio;
      }
      buffer.tint(255, charDisplay.alpha * charDisplay.scale);
      buffer.imageMode(CENTER);
      float charCenterX = charX;
      float charCenterY = screenshotTargetY - screenshotDisplayHeight/2; 
      buffer.image(charImage, charCenterX, charCenterY, screenshotDisplayWidth, screenshotDisplayHeight);
      buffer.noTint();
      buffer.imageMode(CORNER); 
    } catch (Exception e) {
      println("繪製角色到截圖時發生錯誤: " + charDisplay.character + " - " + e.getMessage());
    }
  }
  
  float calculateCharacterXForScreenshotFixed(String position) {
    switch(position) {
      case "left":
        return screenshotWidth * 0.25;  // width * 0.25
      case "center":
        return screenshotWidth * 0.5;   // width * 0.5
      case "right":
        return screenshotWidth * 0.75;  // width * 0.75
      case "far_left":
        return screenshotWidth * 0.15;  // width * 0.15
      case "far_right":
        return screenshotWidth * 0.85;  // width * 0.85
      default:
        return screenshotWidth * 0.5;   // 預設中央
    }
  }

  // 背景繪製方法
  void drawBackgroundToScreenshot(PGraphics buffer, PImage bgImage) {
    if (bgImage == null) return;
    float bgRatio = (float)bgImage.width / bgImage.height;
    float targetRatio = (float)screenshotWidth / screenshotHeight;
    float srcX = 0, srcY = 0, srcW = bgImage.width, srcH = bgImage.height;
    if (bgRatio > targetRatio) {
      srcW = bgImage.height * targetRatio;
      srcX = (bgImage.width - srcW) / 2;
    } else if (bgRatio < targetRatio) {
      srcH = bgImage.width / targetRatio;
      srcY = (bgImage.height - srcH) / 2;
    }
    buffer.image(bgImage, 0, 0, screenshotWidth, screenshotHeight, 
                (int)srcX, (int)srcY, (int)(srcX + srcW), (int)(srcY + srcH));
  }

  // 預設背景繪製
  void drawFallbackBackgroundToScreenshot(PGraphics buffer) {
    for (int i = 0; i < screenshotHeight; i++) {
      float inter = map(i, 0, screenshotHeight, 0, 1);
      color c = lerpColor(color(20, 30, 50), color(60, 80, 120), inter);
      buffer.stroke(c);
      buffer.line(0, i, screenshotWidth, i);
    }
    buffer.noStroke();
  }
  
  void loadScreenshots() {
    for (int i = 0; i < maxSaves; i++) {
      try {
        String filePath = "data/screenshots/save_" + i + ".png";
        File screenshotFile = new File(sketchPath(filePath));
        if (screenshotFile.exists()) {
          PImage screenshot = loadImage(filePath);
          if (screenshot != null) {
            saveScreenshots.put(i, screenshot);
          }
        }
      } catch (Exception e) {
      }
    }
    println("縮圖載入完成，共載入 " + saveScreenshots.size() + " 個");
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
  
  // 音量設定
  float masterVolume = 0.8;
  float musicVolume = 0.8;
  float sfxVolume = 0.8;
  float voiceVolume = 0.9;
  
  // 遊戲設定
  int textSpeed = 3;
  boolean fullscreen = false;
  boolean voiceAutoPlay = true;
  
  // 解析度設定
  int selectedResolutionIndex = 1; 
  ResolutionOption[] resolutionOptions = {
    new ResolutionOption("1920x1080", 1920, 1080),
    new ResolutionOption("1280x720", 1280, 720),
    new ResolutionOption("960x540", 960, 540),
    new ResolutionOption("自訂", width, height)
  };
  
  // 儲存原始視窗尺寸
  int windowedWidth = 1280;
  int windowedHeight = 720;
  
  // 響應式設計基準值
  float baseWidth = 1280;
  float baseHeight = 720;
  
  // UI動畫相關
  float menuAlpha = 0;
  float targetMenuAlpha = 0;
  float[] sliderAnimations;
  boolean[] sliderHovers;
  boolean[] buttonHovers;
  
  // 解析度選擇器動畫
  boolean[] resolutionButtonHovers;
  
  // 滑鼠追蹤
  int lastMouseX = 0;
  int lastMouseY = 0;
  
  // 滑塊拖拽狀態
  boolean isDragging = false;
  int draggingSlider = -1;
  int draggingTab = -1;
  
  // 分頁系統
  String[] tabNames = {"音效設定", "遊戲設定", "畫面設定"};
  int currentTab = 0;
  float[] tabAnimations;
  
  // 開關動畫相關
  float[] switchAnimations;
  boolean[] switchHovers;
  long[] switchToggleTime;
  
  // 解析度選項類別
  class ResolutionOption {
    String displayName;
    int width;
    int height;
    
    ResolutionOption(String displayName, int width, int height) {
      this.displayName = displayName;
      this.width = width;
      this.height = height;
    }
    String getAspectRatio() {
      if (width == 0 || height == 0) return "未知";
      float ratio = (float)width / height;
      if (abs(ratio - 16.0/9.0) < 0.01) return "16:9";
      if (abs(ratio - 4.0/3.0) < 0.01) return "4:3";
      if (abs(ratio - 16.0/10.0) < 0.01) return "16:10";
      return String.format("%.2f:1", ratio);
    }
  }
  
  // 預設構造函數
  SettingsManager() {
    sliderAnimations = new float[5];
    sliderHovers = new boolean[5];
    buttonHovers = new boolean[6];
    tabAnimations = new float[tabNames.length];
    resolutionButtonHovers = new boolean[resolutionOptions.length];
    switchAnimations = new float[10]; 
    switchHovers = new boolean[10];
    switchToggleTime = new long[10];
    for (int i = 0; i < sliderAnimations.length; i++) {
      sliderAnimations[i] = 0;
    }
    for (int i = 0; i < tabAnimations.length; i++) {
      tabAnimations[i] = 0;
    }
    for (int i = 0; i < switchAnimations.length; i++) {
      switchAnimations[i] = 0;
      switchToggleTime[i] = 0;
    }
    updateCustomResolution();
  }
  
  // 更新自訂解析度選項
  void updateCustomResolution() {
    resolutionOptions[3].width = width;
    resolutionOptions[3].height = height;
    for (int i = 0; i < resolutionOptions.length - 1; i++) {
      if (width == resolutionOptions[i].width && height == resolutionOptions[i].height) {
        selectedResolutionIndex = i;
        return;
      }
    }
    selectedResolutionIndex = 3;
  }
  
  // 響應式縮放計算
  float getScaleX() {
    return width / baseWidth;
  }
  
  float getScaleY() {
    return height / baseHeight;
  }
  
  float getUniformScale() {
    return min(getScaleX(), getScaleY());
  }
  
  // 響應式座標轉換
  float scaleX(float x) {
    return x * getScaleX();
  }
  
  float scaleY(float y) {
    return y * getScaleY();
  }
  
  float scaleSize(float size) {
    return size * getUniformScale();
  }
  
  // 響應式字體大小
  void setResponsiveTextSize(float baseSize) {
    textSize(scaleSize(baseSize));
  }
  
  void display() {
    if (!showingSettings) return;
    updateAnimations();
    fill(0, 0, 0, menuAlpha * 0.7);
    rect(0, 0, width, height);
    drawMainPanel();
    drawTabs();
    switch(currentTab) {
      case 0:
        drawAudioSettings();
        break;
      case 1:
        drawGameSettings();
        break;
      case 2:
        drawDisplaySettings();
        break;
    }
    drawCloseButton();
    drawResetButton();
  }
  
  void updateAnimations() {
    if (showingSettings) {
      targetMenuAlpha = 255;
    } else {
      targetMenuAlpha = 0;
    }
    menuAlpha = lerp(menuAlpha, targetMenuAlpha, 0.12);
    for (int i = 0; i < sliderAnimations.length; i++) {
      float target = sliderHovers[i] ? 1.0 : 0.0;
      sliderAnimations[i] = lerp(sliderAnimations[i], target, 0.15);
    }
    for (int i = 0; i < tabAnimations.length; i++) {
      float target = (i == currentTab) ? 1.0 : 0.0;
      tabAnimations[i] = lerp(tabAnimations[i], target, 0.1);
    }
    for (int i = 0; i < switchAnimations.length; i++) {
      float target = switchHovers[i] ? 1.0 : 0.0;
      switchAnimations[i] = lerp(switchAnimations[i], target, 0.12);
    }
    lastMouseX = mouseX;
    lastMouseY = mouseY;
  }
  
  void drawMainPanel() {
    float panelWidth = scaleX(650);
    float panelHeight = scaleY(550);
    float panelX = (width - panelWidth) / 2;
    float panelY = (height - panelHeight) / 2;
    for (int i = 0; i < 8; i++) {
      fill(0, 0, 0, menuAlpha * 0.08);
      rect(panelX + i, panelY + i, panelWidth, panelHeight, scaleSize(15));
    }
    drawOptimizedGradientRect(panelX, panelY, panelWidth, panelHeight, 
                             color(40, 45, 65, menuAlpha), 
                             color(25, 30, 45, menuAlpha), 
                             scaleSize(15));
    stroke(120, 140, 180, menuAlpha * 0.8);
    strokeWeight(scaleSize(2));
    noFill();
    rect(panelX, panelY, panelWidth, panelHeight, scaleSize(15));
    noStroke();
    
    // 標題
    fill(255, 220, 100, menuAlpha);
    textAlign(CENTER);
    setResponsiveTextSize(28);
    text("遊戲設定", width/2, panelY + scaleY(35));
    
    // 標題下方裝飾線
    float lineY = panelY + scaleY(55);
    float lineWidth = scaleX(200);
    for (int i = 0; i < 3; i++) {
      stroke(255, 220, 100, menuAlpha * (0.8 - i * 0.2));
      strokeWeight(scaleSize(2 - i));
      line(width/2 - lineWidth/2, lineY + i, width/2 + lineWidth/2, lineY + i);
    }
    noStroke();
  }
  
  void drawTabs() {
    float panelWidth = scaleX(650);
    float panelX = (width - panelWidth) / 2;
    float panelY = (height - scaleY(550)) / 2;
    float tabWidth = panelWidth / tabNames.length;
    float tabHeight = scaleY(40);
    float tabY = panelY + scaleY(75);
    for (int i = 0; i < tabNames.length; i++) {
      float tabX = panelX + i * tabWidth;
      boolean isActive = (i == currentTab);
      boolean isHovered = mouseX >= tabX && mouseX <= tabX + tabWidth && 
                         mouseY >= tabY && mouseY <= tabY + tabHeight;
      if (isActive) {
        drawOptimizedGradientRect(tabX, tabY, tabWidth, tabHeight,
                                color(80, 120, 200, menuAlpha),
                                color(60, 100, 180, menuAlpha),
                                scaleSize(8));
      } else if (isHovered) {
        fill(60, 80, 120, menuAlpha * 0.7);
        rect(tabX, tabY, tabWidth, tabHeight, scaleSize(8));
      } else {
        fill(30, 35, 50, menuAlpha * 0.5);
        rect(tabX, tabY, tabWidth, tabHeight, scaleSize(8));
      }
      if (isActive) {
        stroke(150, 200, 255, menuAlpha);
        strokeWeight(scaleSize(2));
      } else {
        stroke(80, 100, 140, menuAlpha * 0.6);
        strokeWeight(scaleSize(1));
      }
      noFill();
      rect(tabX, tabY, tabWidth, tabHeight, scaleSize(8));
      noStroke();
      if (isActive) {
        fill(255, 255, 255, menuAlpha);
      } else if (isHovered) {
        fill(200, 220, 255, menuAlpha);
      } else {
        fill(150, 170, 200, menuAlpha);
      }
      textAlign(CENTER, CENTER);
      setResponsiveTextSize(14);
      text(tabNames[i], tabX + tabWidth/2, tabY + tabHeight/2);
    }
  }
  
  void drawAudioSettings() {
    float panelWidth = scaleX(650);
    float panelX = (width - panelWidth) / 2;
    float panelY = (height - scaleY(550)) / 2;
    float contentY = panelY + scaleY(140);
    String[] volumeLabels = {"主音量", "音樂音量", "音效音量", "語音音量"};
    float[] volumeValues = {masterVolume, musicVolume, sfxVolume, voiceVolume};
    for (int i = 0; i < volumeLabels.length; i++) {
      float yPos = contentY + i * scaleY(75);
      drawVolumeSlider(volumeLabels[i], volumeValues[i], panelX + scaleX(50), yPos, i);
    }
    float switchY = contentY + scaleY(320);
    drawModernToggleSwitch("語音自動播放", voiceAutoPlay, panelX + scaleX(50), switchY, 0);
  }
  
  void drawGameSettings() {
    float panelWidth = scaleX(650);
    float panelX = (width - panelWidth) / 2;
    float panelY = (height - scaleY(550)) / 2;
    float contentY = panelY + scaleY(140);
    drawTextSpeedSlider("文字速度", textSpeed / 5.0, panelX + scaleX(50), contentY, 4);
    drawModernToggleSwitch("跳過已讀文本", false, panelX + scaleX(50), contentY + scaleY(100), 1);
  }
  
  void drawDisplaySettings() {
    float panelWidth = scaleX(650);
    float panelX = (width - panelWidth) / 2;
    float panelY = (height - scaleY(550)) / 2;
    float contentY = panelY + scaleY(140);
    drawModernToggleSwitch("全螢幕模式", fullscreen, panelX + scaleX(50), contentY, 2);
    drawResolutionSelector(panelX + scaleX(50), contentY + scaleY(80));
    drawCurrentResolutionInfo(panelX + scaleX(50), contentY + scaleY(320));
  }
  
  // 開關設計
  void drawModernToggleSwitch(String label, boolean value, float x, float y, int index) {
    float switchWidth = scaleX(80);
    float switchHeight = scaleY(38);
    float switchX = x + scaleX(350);
    float switchY = y - scaleY(18);
    boolean isHovered = mouseX >= switchX && mouseX <= switchX + switchWidth &&
                       mouseY >= switchY && mouseY <= switchY + switchHeight;
    switchHovers[index] = isHovered;
    fill(220, 240, 255, menuAlpha);
    textAlign(LEFT, CENTER);
    setResponsiveTextSize(16);
    text(label, x, y);
    float toggleProgress = value ? 1.0 : 0.0;
    long timeSinceToggle = millis() - switchToggleTime[index];
    float bounceEffect = 1.0;
    if (timeSinceToggle < 300) {
      float bounceProgress = timeSinceToggle / 300.0;
      bounceEffect = 1.0 + sin(bounceProgress * PI * 3) * 0.05 * (1 - bounceProgress);
    }
    color trackColor = value ? 
      lerpColor(color(100, 200, 100, menuAlpha), color(120, 220, 120, menuAlpha), switchAnimations[index]) :
      lerpColor(color(60, 60, 80, menuAlpha), color(80, 80, 100, menuAlpha), switchAnimations[index]);
    fill(trackColor);
    rect(switchX, switchY, switchWidth, switchHeight, scaleSize(switchHeight/2));
    stroke(isHovered ? 
      color(255, 255, 255, menuAlpha * 0.8) : 
      color(120, 140, 160, menuAlpha * 0.6));
    strokeWeight(scaleSize(2));
    noFill();
    rect(switchX, switchY, switchWidth, switchHeight, scaleSize(switchHeight/2));
    noStroke();
    if (value) {
      for (int i = 0; i < 3; i++) {
        float glowAlpha = menuAlpha * 0.3 * (1 - i * 0.3);
        fill(150, 255, 150, glowAlpha);
        float glowInset = scaleSize(3 + i * 2);
        rect(switchX + glowInset, switchY + glowInset, 
             switchWidth - glowInset * 2, switchHeight - glowInset * 2, 
             scaleSize((switchHeight - glowInset * 2)/2));
      }
    }
    float sliderSize = scaleSize(32) * bounceEffect;
    float sliderPadding = scaleSize(3);
    float sliderTravel = switchWidth - sliderSize - sliderPadding * 2;
    float sliderX = switchX + sliderPadding + sliderTravel * toggleProgress;
    float sliderY = switchY + (switchHeight - sliderSize) / 2;
    fill(0, 0, 0, menuAlpha * 0.4);
    ellipse(sliderX + sliderSize/2 + scaleSize(2), 
            sliderY + sliderSize/2 + scaleSize(2), 
            sliderSize, sliderSize);
    for (int i = 0; i < sliderSize/2; i++) {
      float inter = map(i, 0, sliderSize/2, 0, 1);
      color sliderColor1 = color(250, 250, 250, menuAlpha);
      color sliderColor2 = color(220, 220, 230, menuAlpha);
      color currentColor = lerpColor(sliderColor1, sliderColor2, inter);
      if (isHovered) {
        currentColor = lerpColor(currentColor, color(255, 255, 255, menuAlpha), 0.3);
      }
      fill(currentColor);
      ellipse(sliderX + sliderSize/2, sliderY + sliderSize/2, 
              sliderSize - i * 2, sliderSize - i * 2);
    }
    stroke(255, 255, 255, menuAlpha);
    strokeWeight(scaleSize(2));
    noFill();
    ellipse(sliderX + sliderSize/2, sliderY + sliderSize/2, sliderSize, sliderSize);
    noStroke();
    fill(value ? color(100, 200, 100, menuAlpha) : color(150, 150, 150, menuAlpha));
    textAlign(CENTER, CENTER);
    setResponsiveTextSize(12);
    String iconText = value ? "●" : "○";
    text(iconText, sliderX + sliderSize/2, sliderY + sliderSize/2);
    if (isHovered) {
      float glowSize = sliderSize + scaleSize(10) * switchAnimations[index];
      stroke(value ? 
        color(100, 200, 100, menuAlpha * 0.5 * switchAnimations[index]) : 
        color(150, 150, 150, menuAlpha * 0.5 * switchAnimations[index]));
      strokeWeight(scaleSize(3));
      noFill();
      ellipse(sliderX + sliderSize/2, sliderY + sliderSize/2, glowSize, glowSize);
      noStroke();
    }
    fill(255, 255, 255, menuAlpha);
    textAlign(CENTER, CENTER);
    setResponsiveTextSize(11);
    String statusText = value ? "開啟" : "關閉";
    text(statusText, switchX + switchWidth/2, y + scaleY(40));
    if (value) {
      for (int i = 0; i < 3; i++) {
        float indicatorX = switchX + scaleSize(15 + i * 8);
        float indicatorY = switchY + switchHeight/2;
        float indicatorAlpha = menuAlpha * (0.6 - i * 0.15) * (0.5 + 0.5 * sin(millis() * 0.005 + i));
        fill(150, 255, 150, indicatorAlpha);
        ellipse(indicatorX, indicatorY, scaleSize(3), scaleSize(3));
      }
    }
  }
  
  // 解析度選擇器
  void drawResolutionSelector(float x, float y) {
    fill(220, 240, 255, menuAlpha);
    textAlign(LEFT, CENTER);
    setResponsiveTextSize(16);
    text("視窗解析度", x, y - scaleY(5));
    float buttonWidth = scaleX(130);
    float buttonHeight = scaleY(35);
    float buttonSpacingX = scaleX(140);
    float buttonSpacingY = scaleY(45);
    for (int i = 0; i < resolutionOptions.length; i++) {
      float buttonX = x + (i % 2) * buttonSpacingX;
      float buttonY = y + scaleY(20) + (i / 2) * buttonSpacingY;
      boolean isHovered = mouseX >= buttonX && mouseX <= buttonX + buttonWidth &&
                        mouseY >= buttonY && mouseY <= buttonY + buttonHeight;
      resolutionButtonHovers[i] = isHovered;
      drawResolutionButton(resolutionOptions[i], buttonX, buttonY, buttonWidth, buttonHeight, 
                          i == selectedResolutionIndex, isHovered);
    }
    fill(180, 200, 220, menuAlpha * 0.8);
    textAlign(LEFT);
    setResponsiveTextSize(11);
    text("選擇標準解析度或使用當前自訂尺寸", x, y + scaleY(140));
  }
  
  // 繪製單個解析度按鈕
  void drawResolutionButton(ResolutionOption option, float x, float y, float w, float h, 
                          boolean isSelected, boolean isHovered) {
    if (isSelected) {
      drawOptimizedGradientRect(x, y, w, h,
                              color(100, 150, 255, menuAlpha),
                              color(80, 130, 235, menuAlpha),
                              scaleSize(8));
    } else if (isHovered) {
      drawOptimizedGradientRect(x, y, w, h,
                              color(70, 90, 150, menuAlpha),
                              color(50, 70, 130, menuAlpha),
                              scaleSize(8));
    } else {
      drawOptimizedGradientRect(x, y, w, h,
                              color(40, 50, 80, menuAlpha),
                              color(30, 40, 70, menuAlpha),
                              scaleSize(8));
    }
    
    if (isSelected) {
      stroke(200, 220, 255, menuAlpha);
      strokeWeight(scaleSize(2));
    } else if (isHovered) {
      stroke(150, 170, 200, menuAlpha);
      strokeWeight(scaleSize(2));
    } else {
      stroke(80, 100, 130, menuAlpha * 0.6);
      strokeWeight(scaleSize(1));
    }
    noFill();
    rect(x, y, w, h, scaleSize(8));
    noStroke();
    fill(255, 255, 255, menuAlpha);
    textAlign(CENTER, CENTER);
    setResponsiveTextSize(12);
    text(option.displayName, x + w/2, y + h/2 - scaleY(8));
    if (!option.displayName.equals("自訂")) {
      fill(200, 200, 200, menuAlpha * 0.8);
      setResponsiveTextSize(9);
      text(option.getAspectRatio(), x + w/2, y + h/2 + scaleY(8));
    } else {
      fill(200, 200, 200, menuAlpha * 0.8);
      setResponsiveTextSize(9);
      text(option.width + "×" + option.height, x + w/2, y + h/2 + scaleY(8));
    }
    if (isSelected) {
      float indicatorSize = scaleSize(8);
      fill(255, 255, 100, menuAlpha);
      ellipse(x + w - scaleX(12), y + scaleY(12), indicatorSize, indicatorSize);
    }
  }
  
  // 當前解析度資訊顯示
  void drawCurrentResolutionInfo(float x, float y) {
    fill(180, 200, 220, menuAlpha);
    textAlign(LEFT);
    setResponsiveTextSize(14);
    text("當前解析度: " + width + " × " + height, x, y);
    ResolutionOption currentOption = new ResolutionOption("current", width, height);
    fill(150, 170, 190, menuAlpha);
    setResponsiveTextSize(12);
    text("寬高比: " + currentOption.getAspectRatio(), x, y + scaleY(20));
  }
  
  void drawVolumeSlider(String label, float value, float x, float y, int index) {
    boolean isHovered = checkSliderHover(x, y);
    sliderHovers[index] = isHovered;
    fill(220, 240, 255, menuAlpha);
    textAlign(LEFT, CENTER);
    setResponsiveTextSize(16);
    text(label, x, y - scaleY(5));
    float trackX = x + scaleX(150);
    float trackY = y - scaleY(8);
    float trackWidth = scaleX(320);
    float trackHeight = scaleY(16);
    fill(30, 40, 60, menuAlpha);
    rect(trackX, trackY, trackWidth, trackHeight, scaleSize(8));
    stroke(80, 100, 140, menuAlpha);
    strokeWeight(scaleSize(1));
    noFill();
    rect(trackX, trackY, trackWidth, trackHeight, scaleSize(8));
    noStroke();
    float fillWidth = trackWidth * value;
    drawOptimizedGradientRect(trackX, trackY, fillWidth, trackHeight,
                            color(100, 150, 255, menuAlpha),
                            color(120, 170, 255, menuAlpha),
                            scaleSize(8));
    float handleX = trackX + fillWidth;
    float handleY = trackY + trackHeight/2;
    float handleSize = scaleSize(20);
    fill(0, 0, 0, menuAlpha * 0.3);
    ellipse(handleX + scaleSize(2), handleY + scaleSize(2), handleSize, handleSize);
    if (isHovered || (isDragging && draggingSlider == index && draggingTab == 0)) {
      drawOptimizedGradientEllipse(handleX, handleY, handleSize,
                                color(200, 220, 255, menuAlpha),
                                color(180, 200, 235, menuAlpha));
    } else {
      drawOptimizedGradientEllipse(handleX, handleY, handleSize,
                                color(160, 180, 220, menuAlpha),
                                color(140, 160, 200, menuAlpha));
    }
    stroke(255, 255, 255, menuAlpha * 0.8);
    strokeWeight(scaleSize(2));
    noFill();
    ellipse(handleX, handleY, handleSize, handleSize);
    noStroke();
    fill(255, 255, 255, menuAlpha);
    textAlign(RIGHT, CENTER);
    setResponsiveTextSize(14);
    text(int(value * 100) + "%", x + scaleX(550), y - scaleY(5));
    if (isHovered) {
      float glowSize = handleSize + scaleSize(8) * sliderAnimations[index];
      stroke(100, 150, 255, menuAlpha * 0.5 * sliderAnimations[index]);
      strokeWeight(scaleSize(3));
      noFill();
      ellipse(handleX, handleY, glowSize, glowSize);
      noStroke();
    }
  }
  
  // 文字速度滑桿
  void drawTextSpeedSlider(String label, float value, float x, float y, int index) {
    boolean isHovered = checkSliderHover(x, y);
    sliderHovers[index] = isHovered;
    
    // 標籤文字
    fill(220, 240, 255, menuAlpha);
    textAlign(LEFT, CENTER);
    setResponsiveTextSize(16);
    text(label, x, y - scaleY(5));
    
    // 滑桿軌道位置和尺寸
    float trackX = x + scaleX(150);
    float trackY = y - scaleY(8);
    float trackWidth = scaleX(320);
    float trackHeight = scaleY(16);
    
    // 繪製軌道背景
    fill(30, 40, 60, menuAlpha);
    rect(trackX, trackY, trackWidth, trackHeight, scaleSize(8));
    
    // 軌道邊框
    stroke(80, 100, 140, menuAlpha);
    strokeWeight(scaleSize(1));
    noFill();
    rect(trackX, trackY, trackWidth, trackHeight, scaleSize(8));
    noStroke();
    
    // 進度填充
    float fillWidth = trackWidth * value;
    drawOptimizedGradientRect(trackX, trackY, fillWidth, trackHeight,
                            color(255, 150, 100, menuAlpha),
                            color(255, 170, 120, menuAlpha),
                            scaleSize(8));
    
    // 滑桿把手
    float handleX = trackX + fillWidth;
    float handleY = trackY + trackHeight/2;
    float handleSize = scaleSize(20);
    
    // 把手陰影
    fill(0, 0, 0, menuAlpha * 0.3);
    ellipse(handleX + scaleSize(2), handleY + scaleSize(2), handleSize, handleSize);
    
    // 把手主體
    if (isHovered || (isDragging && draggingSlider == index && draggingTab == 1)) {
      drawOptimizedGradientEllipse(handleX, handleY, handleSize,
                                color(255, 200, 150, menuAlpha),
                                color(255, 180, 130, menuAlpha));
    } else {
      drawOptimizedGradientEllipse(handleX, handleY, handleSize,
                                color(255, 180, 120, menuAlpha),
                                color(235, 160, 100, menuAlpha));
    }
    
    // 把手邊框
    stroke(255, 255, 255, menuAlpha * 0.8);
    strokeWeight(scaleSize(2));
    noFill();
    ellipse(handleX, handleY, handleSize, handleSize);
    noStroke();
    
    // 數值顯示
    fill(255, 255, 255, menuAlpha);
    textAlign(RIGHT, CENTER);
    setResponsiveTextSize(14);
    text(textSpeed, x + scaleX(550), y - scaleY(5));
    
    // 懸停光暈效果
    if (isHovered) {
      float glowSize = handleSize + scaleSize(8) * sliderAnimations[index];
      stroke(255, 150, 100, menuAlpha * 0.5 * sliderAnimations[index]);
      strokeWeight(scaleSize(3));
      noFill();
      ellipse(handleX, handleY, glowSize, glowSize);
      noStroke();
    }
  }
  
  void drawCloseButton() {
    float buttonSize = scaleSize(40);
    float buttonX = width - scaleX(60);
    float buttonY = scaleY(60);
    boolean isHovered = mouseX >= buttonX - buttonSize/2 && mouseX <= buttonX + buttonSize/2 &&
                       mouseY >= buttonY - buttonSize/2 && mouseY <= buttonY + buttonSize/2;
    
    // 按鈕背景
    if (isHovered) {
      drawOptimizedGradientEllipse(buttonX, buttonY, buttonSize,
                                 color(255, 100, 100, menuAlpha),
                                 color(235, 80, 80, menuAlpha));
    } else {
      drawOptimizedGradientEllipse(buttonX, buttonY, buttonSize,
                                 color(100, 50, 50, menuAlpha),
                                 color(80, 30, 30, menuAlpha));
    }
    
    // 關閉圖標 (X)
    stroke(255, 255, 255, menuAlpha);
    strokeWeight(scaleSize(3));
    float iconSize = scaleSize(12);
    line(buttonX - iconSize/2, buttonY - iconSize/2, buttonX + iconSize/2, buttonY + iconSize/2);
    line(buttonX + iconSize/2, buttonY - iconSize/2, buttonX - iconSize/2, buttonY + iconSize/2);
    noStroke();
  }
  
  void drawResetButton() {
    float buttonWidth = scaleX(120);
    float buttonHeight = scaleY(40);
    float panelWidth = scaleX(650);
    float panelHeight = scaleY(550);
    float panelX = (width - panelWidth) / 2;
    float panelY = (height - panelHeight) / 2;
    float buttonX = panelX + (panelWidth - buttonWidth) / 2;
    float buttonY = panelY + panelHeight - scaleY(60);
    boolean isHovered = mouseX >= buttonX && mouseX <= buttonX + buttonWidth &&
                       mouseY >= buttonY && mouseY <= buttonY + buttonHeight;
    
    // 按鈕背景
    if (isHovered) {
      drawOptimizedGradientRect(buttonX, buttonY, buttonWidth, buttonHeight,
                              color(255, 200, 100, menuAlpha),
                              color(235, 180, 80, menuAlpha),
                              scaleSize(8));
    } else {
      drawOptimizedGradientRect(buttonX, buttonY, buttonWidth, buttonHeight,
                              color(100, 80, 50, menuAlpha),
                              color(80, 60, 30, menuAlpha),
                              scaleSize(8));
    }
    
    // 按鈕邊框
    stroke(isHovered ? color(255, 255, 255, menuAlpha) : color(150, 130, 100, menuAlpha));
    strokeWeight(scaleSize(2));
    noFill();
    rect(buttonX, buttonY, buttonWidth, buttonHeight, scaleSize(8));
    noStroke();
    
    // 按鈕文字
    fill(255, 255, 255, menuAlpha);
    textAlign(CENTER, CENTER);
    setResponsiveTextSize(14);
    text("重置設定", buttonX + buttonWidth/2, buttonY + buttonHeight/2);
  }
  
  // 漸層繪製方法
  void drawOptimizedGradientRect(float x, float y, float w, float h, color c1, color c2, float radius) {
    noStroke();
    int steps = max(8, (int)(h/6));
    for (int i = 0; i < steps; i++) {
      float inter = map(i, 0, steps-1, 0, 1);
      color c = lerpColor(c1, c2, inter);
      fill(c);
      float rectY = y + (h * i / steps);
      float rectH = h / steps + 1;
      if (i == 0) {
        rect(x, rectY, w, rectH, radius, radius, 0, 0);
      } else if (i == steps-1) {
        rect(x, rectY, w, rectH, 0, 0, radius, radius);
      } else {
        rect(x, rectY, w, rectH);
      }
    }
  }
  
  void drawOptimizedGradientEllipse(float x, float y, float size, color c1, color c2) {
    noStroke();
    int steps = max(4, (int)(size/10));
    for (int i = 0; i < steps; i++) {
      float inter = map(i, 0, steps-1, 0, 1);
      color c = lerpColor(c1, c2, inter);
      fill(c);
      float currentSize = size - (i * size / steps);
      ellipse(x, y, currentSize, currentSize);
    }
  }
  
  boolean checkSliderHover(float x, float y) {
    float trackX = x + scaleX(150);
    float trackY = y - scaleY(25);
    float trackWidth = scaleX(320);
    float trackHeight = scaleY(50);
    return mouseX >= trackX && mouseX <= trackX + trackWidth &&
          mouseY >= trackY && mouseY <= trackY + trackHeight;
  }
  
  void handleClick(int x, int y) {
    if (!showingSettings) return;
    float panelWidth = scaleX(650);
    float panelX = (width - panelWidth) / 2;
    float panelY = (height - scaleY(550)) / 2;
    float closeButtonSize = scaleSize(40);
    float closeButtonX = width - scaleX(60);
    float closeButtonY = scaleY(60);
    if (x >= closeButtonX - closeButtonSize/2 && x <= closeButtonX + closeButtonSize/2 &&
        y >= closeButtonY - closeButtonSize/2 && y <= closeButtonY + closeButtonSize/2) {
      showingSettings = false;
      saveSettings();
      if (currentMode == GameMode.SETTINGS) {
        currentMode = GameMode.TITLE;
      }
      return;
    }
    float resetButtonWidth = scaleX(120);
    float resetButtonHeight = scaleY(40);
    float resetButtonX = panelX + (panelWidth - resetButtonWidth) / 2;
    float resetButtonY = panelY + scaleY(550) - scaleY(60);
    if (x >= resetButtonX && x <= resetButtonX + resetButtonWidth &&
        y >= resetButtonY && y <= resetButtonY + resetButtonHeight) {
      resetToDefaults();
      return;
    }
    float tabWidth = panelWidth / tabNames.length;
    float tabHeight = scaleY(40);
    float tabY = panelY + scaleY(75);
    for (int i = 0; i < tabNames.length; i++) {
      float tabX = panelX + i * tabWidth;
      if (x >= tabX && x <= tabX + tabWidth && y >= tabY && y <= tabY + tabHeight) {
        if (i != currentTab) {
          currentTab = i;
          if (audioManager != null) {
            audioManager.playSFX("menu_click");
            switch(i) {
              case 0: // 音效設定分頁
                audioManager.playSFX("audio_setting");
                break;
              case 1: // 遊戲設定分頁
                audioManager.playSFX("game_setting");
                break;
              case 2: // 畫面設定分頁
                audioManager.playSFX("display_setting");
                break;
            }
          }
          println("切換到分頁: " + tabNames[i]);
        }
        return;
      }
    }

    // 根據當前分頁處理點擊
    switch(currentTab) {
      case 0:
        handleAudioSettingsClick(x, y, panelX, panelY);
        break;
      case 1:
        handleGameSettingsClick(x, y, panelX, panelY);
        break;
      case 2:
        handleDisplaySettingsClick(x, y, panelX, panelY);
        break;
    }
  }
  
  void handleAudioSettingsClick(int x, int y, float panelX, float panelY) {
    float contentY = panelY + scaleY(140);
    for (int i = 0; i < 4; i++) {
      float yPos = contentY + i * scaleY(75);
      if (checkSliderClick(x, y, panelX + scaleX(50), yPos)) {
        float value = calculateSliderValue(x, panelX + scaleX(50));
        updateVolumeValue(i, value);
        isDragging = true;
        draggingSlider = i;
        draggingTab = 0;
        return;
      }
    }
    float switchY = contentY + scaleY(320);
    if (checkModernToggleClick(x, y, panelX + scaleX(50), switchY)) {
      voiceAutoPlay = !voiceAutoPlay;
      switchToggleTime[0] = millis();
      if (audioManager != null) {
        audioManager.voiceAutoPlay = voiceAutoPlay;
        if (!voiceAutoPlay) {
          audioManager.stopVoice();
        }
        audioManager.playSFX("toggle_switch");
      }
    }
  }
  
  void handleGameSettingsClick(int x, int y, float panelX, float panelY) {
    float contentY = panelY + scaleY(140);
    if (checkSliderClick(x, y, panelX + scaleX(50), contentY)) {
      float value = calculateSliderValue(x, panelX + scaleX(50));
      textSpeed = int(value * 5) + 1;
      if (dialogueSystem != null) {
        dialogueSystem.textSpeed = textSpeed;
      }
      isDragging = true;
      draggingSlider = 4;
      draggingTab = 1;
    }
    
    if (checkModernToggleClick(x, y, panelX + scaleX(50), contentY + scaleY(100))) {
      // 這裡可以添加跳過已讀文本的邏輯
      switchToggleTime[1] = millis();
      if (audioManager != null) {
        audioManager.playSFX("toggle_switch");
      }
      println("跳過已讀文本設定切換");
    }
  }
  
  void handleDisplaySettingsClick(int x, int y, float panelX, float panelY) {
    float contentY = panelY + scaleY(140);
    if (checkModernToggleClick(x, y, panelX + scaleX(50), contentY)) {
      toggleFullscreen();
      switchToggleTime[2] = millis();
      if (audioManager != null) {
        audioManager.playSFX("toggle_switch");
      }
      return;
    }
    float resolutionY = contentY + scaleY(80);
    float buttonWidth = scaleX(130);
    float buttonHeight = scaleY(35);
    float buttonSpacingX = scaleX(140);
    float buttonSpacingY = scaleY(45);
    for (int i = 0; i < resolutionOptions.length; i++) {
      float buttonX = panelX + scaleX(50) + (i % 2) * buttonSpacingX;
      float buttonY = resolutionY + scaleY(20) + (i / 2) * buttonSpacingY;
      if (x >= buttonX && x <= buttonX + buttonWidth &&
          y >= buttonY && y <= buttonY + buttonHeight) {
        selectResolution(i);
        return;
      }
    }
  }
  
  // 開關點擊檢測
  boolean checkModernToggleClick(int x, int y, float toggleX, float toggleY) {
    float switchWidth = scaleX(80);
    float switchHeight = scaleY(38);
    float switchX = toggleX + scaleX(350);
    float switchY = toggleY - scaleY(18);
    return x >= switchX && x <= switchX + switchWidth &&
           y >= switchY && y <= switchY + switchHeight;
  }
  
  // 選擇解析度
  void selectResolution(int index) {
    if (index < 0 || index >= resolutionOptions.length) return;
    selectedResolutionIndex = index;
    ResolutionOption selected = resolutionOptions[index];
    if (audioManager != null) {
      audioManager.playSFX("menu_click");
    }
    if (index == 3) {
      println("選擇自訂解析度: " + selected.width + "x" + selected.height);
      return;
    }
    applyResolution(selected.width, selected.height);
    println("選擇解析度: " + selected.displayName + " (" + selected.width + "x" + selected.height + ")");
  }
  
  // 應用解析度
  void applyResolution(int newWidth, int newHeight) {
    if (newWidth == width && newHeight == height) {
      println("解析度已經是 " + newWidth + "x" + newHeight + "，無需變更");
      return;
    }
    try {
      if (fullscreen) {
        toggleFullscreen();
        delay(100);
      }
      windowedWidth = newWidth;
      windowedHeight = newHeight;
      if (surface instanceof processing.awt.PSurfaceAWT) {
        processing.awt.PSurfaceAWT awtSurface = (processing.awt.PSurfaceAWT) surface;
        java.awt.Canvas canvas = (java.awt.Canvas) awtSurface.getNative();
        java.awt.Window window = javax.swing.SwingUtilities.getWindowAncestor(canvas);
        if (window instanceof java.awt.Frame) {
          java.awt.Frame frame = (java.awt.Frame) window;
          java.awt.Dimension screenSize = java.awt.Toolkit.getDefaultToolkit().getScreenSize();
          int centerX = (screenSize.width - newWidth) / 2;
          int centerY = (screenSize.height - newHeight) / 2;
          frame.setSize(newWidth, newHeight);
          frame.setLocation(centerX, centerY);
          frame.toFront();
          frame.requestFocus();
          println("✓ 解析度已變更為: " + newWidth + "x" + newHeight);
        }
      }
      surface.setSize(newWidth, newHeight);
      delay(100);
      if (uiBuffer != null) {
        uiBuffer = createGraphics(width, height);
      }
      if (dialogueBuffer != null) {
        dialogueBuffer = createGraphics(width, height);
      }
      if (characterManager != null) {
        characterManager.updateAllCharacterPositions();
      }
      updateCustomResolution();
      uiNeedsUpdate = true;
      dialogueNeedsUpdate = true;
      saveSettings();
    } catch (Exception e) {
      println("解析度變更失敗: " + e.getMessage());
      e.printStackTrace();
    }
  }
  boolean checkSliderClick(int x, int y, float sliderX, float sliderY) {
    float trackX = sliderX + scaleX(150);
    float trackY = sliderY - scaleY(25);
    float trackWidth = scaleX(320);
    float trackHeight = scaleY(50);
    return x >= trackX && x <= trackX + trackWidth &&
           y >= trackY && y <= trackY + trackHeight;
  }
  boolean checkToggleClick(int x, int y, float toggleX, float toggleY) {
    float switchX = toggleX + scaleX(350);
    float switchY = toggleY - scaleY(25);
    float switchWidth = scaleX(100);
    float switchHeight = scaleY(60);
    return x >= switchX && x <= switchX + switchWidth &&
           y >= switchY && y <= switchY + switchHeight;
  }
  float calculateSliderValue(int mouseX, float sliderX) {
    float trackX = sliderX + scaleX(150);
    float trackWidth = scaleX(320);
    float value = (mouseX - trackX) / trackWidth;
    return constrain(value, 0, 1);
  }
  
  void updateVolumeValue(int index, float value) {
    switch(index) {
      case 0:
        masterVolume = value;
        if (audioManager != null) audioManager.setMasterVolume(value);
        break;
      case 1:
        musicVolume = value;
        if (audioManager != null) audioManager.setMusicVolume(value);
        break;
      case 2:
        sfxVolume = value;
        if (audioManager != null) audioManager.setSFXVolume(value);
        break;
      case 3:
        voiceVolume = value;
        if (audioManager != null) audioManager.setVoiceVolume(value);
        break;
    }
  }
  
  void resetToDefaults() {
    masterVolume = 0.8;
    musicVolume = 0.8;
    sfxVolume = 0.8;
    voiceVolume = 0.9;
    textSpeed = 3;
    voiceAutoPlay = true;
    selectedResolutionIndex = 1;
    for (int i = 0; i < switchToggleTime.length; i++) {
      switchToggleTime[i] = millis();
    }
    if (audioManager != null) {
      audioManager.setMasterVolume(masterVolume);
      audioManager.setMusicVolume(musicVolume);
      audioManager.setSFXVolume(sfxVolume);
      audioManager.setVoiceVolume(voiceVolume);
      audioManager.voiceAutoPlay = voiceAutoPlay;
    }
    if (dialogueSystem != null) {
      dialogueSystem.textSpeed = textSpeed;
    }
    applyResolution(1280, 720);
    saveSettings();
    if (audioManager != null) {
      audioManager.playSFX("menu_click");
    }
    println("設定已重置為預設值");
  }
  
  // 處理滑鼠拖拽
  void mouseDragged() {
    if (isDragging && draggingSlider >= 0) {
      float panelX = (width - scaleX(650)) / 2;
      float value = calculateSliderValue(mouseX, panelX + scaleX(50));
      if (draggingTab == 0 && draggingSlider < 4) {
        updateVolumeValue(draggingSlider, value);
      } else if (draggingTab == 1 && draggingSlider == 4) {
        textSpeed = int(value * 5) + 1;
        if (dialogueSystem != null) {
          dialogueSystem.textSpeed = textSpeed;
        }
      }
    }
  }
  
  void mouseReleased() {
    isDragging = false;
    draggingSlider = -1;
    draggingTab = -1;
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
    updateCustomResolution();
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
    settings.setInt("selectedResolutionIndex", selectedResolutionIndex);
    settings.setInt("windowedWidth", windowedWidth);
    settings.setInt("windowedHeight", windowedHeight);
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
        textSpeed = settings.getInt("textSpeed", 3);
        fullscreen = settings.getBoolean("fullscreen", false);
        voiceAutoPlay = settings.getBoolean("voiceAutoPlay", true);
        selectedResolutionIndex = settings.getInt("selectedResolutionIndex", 1);
        windowedWidth = settings.getInt("windowedWidth", 1280);
        windowedHeight = settings.getInt("windowedHeight", 720);
        updateCustomResolution();
        if (dialogueSystem != null) {
          dialogueSystem.textSpeed = textSpeed;
        }
        if (audioManager != null) {
          audioManager.voiceAutoPlay = voiceAutoPlay;
        }
      }
    } catch (Exception e) {
      println("設定檔案不存在，使用預設設定");
    }
  }
}

// 音訊管理器
class AudioManager {
  Minim minim;
  
  // BGM 相關
  AudioPlayer currentBGM;
  String currentBGMName = "";
  HashMap<String, AudioPlayer> bgmTracks;
  
  // 語音相關
  AudioPlayer currentVoice;
  HashMap<String, AudioPlayer> voiceTracks;
  ArrayList<String> attemptedVoiceLoads;
  
  // 音效相關
  HashMap<String, AudioPlayer> sfxSounds;
  ArrayList<String> attemptedSFXLoads;
  
  // BGM載入追蹤
  ArrayList<String> attemptedBGMLoads;
  
  // 音量控制
  float masterVolume = 0.8;
  float musicVolume = 0.8;
  float sfxVolume = 0.8;
  float voiceVolume = 0.9;
  
  // BGM 淡入淡出控制
  boolean isFading = false;
  float fadeProgress = 0.0;
  float fadeSpeed = 0.02;
  AudioPlayer fadingFromBGM = null;
  AudioPlayer fadingToBGM = null;
  String targetBGMName = "";
  String pendingBGMName = "";
  
  // 語音播放控制
  boolean voiceAutoPlay = true;
  boolean voiceInterruptible = true;
  boolean voiceIsPlaying = false;
  boolean voiceFinished = true;
  
  // 音訊格式支援
  String[] supportedAudioFormats = {"wav", "mp3"};
  
  // 場景BGM映射
  HashMap<String, String> sceneBGMMapping;
  boolean autoBGMEnabled = true;
  
  // 音效播放池
  ArrayList<AudioPlayer> activeSFXPlayers;
  int maxSFXPlayers = 8;

  AudioManager(PApplet parent) {
    minim = new Minim(parent);
    bgmTracks = new HashMap<String, AudioPlayer>();
    sfxSounds = new HashMap<String, AudioPlayer>();
    voiceTracks = new HashMap<String, AudioPlayer>();
    attemptedVoiceLoads = new ArrayList<String>();
    attemptedBGMLoads = new ArrayList<String>();
    attemptedSFXLoads = new ArrayList<String>();
    sceneBGMMapping = new HashMap<String, String>();
    activeSFXPlayers = new ArrayList<AudioPlayer>();
  }

  // BGM 管理方法
  void playBGM(String trackName) {
    if (trackName == null || trackName.trim().isEmpty()) {
      println("⚠ BGM名稱為空，跳過播放");
      return;
    }
    trackName = trackName.trim();
    if (trackName.equals(currentBGMName) && !isFading) {
      if (currentBGM != null && currentBGM.isPlaying()) {
        println("BGM已在播放: " + trackName);
        return;
      }
    }
    if (isFading && trackName.equals(targetBGMName)) {
      println("BGM已在淡入中: " + trackName);
      return;
    }
    if (isFading) {
      pendingBGMName = trackName;
      println("BGM淡入淡出進行中，設置待播放: " + trackName);
      return;
    }
    println("準備播放BGM: " + trackName);
    AudioPlayer newTrack = loadBGMIfNeeded(trackName);
    if (newTrack == null) {
      println("⚠ 找不到BGM: " + trackName + "，嘗試使用備用BGM");
      handleBGMLoadFailure(trackName);
      return;
    }
    if (currentBGM != null && currentBGM.isPlaying()) {
      startBGMCrossFade(newTrack, trackName);
    } else {
      playNewBGMDirectly(newTrack, trackName);
    }
  }
  
  void handleBGMLoadFailure(String failedTrackName) {
    if (!failedTrackName.equals("title") && bgmTracks.containsKey("title")) {
      AudioPlayer titleBGM = bgmTracks.get("title");
      if (titleBGM != null) {
        playNewBGMDirectly(titleBGM, "title");
        println("使用title作為備用BGM");
        return;
      }
    }
    if (!failedTrackName.equals("default") && bgmTracks.containsKey("default")) {
      AudioPlayer defaultBGM = bgmTracks.get("default");
      if (defaultBGM != null) {
        playNewBGMDirectly(defaultBGM, "default");
        println("使用default作為備用BGM");
        return;
      }
    }
    println("⚠ 無可用BGM，遊戲繼續");
  }
  
  void startBGMCrossFade(AudioPlayer newTrack, String trackName) {
    fadingFromBGM = currentBGM;
    fadingToBGM = newTrack;
    targetBGMName = trackName;
    fadingToBGM.rewind();
    fadingToBGM.setGain(calculateGain(0));
    fadingToBGM.loop();
    isFading = true;
    fadeProgress = 0.0;
    println("開始BGM淡入淡出: " + currentBGMName + " → " + trackName);
  }
  
  void playNewBGMDirectly(AudioPlayer newTrack, String trackName) {
    if (currentBGM != null && currentBGM.isPlaying()) {
      currentBGM.pause();
    }
    currentBGM = newTrack;
    currentBGMName = trackName;
    currentBGM.rewind();
    currentBGM.setGain(calculateGain(musicVolume));
    currentBGM.loop();
    println("直接播放BGM: " + trackName);
  }
  
  void updateBGMFading() {
    if (!isFading || fadingFromBGM == null || fadingToBGM == null) {
      return;
    }
    fadeProgress += fadeSpeed;
    if (fadeProgress >= 1.0) {
      finishBGMCrossFade();
    } else {
      float fadeOutVolume = musicVolume * (1.0 - fadeProgress);
      float fadeInVolume = musicVolume * fadeProgress;
      
      fadingFromBGM.setGain(calculateGain(fadeOutVolume));
      fadingToBGM.setGain(calculateGain(fadeInVolume));
    }
  }
  
  void finishBGMCrossFade() {
    if (fadingFromBGM != null && fadingFromBGM.isPlaying()) {
      fadingFromBGM.pause();
    }
    currentBGM = fadingToBGM;
    currentBGMName = targetBGMName;
    currentBGM.setGain(calculateGain(musicVolume));
    fadingFromBGM = null;
    fadingToBGM = null;
    targetBGMName = "";
    isFading = false;
    fadeProgress = 0.0;
    println("BGM淡入淡出完成: " + currentBGMName);
    if (!pendingBGMName.isEmpty()) {
      String nextBGM = pendingBGMName;
      pendingBGMName = "";
      println("處理待播放BGM: " + nextBGM);
      playBGM(nextBGM);
    }
  }
  
  void stopBGM() {
    if (currentBGM != null && currentBGM.isPlaying()) {
      currentBGM.pause();
      println("停止BGM: " + currentBGMName);
    }
    if (isFading) {
      if (fadingFromBGM != null && fadingFromBGM.isPlaying()) {
        fadingFromBGM.pause();
      }
      if (fadingToBGM != null && fadingToBGM.isPlaying()) {
        fadingToBGM.pause();
      }
      fadingFromBGM = null;
      fadingToBGM = null;
      targetBGMName = "";
      isFading = false;
      fadeProgress = 0.0;
      println("停止BGM淡入淡出");
    }
    currentBGMName = "";
    pendingBGMName = "";
  }
  
  void pauseBGM() {
    if (currentBGM != null && currentBGM.isPlaying()) {
      currentBGM.pause();
      println("暫停BGM: " + currentBGMName);
    }
  }
  
  void resumeBGM() {
    if (currentBGM != null && !currentBGM.isPlaying()) {
      currentBGM.play();
      println("恢復BGM: " + currentBGMName);
    }
  }
  
  // 場景BGM自動播放
  void playSceneBGM(String sceneName) {
    if (!autoBGMEnabled || sceneName == null || sceneName.trim().isEmpty()) {
      return;
    }
    sceneName = sceneName.trim();
    String bgmName = null;
    if (sceneBGMMapping.containsKey(sceneName)) {
      bgmName = sceneBGMMapping.get(sceneName);
      println("找到場景BGM映射: " + sceneName + " -> " + bgmName);
    } else if (!sceneName.equals("default")) {
      bgmName = sceneName;
      println("使用場景名稱作為BGM: " + sceneName);
    }
    if (bgmName != null && !bgmName.trim().isEmpty()) {
      playBGM(bgmName);
    } else {
      println("⚠ 場景 " + sceneName + " 沒有對應的BGM配置");
    }
  }
  
  void addSceneBGMMapping(String sceneName, String bgmName) {
    if (sceneName != null && bgmName != null) {
      sceneBGMMapping.put(sceneName.trim(), bgmName.trim());
      println("添加場景BGM映射: " + sceneName + " -> " + bgmName);
    }
  }
  
  void removeSceneBGMMapping(String sceneName) {
    if (sceneName != null && sceneBGMMapping.containsKey(sceneName)) {
      sceneBGMMapping.remove(sceneName);
      println("移除場景BGM映射: " + sceneName);
    }
  }
  
  // 載入方法
  AudioPlayer loadBGMIfNeeded(String bgmName) {
    if (bgmName == null || bgmName.trim().isEmpty()) {
      return null;
    }
    String bgmKey = bgmName.trim();
    if (bgmTracks.containsKey(bgmKey)) {
      return bgmTracks.get(bgmKey);
    }
    if (attemptedBGMLoads.contains(bgmKey)) {
      return null;
    }
    attemptedBGMLoads.add(bgmKey);
    return loadBGMFile(bgmKey);
  }
  AudioPlayer loadBGMFile(String bgmName) {
    String[] bgmPaths = {
      "data/audio/bgm/" + bgmName, 
      "data/audio/bgs/" + bgmName,
    };
    for (String basePath : bgmPaths) {
      for (String format : supportedAudioFormats) {
        String filePath = basePath + "." + format;
        try {
          File audioFile = new File(sketchPath(filePath));
          if (!audioFile.exists()) {
            continue;
          }
          AudioPlayer bgm = minim.loadFile(filePath);
          if (bgm != null) {
            bgmTracks.put(bgmName, bgm);
            println("✓ 動態載入BGM: " + bgmName + " (" + filePath + ")");
            return bgm;
          }
        } catch (Exception e) {
          println("載入BGM時出錯: " + filePath + " - " + e.getMessage());
        }
      }
    }
    println("⚠ 找不到BGM檔案: " + bgmName + " (已嘗試多種路徑和格式)");
    return null;
  }
  
  // 音效管理方法
  void playSFX(String soundName) {
    if (soundName == null || soundName.trim().isEmpty()) {
      println("⚠ 音效名稱為空，跳過播放");
      return;
    }
    soundName = soundName.trim();
    println("執行音效播放請求: " + soundName);
    AudioPlayer sfx = loadSFXIfNeeded(soundName);
    if (sfx != null) {
      playLoadedSFX(sfx, soundName);
    } else {
      println("⚠ 無法載入音效: " + soundName + "，遊戲繼續");
    }
  }
  
  // 專門為場景指令強制載入音效的方法
  AudioPlayer forceLoadSFXForCommand(String soundName) {
    if (soundName == null || soundName.trim().isEmpty()) {
      println("⚠ 強制載入音效：音效名稱為空");
      return null;
    }
    String sfxKey = soundName.trim();
    println("場景指令強制載入音效: " + sfxKey);
    if (sfxSounds.containsKey(sfxKey)) {
      AudioPlayer existingSFX = sfxSounds.get(sfxKey);
      if (existingSFX != null) {
        println("使用已載入的音效: " + sfxKey);
        return existingSFX;
      }
    }
    attemptedSFXLoads.remove(sfxKey);
    AudioPlayer newSFX = loadSFXFileForCommand(sfxKey);
    return newSFX;
  }
  
  // 專門為場景指令載入音效檔案的方法
  AudioPlayer loadSFXFileForCommand(String soundName) {
    println("為場景指令載入音效檔案: " + soundName);
    String[] sfxPaths = {
      "data/audio/sfx/" + soundName,     // 系統音效
      "data/audio/se/" + soundName,      // Sound Effect
      "data/audio/me/" + soundName,      // Music Effect
    };
    for (String basePath : sfxPaths) {
      for (String format : supportedAudioFormats) {
        String filePath = basePath + "." + format;
        try {
          File audioFile = new File(sketchPath(filePath));
          if (!audioFile.exists()) {
            continue;
          }
          println("嘗試載入場景音效: " + filePath);
          AudioPlayer sfx = minim.loadFile(filePath);
          if (sfx != null) {
            sfxSounds.put(soundName, sfx);
            if (!attemptedSFXLoads.contains(soundName)) {
              attemptedSFXLoads.add(soundName);
            }
            println("✓ 場景指令音效載入成功: " + soundName + " (" + filePath + ")");
            return sfx;
          } else {
            println("⚠ 音效載入返回null: " + filePath);
          }
        } catch (Exception e) {
          println("載入場景音效時出錯: " + filePath + " - " + e.getMessage());
        }
      }
    }
    
    println("⚠ 場景指令音效載入完全失敗: " + soundName);
    println("已嘗試的音效路徑:");
    for (String basePath : sfxPaths) {
      for (String format : supportedAudioFormats) {
        println("  - " + basePath + "." + format);
      }
    }
    if (!attemptedSFXLoads.contains(soundName)) {
      attemptedSFXLoads.add(soundName);
    }
    return null;
  }
  
  AudioPlayer loadSFXIfNeeded(String soundName) {
    if (soundName == null || soundName.trim().isEmpty()) {
      return null;
    }
    String sfxKey = soundName.trim();
    if (sfxSounds.containsKey(sfxKey)) {
      AudioPlayer existingSFX = sfxSounds.get(sfxKey);
      if (existingSFX != null) {
        println("使用已載入的音效: " + sfxKey);
        return existingSFX;
      }
    }
    if (attemptedSFXLoads.contains(sfxKey)) {
      println("音效 " + sfxKey + " 之前載入失敗，嘗試場景指令強制載入");
      return forceLoadSFXForCommand(sfxKey);
    }
    attemptedSFXLoads.add(sfxKey);
    AudioPlayer sfx = loadSFXFile(sfxKey);
    if (sfx != null) {
      return sfx;
    }
    println("標準音效載入失敗，嘗試場景指令路徑: " + sfxKey);
    return loadSFXFileForCommand(sfxKey);
  }
  AudioPlayer loadSFXFile(String soundName) {
    println("開始載入音效檔案: " + soundName);
    String[] sfxPaths = {
      "data/audio/sfx/" + soundName,     // 系統音效
      "data/audio/se/" + soundName,      // Sound Effect
      "data/audio/me/" + soundName,      // Music Effect
    };
    for (String basePath : sfxPaths) {
      for (String format : supportedAudioFormats) {
        String filePath = basePath + "." + format;
        try {
          File audioFile = new File(sketchPath(filePath));
          if (!audioFile.exists()) {
            continue;
          }
          println("嘗試載入: " + filePath);
          AudioPlayer sfx = minim.loadFile(filePath);
          if (sfx != null) {
            sfxSounds.put(soundName, sfx);
            println("✓ 標準路徑音效載入成功: " + soundName + " (" + filePath + ")");
            return sfx;
          } else {
            println("⚠ 音效載入返回null: " + filePath);
          }
        } catch (Exception e) {
          println("載入音效時出錯: " + filePath + " - " + e.getMessage());
        }
      }
    }
    
    println("⚠ 標準路徑找不到音效檔案: " + soundName);
    return null;
  }
  
  void playLoadedSFX(AudioPlayer sfx, String soundName) {
    try {
      cleanupFinishedSFX();
      if (activeSFXPlayers.size() >= maxSFXPlayers) {
        println("⚠ 達到最大音效播放數量，停止最舊的音效");
        AudioPlayer oldestSFX = activeSFXPlayers.get(0);
        if (oldestSFX != null && oldestSFX.isPlaying()) {
          oldestSFX.pause();
          oldestSFX.rewind();
        }
        activeSFXPlayers.remove(0);
      }
      sfx.rewind();
      sfx.setGain(calculateGain(sfxVolume));
      sfx.play();
      if (!activeSFXPlayers.contains(sfx)) {
        activeSFXPlayers.add(sfx);
      }
      println("✓ 播放音效: " + soundName + " (音量: " + int(sfxVolume * 100) + "%)");
    } catch (Exception e) {
      println("播放音效時出錯: " + soundName + " - " + e.getMessage());
    }
  }
  
  void cleanupFinishedSFX() {
    for (int i = activeSFXPlayers.size() - 1; i >= 0; i--) {
      AudioPlayer sfx = activeSFXPlayers.get(i);
      if (sfx == null || !sfx.isPlaying()) {
        activeSFXPlayers.remove(i);
      }
    }
  }
  
  void loadSFXTrack(String name, String baseFilePath) {
    if (sfxSounds.containsKey(name)) {
      return;
    }
    for (String format : supportedAudioFormats) {
      String filePath = baseFilePath + "." + format;
      try {
        File audioFile = new File(sketchPath(filePath));
        if (!audioFile.exists()) {
          continue;
        }
        
        AudioPlayer track = minim.loadFile(filePath);
        if (track != null) {
          sfxSounds.put(name, track);
          println("✓ 載入基礎音效: " + name + " (" + filePath + ")");
          return;
        }
      } catch (Exception e) {
        println("載入基礎音效失敗: " + filePath + " - " + e.getMessage());
      }
    }
    println("⚠ 基礎音效載入失敗: " + name + " (已嘗試多種格式)");
  }
  
  // 停止所有音效
  void stopAllSFX() {
    for (AudioPlayer sfx : activeSFXPlayers) {
      if (sfx != null && sfx.isPlaying()) {
        sfx.pause();
        sfx.rewind();
      }
    }
    activeSFXPlayers.clear();
    println("停止所有音效");
  }
  
  // 語音管理方法
  void playVoice(String voiceName) {
    if (!voiceAutoPlay || voiceName == null || voiceName.trim().isEmpty()) {
      voiceFinished = true;
      return;
    }
    if (currentVoice != null && currentVoice.isPlaying()) {
      currentVoice.pause();
      currentVoice.rewind();
    }
    
    // 動態載入語音
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
  
  void stopVoice() {
    if (currentVoice != null && currentVoice.isPlaying()) {
      currentVoice.pause();
      currentVoice.rewind();
    }
    voiceIsPlaying = false;
    voiceFinished = true;
  }
  
  boolean isVoicePlaying() {
    if (currentVoice == null) {
      return false;
    }
    return currentVoice.isPlaying();
  }
  
  boolean isVoiceFinished() {
    return voiceFinished;
  }
  
  void resetVoiceState() {
    voiceIsPlaying = false;
    voiceFinished = true;
  }
  
  void updateVoiceStatus() {
    if (voiceIsPlaying && currentVoice != null) {
      if (!currentVoice.isPlaying()) {
        voiceIsPlaying = false;
        voiceFinished = true;
        println("語音播放完畢");
      }
    }
  }
  
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
  
  AudioPlayer loadVoiceFile(String voiceName) {
    String[] voicePaths = {
      "data/audio/voice/" + voiceName,
    };
    if (voiceName.contains("_")) {
      String[] parts = voiceName.split("_");
      if (parts.length >= 2) {
        String characterName = parts[0];
        String[] characterPaths = {
          "data/audio/voice/" + characterName + "/" + voiceName
        };
        String[] allPaths = new String[voicePaths.length + characterPaths.length];
        System.arraycopy(characterPaths, 0, allPaths, 0, characterPaths.length);
        System.arraycopy(voicePaths, 0, allPaths, characterPaths.length, voicePaths.length);
        voicePaths = allPaths;
      }
    }
    for (String basePath : voicePaths) {
      for (String format : supportedAudioFormats) {
        String filePath = basePath + "." + format;
        try {
          File audioFile = new File(sketchPath(filePath));
          if (!audioFile.exists()) {
            continue;
          }
          AudioPlayer voice = minim.loadFile(filePath);
          if (voice != null) {
            voiceTracks.put(voiceName, voice);
            println("✓ 動態載入語音: " + voiceName + " (" + filePath + ")");
            return voice;
          }
        } catch (Exception e) {
          println("載入語音失敗: " + filePath + " - " + e.getMessage());
        }
      }
    }
    println("⚠ 找不到語音檔案: " + voiceName + " (已嘗試多種路徑和格式)");
    return null;
  }
  
  // 音量控制方法
  void setMasterVolume(float vol) {
    masterVolume = constrain(vol, 0, 1);
    updateAllVolumes();
    println("主音量設置為: " + int(masterVolume * 100) + "%");
  }
  
  void setMusicVolume(float vol) {
    musicVolume = constrain(vol, 0, 1);
    updateBGMVolume();
    println("音樂音量設置為: " + int(musicVolume * 100) + "%");
  }
  
  void setSFXVolume(float vol) {
    sfxVolume = constrain(vol, 0, 1);
    println("音效音量設置為: " + int(sfxVolume * 100) + "%");
  }
  
  void setVoiceVolume(float vol) {
    voiceVolume = constrain(vol, 0, 1);
    if (currentVoice != null) {
      currentVoice.setGain(calculateGain(voiceVolume));
    }
    println("語音音量設置為: " + int(voiceVolume * 100) + "%");
  }
  
  void updateBGMVolume() {
    if (currentBGM != null) {
      currentBGM.setGain(calculateGain(musicVolume));
    }
    if (isFading) {
      if (fadingFromBGM != null) {
        float fadeOutVolume = musicVolume * (1.0 - fadeProgress);
        fadingFromBGM.setGain(calculateGain(fadeOutVolume));
      }
      if (fadingToBGM != null) {
        float fadeInVolume = musicVolume * fadeProgress;
        fadingToBGM.setGain(calculateGain(fadeInVolume));
      }
    }
  }
  
  void updateAllVolumes() {
    updateBGMVolume();
    if (currentVoice != null) {
      currentVoice.setGain(calculateGain(voiceVolume));
    }
  }
  
  float calculateGain(float volume) {
    if (volume <= 0.001) return -80;
    float gain = 20 * log(volume * masterVolume) / log(10);
    return constrain(gain, -80, 6);
  }
  
  void update() {
    updateBGMFading();
    updateVoiceStatus();
    cleanupFinishedSFX();
  }
  
  void setVoiceInterruptible(boolean interruptible) {
    voiceInterruptible = interruptible;
  }
  
  // 狀態查詢方法
  String getCurrentBGMName() {
    return currentBGMName;
  }
  
  boolean isBGMPlaying() {
    return currentBGM != null && currentBGM.isPlaying();
  }
  
  boolean isBGMFading() {
    return isFading;
  }
  
  String getTargetBGMName() {
    return targetBGMName;
  }
  
  String getPendingBGMName() {
    return pendingBGMName;
  }
  
  int getActiveSFXCount() {
    cleanupFinishedSFX();
    return activeSFXPlayers.size();
  }
  
  boolean isSFXPlaying(String sfxName) {
    if (sfxName == null || !sfxSounds.containsKey(sfxName)) {
      return false;
    }
    
    AudioPlayer sfx = sfxSounds.get(sfxName);
    return sfx != null && sfx.isPlaying();
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
  
  void scriptStopAllSFX() {
    stopAllSFX();
  }
  
  void scriptPlayVoice(String voiceName) {
    playVoice(voiceName);
  }
  
  void scriptStopVoice() {
    stopVoice();
  }
  
  void scriptSetAutoBGMEnabled(boolean enabled) {
    setAutoBGMEnabled(enabled);
  }
  
  void scriptSetFadeSpeed(float speed) {
    setFadeSpeed(speed);
  }
  
  
  // 其他配置方法
  void setAutoBGMEnabled(boolean enabled) {
    autoBGMEnabled = enabled;
    println("自動BGM切換: " + (enabled ? "啟用" : "停用"));
  }
  
  void setFadeSpeed(float speed) {
    fadeSpeed = constrain(speed, 0.005, 0.1);
    println("BGM淡入淡出速度設置為: " + fadeSpeed);
  }
  
  void setMaxSFXPlayers(int maxPlayers) {
    maxSFXPlayers = constrain(maxPlayers, 1, 16);
    println("最大同時音效播放數設置為: " + maxSFXPlayers);
  }
  
  ArrayList<String> getLoadedBGMList() {
    return new ArrayList<String>(bgmTracks.keySet());
  }
  
  ArrayList<String> getLoadedSFXList() {
    return new ArrayList<String>(sfxSounds.keySet());
  }
  
  ArrayList<String> getLoadedVoiceList() {
    return new ArrayList<String>(voiceTracks.keySet());
  }
  
  // 資源清理方法
  void dispose() {
    println("清理音訊資源...");
    stopAllSFX();
    stopVoice();
    stopBGM();
    if (currentBGM != null) {
      currentBGM.close();
    }
    if (currentVoice != null) {
      currentVoice.close();
    }
    if (fadingFromBGM != null) {
      fadingFromBGM.close();
    }
    if (fadingToBGM != null) {
      fadingToBGM.close();
    }
    for (AudioPlayer track : bgmTracks.values()) {
      if (track != null) {
        track.close();
      }
    }
    for (AudioPlayer sfx : sfxSounds.values()) {
      if (sfx != null) {
        sfx.close();
      }
    }
    for (AudioPlayer voice : voiceTracks.values()) {
      if (voice != null) {
        voice.close();
      }
    }
    bgmTracks.clear();
    sfxSounds.clear();
    voiceTracks.clear();
    attemptedVoiceLoads.clear();
    attemptedBGMLoads.clear();
    attemptedSFXLoads.clear();
    sceneBGMMapping.clear();
    activeSFXPlayers.clear();
    if (minim != null) {
      minim.stop();
    }
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

  // 專門的恢復方法
  void restoreCharacterFromSave(String character, String position, String emotion, JSONObject charData) {
    addCharacter(character, position, emotion);
    if (charData != null && activeCharacters.containsKey(character)) {
      CharacterManager.CharacterDisplay charDisplay = activeCharacters.get(character);
      if (charData.hasKey("alpha")) {
        charDisplay.alpha = charData.getFloat("alpha");
        charDisplay.targetAlpha = charData.getFloat("targetAlpha", charDisplay.alpha);
      }
      if (charData.hasKey("scale")) {
        charDisplay.scale = charData.getFloat("scale");
        charDisplay.targetScale = charData.getFloat("targetScale", charDisplay.scale);
      }
      if (charData.hasKey("isActive")) {
        charDisplay.isActive = charData.getBoolean("isActive");
      }
      charDisplay.calculatePosition();
      charDisplay.baseY = height * 1.35; // 使用當前視窗高度
      charDisplay.targetY = charDisplay.baseY;
      charDisplay.currentX = charDisplay.targetX;
      charDisplay.currentY = charDisplay.targetY;
      charDisplay.isEntering = false;
      println("✓ 完整恢復角色: " + character + " 基準Y: " + charDisplay.baseY);
    }
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

  // 重新設置基準Y位置，確保在窗口大小改變時正確更新
  void updateAllCharacterPositions() {
    for (CharacterDisplay charDisplay : activeCharacters.values()) {
      charDisplay.baseY = height * 1.35;
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
    float baseY;
    
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
      this.baseY = height * 1.35;
      this.targetY = this.baseY;
      boolean isLeftPosition = this.position.equals("left") || this.position.equals("far_left");
      this.currentX = targetX + (isLeftPosition ? -100 : 100);
      this.currentY = this.baseY + 50;
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
          println("⚠ 未知角色位置: " + this.position + "，使用預設位置 center");
          this.position = "center";
          break;
      }
      if (baseY == 0 || abs(baseY - height * 1.35) > 50) {
        baseY = height * 1.35;
        println("重新設置角色 " + character + " 的基準Y位置: " + baseY);
      }
      targetY = baseY;
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
        targetAlpha = 255;
        targetScale = 1.02;
      } else {
        targetAlpha = 225;
        targetScale = 0.98;
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
      targetY = baseY + 50;
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
      
      if (emotionChangeAlpha > 0) {
        emotionChangeAlpha -= 0.02;
        if (emotionChangeAlpha <= 0) {
          emotionChangeAlpha = 0;
        }
      }
      
      if (isExiting && alpha < 5) {
        shouldRemove = true;
      }
      
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
        text("BaseY: " + int(baseY), 0, 195);
      }
      noStroke();
      rectMode(CORNER);
    }
    void forcePositionSync() {
      calculatePosition();
      baseY = height * 1.35; 
      targetY = baseY;
      currentX = targetX;
      currentY = targetY;
      isEntering = false;
      isExiting = false;
    }
  }
}

// 背景管理器
class BackgroundManager {
  String currentBackground = "default";
  HashMap<String, PImage> backgroundImages;
  ArrayList<String> attemptedLoads;
  boolean isInitialized = false;
  String initialBackground = "default";
  boolean shouldSkipInitialTransition = false;
  TransitionController transitionController;
  CloseupCamera closeupCamera;
  boolean isShowingCloseup = false;
  boolean autoFitScreen = true;
  DebounceManager debounceManager;
  BackgroundManager() {
    backgroundImages = new HashMap<String, PImage>();
    attemptedLoads = new ArrayList<String>();
    transitionController = new TransitionController();
    closeupCamera = new CloseupCamera();
    debounceManager = new DebounceManager();
    println("背景管理器初始化完成");
  }
  
  // 初始化方法
  void preloadInitialBackground(String firstSceneBackground) {
    if (firstSceneBackground != null && !firstSceneBackground.trim().isEmpty() && 
        !firstSceneBackground.equals("default")) {
      String bgName = firstSceneBackground.trim();
      PImage bgImage = loadBackgroundIfNeeded(bgName);
      if (bgImage != null) {
        currentBackground = bgName;
        initialBackground = bgName;
        shouldSkipInitialTransition = true;
        println("✓ 預載入初始背景: " + bgName);
      } else {
        println("⚠ 初始背景載入失敗，使用default: " + bgName);
      }
    }
    isInitialized = true;
  }
  
  // 設置初始背景
  void setInitialBackground(String backgroundName) {
    if (backgroundName == null || backgroundName.trim().isEmpty()) {
      backgroundName = "default";
    }
    backgroundName = backgroundName.trim();
    if (backgroundName.equals("default")) {
      currentBackground = "default";
      println("設置初始背景為預設");
      return;
    }
    PImage bgImage = loadBackgroundIfNeeded(backgroundName);
    if (bgImage != null) {
      currentBackground = backgroundName;
      println("✓ 設置初始背景: " + backgroundName);
    } else {
      currentBackground = "default";
      println("⚠ 初始背景載入失敗，使用default: " + backgroundName);
    }
    if (audioManager != null && !backgroundName.equals("default")) {
      audioManager.playSceneBGM(backgroundName);
    }
    isInitialized = true;
  }
  
  // 重置背景管理器
  void resetForNewGame() {
    currentBackground = "default";
    isInitialized = false;
    shouldSkipInitialTransition = false;
    initialBackground = "default";
    transitionController.cancelCurrentTransition();
    if (isShowingCloseup) {
      closeupCamera.stop();
      isShowingCloseup = false;
    }
    debounceManager.clearPendingRequest();
    transitionController.clearPendingTransition();
    println("背景管理器已重置");
  }
  
  // 防抖管理器
  class DebounceManager {
    long lastRequestTime = 0;
    String lastRequestedBackground = "";
    String pendingBackground = "";
    boolean hasPendingRequest = false;
    long debounceInterval = 100; // 100ms防抖
    boolean shouldDebounce(String backgroundName) {
      long currentTime = millis();
      if (backgroundName.equals(lastRequestedBackground) && 
          (currentTime - lastRequestTime) < debounceInterval) {
        println("背景請求防抖: " + backgroundName);
        return true;
      }
      lastRequestedBackground = backgroundName;
      lastRequestTime = currentTime;
      return false;
    }
    
    void setPendingRequest(String backgroundName) {
      if (!backgroundName.equals(currentBackground) && 
          !backgroundName.equals(transitionController.getTargetBackground())) {
        hasPendingRequest = true;
        pendingBackground = backgroundName;
        println("設置待處理背景: " + backgroundName);
      }
    }
    
    void clearPendingRequest() {
      hasPendingRequest = false;
      pendingBackground = "";
    }
    
    void processPendingRequest() {
      if (hasPendingRequest && !pendingBackground.isEmpty()) {
        String pendingName = pendingBackground;
        clearPendingRequest();
        println("處理待處理的背景切換: " + pendingName);
        new Thread(() -> {
          try { Thread.sleep(50); } catch (Exception e) {}
          executeBackgroundChange(pendingName, "fade", 500);
        }).start();
      }
    }
  }
  
  // 轉場控制器
  class TransitionController {
    // 轉場狀態
    boolean isTransitioning = false;
    String transitionType = "fade";
    float transitionProgress = 0;
    float transitionDuration = 600;
    long transitionStartTime = 0;
    
    // 背景對象
    PImage fromBackground = null;
    PImage toBackground = null;
    String targetBackground = "";
    
    // 待處理的轉場請求
    boolean hasPendingTransition = false;
    String pendingBackgroundName = "";
    String pendingTransitionType = "";
    float pendingDuration = 0;
    
    void startTransition(String targetBGName, PImage targetBG, String transition, float duration) {
      if (shouldSkipInitialTransition && targetBGName.equals(initialBackground)) {
        println("跳過初始場景轉場: " + targetBGName);
        currentBackground = targetBGName;
        shouldSkipInitialTransition = false;
        return;
      }
      if (isTransitioning) {
        setPendingTransition(targetBGName, transition, duration);
        return;
      }
      if (targetBGName.equals(currentBackground)) {
        println("背景已經是: " + targetBGName + "，跳過轉場");
        return;
      }
      executeTransition(targetBGName, targetBG, transition, duration);
    }
    
    void executeTransition(String targetBGName, PImage targetBG, String transition, float duration) {
      fromBackground = getCurrentBackgroundImage();
      toBackground = targetBG;
      targetBackground = targetBGName;
      transitionType = transition;
      transitionDuration = max(duration, 100);
      transitionProgress = 0;
      transitionStartTime = millis();
      isTransitioning = true;
      clearPendingTransition();
      println("開始背景轉場: " + currentBackground + " → " + targetBGName + " (" + transition + ")");
    }
    
    void setPendingTransition(String backgroundName, String transition, float duration) {
      if (!backgroundName.equals(currentBackground) && !backgroundName.equals(targetBackground)) {
        hasPendingTransition = true;
        pendingBackgroundName = backgroundName;
        pendingTransitionType = transition;
        pendingDuration = duration;
        println("設置待處理轉場: " + backgroundName);
      }
    }
    
    void clearPendingTransition() {
      hasPendingTransition = false;
      pendingBackgroundName = "";
      pendingTransitionType = "";
      pendingDuration = 0;
    }
    
    void update() {
      if (!isTransitioning) return;
      long elapsed = millis() - transitionStartTime;
      transitionProgress = elapsed / transitionDuration;
      if (transitionProgress >= 1.0) {
        finishTransition();
      }
    }
    
    void finishTransition() {
      currentBackground = targetBackground;
      isTransitioning = false;
      transitionProgress = 1.0;
      fromBackground = null;
      toBackground = null;
      targetBackground = "";
      println("背景轉場完成: " + currentBackground);
      processPendingTransition();
      debounceManager.processPendingRequest();
    }
    
    void processPendingTransition() {
      if (hasPendingTransition && !pendingBackgroundName.isEmpty()) {
        String pendingName = pendingBackgroundName;
        String pendingType = pendingTransitionType;
        float pendingDur = pendingDuration;
        clearPendingTransition();
        println("處理待處理的轉場: " + pendingName);
        new Thread(() -> {
          try { Thread.sleep(50); } catch (Exception e) {}
          PImage pendingBG = loadBackgroundIfNeeded(pendingName);
          if (pendingBG != null || pendingName.equals("default")) {
            executeTransition(pendingName, pendingBG, pendingType, pendingDur);
          }
        }).start();
      }
    }
    
    void forceCompleteTransition() {
      if (isTransitioning) {
        finishTransition();
      }
    }
    
    void cancelCurrentTransition() {
      if (isTransitioning) {
        isTransitioning = false;
        fromBackground = null;
        toBackground = null;
        targetBackground = "";
        clearPendingTransition();
        println("取消當前轉場");
      }
    }
    
    // 狀態查詢
    boolean isTransitioning() {
      return isTransitioning;
    }
    
    String getTargetBackground() {
      return targetBackground;
    }
    
    float getProgress() {
      return transitionProgress;
    }
    
    // 轉場繪製
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
    
    // 轉場效果實現
    void drawFadeTransition() {
      float progress = closeupCamera.applyEasing(transitionProgress, "easeInOut");
      imageMode(CORNER);
      tint(255, 255 * (1 - progress));
      drawBackgroundImage(fromBackground);
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
      drawBackgroundImage(fromBackground);
      float progress = closeupCamera.applyEasing(transitionProgress, "easeInOut");
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
      PGraphics masked = createGraphics(width, height);
      masked.beginDraw();
      masked.clear();
      masked.image(toBackground, 0, 0, width, height);
      masked.endDraw();
      copy(masked, clipX, clipY, clipW, clipH, clipX, clipY, clipW, clipH);
    }
    
    void drawCircleTransition() {
      imageMode(CORNER);
      drawBackgroundImage(fromBackground);
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
        image(toBackground, width/2, height/2, width, height);
        float scale = 1 + progress * 0.5;
        float alpha = 255 * (1 - progress);
        tint(255, alpha);
        image(fromBackground, width/2, height/2, width * scale, height * scale);
        noTint();
      } else {
        image(fromBackground, width/2, height/2, width, height);
        float scale = 0.5 + progress * 0.5;
        float alpha = 255 * progress;
        tint(255, alpha);
        image(toBackground, width/2, width/2, width * scale, height * scale);
        noTint();
      }
      imageMode(CORNER);
    }
    
    void drawBlindsTransition() {
      imageMode(CORNER);
      drawBackgroundImage(fromBackground);
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
      float progress = transitionProgress;
      tint(255, 255 * (1 - progress));
      drawBackgroundImage(fromBackground);
      blendMode(ADD);
      tint(255, 255 * progress * 0.5);
      drawBackgroundImage(toBackground);
      blendMode(NORMAL);
      noTint();
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
      
      // 計算顯示位置
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
      isShowingCloseup = false;
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
  
  // 核心背景切換API
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
    if (!isInitialized) {
      setInitialBackground(backgroundName);
      return;
    }
    if (debounceManager.shouldDebounce(backgroundName)) {
      return;
    }
    if (backgroundName.equals(currentBackground) && !transitionController.isTransitioning()) {
      if (audioManager != null && !backgroundName.equals("default")) {
        audioManager.playSceneBGM(backgroundName);
      }
      return;
    }
    if (transitionController.isTransitioning() && backgroundName.equals(transitionController.getTargetBackground())) {
      println("背景已在切換至: " + backgroundName + "，跳過重複切換");
      return;
    }
    if (transitionController.isTransitioning()) {
      debounceManager.setPendingRequest(backgroundName);
      return;
    }
    executeBackgroundChange(backgroundName, transition, duration);
  }
  
  void executeBackgroundChange(String backgroundName, String transition, float duration) {
    PImage newBG = loadBackgroundIfNeeded(backgroundName);
    if (newBG == null && !backgroundName.equals("default")) {
      println("⚠ 背景載入失敗: " + backgroundName);
      return;
    }
    if (backgroundName.equals("default")) {
      currentBackground = backgroundName;
      println("設置預設背景");
    } else {
      transitionController.startTransition(backgroundName, newBG, transition, duration);
    }
    if (audioManager != null && !backgroundName.equals("default")) {
      audioManager.playSceneBGM(backgroundName);
    }
    println("背景切換請求: " + currentBackground + " -> " + backgroundName + " (" + transition + ")");
  }
  
  // 場景特寫API
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

  // 背景載入系統
  PImage loadBackgroundIfNeeded(String backgroundName) {
    if (backgroundImages.containsKey(backgroundName)) {
      return backgroundImages.get(backgroundName);
    }
    if (attemptedLoads.contains(backgroundName)) {
      return null;
    }
    attemptedLoads.add(backgroundName);
    return loadBackground(backgroundName);
  }
  PImage loadBackground(String backgroundName) {
    String[] formats = {"png", "jpg", "jpeg"};
    String[] paths = {
      "data/images/bg/"
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
  
  void display() {
    if (isShowingCloseup) {
      closeupCamera.update();
      closeupCamera.display();
    } else {
      transitionController.update();
      transitionController.drawTransition();
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
    text("請將背景圖片放在 data/images/bg/ 資料夾", width/2, height/2 + 40);
  }
  
  // 高級控制方法
  void forceCompleteTransition() {
    transitionController.forceCompleteTransition();
  }
  
  void cancelCurrentTransition() {
    transitionController.cancelCurrentTransition();
  }
  
  void clearPendingRequests() {
    debounceManager.clearPendingRequest();
    transitionController.clearPendingTransition();
  }
  
  // 腳本接口方法
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
  
  // 工具方法
  String getCurrentBackground() {
    return currentBackground;
  }
  
  boolean isTransitioning() {
    return transitionController.isTransitioning();
  }
  
  boolean isShowingCloseup() {
    return isShowingCloseup;
  }
  
  void setAutoFitScreen(boolean enabled) {
    autoFitScreen = enabled;
  }
  
  float getTransitionProgress() {
    return transitionController.getProgress();
  }
  
  String getTargetBackground() {
    return transitionController.getTargetBackground();
  }
  
  boolean hasPendingTransition() {
    return transitionController.hasPendingTransition || debounceManager.hasPendingRequest;
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

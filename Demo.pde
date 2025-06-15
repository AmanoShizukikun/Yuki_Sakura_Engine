// 基本資訊
void configureGameSettings(GameConfig config) {
  config.setGameTitle("雪櫻引擎 Ver 1.0.0 Demo");
  config.setGameVersion("1.0.0");
  config.setGameAuthor("天野靜樹");
  config.setGameDescription("雪櫻引擎功能示範 - 完整教學版");
}

// 場景配置
void configureSceneNames() {
  HashMap<String, String> sceneNames = new HashMap<String, String>();
  sceneNames.put("office", "開發者辦公室");
  sceneNames.put("classroom", "教室");
  sceneNames.put("school_gate", "學校門口");
  sceneNames.put("library", "圖書館");
  sceneNames.put("park", "公園");
  sceneNames.put("demo_room", "展示間");
  dialogueSystem.scriptSetSceneDisplayNames(sceneNames);
}

// 音樂配置
void configureBGMMapping() {
  if (audioManager != null) {
    audioManager.scriptAddSceneBGM("office", "demo_bgm");
    audioManager.scriptAddSceneBGM("classroom", "school");
    audioManager.scriptAddSceneBGM("school_gate", "school");
    audioManager.scriptAddSceneBGM("library", "calm");
    audioManager.scriptAddSceneBGM("park", "peaceful");
    audioManager.scriptAddSceneBGM("demo_room", "demo_bgm");
  }
}

// 遊戲劇本
void createStoryScript() {
  configureSceneNames(); 
  configureBGMMapping();
  
  // 清空所有對話節點
  dialogueSystem.clearNodes();

  // =========================
  // 開場：開發者介紹
  // =========================
  
  DialogueNode start = new DialogueNode(
    "天野靜樹", 
    "歡迎來到雪櫻引擎的功能展示！我是這個引擎的開發者天野靜樹。", 
    "office", 
    "amano", 
    "center", 
    "normal"
  );
  start.nextNode = "intro_engine";
  dialogueSystem.addNode("start", start);

  DialogueNode introEngine = new DialogueNode(
    "天野靜樹", 
    "今天我將為大家完整示範雪櫻引擎的各種功能，讓你了解如何用它來製作屬於自己的galgame！", 
    "office", 
    "amano", 
    "center", 
    "smile"
  );
  introEngine.nextNode = "explain_purpose";
  dialogueSystem.addNode("intro_engine", introEngine);

  DialogueNode explainPurpose = new DialogueNode(
    "天野靜樹", 
    "雪櫻引擎是我用Processing開發的視覺小說引擎，支援多種功能：對話系統、角色管理、背景切換、音樂播放等等。", 
    "office", 
    "amano", 
    "center", 
    "explain"
  );
  explainPurpose.nextNode = "demo_choice";
  dialogueSystem.addNode("explain_purpose", explainPurpose);

  // =========================
  // 功能選擇分支
  // =========================
  
  DialogueNode demoChoice = new DialogueNode(
    "天野靜樹", 
    "那麼，你想先看看哪個功能的示範呢？", 
    "office", 
    "amano", 
    "center", 
    "question"
  );
  demoChoice.addChoice("角色系統示範", "character_demo", 0, 0);
  demoChoice.addChoice("背景與場景切換", "background_demo", 0, 0);
  demoChoice.addChoice("音效與音樂系統", "audio_demo", 0, 0);
  demoChoice.addChoice("特殊效果展示", "effects_demo", 0, 0);
  dialogueSystem.addNode("demo_choice", demoChoice);

  // =========================
  // 角色系統示範
  // =========================
  
  DialogueNode characterDemo = new DialogueNode(
    "天野靜樹", 
    "很好！讓我們先來看看角色系統。雪櫻引擎支援多角色同時顯示，以及豐富的情感表現。", 
    "classroom", 
    "amano", 
    "left", 
    "explain"
  );
  characterDemo.nextNode = "add_characters";
  characterDemo.setTransition("slide_right");
  dialogueSystem.addNode("character_demo", characterDemo);

  DialogueNode addCharacters = new DialogueNode(
    "天野靜樹", 
    "現在我來示範如何添加其他角色到場景中。", 
    "classroom", 
    "amano", 
    "left", 
    "normal"
  );
  addCharacters.addCharacter("yuki", "center", "normal");
  addCharacters.nextNode = "introduce_yuki";
  dialogueSystem.addNode("add_characters", addCharacters);

  DialogueNode introduceYuki = new DialogueNode(
    "雪", 
    "大家好～我是雪！很高興參與這次的引擎示範～", 
    "classroom", 
    "yuki", 
    "center", 
    "smile"
  );
  introduceYuki.nextNode = "add_sakura";
  dialogueSystem.addNode("introduce_yuki", introduceYuki);

  DialogueNode addSakura = new DialogueNode(
    "天野靜樹", 
    "接下來再加入另一個角色...", 
    "classroom", 
    "amano", 
    "left", 
    "normal"
  );
  addSakura.addCharacter("sakura", "right", "normal");
  addSakura.nextNode = "introduce_sakura";
  dialogueSystem.addNode("add_sakura", addSakura);

  DialogueNode introduceSakura = new DialogueNode(
    "櫻", 
    "初次見面，我是櫻。這個引擎看起來很厲害呢！", 
    "classroom", 
    "sakura", 
    "right", 
    "normal"
  );
  introduceSakura.nextNode = "emotion_demo";
  dialogueSystem.addNode("introduce_sakura", introduceSakura);

  DialogueNode emotionDemo = new DialogueNode(
    "天野靜樹", 
    "你們看，角色可以表現不同的情感。比如...", 
    "classroom", 
    "amano", 
    "left", 
    "explain"
  );
  emotionDemo.updateCharacterEmotion("yuki", "happy");
  emotionDemo.updateCharacterEmotion("sakura", "shy");
  emotionDemo.nextNode = "emotion_demo2";
  dialogueSystem.addNode("emotion_demo", emotionDemo);

  DialogueNode emotionDemo2 = new DialogueNode(
    "雪", 
    "哇～這樣就能顯示開心的表情了！", 
    "classroom", 
    "yuki", 
    "center", 
    "happy"
  );
  emotionDemo2.nextNode = "emotion_demo3";
  dialogueSystem.addNode("emotion_demo2", emotionDemo2);

  DialogueNode emotionDemo3 = new DialogueNode(
    "櫻", 
    "而且還能顯示害羞的表情呢...", 
    "classroom", 
    "sakura", 
    "right", 
    "shy"
  );
  emotionDemo3.nextNode = "position_demo";
  dialogueSystem.addNode("emotion_demo3", emotionDemo3);

  DialogueNode positionDemo = new DialogueNode(
    "天野靜樹", 
    "角色還可以改變位置。看我讓她們換個位置...", 
    "classroom", 
    "amano", 
    "left", 
    "normal"
  );
  positionDemo.updateCharacterPosition("yuki", "right");
  positionDemo.updateCharacterPosition("sakura", "center");
  positionDemo.nextNode = "position_demo2";
  dialogueSystem.addNode("position_demo", positionDemo);

  DialogueNode positionDemo2 = new DialogueNode(
    "櫻", 
    "哇，我移動到中間來了！", 
    "classroom", 
    "sakura", 
    "center", 
    "surprised"
  );
  positionDemo2.nextNode = "back_to_menu";
  dialogueSystem.addNode("position_demo2", positionDemo2);

  // =========================
  // 背景與場景示範
  // =========================
  
  DialogueNode backgroundDemo = new DialogueNode(
    "天野靜樹", 
    "接下來示範背景系統！雪櫻引擎支援多種場景轉換效果。", 
    "demo_room", 
    "amano", 
    "center", 
    "explain"
  );
  backgroundDemo.setTransition("fade");
  backgroundDemo.clearAllCharacters();
  backgroundDemo.nextNode = "scene_transition1";
  dialogueSystem.addNode("background_demo", backgroundDemo);

  DialogueNode sceneTransition1 = new DialogueNode(
    "天野靜樹", 
    "比如我們可以用淡入淡出的方式切換到學校門口...", 
    "school_gate", 
    "amano", 
    "center", 
    "normal"
  );
  sceneTransition1.setTransition("fade");
  sceneTransition1.nextNode = "scene_transition2";
  dialogueSystem.addNode("scene_transition1", sceneTransition1);

  DialogueNode sceneTransition2 = new DialogueNode(
    "天野靜樹", 
    "或者用滑動效果切換到圖書館...", 
    "library", 
    "amano", 
    "center", 
    "normal"
  );
  sceneTransition2.setTransition("slide_left");
  sceneTransition2.nextNode = "scene_transition3";
  dialogueSystem.addNode("scene_transition2", sceneTransition2);

  DialogueNode sceneTransition3 = new DialogueNode(
    "天野靜樹", 
    "還有圓形擴散效果切換到公園！", 
    "park", 
    "amano", 
    "center", 
    "smile"
  );
  sceneTransition3.setTransition("circle");
  sceneTransition3.nextNode = "closeup_demo";
  dialogueSystem.addNode("scene_transition3", sceneTransition3);

  DialogueNode closeupDemo = new DialogueNode(
    "天野靜樹", 
    "更厲害的是，我們還支援場景特寫效果！", 
    "park", 
    "amano", 
    "center", 
    "excited"
  );
  closeupDemo.addCommand("CLOSEUP", "park", "1.5", "2000");
  closeupDemo.nextNode = "ken_burns_demo";
  dialogueSystem.addNode("closeup_demo", closeupDemo);

  DialogueNode kenBurnsDemo = new DialogueNode(
    "天野靜樹", 
    "甚至還有電影級的Ken Burns效果！", 
    "park", 
    "amano", 
    "center", 
    "proud"
  );
  kenBurnsDemo.addCommand("KEN_BURNS", "park", "1.0", "1.8", "3000");
  kenBurnsDemo.nextNode = "back_to_menu";
  dialogueSystem.addNode("ken_burns_demo", kenBurnsDemo);

  // =========================
  // 音效系統示範
  // =========================
  
  DialogueNode audioDemo = new DialogueNode(
    "天野靜樹", 
    "現在來展示音效系統！雪櫻引擎支援BGM、音效和語音。", 
    "demo_room", 
    "amano", 
    "center", 
    "explain"
  );
  audioDemo.setTransition("fade");
  audioDemo.clearAllCharacters();
  audioDemo.nextNode = "bgm_demo";
  dialogueSystem.addNode("audio_demo", audioDemo);

  DialogueNode bgmDemo = new DialogueNode(
    "天野靜樹", 
    "首先是背景音樂切換...", 
    "demo_room", 
    "amano", 
    "center", 
    "normal"
  );
  bgmDemo.addCommand("CHANGE_BGM", "peaceful");
  bgmDemo.nextNode = "sfx_demo";
  dialogueSystem.addNode("bgm_demo", bgmDemo);

  DialogueNode sfxDemo = new DialogueNode(
    "天野靜樹", 
    "還有各種音效...", 
    "demo_room", 
    "amano", 
    "center", 
    "normal"
  );
  sfxDemo.addCommand("PLAY_SFX", "notification");
  sfxDemo.nextNode = "volume_demo";
  dialogueSystem.addNode("sfx_demo", sfxDemo);

  DialogueNode volumeDemo = new DialogueNode(
    "天野靜樹", 
    "音量也可以動態調整！", 
    "demo_room", 
    "amano", 
    "center", 
    "smile"
  );
  volumeDemo.addCommand("SET_VOLUME", "music", "0.5");
  volumeDemo.nextNode = "back_to_menu";
  dialogueSystem.addNode("volume_demo", volumeDemo);

  // =========================
  // 特殊效果示範
  // =========================
  
  DialogueNode effectsDemo = new DialogueNode(
    "天野靜樹", 
    "最後來看看特殊效果！雪櫻引擎內建多種視覺效果。", 
    "demo_room", 
    "amano", 
    "center", 
    "explain"
  );
  effectsDemo.setTransition("fade");
  effectsDemo.clearAllCharacters();
  effectsDemo.nextNode = "fade_effect";
  dialogueSystem.addNode("effects_demo", effectsDemo);

  DialogueNode fadeEffect = new DialogueNode(
    "天野靜樹", 
    "比如畫面淡入淡出效果...", 
    "demo_room", 
    "amano", 
    "center", 
    "normal"
  );
  fadeEffect.addCommand("FADE_TO_BLACK", "1000");
  fadeEffect.nextNode = "shake_effect";
  dialogueSystem.addNode("fade_effect", fadeEffect);

  DialogueNode shakeEffect = new DialogueNode(
    "天野靜樹", 
    "還有震動效果！", 
    "demo_room", 
    "amano", 
    "center", 
    "excited"
  );
  shakeEffect.addCommand("SCREEN_SHAKE", "15", "800");
  shakeEffect.nextNode = "text_speed_demo";
  dialogueSystem.addNode("shake_effect", shakeEffect);

  DialogueNode textSpeedDemo = new DialogueNode(
    "天野靜樹", 
    "文字顯示速度也能調整...", 
    "demo_room", 
    "amano", 
    "center", 
    "normal"
  );
  textSpeedDemo.addCommand("SET_TEXT_SPEED", "8");
  textSpeedDemo.nextNode = "back_to_menu";
  dialogueSystem.addNode("text_speed_demo", textSpeedDemo);

  // =========================
  // 返回選單
  // =========================
  
  DialogueNode backToMenu = new DialogueNode(
    "天野靜樹", 
    "怎麼樣？還想看其他功能嗎？", 
    "office", 
    "amano", 
    "center", 
    "question"
  );
  backToMenu.setTransition("fade");
  backToMenu.clearAllCharacters();
  backToMenu.addChoice("看其他功能", "demo_choice", 0, 0);
  backToMenu.addChoice("進階功能展示", "advanced_demo", 0, 0);
  backToMenu.addChoice("結束示範", "ending", 0, 0);
  dialogueSystem.addNode("back_to_menu", backToMenu);

  // =========================
  // 進階功能展示
  // =========================
  
  DialogueNode advancedDemo = new DialogueNode(
    "天野靜樹", 
    "那麼來看看一些進階功能！首先是複雜的多角色場景。", 
    "classroom", 
    "amano", 
    "far_left", 
    "explain"
  );
  advancedDemo.setTransition("slide_right");
  advancedDemo.nextNode = "multi_character_scene";
  dialogueSystem.addNode("advanced_demo", advancedDemo);

  DialogueNode multiCharacterScene = new DialogueNode(
    "天野靜樹", 
    "我們來創建一個五人的教室場景...", 
    "classroom", 
    "amano", 
    "far_left", 
    "normal"
  );
  multiCharacterScene.addCharacter("yuki", "left", "normal");
  multiCharacterScene.addCharacter("sakura", "center", "normal");
  multiCharacterScene.addCharacter("teacher", "right", "normal");
  multiCharacterScene.addCharacter("student", "far_right", "normal");
  multiCharacterScene.nextNode = "group_dialogue1";
  dialogueSystem.addNode("multi_character_scene", multiCharacterScene);

  DialogueNode groupDialogue1 = new DialogueNode(
    "老師", 
    "同學們，今天我們來學習雪櫻引擎的使用方法。", 
    "classroom", 
    "teacher", 
    "right", 
    "explain"
  );
  groupDialogue1.nextNode = "group_dialogue2";
  dialogueSystem.addNode("group_dialogue1", groupDialogue1);

  DialogueNode groupDialogue2 = new DialogueNode(
    "雪", 
    "哇～聽起來很有趣！", 
    "classroom", 
    "yuki", 
    "left", 
    "excited"
  );
  groupDialogue2.nextNode = "group_dialogue3";
  dialogueSystem.addNode("group_dialogue2", groupDialogue2);

  DialogueNode groupDialogue3 = new DialogueNode(
    "櫻", 
    "我也想學會製作自己的遊戲！", 
    "classroom", 
    "sakura", 
    "center", 
    "happy"
  );
  groupDialogue3.nextNode = "group_dialogue4";
  dialogueSystem.addNode("group_dialogue3", groupDialogue3);

  DialogueNode groupDialogue4 = new DialogueNode(
    "學生", 
    "這個引擎看起來功能很完整呢！", 
    "classroom", 
    "student", 
    "far_right", 
    "impressed"
  );
  groupDialogue4.nextNode = "chapter_demo";
  dialogueSystem.addNode("group_dialogue4", groupDialogue4);

  DialogueNode chapterDemo = new DialogueNode(
    "天野靜樹", 
    "引擎還支援章節系統，讓你的故事更有條理。", 
    "classroom", 
    "amano", 
    "far_left", 
    "explain"
  );
  chapterDemo.setChapter(2, "進階功能示範");
  chapterDemo.nextNode = "complex_choice";
  dialogueSystem.addNode("chapter_demo", chapterDemo);

  DialogueNode complexChoice = new DialogueNode(
    "天野靜樹", 
    "最後，我們來展示複雜的選擇分支系統。這個選擇會影響好感度！", 
    "classroom", 
    "amano", 
    "far_left", 
    "question"
  );
  complexChoice.addChoice("讚美雪櫻引擎很棒", "praise_engine", 2, 1);
  complexChoice.addChoice("詢問開發過程", "ask_development", 1, 0);
  complexChoice.addChoice("表達想學習的意願", "want_to_learn", 1, 2);
  dialogueSystem.addNode("complex_choice", complexChoice);

  DialogueNode praiseEngine = new DialogueNode(
    "天野靜樹", 
    "謝謝你的讚美！開發這個引擎確實花了我很多心血。", 
    "classroom", 
    "amano", 
    "far_left", 
    "happy"
  );
  praiseEngine.nextNode = "final_demo";
  dialogueSystem.addNode("praise_engine", praiseEngine);

  DialogueNode askDevelopment = new DialogueNode(
    "天野靜樹", 
    "開發過程很有挑戰性，但看到大家能用它創作，一切都值得了！", 
    "classroom", 
    "amano", 
    "far_left", 
    "proud"
  );
  askDevelopment.nextNode = "final_demo";
  dialogueSystem.addNode("ask_development", askDevelopment);

  DialogueNode wantToLearn = new DialogueNode(
    "天野靜樹", 
    "太好了！我相信你一定能創作出精彩的作品！", 
    "classroom", 
    "amano", 
    "far_left", 
    "excited"
  );
  wantToLearn.nextNode = "final_demo";
  dialogueSystem.addNode("want_to_learn", wantToLearn);

  DialogueNode finalDemo = new DialogueNode(
    "天野靜樹", 
    "最後，讓我們用一個特殊的結尾效果來結束這次示範！", 
    "classroom", 
    "amano", 
    "far_left", 
    "smile"
  );
  finalDemo.addCommand("KEN_BURNS", "classroom", "1.0", "2.0", "3000");
  finalDemo.addCommand("FADE_TO_BLACK", "2000");
  finalDemo.nextNode = "ending";
  dialogueSystem.addNode("final_demo", finalDemo);

  // =========================
  // 結尾
  // =========================
  
  DialogueNode ending = new DialogueNode(
    "天野靜樹", 
    "感謝您體驗雪櫻引擎的功能展示！", 
    "office", 
    "amano", 
    "center", 
    "bow"
  );
  ending.setTransition("fade");
  ending.clearAllCharacters();
  ending.nextNode = "ending2";
  dialogueSystem.addNode("ending", ending);

  DialogueNode ending2 = new DialogueNode(
    "天野靜樹", 
    "希望這個引擎能幫助你創作出屬於自己的精彩故事！", 
    "office", 
    "amano", 
    "center", 
    "smile"
  );
  ending2.nextNode = "credits";
  dialogueSystem.addNode("ending2", ending2);

  DialogueNode credits = new DialogueNode(
    "系統", 
    "雪櫻引擎 Ver 1.0.0\n開發者：天野靜樹\n\n感謝您的體驗！\n\n即將返回標題畫面...", 
    "office", 
    null, 
    null, 
    null
  );
  credits.nextNode = "return_to_title";
  dialogueSystem.addNode("credits", credits);

  DialogueNode returnToTitle = new DialogueNode(
    "系統", 
    "", 
    "office", 
    null, 
    null, 
    null
  );
  returnToTitle.addCommand("FADE_TO_BLACK", "2000");
  returnToTitle.addCommand("RETURN_TO_TITLE", "");
  dialogueSystem.addNode("return_to_title", returnToTitle);

}


PGraphics offscreenBuffer; 
float lastUpdateTimestamp; 

PImage sourceImage;
PImage orgSourceImage; 

AnimationController animationController; 
PixCollection pixCollection;   

TextAnimator textOverlayAnimator; 
PFont font;
PFont statusFont; 

boolean isFetchingImage = false; 
float lastImageTimestamp = 0.0f;
float lastStateTimestamp = 0.0f;
boolean requestedToUpdateImage = false; 

AnimationState animationState = AnimationState.Idle; 
int stateChangedCounter = 0; 

ProximityDetector proximityDetector;

boolean readyToTransitionNewColour = false;  
float readyToTransitionNewColourTimestamp = 0.0f; 

color currentMainColour = color(255,255,255); 
String currentColourName = "";
String currentImageId = "";

ConfigManager configManager; 
LocalService pairCommunicationService; 

private static PApplet pApplet;

public static PApplet MainPApplet(){    
  return pApplet;    
}

void setup() {   
    
  frameRate(FRAME_RATE);
  
  //size(720, 480, P2D);  
  //fullScreen(P2D);   
  size(720, 480);
  
  pApplet = this;
  
  noCursor();
  
  configManager = new ConfigManager();
  thread("initConfigManager"); 
  
  proximityDetector = createProximityDetector(); 
  
  iniSourceImage(); 
  
  surface.setResizable(false);
  
  animationController = new AnimationController(width, height); 
  //offscreenBuffer = createGraphics(width, height, P2D);    
  offscreenBuffer = createGraphics(width, height);
  lastUpdateTimestamp = millis();
  
  initOverlay();     
} 

void initConfigManager(){
  configManager.init();   
}

void initOverlay(){
  font = loadFont("Helvetica-70.vlw");
  statusFont = loadFont("courier-12.vlw");
  
  textOverlayAnimator = new TextAnimator(font, "");
  textOverlayAnimator.hide(); 
}

void iniSourceImage(){    
  float aspectRatio = (float)height/(float)width;      
  float w = min(configManager.offscreenBufferMaxWidth, width); 
  float h = w * aspectRatio; 
  
  println("iniSourceImage " + width + "x" + height + ", aspect ratio " + aspectRatio);  
  println("iniSourceImage - creating image with dimensions w " + w + "," + h); 
   
  sourceImage = createImage((int)w, (int)h, RGB);  
  orgSourceImage = createImage((int)w, (int)h, RGB);
  
  for(int i=0; i<sourceImage.pixels.length; i++){
      sourceImage.pixels[i] = color(255, 255, 255);
      orgSourceImage.pixels[i] = color(255, 255, 255);
  }  
}

void draw(){
  float et = millis() - lastUpdateTimestamp;
  lastUpdateTimestamp = millis(); 
  
  if(configManager.isFinishedInitilising()){
    pairCommunicationService = new LocalService(configManager);
    requestNextImage();    
  }
  
  if(pairCommunicationService != null){
    pairCommunicationService.update(et); 
  }
  
  if(!isFetchingImage && !readyToTransitionNewColour){
    if(animationState == AnimationState.TransitionIn){
      if(!textOverlayAnimator.isAnimating() && textOverlayAnimator.getState() == AnimationState.TransitionOut && animationController.getState() != AnimationState.TransitionIn){
        animationController.setState(AnimationState.TransitionIn);  
      }
    } else if(animationState == AnimationState.TransitionOut){
      if(!animationController.isAnimating() && animationController.getState() == AnimationState.TransitionOut && textOverlayAnimator.getState() != AnimationState.TransitionIn){
        textOverlayAnimator.setState(AnimationState.TransitionIn);       
      }
    }
  }
  
  offscreenBuffer.beginDraw();    
     
  animationController.draw(offscreenBuffer, et);
  textOverlayAnimator.draw(offscreenBuffer, et);
     
  if(SHOW_FRAME_RATE){
    offscreenBuffer.textAlign(LEFT, TOP);
    offscreenBuffer.fill(255, 255, 255, 255);
    offscreenBuffer.noStroke(); 
    offscreenBuffer.textFont(statusFont, 12);
    offscreenBuffer.text("FPS: " + frameRate, 20, 20);        
  }
  
  if(SHOW_DISTANCE){
    offscreenBuffer.textAlign(LEFT, TOP);
    offscreenBuffer.fill(255, 255, 255, 255);
    offscreenBuffer.noStroke(); 
    offscreenBuffer.textFont(statusFont, 12);
    offscreenBuffer.text("DISTANCE: " + proximityDetector.getDistance() + "(" + proximityDetector.updatesPerSecond + ")", 20, 50);
    //offscreenBuffer.text("DISTANCE: " + proximityDetector.rawDistance, 20, 50);    
  }
    
  offscreenBuffer.endDraw();
  
  image(offscreenBuffer, 0, 0, width, height);  
  
  if(readyToTransitionNewColour){
    float elapsedTime = millis() - readyToTransitionNewColourTimestamp; 
    if(elapsedTime >= 5000 && !textOverlayAnimator.isAnimating()){
      animationController.setPaused(false);
      textOverlayAnimator.text = currentColourName; 
      readyToTransitionNewColour = false; 
      setAnimationState(AnimationState.TransitionOut); 
    }
  }    
  
  if(isReadyForNewImage()){        
    requestNextImage();     
  } 
  
  if(isReadyToPollDistance()){
    pollDistance();     
  }
  
  thread("updateConfigManager"); 
}

void updateConfigManager(){
  configManager.update(currentImageId, stateChangedCounter);
}

boolean isReadyForNewImage(){ 
  boolean inValidState = !isFetchingImage && !readyToTransitionNewColour && animationState == AnimationState.TransitionOut && !animationController.isAnimating();  
  boolean enoughTimeElapsed = millis() - lastImageTimestamp >= configManager.imageUpdateFrequency && configManager.isMaster();
  boolean enoughTimeElapsedSinceStateChange = millis() - lastStateTimestamp >= configManager.elapsedStateIdleTimeBeforeImageUpdate;  
  
  return inValidState && (enoughTimeElapsed || requestedToUpdateImage) && enoughTimeElapsedSinceStateChange; 
}

boolean isReadyToPollDistance(){
  boolean inValidState =  !isFetchingImage && !readyToTransitionNewColour && proximityDetector.isReady(); 
  return inValidState; 
}

void pollDistance(){
  thread("updateProximityDetector"); 
  
  ProximityRange currentRange = proximityDetector.getCurrentRange(); 
  boolean inProximity = currentRange != ProximityRange.Far && currentRange != ProximityRange.Undefined;
  if(inProximity && (animationState == AnimationState.Idle || animationState == AnimationState.TransitionOut)){
    setAnimationState(AnimationState.TransitionIn);   
  } else if(!inProximity && (animationState == AnimationState.Idle || animationState == AnimationState.TransitionIn)){
    setAnimationState(AnimationState.TransitionOut);
  }
  
  animationController.unlockLastFrame = currentRange == ProximityRange.Close;
}

void updateProximityDetector(){
  proximityDetector.update();     
}

boolean isValidToTransitionState(){
  return !isFetchingImage;  
}

void keyPressed() {
  if(proximityDetector.onKeyDown(keyCode)){
    return;   
  }
  
  if(keyCode == 78 && !isFetchingImage){ // n
    fetchNextImage(); 
  } else if(keyCode == 68){ // d
    pollDistance(); 
  }
}

void setFetchingImage(boolean val){
  isFetchingImage = val;     
  
  if(!val){    
    readyToTransitionNewColour = true;
    readyToTransitionNewColourTimestamp = millis();  
    textOverlayAnimator.setState(AnimationState.TransitionOut);
  } else{
    requestedToUpdateImage = false; // reset flag  
    
    if(animationController != null)
      animationController.setPaused(true);  
  }
}

void setColourDetails(color mainColour, String colourName, String imageId){
  currentMainColour = mainColour; 
  currentColourName = colourName; 
  currentImageId = imageId; 
  
  configManager.currentImageId = imageId; 
  
  if(pairCommunicationService != null){
    pairCommunicationService.updatePairsOfNewImageId(configManager.currentImageId);   
  }
}

AnimationState getAnimationState(){
  return animationState;   
}

void setAnimationState(AnimationState state){
  AnimationState previousAnimationState = animationState;  
  animationState = state; 
  boolean changedState = previousAnimationState != animationState; 
  
  stateChangedCounter += changedState ? 1 : 0; 
  
  if(changedState){
    lastStateTimestamp = millis();
  }
  
  if(state == AnimationState.TransitionOut){       
      animationController.setState(state); 
  } else if(state == AnimationState.TransitionIn){
      textOverlayAnimator.setState(AnimationState.TransitionOut);
  }
}

void setPixCollectionAnimationForNewColourTransition(){
  if(pixCollection == null){
    return;   
  }
  
  for(int y=0; y<pixCollection.sourceYRes; y++){
    for(int x=0; x<pixCollection.sourceXRes; x++){
      Pix pix = pixCollection.pixies[y][x];
      
      // set source colour and animation time for LEVEL 0
      float index = y * pixCollection.sourceXRes + x;   
      float animTimeForLevel0 = 10.0f + index * 1.5f;
      pix.setAnimTime(animTimeForLevel0, 0);
    }
  } 
}

void resetPixCollectionAnimation(){
  if(pixCollection == null){
    return;   
  }
  
  for(int y=0; y<pixCollection.sourceYRes; y++){
    for(int x=0; x<pixCollection.sourceXRes; x++){
      Pix pix = pixCollection.pixies[y][x];
      
      // set source colour and animation time for LEVEL 0
      float index = y * pixCollection.sourceXRes + x;
      float animTimeForLevel0 = 500.0f;                  
      pix.setAnimTime(animTimeForLevel0, 0);
    }
  } 
}
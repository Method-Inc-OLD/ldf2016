import java.util.*; 

PGraphics offscreenBuffer; 
float lastUpdateTimestamp; 

int srcImageWidth; 
int srcImageHeight; 
PImage srcColourisedImage;
PImage srcfullColourImage; 

PixCollection pixCollection;   
AnimationController animationController; 

TextAnimator textOverlayAnimator; 
PFont font;
PFont statusFont; 

float imageUpdatedTimestamp = 0.0f; 
float lastStateTimestamp = 0.0f;
boolean requestedToUpdateImage = false; 

AnimationState animationState = AnimationState.Idle; 
int stateChangedCounter = 0; 

ProximityDetector proximityDetector;

LDFServiceAPI ldfService;

boolean preparingToTransitionNewColour = false; 
boolean readyToTransitionNewColour = false;  
float readyToTransitionNewColourTimestamp = 0.0f; 

int isReadyToMoveToNextImageScore = 0; 

ConfigManager configManager; 

LocalService pairCommunicationService; 

private static PApplet pApplet;

public static PApplet MainPApplet(){    
  return pApplet;    
}

void setup() { 
    
  frameRate(FRAME_RATE);  
  //size(720, 480, P2D);  
  size(720, 480);
  //fullScreen(P2D);
  
  surface.setResizable(false);
  
  pApplet = this;
  
  noCursor();    
  
  initConfigManager();     
  
  initProximityDetector();
  
  iniSourceDimensions();    
  
  initLDFService(); 
    
  initAnimationController(); 
  
  initFontsAndTextOverlay();
  
  //offscreenBuffer = createGraphics(width, height, P2D);  
  offscreenBuffer = createGraphics(width, height);
  
  lastUpdateTimestamp = millis();     
} 

void initConfigManager(){
  configManager = new ConfigManager();
  thread("asyncInitConfigManager");  
}

void asyncInitConfigManager(){
  configManager.init();     
}

void initProximityDetector(){  
  //proximityDetector = new MockProximityDetector();  
  proximityDetector = new UltrasonicProximityDetector();
  
  thread("_initProximityDetector"); 
}

void _initProximityDetector(){
  proximityDetector.init();     
}

void initFontsAndTextOverlay(){
  font = loadFont("Jungka-Medium-70.vlw");
  statusFont = loadFont("courier-12.vlw");
  
  textOverlayAnimator = new TextAnimator(font, "");
  textOverlayAnimator.hide(); 
}

void initAnimationController(){
  animationController = new AnimationController(width, height);  
}

void iniSourceDimensions(){    
  float aspectRatio = (float)height/(float)width;      
  srcImageWidth  = (int)(min(configManager.offscreenBufferMaxWidth, width)); 
  srcImageHeight = (int)(srcImageWidth * aspectRatio);      
}

void initLDFService(){
  ldfService = new LDFServiceAPI(srcImageWidth, srcImageHeight); 
}

void draw(){
  float et = millis() - lastUpdateTimestamp;
  lastUpdateTimestamp = millis(); 
  
  if(configManager.isFinishedInitilising()){
    println("finished initlising");    
    startPollDistanceThread();
    
    pairCommunicationService = new LocalService(configManager);    
    
    requestNextImage();    
  } 
  
  if(pairCommunicationService != null){
    pairCommunicationService.update(et); 
  }
  
  if(!readyToTransitionNewColour){
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
     
  if(configManager.showFrameRate){
    offscreenBuffer.textAlign(LEFT, TOP);
    offscreenBuffer.fill(255, 255, 255, 255);
    offscreenBuffer.noStroke(); 
    offscreenBuffer.textFont(statusFont, 12);
    offscreenBuffer.text("FPS: " + frameRate, 20, 20);        
  }
  
  if(configManager.showDistance){
    offscreenBuffer.textAlign(LEFT, TOP);
    offscreenBuffer.fill(255, 255, 255, 255);
    offscreenBuffer.noStroke(); 
    offscreenBuffer.textFont(statusFont, 12);
    offscreenBuffer.text("DISTANCE: " + proximityDetector.getDistance() + "(" + proximityDetector.updatesPerSecond + ")", 20, 50);    
  }
    
  offscreenBuffer.endDraw();
  
  image(offscreenBuffer, 0, 0, width, height);  
  
  // rendering the text over the tiles (outside the OpenGL context) to resolve the bug of 
  // certain characters being missing from the text 
  textOverlayAnimator.draw(this.g, et);
  
  if(preparingToTransitionNewColour){
    if(isReadyToMoveToNextImage()){      
      moveToNextImage();            
    } 
  }
  else if(readyToTransitionNewColour){
    float elapsedTime = millis() - readyToTransitionNewColourTimestamp; 
    if(elapsedTime >= 5000 && !textOverlayAnimator.isAnimating()){
      animationController.setPaused(false);
      textOverlayAnimator.text = ldfService.getColourName(); 
      readyToTransitionNewColour = false; 
      setAnimationState(AnimationState.TransitionOut); 
    }
  }    
  
  if(isReadyForNewImage()){        
    requestNextImage();     
  } 
  
  if(configManager.isInitilised()){
    thread("updateConfigManager"); 
  }
}

void updateConfigManager(){
  configManager.update(stateChangedCounter);
}

boolean isReadyToMoveToNextImage(){
  if(configManager.currentImageId.length() == 0){
    return true;   
  }
  
  if(configManager.isMaster()){
    // here we are keeping a 'score' (isReadyToMoveToNextImageScore) to ensure the system is stable and settled before 
    // jumping to the next image i.e. we a slave has JUST transitioned to TransitionOut we want to wait a few 'ticks' to ensure 
    // that the environment is 'stable' (remove noise) 
    
    // if all pairs are in a transition out and have the same image 
    for(int i=0; i<configManager.getPairCount(); i++){
      Pair p = configManager.getPairAtIndex(i); 
      if(!p.currentImageId.equals(ldfService.getImageId())){
        isReadyToMoveToNextImageScore = 0; 
        return false;   
      }
      
      if(p.currentAnimationState == AnimationState.TransitionIn.getValue()){
        isReadyToMoveToNextImageScore = 0; 
        return false;   
      }
    }        
    
    if(animationState == AnimationState.TransitionOut){
      isReadyToMoveToNextImageScore += 1; 
    } else{
      isReadyToMoveToNextImageScore = 0;   
    }
    
    return isReadyToMoveToNextImageScore >= 5; 
  } else{
    if(configManager.getMaster().currentAction != LocalService.ACTION_UPDATE_IMAGE){
      return false;   
    }
    
    return animationState == AnimationState.TransitionOut;
  }
}

boolean isReadyForNewImage(){ 
  boolean inValidState = !ldfService.isFetchingImage() && !readyToTransitionNewColour && animationState == AnimationState.TransitionOut && !animationController.isAnimating();
  boolean alreadyHasNewImage = !configManager.currentImageId.equals(ldfService.getImageId()); 
  boolean enoughTimeElapsed = (millis() - imageUpdatedTimestamp) >= configManager.imageUpdateFrequency && configManager.isMaster();
  boolean enoughTimeElapsedSinceStateChange = millis() - lastStateTimestamp >= configManager.elapsedStateIdleTimeBeforeImageUpdate;  
  
  return inValidState && !alreadyHasNewImage && (enoughTimeElapsed || requestedToUpdateImage) && enoughTimeElapsedSinceStateChange; 
}

void startPollDistanceThread(){
  println("startPollDistanceThread"); 
  thread("updateProximityDetector");    
}

void updateProximityDetector(){  
  
  while(true){  
    int start = millis();     
    proximityDetector.update();
    int et = millis() - start; 
    if(et < 500){
      delay(500-et);     
    }
  }      
}

void onProximityChanged(ProximityRange currentRange){  
  if(animationController == null){
    return;   
  }
  
  boolean inProximity = currentRange != ProximityRange.Far && currentRange != ProximityRange.Undefined;
  if(inProximity && (animationState == AnimationState.Idle || animationState == AnimationState.TransitionOut)){
    setAnimationState(AnimationState.TransitionIn);   
  } else if(!inProximity && (animationState == AnimationState.Idle || animationState == AnimationState.TransitionIn)){
    setAnimationState(AnimationState.TransitionOut);
  }
  
  animationController.unlockLastFrame = currentRange == ProximityRange.Close;  
}

void keyPressed() {
  if(proximityDetector.onKeyDown(keyCode)){
    return;   
  }
  
  if(keyCode == 78){ // n
    requestNextImage(); 
  } 
}

void onImageFetchComplete(LDFServiceAPI caller){ 
  println("onImageFetchComplete");
  isReadyToMoveToNextImageScore = 0; 
  preparingToTransitionNewColour = true; 
  
  if(pairCommunicationService != null){
    pairCommunicationService.updatePairsOfNewImageId(ldfService.getImageId());   
  }
}

void onImageFetchFailed(LDFServiceAPI caller){
  println("onImageFetchFailed");
}

void moveToNextImage(){
  preparingToTransitionNewColour = false;  
  imageUpdatedTimestamp = millis(); 
  
  if(pixCollection == null){
    pixCollection = createPixCollection(configManager.resolutionX, configManager.resolutionY, (int)width, (int)height, configManager.levelsOfDetail, ldfService.sampleImage, ldfService.getColour());   
  } else{
    initPixCollection(pixCollection, ldfService.sampleImage, ldfService.getColour());
  }
    
  animationController.init(ldfService.colourisedImage, ldfService.fullColourImage, pixCollection);
  
  configManager.currentImageId = ldfService.getImageId();
  readyToTransitionNewColour = true;
  readyToTransitionNewColourTimestamp = millis();  
  textOverlayAnimator.setState(AnimationState.TransitionOut);
  
  if(configManager.isMaster()){
    pairCommunicationService.updatePairsOfAction(LocalService.ACTION_UPDATE_IMAGE);     
  }
}

void requestNextImage(){
  println("requestNextImage");
  requestedToUpdateImage = false;   // reset flag 
  ldfService.requestNextImage(); 
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
    if(pairCommunicationService != null){
      pairCommunicationService.updatePairsOfNewAnimationState(state.getValue());
    }
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
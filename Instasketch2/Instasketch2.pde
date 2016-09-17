import java.util.*; 

enum AppState{
  Undefined, 
  Initilising, 
  FetchingFirstImage, 
  Interactive, 
  TransitioningOutImage, 
  TransitioningInNewImage
}

PGraphics offscreenBuffer; 
float lastUpdateTimestamp; 

int srcImageWidth; 
int srcImageHeight; 
PImage srcColourisedImage;
PImage srcfullColourImage; 

PixCollection pixCollection;   
AnimationController animationController; 

PFont statusFont; 

float imageUpdatedTimestamp = 0.0f; 
float lastStateTimestamp = 0.0f;
boolean requestedToFetchNextImage = false; 
boolean requestedToTransitionToNextImage = false;

AppState appState = AppState.Undefined;
AnimationState animationState = AnimationState.Idle; 
int stateChangedCounter = 0;  

ConfigManager configManager; 

ProximityDetector proximityDetector;

LDFServiceAPI ldfService;

LocalService pairCommunicationService; 

private static PApplet pApplet;

private boolean requestRetryToFetchImage = false; 

public static PApplet MainPApplet(){    
  return pApplet;    
}

void setup() { 
    
  frameRate(FRAME_RATE);    
  size(720, 480); 
  surface.setResizable(false);  
  pApplet = this;  
  noCursor();    
  
  setAppState(AppState.Initilising);      
  
  lastUpdateTimestamp = millis();     
} 

void init(){
  initConfigManager();     
  
  initProximityDetector();
  
  iniSourceDimensions();    
  
  initLDFService(); 
    
  initAnimationController(); 
  
  initFonts();
  
  offscreenBuffer = createGraphics(width, height);
}

void initConfigManager(){
  configManager = new ConfigManager();
  thread("asyncInitConfigManager");  
}

void asyncInitConfigManager(){
  configManager.init();     
}

void initProximityDetector(){  
  proximityDetector = new MockProximityDetector();  
  //proximityDetector = new UltrasonicProximityDetector();
  
  thread("_initProximityDetector"); 
}

void _initProximityDetector(){
  proximityDetector.init();     
}

void initFonts(){
  statusFont = loadFont("courier-12.vlw");    
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
  
  onPreDraw(et); 
  
  onDraw(et);  
  
  onPostDraw(et);     
}

void onPreDraw(float et){
    
  if(getAppState() == AppState.Initilising){
    if(configManager.isInitilised()){      
      setAppState(AppState.FetchingFirstImage);                  
    }
  } 
  
  if(getAppState() != AppState.Initilising && pairCommunicationService != null){
    pairCommunicationService.update(et); 
  }
  
  if(requestRetryToFetchImage){
    requestRetryToFetchImage = false; 
    requestNextImage(); 
  }
}

void onDraw(float et){
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
}

void onPostDraw(float et){
  if(getAppState() == AppState.Initilising){
    return;     
  }    
  
  if(getAppState() == AppState.TransitioningOutImage){
    if(!animationController.isAnimating()){
      setAppState(AppState.TransitioningInNewImage);    
    }
  }
  
  else if(getAppState() == AppState.TransitioningInNewImage){
    if(!animationController.isAnimating()){
      setAppState(AppState.Interactive);  
    }
  }
  
  else if(getAppState() == AppState.Interactive){
    if(isValidToFetchNextImage()){
      requestNextImage();   
    }
    
    checkProximityChanges(); 
  }
  
  if(isNewImageAvailable()){
    if(getAppState() == AppState.FetchingFirstImage){
      setAppState(AppState.TransitioningInNewImage); 
    } 
    
    else if(getAppState() == AppState.Interactive && isValidToTransitionInNewImage()){
      setAppState(AppState.TransitioningOutImage);    
    }
  }
  
  if(configManager.isInitilised() && configManager.isReadyForUpdate()){
    thread("asyncUpdateConfigManager"); 
  }
}

void checkProximityChanges(){
  boolean inProximity = proximityDetector.currentRange != ProximityRange.Far && proximityDetector.currentRange != ProximityRange.Undefined;
  if(inProximity && (animationState == AnimationState.Idle || animationState == AnimationState.TransitionOut)){
    setAnimationState(AnimationState.TransitionIn);   
  } else if(!inProximity && (animationState == AnimationState.Idle || animationState == AnimationState.TransitionIn)){
    setAnimationState(AnimationState.TransitionOut);
  }
  
  animationController.unlockLastFrame = proximityDetector.currentRange == ProximityRange.Close;  
}

void asyncUpdateConfigManager(){
  configManager.update(stateChangedCounter);
}

void setRequestedToFetchNextImage(boolean val){
  if(getAppState() != AppState.Initilising && getAppState() != AppState.FetchingFirstImage){
    requestedToFetchNextImage = val;   
  }
}

void setRequestedToTransitionToNextImage(boolean val){
  if(getAppState() != AppState.Initilising && getAppState() != AppState.FetchingFirstImage){
    requestedToTransitionToNextImage = val;   
  }
}

boolean isValidToFetchNextImage(){
  if(ldfService.isFetchingImage())
    return false;   
  
  if(configManager.isMaster()){
    return (millis() - imageUpdatedTimestamp) >= configManager.imageUpdateFrequency 
      && ldfService.getTimeSinceLastImageUpdate() >= configManager.imageUpdateFrequency 
        && !isNewImageAvailable();  
  } else{
    if(requestedToFetchNextImage){
      requestedToFetchNextImage = false; 
      return true; 
    }    
  }
  
  return false; 
}

boolean isValidToTransitionInNewImage(){
  if(getAnimationState() != AnimationState.TransitionOut){
    println("isValidToTransitionInNewImage = FALSE - AnimState = TransitionIn"); 
    return false;   
  }
  
  if(configManager.isMaster()){
    for(int i=0; i<configManager.getPairCount(); i++){
      Pair p = configManager.getPairAtIndex(i); 
      if(p.waitingForImage){ 
        println("Waiting for " + p.index + " to fetching the latest image");
        return false;   
      }
      
      if(p.currentAnimationState == AnimationState.TransitionIn.getValue()){
        println("Waiting for " + p.index + " to be in the right anim state");
        return false;   
      }
    } 
    
    return true; 
  } else{
    if(requestedToTransitionToNextImage){
      requestedToTransitionToNextImage = false;
      return true; 
    }    
    
    return false; 
  }
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
    if(et < 700){
      delay(700-et);     
    }
  }      
}

void onProximityChanged(ProximityRange currentRange){  
    
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
  
  if(pairCommunicationService != null){
    pairCommunicationService.updatePairsOfNewImageId(ldfService.getImageId(), ldfService.imageCounter);   
  }
}

void onImageFetchFailed(LDFServiceAPI caller){
  println("onImageFetchFailed");
  requestRetryToFetchImage = true; 
}

boolean isNewImageAvailable(){
  if(ldfService == null || ldfService.isFetchingImage())
    return false; 
  
  return !ldfService.getImageId().equals(configManager.currentImageId);
}

void requestNextImage(){
  println("requestNextImage"); 
  ldfService.requestNextImage(); 
}

AppState getAppState(){
  return appState;   
}

void setAppState(AppState state){
  println("updating AppState from " + appState + " to " + state);
  appState = state; 
  
  if(appState == AppState.Initilising){
    init();   
  } 
  
  else if(appState == AppState.FetchingFirstImage){
    startPollDistanceThread();    
    pairCommunicationService = new LocalService(configManager);    
    requestNextImage();    
  } 
  
  else if(appState == AppState.TransitioningOutImage){    
    ((TextOverlayAnimator)animationController.getAnimatorAtIndex(0)).textAnimator.setState(AnimationState.TransitionIn);
    
    if(configManager.isMaster()){
      pairCommunicationService.updatePairsOfAction(LocalService.ACTION_UPDATE_IMAGE);     
    }
  } 
  
  else if(appState == AppState.TransitioningInNewImage){
    imageUpdatedTimestamp = millis();
  
    if(pixCollection == null)
      pixCollection = createPixCollection(configManager.resolutionX, configManager.resolutionY, (int)width, (int)height, configManager.levelsOfDetail, ldfService.sampleImage, ldfService.getColour());   
    else
      initPixCollection(pixCollection, ldfService.sampleImage, ldfService.getColour());
    
    animationController.init(ldfService.colourisedImage, ldfService.fullColourImage, pixCollection, ldfService.getColourName());  
    configManager.currentImageId = ldfService.getImageId();           
    
    setAnimationState(AnimationState.TransitionOut);        
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
    if(pairCommunicationService != null){
      pairCommunicationService.updatePairsOfNewAnimationState(state.getValue());
    }
  }
  
  animationController.setState(state);
}
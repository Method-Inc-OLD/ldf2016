

PGraphics offscreenBuffer; 
float lastUpdateTimestamp; 

PImage sourceImage;
PImage orgSourceImage; 

AnimationController animationController; 
PixCollection pixCollection; 

int myPaletteIndex = 3; // will be a constant when released  

TextAnimator textOverlayAnimator; 
PFont font;

boolean isFetchingImage = false; 
float lastImageTimestamp = 0.0f;
float lastStateTimestamp = 0.0f; 

AnimationState animationState = AnimationState.Idle; 

void setup() {   
    
  frameRate(FRAME_RATE);
  //frameRate(2);
  size(1920, 1080, P2D);  
  //fullScreen(P2D);
  
  iniSourceImage(); 
  
  surface.setResizable(false);
  
  animationController = new AnimationController(width, height); 
  offscreenBuffer = createGraphics(width, height, P2D);    
  lastUpdateTimestamp = millis();
  
  initOverlay(); 
  
  requestNextImage(); 
} 

void initOverlay(){
  font = loadFont("helvetica-220.vlw");
  
  textOverlayAnimator = new TextAnimator(font, "");
  textOverlayAnimator.hide(); 
}

void iniSourceImage(){
  float aspectRatio = (float)height/(float)width;
  float w = min(OFFSCREEN_BUFFER_MAX_WIDTH, width); 
  float h = w * aspectRatio; 
  
  println("initDrawImages - creating image with dimensions w " + w + "," + h); 
   
  sourceImage = createImage((int)w, (int)h, RGB);  
  orgSourceImage = createImage((int)w, (int)h, RGB);
  
  for(int i=0; i<sourceImage.pixels.length; i++){
      sourceImage.pixels[i] = color(255, 255, 255);
      orgSourceImage.pixels[i] = color(255, 255, 255);
  }  
}

int dir = 1; 

void draw(){
  float et = millis() - lastUpdateTimestamp;
  lastUpdateTimestamp = millis();
  
  if(!isFetchingImage){
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
    offscreenBuffer.textSize(9);
    offscreenBuffer.textAlign(LEFT, TOP);
    offscreenBuffer.fill(0, 0, 0);
    offscreenBuffer.text(frameRate, 20, 20);
  }
    
  offscreenBuffer.endDraw();
  
  image(offscreenBuffer, 0, 0, width, height);  
  
  if(isReadyForNewImage()){
    requestNextImage();     
  }    
}

boolean isReadyForNewImage(){
  //println("animationController.isAnimating() " + animationController.isAnimating()); 
  boolean inValidState = !isFetchingImage && animationState == AnimationState.TransitionOut && !animationController.isAnimating(); 
  boolean enoughTimeElapsed = millis() - lastImageTimestamp >= IMAGE_UPDATE_FREQUENCY;
  boolean enoughTimeElapsedSinceStateChange = millis() - lastStateTimestamp >= STATE_TIME_ELAPSED_FOR_IMAGE_UPDATE_THRESHOLD; 
  
  return inValidState && enoughTimeElapsed && enoughTimeElapsedSinceStateChange; 
}

boolean isValidToTransitionState(){
  return !isFetchingImage;  
}

void keyPressed() {
  if(keyCode == UP || keyCode == DOWN){
    if(animationController.getState() == AnimationState.Idle && isValidToTransitionState()){
      setAnimationState(AnimationState.TransitionIn);   
    } else if(animationController.getState() == AnimationState.TransitionIn && isValidToTransitionState()){
      setAnimationState(AnimationState.TransitionOut);
    } else if(animationController.getState() == AnimationState.TransitionOut && isValidToTransitionState()){
      setAnimationState(AnimationState.TransitionIn);      
    }
  }
}

void setFetchingImage(boolean val){
  isFetchingImage = val;     
  
  //textOverlayAnimator.setState(isFetchingImage ? AnimationState.TransitionOut : AnimationState.TransitionIn);
  
  if(!val){
    textOverlayAnimator.setState(AnimationState.TransitionOut); 
    setAnimationState(AnimationState.TransitionOut);   
  }
}

void setColourDetails(color mainColour, String colourName){
  textOverlayAnimator.text = colourName;   
}

AnimationState getAnimationState(){
  return animationState;   
}

void setAnimationState(AnimationState state){
  animationState = state; 
  lastStateTimestamp = millis(); 
  
  if(state == AnimationState.TransitionOut){
      animationController.setState(state); 
  } else if(state == AnimationState.TransitionIn){
      textOverlayAnimator.setState(AnimationState.TransitionOut);
  }
}
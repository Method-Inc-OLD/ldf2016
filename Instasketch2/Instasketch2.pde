

PGraphics offscreenBuffer; 
float lastUpdateTimestamp; 

PImage sourceImage;
PImage orgSourceImage; 

AnimationController animationController; 
PixCollection pixCollection; 

int myPaletteIndex = 3; // will be a constant when released  

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
  
  requestNextImage(); 
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
  
  offscreenBuffer.beginDraw();
  
  animationController.draw(offscreenBuffer, et);
  
  if(SHOW_FRAME_RATE){
    offscreenBuffer.fill(0, 0, 0);
    offscreenBuffer.text(frameRate, 20, 20);
  }
    
  offscreenBuffer.endDraw();
  
  image(offscreenBuffer, 0, 0, width, height);  
}

void keyPressed() {
  if(keyCode == UP || keyCode == DOWN){
    if(animationController.getState() == AnimationState.Idle){
      animationController.setState(AnimationState.TransitionIn);   
    } else if(animationController.getState() == AnimationState.TransitionIn){
      animationController.setState(AnimationState.TransitionOut);
    } else if(animationController.getState() == AnimationState.TransitionOut){
      animationController.setState(AnimationState.TransitionIn);      
    }
  }
}
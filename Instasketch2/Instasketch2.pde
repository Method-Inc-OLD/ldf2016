

PGraphics offscreenBuffer; 
float lastUpdateTimestamp; 

PImage sourceImage;

PixCollection pixCollection; 

int myPaletteIndex = 3; // will be a constant when released  

void setup() {   
    
  frameRate(FRAME_RATE);
  size(960, 540, P2D);  
  //fullScreen(P2D);
  
  iniSourceImage(); 
  
  surface.setResizable(false);
  
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
  
  for(int i=0; i<sourceImage.pixels.length; i++){
      sourceImage.pixels[i] = color(255, 255, 255); 
  }  
}

int dir = 1; 

void draw(){
  float et = millis() - lastUpdateTimestamp;
  lastUpdateTimestamp = millis(); 
  
  if(!isFetchingImage && pixCollection != null){
    offscreenBuffer.beginDraw();    
    pixCollection.draw(offscreenBuffer, et); 
    
    offscreenBuffer.endDraw();
    
    offscreenBuffer.fill(0, 0, 0);
    offscreenBuffer.text(frameRate, 20, 20);
    
    image(offscreenBuffer, 0, 0, width, height);
    
    if(!pixCollection.isAnimating()){
      int nextLevel = pixCollection.currentLevel; 
      nextLevel += dir;
      
      if(nextLevel < pixCollection.levels){
          pixCollection.setLevel(nextLevel);
      }
      
      //if(nextLevel < 0){
      //  nextLevel += 2; 
      //  dir = -dir;         
      //} else if(nextLevel >= pixCollection.levels){
      //  nextLevel -= 2; 
      //  dir = -dir;    
      //}
      
      //pixCollection.setLevel(nextLevel);
            
    }
  } else{
    //background(255);   
  }
  
  /*if(SHOW_FRAME_RATE){
    fill(255, 255, 255);
    text(frameRate, 20, 20); 
  }*/
  
}
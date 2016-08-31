
 int PALETTE_INDEX = 3;
 
boolean fetchingImage = false; 

PImage sourceImage = null; 

float lastUpdateTimestamp = millis(); 
float stateChangedTimestamp = millis();
float lastImageTimestamp = millis();

float currentProximityDistance = 0;  

PixelRenderer currentPixelRenderer; 
PImageBuffer offscreenBuffer; 

State previousState = State.Undefined;
State currentState = State.Undefined;

ProximityRange previousProximityRange = ProximityRange.Far; 
ProximityRange currentProximityRange = ProximityRange.Far; 

float tmpTimestamp = 0;  

UltrasonicSensor ultrasonicSensor; 

int sourceImageAlpha = 0; 

void setup() {    
  //fullScreen();
  size(800, 600);  
  
  surface.setResizable(false);
  
  initDrawImages(); 
  
  initUltrasonicSensor(); 
  
  lastUpdateTimestamp = millis();
  
  requestNextImage();
}   

void initDrawImages(){
  float aspectRatio = (float)height/(float)width;
  float w = min(OFFSCREEN_BUFFER_MAX_WIDTH, width); 
  float h = w * aspectRatio; 
  
  println("initDrawImages - creating image with dimensions w " + w + "," + h); 
   
  sourceImage = createImage((int)w, (int)h, RGB);  
  offscreenBuffer = new PImageBuffer((int)w, (int)h, RGB); 
  
  for(int i=0; i<offscreenBuffer.length; i++){
      offscreenBuffer.setPixel(i, color(255, 255, 255));
      sourceImage.pixels[i] = color(255, 255, 255); 
  }
}

void initUltrasonicSensor(){
  ultrasonicSensor = new UltrasonicSensor();   
}

void setState(State state){
  previousState = currentState; 
  currentState = state; 
  stateChangedTimestamp = millis();
  
  onStateChanged();   
}

void onStateChanged(){
  println("onStateChanged " + currentState); 
  
  if(currentState == State.TransitioningIn){
    sourceImageAlpha = 0;   
  }  
}

void setPixelRenderer(PixelRenderer pixelRenderer){
  currentPixelRenderer = pixelRenderer;  
  if(currentPixelRenderer != null){
    currentPixelRenderer.setLevel(0);   
  }
}

void setProximityRange(ProximityRange proximityRange){
  previousProximityRange = currentProximityRange; 
  currentProximityRange = proximityRange;
    
  if(previousProximityRange != currentProximityRange){
    onProximityRangeChanged();  
  }  
}

void onProximityRangeChanged(){
  println("onProximityRangeChanged " + currentProximityRange); 
  if(currentProximityRange == ProximityRange.Far || currentProximityRange == ProximityRange.MediumFar){
    if(currentState != State.IdleOut && currentState != State.TransitioningOut){
      setState(State.TransitioningOut);     
    }      
  }
  
  if(currentProximityRange == ProximityRange.Medium || currentProximityRange == ProximityRange.Close){
    if(currentState != State.IdleIn && currentState != State.TransitioningIn){
      setState(State.TransitioningIn);     
    }      
  }
}

void markStartTime(){
  tmpTimestamp = millis();   
}

float markEndTime(){
  float et = millis() - tmpTimestamp; 
  tmpTimestamp = millis(); 
  return et;    
}

void draw() {    
  float et = millis() - lastUpdateTimestamp;
  lastUpdateTimestamp = millis(); 
  
  imageUpdateCheck(); 
  
  distanceUpdateCheck(); 

  updateState(); 
  
  if(currentPixelRenderer != null){
    // TODO: fix hack 
    if(currentState == State.IdleIn){
      sourceImageAlpha += 10;
      sourceImageAlpha = clamp(sourceImageAlpha, 0, 255);      
    } else if(currentState == State.TransitioningOut && sourceImageAlpha > 0){
      sourceImageAlpha -= 10; 
      sourceImageAlpha = clamp(sourceImageAlpha, 0, 255);
    } else{
      currentPixelRenderer.update(et);  
    }    
    
    // draw
    tint(255, 255);
    image(currentPixelRenderer.getImage(), 0, 0, width, height);       
    
    if(sourceImageAlpha > 5){
      tint(255, sourceImageAlpha); 
      image(sourceImage, 0, 0, width, height);  
    }
    
    //image(sourceImage, 0, 0, width, height);
  } else{
    background(255);  
  }
  
  lastUpdateTimestamp = millis(); 
}

void keyPressed() {
  ultrasonicSensor.onKeyDown(keyCode);  // for development  
}

void updateState(){
  if(currentPixelRenderer == null){
    return;   
  }
  
  // state update
  if(!fetchingImage){
    if(!currentPixelRenderer.isAnimating()){
      if(currentState == State.TransitionToNewImage){
        setState(State.IdleOut);   
      } else if(currentState == State.TransitioningIn){
        if(currentPixelRenderer.currentLevel < currentPixelRenderer.size()-1){
          currentPixelRenderer.setLevel(currentPixelRenderer.currentLevel+1);   
        } else{
          setState(State.IdleIn);   
        }
      } else if(currentState == State.TransitioningOut){
        if(currentPixelRenderer.currentLevel > 0){
          currentPixelRenderer.setLevel(currentPixelRenderer.currentLevel-1);   
        } else{
          setState(State.IdleOut); 
        }
      }
    }
  }
}

boolean distanceUpdateCheck(){
  if(ultrasonicSensor.isReady()){
    thread("updateUltrasonicSensor");
  }
  
  if(fetchingImage || currentState == State.TransitionToNewImage){
    return false; //  
  }   
  
  setProximityRange(ultrasonicSensor.getCurrentRange());     
  
  return true; 
}

void updateUltrasonicSensor(){
  ultrasonicSensor.update();  
}

boolean imageUpdateCheck(){
  float etSinceLastImage = millis() - lastImageTimestamp;
  float etSinceStateChange = millis() - stateChangedTimestamp; 
  if(currentState == State.IdleOut && etSinceLastImage >= IMAGE_UPDATE_FREQUENCY && etSinceStateChange > IMAGE_UPDATE_STATE_CHANGE_THRESHOLD){
    requestNextImage();
    return true; 
  }
  
  return false; 
}

void requestNextImage() {
  if (fetchingImage) {
    return;
  }  
  
  lastImageTimestamp = millis();
  
  thread("fetchNextImage");
}

void fetchNextImage() {
  println("--- fetchNextImage ---");
  
  fetchingImage = true;  
  
  markStartTime();  

  JSONObject obj = loadJSONObject(URL_NEXTIMAGE);
  if(obj == null){
    // TODO; handle exception 
    return; 
  }
  
  println("Time taken to fetch next image details " + markEndTime()); 
  
  obj = obj.getJSONObject("next_image");
  
  PALETTE_INDEX = getSwatchIndexFromPalette(obj);     
    
  ImageDetails imageDetails = new ImageDetails(obj, PALETTE_INDEX);
  PixelRenderer pixelRenderer = new PixelRenderer(imageDetails, offscreenBuffer);  
  
  pixelRenderer.createGridGrowLevelFromMainColour(4, 4, 30, 3); 
  
  String imageSrc = imageDetails.getImageSrc();  
  
  // call the colourise service 
  String colouriseUrl = URL_COLOURISED_IMAGE + "?image_url=" + imageSrc + "&colours=6" + "&swatch_index=" + PALETTE_INDEX;
  println("posting: " + colouriseUrl); 
  PImage nextImage = loadImage(colouriseUrl, "jpg");
  
  println("Time taken to download image " + markEndTime());
  
  float imageScale = 1.0f;   
  
  if(sourceImage.width > sourceImage.height){
    imageScale = (float)sourceImage.width/(float)nextImage.width;   
  } else{
    imageScale = (float)sourceImage.height/(float)nextImage.height;   
  }
  
  nextImage.resize((int)(nextImage.width * imageScale), (int)(nextImage.height * imageScale));
  
  int ox = (int)(((float)sourceImage.width - (float)nextImage.width)*0.5f);
  int oy = (int)(((float)sourceImage.height - (float)nextImage.height)*0.5f);
  
  for(int y=0; y<sourceImage.height; y++){
    for(int x=0; x<sourceImage.width; x++){
      int sourceIndex = (y * sourceImage.width) + x;
      int nextIndex = ((y - oy) * nextImage.width) + (x + ox); 
      
      if(y < 0 || y >= sourceImage.height || x < 0 || x >= sourceImage.width){            
        continue; 
      }
      
      if((x + ox) < 0 || (x + ox) >= nextImage.width || (y - oy) < 0 || (y - oy) >= nextImage.height){
        sourceImage.pixels[sourceIndex] = color(255, 255, 255);
        continue;   
      }            
      
      sourceImage.pixels[sourceIndex] = nextImage.pixels[nextIndex];             
    }
  }
  sourceImage.updatePixels();
  
  int[] levelResolutions = new int[]{
    5, 10, 30, 50, 80, 100   
  };
  
  int[] levelTransitionTimesInMS = new int[]{
    15, 10, 5, 5, 2, 1         
  };
  
  int[] levelSeeds = new int[]{
    20, 30, 40, 50, 60, 100          
  };
  
  for(int i=0; i<levelResolutions.length; i++){
    pixelRenderer.createGridGrowLevelFromImage(levelResolutions[i],levelResolutions[i], sourceImage, levelTransitionTimesInMS[i], levelSeeds[i]);    
  }
 
  println("Time taken to resize image " + markEndTime());   
  
  println("Time taken to update pixels " + markEndTime());
  
  setPixelRenderer(pixelRenderer); 
  
  setState(State.TransitionToNewImage);
   
  fetchingImage = false;   
}

int getSwatchIndexFromPalette(JSONObject nextImageJson){
  JSONObject paletteJSONObject = nextImageJson.getJSONObject("palette");
  JSONArray vibrantRGBObj = paletteJSONObject.getJSONArray("vibrant_swatch");
  int[] vibrantRGB = new int[]{vibrantRGBObj.getInt(0), vibrantRGBObj.getInt(1), vibrantRGBObj.getInt(2)}; 
  
  JSONArray rgbClusters = nextImageJson.getJSONArray("rgb_clusters");
  for(int i=0; i<rgbClusters.size(); i++){
    JSONObject rgbClusterObj = rgbClusters.getJSONObject(i); 
    JSONArray rgbObj = rgbClusterObj.getJSONArray("rgb");
    int[] rgb = new int[]{rgbObj.getInt(0), rgbObj.getInt(1), rgbObj.getInt(2)};
    
    if(rgb[0] == vibrantRGB[0] && rgb[1] == vibrantRGB[1] && rgb[2] == vibrantRGB[2]){      
      return i; 
    }
  } 
  
  return PALETTE_INDEX; 
}
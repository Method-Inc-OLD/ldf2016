
final String URL_NEXTIMAGE = "http://instacolour.herokuapp.com/api/nextimage?randomly_select_from_top=100"; 
final String URL_COLOURISED_IMAGE = "http://instacolour.herokuapp.com/api/colourise"; 

int PALETTE_INDEX = 3;
final long IMAGE_UPDATE_FREQUENCY = 120000; 

final int IMAGE_DOWNSAMPLING = 2; 

boolean fetchingImage = false; 

PImage sourceImage = null; 

long lastUpdateTimestamp = millis(); 
long stateChangedTimestamp = millis();
long lastImageTimestamp = millis();

long currentProximityDistance = 0;  

PixelRenderer previousPixelRenderer; 
PixelRenderer currentPixelRenderer; 

State previousState = State.Undefined;
State currentState = State.Undefined;

ProximityRange previousProximityRange = ProximityRange.Far; 
ProximityRange currentProximityRange = ProximityRange.Far; 

long tmpTimestamp = 0;  

int dir = 1; 

UltrasonicSensor ultrasonicSensor; 

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
  sourceImage = createImage(width/IMAGE_DOWNSAMPLING, width/IMAGE_DOWNSAMPLING, RGB);
}

void initUltrasonicSensor(){
  ultrasonicSensor = new UltrasonicSensor();   
}

void setCurrentPixelRenderer(PixelRenderer pixelRenderer){
  if(currentPixelRenderer != null){
    currentPixelRenderer.freeze(); 
    previousPixelRenderer = currentPixelRenderer; 
  }
  
  currentPixelRenderer = pixelRenderer; 
}

void setState(State state){
  previousState = currentState; 
  currentState = state; 
  stateChangedTimestamp = millis();
  
  onStateChanged();   
}

void onStateChanged(){
  println("onStateChanged " + currentState); 
  
  if(currentState == State.TransitionToNewImage){
    dir = 1;   
  }   
}

void setProximityRange(ProximityRange proximityRange){
  previousProximityRange = currentProximityRange; 
  currentProximityRange = proximityRange;
  
  onProximityRangeChanged(); 
}

void onProximityRangeChanged(){
  
}

void markStartTime(){
  tmpTimestamp = millis();   
}

long markEndTime(){
  long et = millis() - tmpTimestamp; 
  tmpTimestamp = millis(); 
  return et;    
}

void draw() {    
  long et = millis() - lastUpdateTimestamp;
  
  imageUpdateCheck(); 
  
  distanceUpdateCheck(); 
  
  if(currentState == State.TransitionToNewImage){ 
    drawTransitionToNewImage(et);     
  } else if(currentState == State.Ready){ 
    drawReady(et);     
  } else{
    fill(255,255,255); 
    rect(0,0,width,height); 
  }
  
  lastUpdateTimestamp = millis(); 
  
  //if(currentState == State.Ready){
  //  if(!currentPixelRenderer.isAnimating()){
  //    int level = currentPixelRenderer.currentLevel;
  //    level += dir;
      
  //    if(dir > 0 && level >= currentPixelRenderer.size()){
  //      dir = -dir; 
  //      currentPixelRenderer.setLevel(currentPixelRenderer.currentLevel+dir);
  //    } else if(dir < 0 && level < 0){
  //      dir = -dir;
  //      currentPixelRenderer.setLevel(currentPixelRenderer.currentLevel+dir);
  //    } else{
  //      currentPixelRenderer.setLevel(level);
  //    }      
  //  }
  //}
}

/** updating sqaures/voxels, fading into the next colour - expected whole screen **/ 
void drawTransitionToNewImage(long et){
  if(previousPixelRenderer == null){
    fill(255,255,255);
    rect(0,0,width,height);  
  } else{
    previousPixelRenderer.fillWithMainColour(); 
    rect(0,0,width,height);
  }
  
  currentPixelRenderer.draw(et);
  
  if(!currentPixelRenderer.isAnimating()){
    setState(State.Ready);
  }  
}

void drawReady(long et){
  currentPixelRenderer.draw(et);
}

boolean distanceUpdateCheck(){
  if(ultrasonicSensor.isReady()){
    thread("updateUltrasonicSensor");
  }
  
  if(fetchingImage || currentState != State.Ready){
    return false; // ignore, only process when 'Ready'    
  }   
  
  previousProximityRange = currentProximityRange; 
  currentProximityRange = ultrasonicSensor.getCurrentRange(); 
  
  // update level based on current range 
  if(currentProximityRange == ProximityRange.Far){
    currentPixelRenderer.setLevel(0);
  } else if(currentProximityRange == ProximityRange.MediumFar){
    currentPixelRenderer.setLevel(1);
  } else if(currentProximityRange == ProximityRange.Medium){
    currentPixelRenderer.setLevel(2);
  } else if(currentProximityRange == ProximityRange.Close){
    currentPixelRenderer.setLevel(3);
  } 
  
  return true; 
}

void updateUltrasonicSensor(){
  ultrasonicSensor.update();  
}

boolean imageUpdateCheck(){
  long et = millis() - lastImageTimestamp; 
  if(et > IMAGE_UPDATE_FREQUENCY && currentProximityRange == ProximityRange.Far && currentState == State.Ready){
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
  PixelRenderer pixelRenderer = new PixelRenderer(imageDetails);  
  
  pixelRenderer.createLevelFromMainColour(4,4, 1*1000); 
  
  String imageSrc = imageDetails.getImageSrc();  
  
  // call the colourise service 
  String colouriseUrl = URL_COLOURISED_IMAGE + "?image_url=" + imageSrc + "&colours=6" + "&swatch_index=" + PALETTE_INDEX;
  println("posting: " + colouriseUrl); 
  PImage nextImage = loadImage(colouriseUrl, "jpg");
  
  println("Time taken to download image " + markEndTime());
  
  float imageScale = 1.0f;   
  
  if(nextImage.width > nextImage.height){
    imageScale = sourceImage.width/nextImage.width;   
  } else{
    imageScale = sourceImage.height/nextImage.height;   
  }
  
  nextImage.resize((int)(nextImage.width * imageScale), (int)(nextImage.height * imageScale));
  
  //pixelRenderer.createLevelFromImage(10,10, nextImage, 1000);
  //pixelRenderer.createLevelFromImage(20,20, nextImage, 40);
  //pixelRenderer.createLevelFromImage(30,30, nextImage, 30);
  //pixelRenderer.createLevelFromImage(40,40, nextImage, 20);
  //pixelRenderer.createLevelFromImage(50,50, nextImage, 10);
  //pixelRenderer.createLevelFromImage(60,60, nextImage, 5);
  //pixelRenderer.createLevelFromImage(70,70, nextImage, 2);
  
  // mediumfar 
  pixelRenderer.createLevelFromImage(20,20, nextImage, 40); // 1
  // medium 
  pixelRenderer.createLevelFromImage(40,40, nextImage, 20); // 2
  // close 
  pixelRenderer.createLevelFromImage(80,80, nextImage, 2); // 3 
 
  println("Time taken to resize image " + markEndTime());
  
  int ox = (int)((float)(nextImage.width/(float)sourceImage.width)*0.5f);
  int oy = (int)((float)(nextImage.height/(float)sourceImage.height)*0.5f);
  
  for(int y=0; y<sourceImage.height; y++){
    for(int x=0; x<sourceImage.width; x++){
      int index = (y * sourceImage.width) + x; 
      
      if(y >= oy && y < (sourceImage.height-oy*2) && x >= ox && x < (sourceImage.height-ox*2)){
        int subX = x - ox; 
        int subY = y - oy; 
        int subIndex = (subY * nextImage.width) + subX;
        sourceImage.pixels[index] = nextImage.pixels[subIndex]; 
      } else{
        sourceImage.pixels[index] = color(255, 255, 255);    
      }
    }
  }
  sourceImage.updatePixels();
  
  println("Time taken to update pixels " + markEndTime());
  
  setCurrentPixelRenderer(pixelRenderer); 
  
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

boolean isFetchingImage = false; 
float lastImageTimestamp = 0.0f; 

void requestNextImage(){
  if (isFetchingImage) {
    return;
  }  
  
  isFetchingImage = true;   
  lastImageTimestamp = millis();  
  thread("fetchNextImage");
}

void fetchNextImage() {
  println("--- fetchNextImage ---");

  JSONObject responseJSON = loadJSONObject(URL_NEXTIMAGE);
  if(responseJSON == null){
    // TODO; handle exception 
    return; 
  }  
  
  // NB: this will be a constant (ie each PI will be assigned a palette index) value in production 
  myPaletteIndex = getSwatchIndexFromPalette(responseJSON.getJSONObject("next_image"));     
    
  ImageDetails imageDetails = new ImageDetails(responseJSON.getJSONObject("next_image"), myPaletteIndex);         
  
  // call the colourise service 
  String colouriseUrl = URL_COLOURISED_IMAGE + "?image_url=" + imageDetails.getImageSrc() + "&colours=6" + "&swatch_index=" + myPaletteIndex;
  println("posting: " + colouriseUrl); 
  
  PImage nextImage = loadImage(colouriseUrl, "jpg");
  
  // resize image to fill fit the screen 
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
  
  // now resize to be used as the source for the new pixels 
  int xRes = 80;
  int yRes = 60;
  
  println("xRes " + xRes); 
  
  PImage sampleImage = sourceImage.copy(); 
  sampleImage.resize(xRes, yRes);
  
  if(pixCollection == null){
    pixCollection = createPixCollection(xRes, yRes, (int)width, (int)height, 5, sampleImage, imageDetails.myColour);   
  }
  
  println("create pixCollection"); 
   
  isFetchingImage = false;   
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
  
  return myPaletteIndex; 
}
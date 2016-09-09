

void requestNextImage(){
  if (isFetchingImage) {
    return;
  }  
  
  setFetchingImage(true);   
  thread("fetchNextImage");
}

void fetchNextImage() {
  println("--- fetchNextImage ---");
  
  String url = "";
  
  if(configManager.isMaster()){ // only the MASTER progresses through the queue, the others (SLAVES) just pull down the current image. 
    url = URL_POP;  
  } else{
    url = URL_PEEK;
  }
  
  url += "?pi_index=" + configManager.piIndex;
  
  println("POSTING: " + url); 
  JSONObject responseJSON = loadJSONObject(url);
  if(responseJSON == null){
    // TODO; handle exception 
    return; 
  }   
    
  ImageDetails imageDetails = new ImageDetails(responseJSON.getJSONObject("next_image"), configManager.piIndex);         
  
  fetchAndSetImage(imageDetails);  
  fetchAndSetColoursiedImage(imageDetails); 
  
  // now resize to be used as the source for the new pixels 
  PImage sampleImage = sourceImage.copy(); 
  sampleImage.resize(configManager.resolutionX, configManager.resolutionY);
  
  if(pixCollection == null){
    pixCollection = createPixCollection(configManager.resolutionX, configManager.resolutionY, (int)width, (int)height, configManager.levelsOfDetail, sampleImage, imageDetails.myColour);   
  } else{
    initPixCollection(pixCollection, sampleImage, imageDetails.myColour);
  }
  
  animationController.init(sourceImage, orgSourceImage, pixCollection);
  
  setColourDetails(imageDetails.myColour, imageDetails.myColourName, imageDetails.getImageId());  
  
  lastImageTimestamp = millis();
  setFetchingImage(false);   
}

void fetchAndSetImage(ImageDetails imageDetails){  
  // call the colourise service imageDetails){
  String imageUrl = imageDetails.getImageSrc();
  println("POSTING: " + imageUrl); 
  
  PImage image = loadImage(imageUrl, "jpg");
  
  // resize image to fill fit the screen 
  float imageScale = 1.0f;   
  
  if(orgSourceImage.width > orgSourceImage.height){
    imageScale = (float)orgSourceImage.width/(float)image.width;   
  } else{
    imageScale = (float)orgSourceImage.height/(float)image.height;   
  }
  
  image.resize((int)(image.width * imageScale), (int)(image.height * imageScale));
  
  int ox = (int)(((float)orgSourceImage.width - (float)image.width)*0.5f);
  int oy = (int)(((float)orgSourceImage.height - (float)image.height)*0.5f);
  
  for(int y=0; y<orgSourceImage.height; y++){
    for(int x=0; x<orgSourceImage.width; x++){
      int sourceIndex = (y * orgSourceImage.width) + x;
      int nextIndex = ((y - oy) * image.width) + (x + ox); 
      
      if(y < 0 || y >= orgSourceImage.height || x < 0 || x >= orgSourceImage.width){            
        continue; 
      }
      
      if((x + ox) < 0 || (x + ox) >= image.width || (y - oy) < 0 || (y - oy) >= image.height){
        orgSourceImage.pixels[sourceIndex] = color(255, 255, 255);
        continue;   
      }            
      
      orgSourceImage.pixels[sourceIndex] = image.pixels[nextIndex];             
    }
  }
  orgSourceImage.updatePixels();  
}

void fetchAndSetColoursiedImage(ImageDetails imageDetails){
  // call the colourise service 
  String colouriseUrl = URL_COLOURISED_IMAGE + "?image_url=" + imageDetails.getImageSrc() + "&colours=5" + "&swatch_index=" + configManager.piIndex;
  println("POSTING: " + colouriseUrl); 
  
  PImage colourisedImage = loadImage(colouriseUrl, "jpg");
  
  // resize image to fill fit the screen 
  float imageScale = 1.0f;   
  
  if(sourceImage.width > sourceImage.height){
    imageScale = (float)sourceImage.width/(float)colourisedImage.width;   
  } else{
    imageScale = (float)sourceImage.height/(float)colourisedImage.height;   
  }
  
  colourisedImage.resize((int)(colourisedImage.width * imageScale), (int)(colourisedImage.height * imageScale));
  
  int ox = (int)(((float)sourceImage.width - (float)colourisedImage.width)*0.5f);
  int oy = (int)(((float)sourceImage.height - (float)colourisedImage.height)*0.5f);
  
  for(int y=0; y<sourceImage.height; y++){
    for(int x=0; x<sourceImage.width; x++){
      int sourceIndex = (y * sourceImage.width) + x;
      int nextIndex = ((y - oy) * colourisedImage.width) + (x + ox); 
      
      if(y < 0 || y >= sourceImage.height || x < 0 || x >= sourceImage.width){            
        continue; 
      }
      
      if((x + ox) < 0 || (x + ox) >= colourisedImage.width || (y - oy) < 0 || (y - oy) >= colourisedImage.height){
        sourceImage.pixels[sourceIndex] = color(255, 255, 255);
        continue;   
      }            
      
      sourceImage.pixels[sourceIndex] = colourisedImage.pixels[nextIndex];             
    }
  }
  sourceImage.updatePixels();  
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
  
  return 0; 
}

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
  
  fetchAndSetImage(imageDetails);
  fetchAndSetColoursiedImage(imageDetails); 
  
  // now resize to be used as the source for the new pixels 
  int xRes = 40; // 60; // 80;
  int yRes = 20; // 40; // 60;
  
  println("xRes " + xRes); 
  
  PImage sampleImage = sourceImage.copy(); 
  sampleImage.resize(xRes, yRes);
  
  if(pixCollection == null){
    pixCollection = createPixCollection(xRes, yRes, (int)width, (int)height, LEVELS_OF_DETAIL, sampleImage, imageDetails.myColour);   
  }
  
  animationController.init(sourceImage, orgSourceImage, pixCollection);    
  
  println("create pixCollection"); 
   
  isFetchingImage = false;   
}

void fetchAndSetImage(ImageDetails imageDetails){  
  // call the colourise service imageDetails){
  String imageUrl = imageDetails.getImageSrc();
  println("posting: " + imageUrl); 
  
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
  String colouriseUrl = URL_COLOURISED_IMAGE + "?image_url=" + imageDetails.getImageSrc() + "&colours=6" + "&swatch_index=" + myPaletteIndex;
  println("posting: " + colouriseUrl); 
  
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
  
  return myPaletteIndex; 
}
enum State{
  Undefined, 
  TransitionToNewImage, 
  IdleOut,
  IdleIn, 
  TransitioningIn, 
  TransitioningOut
};

enum PixelRendererLevelType{
  FadeTile, 
  Grow 
}

class ImageDetails{
  int swatchIndex = 0; 
  JSONObject obj; 
  color myColour; 
  
  ImageDetails(JSONObject obj, int swatchIndex){
    this.obj = obj; 
    this.swatchIndex = swatchIndex;
    
    myColour = getColor(); 
  }
  
  float getRed(){
      return red(myColour); 
  }
  
  float getGreen(){
      return green(myColour); 
  }
  
  float getBlue(){
      return blue(myColour); 
  }
  
  color getColor(){
      JSONObject rgbCluster = getRGBClusters().getJSONObject(swatchIndex); 
      JSONArray rgb = rgbCluster.getJSONArray("rgb");  
      return color(rgb.getInt(0), rgb.getInt(1), rgb.getInt(2));
  }
  
  JSONArray getRGBClusters(){
    return obj.getJSONArray("rgb_clusters");  
  }
  
  String getImageSrc(){
    return obj.getString("img_src");   
  }
}

class Rect{
  int x; 
  int y; 
  int w; 
  int h; 
  
  Rect(int x, int y, int w, int h){
    this.x = x; 
    this.y = y; 
    this.w = w; 
    this.h = h; 
  }
  
  int getX(){
    return x;   
  }
  
  int getX2(){
    return x + w;     
  }
  
  int getY(){
    return y; 
  }  
  
  int getY2(){
    return y + h;   
  }
  
  int getWidth(){
    return w;   
  }
  
  int getHeight(){
    return h;   
  }
}

/**
 * src and dst must be the same size 
**/
//int fadeInto(PImage src, PImage dst, Rect rect, float t){
//  int maxDistance = 0; 
//  for(int y=rect.y; y<rect.getY2(); y++){
//    for(int x=rect.x; x<rect.getX2(); x++){
//      int index = (y * src.width) + x; 
      
//      float sR = red(src.pixels[index]);
//      float sG = green(src.pixels[index]);
//      float sB = blue(src.pixels[index]);
      
//      float dR = red(dst.pixels[index]);
//      float dG = green(dst.pixels[index]);
//      float dB = blue(dst.pixels[index]);
      
//      float diffR = dR - sR;
//      float diffG = dG - sG;
//      float diffB = dB - sB;
      
//      float r = sR + diffR * t;
//      float g = sG + diffG * t;
//      float b = sB + diffB * t;
       
//      src.pixels[index] = color(r, g, b);   
//      //maxDistance = max(diff, maxDistance); 
//    }
//  }
  
//  return maxDistance; 
//}
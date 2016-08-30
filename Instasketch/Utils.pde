
color getDominateColourFromImagePatch(PImage image, int x, int y, int w, int h){
  return 0;   
}

color getAverageColourFromImagePatch(PImage image, int x, int y, int w, int h){
  if(image.pixels == null)
    image.loadPixels(); 
    
  float numberOfPixels = 0; 
  float totalR = 0;
  float totalG = 0;
  float totalB = 0;
    
  for(int i=y; i<y+h; i++){
    for(int j=x; j<x+w; j++){
      int index = (i*image.width) + j; 
      color c = image.pixels[index]; 
      totalR += red(c);
      totalG += green(c); 
      totalB += blue(c); 
      numberOfPixels += 1; 
    }
  }
  
  if(numberOfPixels == 0){
    return color(255,255,255);   
  }
    
  return color((int)(totalR/numberOfPixels), (int)(totalG/numberOfPixels), (int)(totalB/numberOfPixels));  
}

color lerpColour(color c1, color c2, float t){
  t = max(min(1.0f, t), 0.0f); 
  
  float r1 = red(c1); 
  float r2 = red(c2);
  
  float g1 = green(c1); 
  float g2 = green(c2);
  
  float b1 = blue(c1); 
  float b2 = blue(c2);     
  
  float r = r1 + ((r2 - r1) * t);
  float g = g1 + ((g2 - g1) * t);
  float b = b1 + ((b2 - b1) * t);
  
  return color(r, g, b);     
}

boolean isApproximately(float val, float target){
  return Math.abs(val - target) < 0.01f;   
}
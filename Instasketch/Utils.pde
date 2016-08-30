
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
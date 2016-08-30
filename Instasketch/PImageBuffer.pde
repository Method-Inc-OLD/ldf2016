
class PImageBuffer{
  
  PImage pImage;
  
  public int width = 0;
  public int height = 0;
  public int length = 0; 
  
  color strokeColour = color(255, 255, 255, 255); 
  color fillColour = color(255, 255, 255, 255); 
    
  PImageBuffer(){
    
  }
  
  PImageBuffer(int w, int h){
    PImage image = createImage(w, h, RGB); 
    setImage(image);    
  }
  
  PImageBuffer(int w, int h, int format){
    PImage image = createImage(w, h, format); 
    setImage(image);    
  }
  
  PImageBuffer(PImage image){
    setImage(image);
    
    for(int i=0; i<image.pixels.length; i++){
      pImage.pixels[i] = image.pixels[i];         
    }
  }
  
  PImageBuffer(PImageBuffer imageBuffer){
    PImage image = createImage(imageBuffer.width, imageBuffer.height, RGB); 
    setImage(image);
    
    for(int i=0; i<imageBuffer.length; i++){
      pImage.pixels[i] = imageBuffer.getPixel(i);         
    }
  }
  
  void setImage(PImage image){
    pImage = image;
    this.width = pImage.width; 
    this.height = pImage.height;  
    this.length = pImage.pixels.length; 
    
    if(pImage.pixels == null){
      pImage.loadPixels();   
    }
  }
  
  void updatePixels(){
      pImage.updatePixels(); 
  }
  
  void updatePixels(int x, int y, int w, int h){
      pImage.updatePixels(x, y, w, h); 
  }
  
  void setPixel(int index, color c){
      pImage.pixels[index] = c; 
  }
  
  void setPixel(int x, int y, color c){
    int index = (y * this.width) + x; 
    pImage.pixels[index] = c;
  }
  
  color getPixel(int index){
    return pImage.pixels[index];   
  }
  
  color getPixel(int y, int x){
    int index = (y * this.width) + x; 
    return pImage.pixels[index]; 
  }
  
  void stroke(float r, float g, float b, float a){
    strokeColour = color(r, g, b, a);   
  }
  
  void stroke(int r, int g, int b, int a){
    strokeColour = color(r, g, b, a);   
  }
  
  void fill(int r, int g, int b){
    fillColour = color(r, g, b);   
  }
  
  void fill(int r, int g, int b, int a){
    fillColour = color(r, g, b, a);   
  }    
  
  void fill(float r, float g, float b, float a){
    fillColour = color(r, g, b, a);   
  } 
  
  void fill(float r, float g, float b){
    fillColour = color(r, g, b);   
  }
  
  void rect(int x, int y, int w, int h){
    if(pImage.pixels == null){
      pImage.loadPixels();   
    }
    
    for(int cy=y; cy<y+w; cy++){
      for(int cx=x; cx<x+h; cx++){
        if(cy < 0 || cy >= pImage.height || cx < 0 || cx >= pImage.width){
          continue;           
        }
        
        int index = (cy * pImage.width) + cx; 
        // TODO: stroke colour  
        pImage.pixels[index] = fillColour; 
      }
    }
  }   
  
  color getAverageColourInRect(int x, int y, int w, int h){
    int totalR = 0; 
    int totalG = 0; 
    int totalB = 0; 
    int totalA = 0; 
    int pixelsInRect = 0; 
    
    if(pImage.pixels == null){
      pImage.loadPixels();   
    }
    
    for(int cy=y; cy<y+w; cy++){
      for(int cx=x; cx<x+h; cx++){
        if(cy < 0 || cy >= pImage.height || cx < 0 || cx >= pImage.width){
          continue;           
        }
        
        int index = (cy * pImage.width) + cx;         
        color c = pImage.pixels[index];
        totalR += red(c); 
        totalG += green(c);
        totalB += blue(c);
        totalA += alpha(c);
        
        pixelsInRect += 1; 
      }
    }
    
    return color(totalR/pixelsInRect, totalG/pixelsInRect, totalB/pixelsInRect, totalA/pixelsInRect); 
  }
  
  void copyPixels(PImageBuffer other){
    copyPixels(other.pImage); 
  }
  
  void copyPixels(PImage other){
    if(other.pixels == null){
      other.loadPixels();   
    }
    
    // TODO: validate (i.e. same width and height) 
    
    for(int i=0; i<other.pixels.length; i++){
      this.pImage.pixels[i] = other.pixels[i];    
    }
  }
  
  PImage copy(){
    return pImage.copy();   
  }
}
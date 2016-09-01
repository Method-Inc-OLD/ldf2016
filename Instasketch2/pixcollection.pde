
class PixCollection{
  
  public int levels = 0; 
  public int currentLevel = 0; 
  public int sourceXRes; 
  public int sourceYRes; 
  public int sourceWidth; 
  public int sourceHeight; 
  
  public Pix[][] pixies; 
  
  private boolean animating = false; 
  
  public PixCollection(){
    
  }
  
  public void draw(PGraphics graphics, float et){       
      animating = false; 
      
      for(int y=0; y<sourceYRes; y++){
        for(int x=0; x<sourceXRes; x++){
          pixies[y][x].draw(graphics, et); 
          if(pixies[y][x].isAnimating()){
            animating = true;     
          }
        }
      }            
  }  
  
  public boolean isAnimating(){
    return animating;   
  }
  
  public void setLevel(int level){
    println("PixCollection; setting level to " + level); 
    currentLevel = level; 
    
    for(int y=0; y<sourceYRes; y++){
      for(int x=0; x<sourceXRes; x++){
        pixies[y][x].setLevel(currentLevel);            
      }
    }
  }
}

public PixCollection createPixCollection(int xRes, int yRes, int w, int h, int levels, PImage image, color imageMainColour){
  PixCollection pixCollection = new PixCollection();
  pixCollection.levels = levels;
  pixCollection.sourceXRes = xRes; 
  pixCollection.sourceYRes = yRes;
  pixCollection.pixies = new Pix[yRes][xRes]; 
  
  if(image.pixels == null)
    image.loadPixels(); 
  
  int pixWidth = w/xRes; 
  int pixHeight = h/yRes; 
  
  for(int y=0; y<yRes; y++){
    for(int x=0; x<xRes; x++){
      Pix pix = new Pix(x, y, pixWidth, pixHeight, levels+1); 
      pix.setColour(imageMainColour, 0); 
      pixCollection.pixies[y][x] = pix;
      setPixelColours(pix, levels, image); 
      pix.setLevel(0, color(255, 255, 255)); 
    }
  }
    
  return pixCollection; 
}

public void setPixelColours(Pix pix, int levels, PImage image){
  for(int i=0; i<levels; i++){
    pix.setColour(getColourFromImage(pix.x, pix.y, i, image), levels-(i+1));     
  }    
}

public color getColourFromImage(int x, int y, int level, PImage image){
  float tR = 0; 
  float tG = 0; 
  float tB = 0; 
  
  float pixelCount = 0; 
  
  for(int cy=y-level; cy<=y+level; cy++){
    for(int cx=x-level; cx<=x+level; cx++){
      if(cx < 0 || cx >= image.width || cy < 0 || cy >= image.height)
        continue; 
       
       int index = (cy * image.width) + cx; 
       color c = image.pixels[index]; 
       tR += red(c); 
       tG += green(c); 
       tB += blue(c); 
       pixelCount += 1; 
    }
  }
  
  if(pixelCount == 0){
    return color(255,255,255);   
  }
  
  return color(tR / pixelCount, tG / pixelCount, tB / pixelCount);  
}
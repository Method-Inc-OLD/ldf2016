
class PixelIndex{
  int index = -1; 
  int row = 0; 
  int col = 0; 
  
  PixelIndex(){
    
  }
  
  PixelIndex(int index){
    this.index = index;  
  }
  
  PixelIndex(int row, int col){
    this.row = row; 
    this.col = col; 
  }
  
  PixelIndex(int index, int row, int col){
    this.index = index; 
    this.row = row; 
    this.col = col; 
  }
  
  public boolean equals(Object other){
    if (other == null) return false;
    if (other == this) return true;
    
    if (!(other instanceof PixelIndex)) return false;
    PixelIndex otherPixelIndex = (PixelIndex)other;
    
    return (otherPixelIndex.row == row && otherPixelIndex.col == col) || (otherPixelIndex.index != -1 && index != -1 && otherPixelIndex.index == index); 
  }  
}

class Pixel extends Rect{
  
  int row = -1; 
  int col = -1; 

  color targetColor;   
  
  float age = 0; 
  
  float speed = 1; 
  
  Pixel(int x, int y, int w, int h, color targetColor){
    super(x, y, w, h);  
    
    this.targetColor = targetColor; 
  }
  
  void update(PImageBuffer srcImage, PImageBuffer dstImage, float t){
    int imageW = srcImage.width; 
    int imageH = srcImage.height;  
    
    for(int cy=this.y; cy<this.y+this.h; cy++){
      int yIndex = cy * imageW; 
      for(int cx=this.x; cx<this.x+this.w; cx++){
        if(cx < 0 || cx >= imageW || cy < 0 || cy>= imageH){
          continue;   
        }
        
        int index = yIndex + cx; 
        color c1 = srcImage.getPixel(index); 
        color c2 = targetColor; 
        color c = lerpColour(c1, c2, t);
        
        dstImage.setPixel(index, c); 
      }
    }
    
    dstImage.updatePixels(getX(), getY(), getWidth(), getHeight());
  }    
  
  void reset(){
      age = 0; 
  }
  
  float getRed(){
    return red(targetColor);  
  }
  
  float getGreen(){
    return green(targetColor);  
  }
  
  float getBlue(){
    return blue(targetColor);  
  }   
  
  boolean isGrey(){
    return (getRed() == getGreen() &&  getGreen() == getBlue());   
  }
}

class PixelRenderer{
  
  ImageDetails imageDetails;
  PImageBuffer srcImageBuffer; 
  PImageBuffer dstImageBuffer;
  
  boolean uniformPixels = false;
  
  float randomOffsetPerc = 0.01f;
     
  int previousLevel = 0;
  int currentLevel = 0;
  
  ArrayList<BasePixelRendererLevel> levels = new ArrayList<BasePixelRendererLevel>();
  
  float defaultSpeed = 0.2f; 
  
  PixelRenderer(ImageDetails imageDetails, PImageBuffer dstImageBuffer){
    this.imageDetails = imageDetails; 
    this.dstImageBuffer = dstImageBuffer; 
    this.srcImageBuffer = new PImageBuffer(this.dstImageBuffer); 
  }  
  
  void update(float et){
    if(levels.size() == 0){
      return;   
    }
    
    getCurrentPixelRenderer().update(et, srcImageBuffer, dstImageBuffer);     
  }
  
  PImage getImage(){
    return dstImageBuffer.pImage; 
  }
  
  void reset(){      
      currentLevel = 0; 
      previousLevel = -1;
      setLevel(0); 
  }
  
  void clear(){
      levels.clear(); 
      currentLevel = 0; 
      previousLevel = -1; 
  }
  
  BasePixelRendererLevel getCurrentPixelRenderer(){
    return levels.get(currentLevel); 
  }
  
   BasePixelRendererLevel getPreviousPixelRenderer(){
     if(previousLevel == -1){
       return null; 
     }
    return levels.get(previousLevel); 
  }
  
  float getWidth(){
    return dstImageBuffer.width; 
  }
  
  float getHeight(){
    return dstImageBuffer.height; 
  }
  
  
  
  void createFadeInLevelFromMainColour(float xres, float yres, float speed){
    BasePixelRendererLevel level = createPixelRendererLevelFromType(PixelRendererLevelType.FadeTile);
    level.speed = speed; 
    
    int w = 1; 
    int h = 1; 
    
    w = (int)Math.ceil(getWidth() / xres); 
    h = (int)Math.ceil(getHeight() / yres);
      
    if(uniformPixels){
      w = min(w,h); 
      h = min(w,h); 
    }           
    
    float cols = (float)getWidth()/(float)w;
    float rows = (float)getHeight()/(float)h;
    
    float rw = getWidth() - (w * cols); 
    float rh = getHeight() - (h * rows);
    
    if(rw > 0){
      w += rw;   
    }
    
    if(rh > 0){
      h += rh;   
    }
    
    int row = 0; 
    int col = 0; 
    
    for(int y=0; y<getHeight(); y+=h){      
      for(int x=0; x<getWidth(); x+=w){        
        Pixel pix = new Pixel(x, y, w, h, imageDetails.myColour); 
        
        pix.col = col;
        pix.row = row;
        
        pix.speed = level.speed; 
          
        level.add(pix);            
        
        col += 1;
      }
      
      row += 1; 
      col = 0;
    } 
    
    add(level); 
  }
  
  void createGridGrowLevelFromMainColour(float xres, float yres, float speed, int numberOfSeeds){
    BasePixelRendererLevel level = createPixelRendererLevelFromType(PixelRendererLevelType.Grow);
    ((GrowPixelRendererLevel)level).maxSeeds = numberOfSeeds;
    level.speed = speed; 
    
    int w = (int)(getWidth() / xres); 
    int h = (int)(getHeight() / yres); 
    
    if(uniformPixels){
      w = min(w,h); 
      h = min(w,h); 
    } 
    
    float randomSpeed = speed * 0.2f; 
    
    int row = 0; 
    int col = 0; 
    
    for(int y=0; y<getHeight(); y+=h){
      int yIndex = (int)(y*getWidth()); 
      for(int x=0; x<getWidth(); x+=w){                 
        int index = yIndex + x;   
        Pixel pix = new Pixel(x, y, w, h, imageDetails.myColour);        
        pix.col = col;
        pix.row = row;
        
        pix.speed = (level.speed + randomSpeed);
          
        level.add(pix);  
        
        col += 1; 
      }
      row += 1; 
      col = 0; 
    } 
    
    add(level); 
  }
  
  void createGridGrowLevelFromImage(float xres, float yres, PImage image, float speed, int numberOfSeeds){    
    BasePixelRendererLevel level = createPixelRendererLevelFromType(PixelRendererLevelType.Grow);
    ((GrowPixelRendererLevel)level).maxSeeds = numberOfSeeds;
    level.speed = speed; 
    
    int w = (int)(getWidth() / xres); 
    int h = (int)(getHeight() / yres); 
    
    if(uniformPixels){
      w = min(w,h); 
      h = min(w,h); 
    }     
    
    float randomSpeed = speed * 0.4f; 
    
    int row = 0; 
    int col = 0; 
    
    for(int y=0; y<getHeight(); y+=h){
      
      for(int x=0; x<getWidth(); x+=w){ 
        // extand if only a few pixels aay from the edge 
        int cw = w; 
        int ch = h; 
        
        // PImage image, int x, int y, int w, int h
        if((x + cw) > getWidth()){
          cw = (int)((x + cw) - getWidth());  
        } else if(Math.abs((x + cw) - getWidth()) < 5){
          cw += Math.abs((x + cw) - getWidth());   
        }
        
        if((y + ch) > getHeight()){
          ch = (int)((y + ch) - getHeight());  
        } else if(Math.abs((ch + h) - getHeight()) < 5){
          ch += Math.abs((ch + h) - getHeight());   
        }
        
        if( cw <= 0 || ch <= 0)
          continue; 
        
        color pixelColour = getAverageColourFromImagePatch(image, x, y, cw, ch); 
        
        Pixel pix = new Pixel(x, y, cw, ch, pixelColour);        
        pix.col = col;
        pix.row = row;
        
        pix.speed = (level.speed + random(-randomSpeed, randomSpeed));
          
        level.add(pix);  
        
        col += 1; 
      }
      row += 1; 
      col = 0; 
    } 
    
    add(level); 
  }
  
  public void add(BasePixelRendererLevel level){
    level.prepare(); 
    levels.add(level);   
  }
  
  public void setLevel(int level){
    if(level < 0 || level >= size()){
      return;   
    }
    
    println("Updating to level " + level);
    
    previousLevel = currentLevel; 
    currentLevel = level;
    
    this.srcImageBuffer.copyPixels(dstImageBuffer);
    this.srcImageBuffer.updatePixels(); 
    
    levels.get(currentLevel).reset();      
  }
  
  public int size(){
    return levels.size();   
  }
  
  boolean isAnimating(){
    return getCurrentPixelRenderer().isAnimating(); 
  }  
}
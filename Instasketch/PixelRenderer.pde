
class PixelIndex{
  int row = 0; 
  int col = 0; 
  
  PixelIndex(){
    
  }
  
  PixelIndex(int row, int col){
    this.row = row; 
    this.col = col; 
  }
  
  public boolean equals(Object other){
    if (other == null) return false;
    if (other == this) return true;
    
    if (!(other instanceof PixelIndex)) return false;
    PixelIndex otherPixelIndex = (PixelIndex)other;
    
    return otherPixelIndex.row == row && otherPixelIndex.col == col; 
  }  
}

class Pixel extends Rect{
  
  int row = -1; 
  int col = -1; 
  
  color targetColor; 
  
  long age = 0; 
  
  float speed = 1; 
  
  Pixel(int x, int y, int w, int h, color targetColor){
    super(x, y, w, h);  
    
    this.targetColor = targetColor; 
  }
  
  void update(PImageBuffer srcImage, PImageBuffer dstImage, float t){
    int imageW = srcImage.width; 
    int imageH = srcImage.height;  
    
    for(int cy=this.y; cy<this.y+this.h; cy++){
      for(int cx=this.x; cx<this.x+this.w; cx++){
        if(cx < 0 || cx >= imageW || cy < 0 || cy>= imageH){
          continue;   
        }
        
        int index = (cy * imageW) + cx; 
        color c1 = srcImage.getPixel(index); 
        color c2 = targetColor; 
        color c = lerpColour(c1, c2, t);
        //c = color(255, 255, 255); 
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
  
  boolean randomlyOffsetPixels = true; 
  
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
  
  void freeze(){
      getCurrentPixelRenderer().frozen = true; 
  }
  
  void update(long et){
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
  
  //void fillWithMainColour(){    
  //  dstImageBuffer.fill(imageDetails.getRed(),imageDetails.getGreen(),imageDetails.getBlue());
  //  dstImageBuffer.rect(0, 0, width, height);  
  //}
  
  BasePixelRendererLevel getCurrentPixelRenderer(){
    return levels.get(currentLevel); 
  }
  
   BasePixelRendererLevel getPreviousPixelRenderer(){
     if(previousLevel == -1){
       return null; 
     }
    return levels.get(previousLevel); 
  }
  
  void createLevelFromMainColour(float xres, float yres){
    createLevelFromMainColour(xres, yres, defaultSpeed); 
  }
  
  float getWidth(){
    return dstImageBuffer.width; 
  }
  
  float getHeight(){
    return dstImageBuffer.height; 
  }
  
  void createLevelFromMainColour(float xres, float yres, float speed){
    BasePixelRendererLevel level = createPixelRendererLevelFromType(PixelRendererLevelType.FadeTile);
    level.speed = speed; 
    
    int w = 1; 
    int h = 1; 
    
    w = (int)(getWidth() / xres); 
    h = (int)(getHeight() / yres);
      
    if(uniformPixels){
      w = min(w,h); 
      h = min(w,h); 
    }                
    
    float randomOX = w * randomOffsetPerc;
    float randomOY = h * randomOffsetPerc; 
    
    int row = 0; 
    int col = 0; 
    
    for(int y=0; y<getHeight(); y+=h){      
      for(int x=0; x<getWidth(); x+=w){        
        Pixel pix = new Pixel(x, y, w, h, imageDetails.myColour); 
        
        pix.col = col;
        pix.row = row;
        
        pix.speed = level.speed; 
          
        level.add(pix);          
        
        if(randomlyOffsetPixels && random(0, 100) > 80){
          float ox = random(-randomOX, randomOX);
          float oy = random(-randomOY, randomOY);
          //pix.x += ox; 
          //pix.y += oy;                             
        }     
        
        col += 1;
      }
      
      row += 1; 
      col = 0;
    } 
    
    add(level); 
  }
  
  void createLevelFromImage(float xres, float yres, PImage image){
      createLevelFromImage(xres, yres, image, defaultSpeed);
  }
  
  void createLevelFromImage(float xres, float yres, PImage image, float speed){    
    BasePixelRendererLevel level = createPixelRendererLevelFromType(PixelRendererLevelType.Grow); 
    level.speed = speed; 
    
    int w = (int)(getWidth() / xres); 
    int h = (int)(getHeight() / yres); 
    
    if(uniformPixels){
      w = min(w,h); 
      h = min(w,h); 
    } 
    
    float randomOX = w * 0.05f;
    float randomOY = h * 0.05f; 
    
    float randomSpeed = speed * 0.2f; 
    
    int row = 0; 
    int col = 0; 
    
    for(int y=0; y<getHeight(); y+=h){           
      for(int x=0; x<getWidth(); x+=w){                
        // PImage image, int x, int y, int w, int h
        color pixelColour = getAverageColourFromImagePatch(image, x, y, w, h); 
        
        Pixel pix = new Pixel(x, y, w, h, pixelColour);        
        pix.col = col;
        pix.row = row;
        
        pix.speed = (level.speed + random(-randomSpeed, randomSpeed));
          
        level.add(pix);  
        
        if(randomlyOffsetPixels && random(0, 100) > 80){
          float ox = random(-randomOX, randomOX);
          float oy = random(-randomOY, randomOY);
          pix.x += ox; 
          pix.y += oy;
        }
        
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
    
    if(previousLevel >= 0 && previousLevel<size()){
      levels.get(previousLevel).frozen = true;   
    }
    
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
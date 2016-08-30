
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
  
  int alpha = 0;
  
  long age = 0; 
  
  float speed = 1; 
  
  Pixel(int x, int y, int w, int h, color targetColor){
    super(x, y, w, h);  
    
    this.targetColor = targetColor; 
    this.alpha = 0; 
  }
  
  void draw(){       
    if(alpha < 20){
      return;   
    }
    
    stroke(0,0,0,0);        
    fill(red(targetColor), green(targetColor), blue(targetColor), alpha); 
    rect(x,y,w,h);
  }
  
  void reset(){
      alpha = 0; 
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
  
  boolean uniformPixels = true;
  
  boolean randomlyOffsetPixels = true; 
  
  float randomOffsetPerc = 0.01f;
     
  int previousLevel = 0;
  int currentLevel = 0;
  
  ArrayList<BasePixelRendererLevel> levels = new ArrayList<BasePixelRendererLevel>();
  
  float defaultSpeed = 0.2f; 
  
  PixelRenderer(ImageDetails imageDetails){
    this.imageDetails = imageDetails; 
  }  
  
  void freeze(){
      getCurrentPixelRenderer().frozen = true; 
  }
  
  void draw(long et){
    if(levels.size() == 0){
      return;   
    }
    
    if(getPreviousPixelRenderer() != null){
      getPreviousPixelRenderer().draw(et);   
    }
    
    getCurrentPixelRenderer().draw(et);     
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
  
  void fillWithMainColour(){
    stroke(0,0,0,0); 
    fill(imageDetails.getRed(),imageDetails.getGreen(),imageDetails.getBlue());
    rect(0,0,width,height);  
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
  
  void createLevelFromMainColour(float xres, float yres){
    createLevelFromMainColour(xres, yres, defaultSpeed); 
  }
  
  void createLevelFromMainColour(float xres, float yres, float speed){
    BasePixelRendererLevel level = createPixelRendererLevelFromType(PixelRendererLevelType.FadeTile);
    level.speed = speed; 
    
    int w = (int)(width / xres); 
    int h = (int)(height / yres); 
    
    if(uniformPixels){
      w = min(w,h); 
      h = min(w,h); 
    }
    
    float randomOX = w * randomOffsetPerc;
    float randomOY = h * randomOffsetPerc; 
    
    int row = 0; 
    int col = 0; 
    
    for(int y=0; y<height; y+=h){      
      for(int x=0; x<width; x+=w){        
        Pixel pix = new Pixel(x, y, w, h, imageDetails.myColour);
        pix.col = col;
        pix.row = row;
        
        pix.speed = level.speed; 
          
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
  
  void createLevelFromImage(float xres, float yres, PImage image){
      createLevelFromImage(xres, yres, image, defaultSpeed);
  }
  
  void createLevelFromImage(float xres, float yres, PImage image, float speed){    
    BasePixelRendererLevel level = createPixelRendererLevelFromType(PixelRendererLevelType.Grow); 
    level.speed = speed; 
    
    int w = (int)(width / xres); 
    int h = (int)(height / yres); 
    
    if(uniformPixels){
      w = min(w,h); 
      h = min(w,h); 
    } 
    
    float randomOX = w * 0.05f;
    float randomOY = h * 0.05f; 
    
    float randomSpeed = speed * 0.2f; 
    
    int row = 0; 
    int col = 0; 
    
    for(int y=0; y<height; y+=h){           
      for(int x=0; x<width; x+=w){
        // translate into image space 
        float sx = (float)image.width / (float)width; 
        float sy = (float)image.height / (float)height;
        
        int ix = (int)(sx * x); 
        int iy = (int)(sy * y);
        int iw = (int)(min(sx * w, sy * h));
        int ih = iw; 
        
        // PImage image, int x, int y, int w, int h
        color pixelColour = getAverageColourFromImagePatch(image, ix, iy, iw, ih); 
        
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
    previousLevel = currentLevel; 
    currentLevel = level;
    
    if(previousLevel >= 0 && previousLevel<size()){
      levels.get(previousLevel).frozen = true;   
    }
    
    levels.get(currentLevel).reset();      
  }
  
  public int size(){
    return levels.size();   
  }
  
  boolean isAnimating(){
    return !getCurrentPixelRenderer().isFinished(); 
  }  
}

class Pix{
  
  public int x; 
  public int y; 
  public int w; 
  public int h; 
  
  public color[] colours; 
  public color srcColour = color(255, 255, 255); 
  public color dstColour = color(255, 255, 255); 
  
  public float elapsedTime = 0.0f;
  public float animTime = 2000.0f;
  
  private int currentLevel = 0; 
  
  public Pix(int x, int y, int w, int h, int levels){
    this.x = x; 
    this.y = y; 
    this.w = w; 
    this.h = h; 
    
    this.colours = new color[levels];   
  }
  
  public void draw(PGraphics graphics, float et){
    elapsedTime += et; 
    
    color currentColour = getCurrentColour();
    
    graphics.fill(currentColour);
    graphics.stroke(currentColour);
    graphics.rect( x * w, y * h, w, h);
  }
  
  public void setLevel(int level){
    if(colours == null || level < 0 || level >= colours.length)
      return;
    
    setLevel(level, colours[currentLevel]);                  
  }
  
  public void setLevel(int level, color usingSrcColour){
    if(colours == null || level < 0 || level >= colours.length)
      return;
    
    srcColour = usingSrcColour;
    dstColour = colours[level];
    
    currentLevel = level;            
    
    elapsedTime = 0.0f;              
  }
  
  public float getCurrentAnimTime(){
    if(elapsedTime <= 0.0f){
      return 0.0f;   
    }
    float t = elapsedTime / animTime; 
    t = min(1.0f, max(t, 0.0f)); 
    return t; 
  }
  
  public color getCurrentColour(){
      return lerpColor(srcColour, dstColour, getCurrentAnimTime()); 
  }
  
  public void setColours(color[] newColours){
    for(int i=0; i<colours.length; i++){
      if(newColours.length <= i)
        break; 
        
      colours[i] = newColours[i]; 
    }
  }
  
  public void setColour(color newColour, int level){
    if(level < 0 || level >= colours.length)
      return; 
      
    colours[level] = newColour;  
  }
  
  public boolean isAnimating(){
    return elapsedTime < animTime;    
  }
  
  public int getX(){
    return x;   
  }    
  
  public int getY(){
    return y;   
  }
  
  public int getX2(){
    return x + w;   
  }
  
  public int getY2(){
    return y + h;   
  }
  
  public int getWidth(){
    return w;   
  }
  
  public int getHeight(){
    return h;   
  }    
}

BasePixelRendererLevel createPixelRendererLevelFromType(PixelRendererLevelType type){
  if(type == PixelRendererLevelType.FadeTile){
    return new FadeTilePixelRendererLevel();
  } else if(type == PixelRendererLevelType.Grow){
    return new GrowPixelRendererLevel(); 
  }
      
  return new FadeTilePixelRendererLevel(); // return default renderer  
}

class BasePixelRendererLevel{
  ArrayList<Pixel> pixelArray = new ArrayList<Pixel>();    
  
  float speed = 1.0f;
  
  int rows = 0; 
  int cols = 0; 
  
  boolean frozen = false; 
  
  BasePixelRendererLevel(){
    
  }
  
  void prepare(){
    
  }
  
  void add(Pixel pix){
    rows = max(rows, pix.row + 1); 
    cols = max(cols, pix.col + 1); 
    
    pixelArray.add(pix);   
  }
  
  int size(){
    return pixelArray.size();     
  }
  
  void update(long et, PImageBuffer srcImage, PImageBuffer dstImage){
    // override  
  }
  
  void reset(){
    frozen = false; 
  }
  
  void clear(){
    // override
  }
  
  boolean isAnimating(){
    return true;  
  }
}

class FadeTilePixelRendererLevel extends BasePixelRendererLevel{   
  
  int currentPixelIndex = 0;
  
  FadeTilePixelRendererLevel(){
    super();   
  }
  
  void update(long et, PImageBuffer srcImage, PImageBuffer dstImage){
    int index = 0; 
    for(int r=0; r<rows; r++){
      for(int c=0; c<cols; c++){
        index = (r * cols) + c; 
        
        if(!frozen){
          if(index == currentPixelIndex){
            pixelArray.get(index).age += et;            
            float t = (float)pixelArray.get(index).age/(float)(pixelArray.get(index).speed);
            t = max(min(1.0f, t), 0.0f);
            
            //println("t " + t + ", age " + pixelArray.get(index).age + ", index " + index);  
            
            if(isApproximately(t,1.0f)){
              pixelArray.get(index).update(srcImage, dstImage, 1.0f);  
              currentPixelIndex += 1; 
            } else{
              pixelArray.get(index).update(srcImage, dstImage, t);
            } 
          }
        }
      }
    }    
  }
  
  void reset(){
    super.reset(); 
    
    currentPixelIndex = 0; 
    
    for(int r=0; r<rows; r++){
      for(int c=0; c<cols; c++){
        int index = (r * cols) + c; 
        pixelArray.get(index).reset();   
      }
    }    
  }
  
  void clear(){
    currentPixelIndex = 0; 
    pixelArray.clear();      
  }
  
  boolean isAnimating(){
    return currentPixelIndex < size();  
  }
}

class GrowPixelRendererLevel extends BasePixelRendererLevel{
  
  int maxSeeds = 20; 
  
  ArrayList<PixelIndex> seeds = new ArrayList<PixelIndex>();
  ArrayList<PixelIndex> gorwn = new ArrayList<PixelIndex>();
  ArrayList<PixelIndex> growing = new ArrayList<PixelIndex>();
  
  GrowPixelRendererLevel(){
    super();   
  }
  
  void add(Pixel pix){
    super.add(pix); 
    
    //if(!pix.isGrey() && growing.size() < maxSeeds){
    //  growing.add(new PixelIndex(pix.row, pix.col)); 
    //}
  }
  
  void update(long et, PImageBuffer srcImage, PImageBuffer dstImage){    
    //for(int i=0; i<gorwn.size(); i++){
    //  PixelIndex index = gorwn.get(i);        
    //  pixelArray.get(getArrayIndex(index)).draw(); 
    //}
    
    for(int i=0; i<growing.size(); i++){
      PixelIndex pixIndex = growing.get(i);
      int index = getArrayIndex(pixIndex);       
      
      if(!frozen){
        pixelArray.get(index).age += et; 
        float t = (float)(pixelArray.get(index).age) / (float)(pixelArray.get(index).speed);
        t = max(min(1.0f, t), 0.0f);
          
        if(t == 1.0f){
          pixelArray.get(index).update(srcImage, dstImage, 1.0f);
          gorwn.add(pixIndex); 
          growing.remove(i); 
          
          addNeighboursForPixelAtIndex(pixIndex);
        } else{
          pixelArray.get(index).update(srcImage, dstImage, t);
        }   
      }
    }    
  }
  
  int getArrayIndex(PixelIndex index){
    return (cols * index.row) + index.col;   
  }
  
  void addNeighboursForPixelAtIndex(PixelIndex index){
    //int sy = index/rows; 
    //int sx = index%rows;  
    
    int sy = index.row;
    int sx = index.col;   
    
    for(int y=sy-1; y<=sy+1; y++){
      for(int x=sx-1; x<=sx+1; x++){
        if(y < 0 || y >= rows || x < 0 || x >= cols){
          continue; // bounds checking   
        }
        if(sx == x && sy == y){
          continue;   
        }
        
        PixelIndex newIndex = new PixelIndex(y, x); 
          
        if(isVisible(newIndex)){
          continue;   
        }
        
        //println("addNeighboursForPixelAtIndex " + neighbourIdx + ", x " + x + ", y " + y + ", idx " + neighbourIdx);
        
        growing.add(new PixelIndex(y, x)); 
      }
    }
  }
  
  boolean isVisible(PixelIndex index){
    // TODO: make into a sorted ArrayList 
    for(int i=0; i<growing.size(); i++){
      PixelIndex growingIndex = growing.get(i); 
      if(growingIndex.row == index.row && growingIndex.col == index.col){
        return true;   
      }      
    }
    
    for(int i=0; i<gorwn.size(); i++){
      PixelIndex gorwnIndex = gorwn.get(i); 
      if(gorwnIndex.row == index.row && gorwnIndex.col == index.col){
        return true;   
      }      
    }
    
    return false;   
  }
  
  void reset(){
    super.reset();
    
    gorwn.clear();  
    growing.clear();
    
    for(int r=0; r<rows; r++){
      for(int c=0; c<cols; c++){
        int index = (r * cols) + c; 
        pixelArray.get(index).reset();   
      }
    }
    
    setInitialSeeds(); 
  }
  
  void setInitialSeeds(){
    for(int r=0; r<rows; r++){
      for(int c=0; c<cols; c++){
        int index = (r * cols) + c; 
        pixelArray.get(index).reset();
        
        if(!pixelArray.get(index).isGrey()){
          seeds.add(new PixelIndex(r,c)); 
          //growing.add(new PixelIndex(r,c));
        }
      }
    } 
    
    while(seeds.size() > 0 && growing.size() < maxSeeds){
      int index = (int)random(0, seeds.size()); 
      growing.add(seeds.get(index)); 
      seeds.remove(index); 
    }
  }
  
  void prepare(){
    super.prepare(); 
    
    setInitialSeeds(); 
  }
  
  void clear(){
    seeds.clear(); 
    gorwn.clear();  
    growing.clear();
    pixelArray.clear();     
  }
  
  boolean isAnimating(){
    return gorwn.size() != size(); 
  }
  
}
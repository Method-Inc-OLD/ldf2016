
public enum AnimationState{
  Idle, 
  TransitionIn, 
  TransitionOut 
}

public class AnimationController{
  
  public int width; 
  public int height;
  
  public Animator[] animators; 
  public int currentAnimatorIndex = 0; 
  
  public AnimationState state = AnimationState.Idle; 
      
  public AnimationController(int width, int height){
    this.width = width; 
    this.height = height;     
  }
  
  public void init(PImage image, PImage fullColourImage, PixCollection pixCollection){
    if(animators == null){
      animators = new Animator[3];   
    }
    animators[0] = new PixCollectionAnimator(pixCollection); 
    animators[1] = new ImageAnimator(image, this.width, this.height); 
    animators[2] = new ImageAnimator(fullColourImage, this.width, this.height);     
  }
  
  public void draw(PGraphics graphics, float et){
    if(animators == null){
      graphics.background(255);
      return; 
    }
    
    int previousurrentAnimatorIndex = currentAnimatorIndex; 
    
    // lets just draw them all 
    if(currentAnimatorIndex <= 1){
      if(currentAnimatorIndex == 0 || animators[1].isAnimating()){
        animators[0].draw(graphics, et);
      }
      
      if(!animators[0].isAnimating() && currentAnimatorIndex == 0){
        currentAnimatorIndex += getState() == AnimationState.TransitionIn ? 1 : 0;
        
        if(currentAnimatorIndex == 1){
          animators[0].paused = true; 
        }
      }
    }
    
    if(currentAnimatorIndex>=1){
      if(currentAnimatorIndex == 1 || animators[2].isAnimating()){
        animators[1].draw(graphics, et);
      }
      
      if(!animators[1].isAnimating() && currentAnimatorIndex == 1){
        currentAnimatorIndex += getState() == AnimationState.TransitionIn ? 1 : -1;
        
        if(currentAnimatorIndex == 2){
          animators[1].paused = true; 
        } else if(currentAnimatorIndex == 0){
          animators[0].paused = false;
        }
      }
    }   
    
    if(currentAnimatorIndex>=2){
      animators[2].draw(graphics, et);
      
      if(!animators[2].isAnimating() && currentAnimatorIndex == 2){
        currentAnimatorIndex += getState() == AnimationState.TransitionIn ? 0 : -1;
          
        if(currentAnimatorIndex == 1){
          animators[1].paused = false; 
        } 
      }
    }
    
    if(previousurrentAnimatorIndex != currentAnimatorIndex){
      println("currentAnimatorIndex " + currentAnimatorIndex);  
    }
  }
  
  public boolean isAnimating(){
    if(animators == null){
      return false;  
    }
    for(int i=0; i<animators.length; i++){
      if(animators[i].isAnimating()){
        return true; 
      }
    }
    
    return false; 
  }
  
  public AnimationState getState(){
    return state;   
  }
  
  public void setState(AnimationState state){
    this.state = state; 
    println("setState " + state); 
    if(animators != null){
      for(int i=0; i<animators.length; i++){
        animators[i].setState(state); 
      }
    }
  }
  
}

public class Animator{
  
  boolean paused = false; 
  AnimationState state = AnimationState.Idle;
  
  public Animator(){}
  
  public void setState(AnimationState state){
    this.state = state;   
  }
  
  public AnimationState getState(){
    return state;   
  }
  
  public void draw(PGraphics graphics, float et){
      
  }
  
  public boolean isAnimating(){
    return false;   
  }
  
}

public class PixCollectionAnimator extends Animator{
  
  public PixCollection pixCollection; 
  
  public PixCollectionAnimator(PixCollection pixCollection){
    this.pixCollection = pixCollection;   
  }
   
  public void draw(PGraphics graphics, float et){
    if(pixCollection == null){
      return;   
    }
    
    pixCollection.draw(graphics, et);
    
    if(!paused && !pixCollection.isAnimating() && state != AnimationState.Idle){
      int nextLevel = pixCollection.currentLevel; 
      nextLevel += state == AnimationState.TransitionIn ? 1 : -1; 
      
      if(nextLevel >= 0 && nextLevel <= pixCollection.levels-1){
        pixCollection.setLevel(nextLevel);    
      }
    }
  }
  
  public boolean isAnimating(){
    if(pixCollection.isAnimating()){
      return true;   
    }
    int currentLevel = pixCollection.currentLevel;
    if(state == AnimationState.TransitionIn && currentLevel == pixCollection.levels -1)
      return false; 
      
    if(state == AnimationState.TransitionOut && currentLevel == 0)
      return false;  
      
    return true; 
  }
}

public class ImageAnimator extends Animator{
  
  public final float ALPHA_FADE_TIME = 5000; 
  
  public int width; 
  public int height; 
  public int alpha = 0;   
  public PImage image; 
  public float elapsedTime = 0.0f;
  public float animTime = ALPHA_FADE_TIME;
  
  public ImageAnimator(PImage image, int width, int height){
    this.image = image; 
    this.width = width; 
    this.height = height; 
  }
  
  public void draw(PGraphics graphics, float et){
    if(image == null){
      return;   
    }
    
    if(!paused){
      updateAlpha(et);
    }
    
    graphics.tint(255, alpha);  
    graphics.image(image, 0, 0, this.width, this.height);
    graphics.noTint(); 
  }
  
  public void updateAlpha(float et){
    elapsedTime += et; 
    float t = elapsedTime / animTime; 
    t = min(1.0f, max(t, 0.0f));     
    
    if(state == AnimationState.TransitionIn){
      alpha = (int)(255 * t);    
    } else if(state == AnimationState.TransitionOut){
      alpha = 255 - (int)(255 * t);  
    }
  }
  
  public boolean isAnimating(){
    return elapsedTime < animTime;  
  }
  
  public void setState(AnimationState state){
    super.setState(state); 
    
    elapsedTime = 0.0f;     
  }  
}
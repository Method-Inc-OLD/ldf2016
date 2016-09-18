
public enum AnimationState{
  Idle(0), 
  TransitionIn(1), 
  TransitionOut(2); 
  
  private final int value;
  
  private AnimationState(int value) {
    this.value = value;
  }

  public int getValue() {
    return value;
  }
}

public class AnimationController{
  
  public int width; 
  public int height;
  
  public Animator[] animators; 
  public int currentAnimatorIndex = 0; 
  
  public AnimationState state = AnimationState.Idle;  
  
  /**
  Requested that the last frame is only revealed when the user is close 
  **/ 
  public boolean unlockLastFrame = false; 
      
  public AnimationController(int width, int height){
    this.width = width; 
    this.height = height;           
  }
  
  public void init(PImage image, PImage fullColourImage, PixCollection pixCollection, String colourName){
    if(animators == null){
      animators = new Animator[3];   
    }
    
    TextOverlayAnimator ca = new TextOverlayAnimator(
    new TextAnimator(loadFont("Jungka-Medium-70.vlw"), colourName),
      new PixCollectionAnimator(pixCollection)        
    );        
    animators[0] = ca;    
    animators[1] = new ImageAnimator(image, this.width, this.height, ImageAnimator.DEFAULT_ALPHA_FADE_IN_TIME, ImageAnimator.DEFAULT_ALPHA_FADE_OUT_TIME); 
    animators[2] = new ImageAnimator(fullColourImage, this.width, this.height, ImageAnimator.DEFAULT_ALPHA_FADE_IN_TIME_B, ImageAnimator.DEFAULT_ALPHA_FADE_OUT_TIME_B); 
  }
  
  public Animator getAnimatorAtIndex(int index){
    return animators[index];   
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
        currentAnimatorIndex += (getState() == AnimationState.TransitionIn && unlockLastFrame) ? 1 : -1;
        
        if(currentAnimatorIndex == 2){
          animators[1].paused = true; 
        } else if(currentAnimatorIndex == 0){
          animators[0].paused = false;
        }
      }
    }   
    
    if(currentAnimatorIndex>=2){
      if(unlockLastFrame && state == AnimationState.TransitionIn && animators[2].state == AnimationState.TransitionOut){
        animators[2].state = AnimationState.TransitionIn;      
      } else if(!unlockLastFrame && state == AnimationState.TransitionIn && animators[2].state == AnimationState.TransitionIn){
        animators[2].state = AnimationState.TransitionOut;      
      }
        
      
        animators[2].draw(graphics, et);
        
        if(!animators[2].isAnimating() && currentAnimatorIndex == 2){
          currentAnimatorIndex += (getState() == AnimationState.TransitionIn && unlockLastFrame) ? 0 : -1;
            
          if(currentAnimatorIndex == 1){
            animators[1].paused = false; 
          } 
        }
      }  
    
    if(previousurrentAnimatorIndex != currentAnimatorIndex){
      println("currentAnimatorIndex " + currentAnimatorIndex);  
    }
  }
  
  public void setPaused(boolean paused){
    if(animators == null){
      return;  
    }
    
    for(int i=0; i<animators.length; i++){
      animators[i].setPaused(paused); 
    } 
  }
  
  public boolean isPasued(){
    for(int i=0; i<animators.length; i++){
      if(animators[i].isPaused()){
        return true;   
      }
    }
    
    return false; 
  }
  
  public boolean isAnimating(){
    if(animators == null){
      return false;  
    }
    
    return animators[currentAnimatorIndex].isAnimating(); 
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
  AnimationState state = AnimationState.TransitionOut;
  
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
  
  public void hide(){
    
  }
  
  public void show(){
    
  }  
  
  public void setPaused(boolean pause){
    this.paused = pause;     
  }
  
  public boolean isPaused(){
    return paused;   
  }
}

public class TextOverlayAnimator extends Animator{
  
  TextAnimator textAnimator; 
  Animator animator;  
  
  public TextOverlayAnimator(TextAnimator textAnimator, Animator animator){
    super(); 
    
    this.textAnimator = textAnimator; 
    this.animator = animator; 
  }
  
  public void setState(AnimationState state){
    this.state = state;  
    
    this.textAnimator.setState(state); 
    this.animator.setState(state);
  }
 
  public AnimationState getState(){
    return state;   
  }
  
  public void draw(PGraphics graphics, float et){
    if(state == AnimationState.TransitionIn){
      this.animator.draw(graphics, this.textAnimator.isAnimating() ? 0 : et); 
      this.textAnimator.draw(graphics, et);
    } else if(state == AnimationState.TransitionOut){
      this.animator.draw(graphics, et); 
      if(!this.animator.isAnimating()){
        this.textAnimator.draw(graphics, et);      
      }
    }    
  }
  
  public boolean isAnimating(){
    return this.textAnimator.isAnimating() || animator.isAnimating(); 
  }
  
  public void hide(){
    this.textAnimator.hide();  
    this.animator.hide();   
  }
  
  public void show(){
    this.textAnimator.show();  
    this.animator.show();
  }  
  
  public void setPaused(boolean pause){
    this.paused = pause;
    
    this.textAnimator.setPaused(this.paused);  
    this.animator.setPaused(this.paused);
  }
  
  public boolean isPaused(){
    return paused;   
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
  
  public void setState(AnimationState state){
    super.setState(state); 
  }
  
  public void setPaused(boolean pause){
    super.setPaused(pause); 
    
    pixCollection.paused = this.paused; 
  } 
}

public class TextAnimator extends Animator{
  public final float ALPHA_FADE_OUT_TIME = 500;
  public final float ALPHA_FADE_IN_TIME = 500;
  
  public int alpha = 0;   
  public float elapsedTime = 0.0f;
  public float animTime = ALPHA_FADE_OUT_TIME;
  public PFont font;
  public String text = "";
  public int size = 40;
  
  public TextAnimator(PFont font, String text){
    this.font = font; 
    this.text = text; 
  }
  
  public void draw(PGraphics graphics, float et){
    if(text == null){
      return;   
    }
    
    if(!isPaused() && state != AnimationState.Idle){
      updateAlpha(et);
    }
    
    graphics.textAlign(CENTER, CENTER);
    graphics.fill(255, 255, 255, alpha);
    graphics.stroke(255, 255, 255, alpha); 
    graphics.textFont(font, size);
    graphics.textFont(font);
    graphics.text(text, graphics.width/2, graphics.height/2);
  }
  
  public void updateAlpha(float et){
    elapsedTime += et; 
    float t = elapsedTime / animTime; 
    t = min(1.0f, max(t, 0.0f));     
    
    if(state == AnimationState.TransitionOut){
      alpha = (int)(255 * t);         
    } else if(state == AnimationState.TransitionIn){      
      alpha = 255 - (int)(255 * t);
    }
  }
  
  public boolean isAnimating(){
    return elapsedTime < animTime;  
  }
  
  public void setState(AnimationState state){
    super.setState(state); 
    
    animTime = state == AnimationState.TransitionIn ? ALPHA_FADE_IN_TIME : ALPHA_FADE_OUT_TIME;
    
    elapsedTime = 0.0f;     
  } 
}

public class ImageAnimator extends Animator{
  
  public static final float DEFAULT_ALPHA_FADE_IN_TIME = 300;
  public static final float DEFAULT_ALPHA_FADE_OUT_TIME = 300;
  
  public static final float DEFAULT_ALPHA_FADE_IN_TIME_B = 600;
  public static final float DEFAULT_ALPHA_FADE_OUT_TIME_B = 600;
  
  public int width; 
  public int height; 
  public int alpha = 0;   
  public PImage image; 
  public float elapsedTime = 0.0f;
  public float animInTime = DEFAULT_ALPHA_FADE_IN_TIME;
  public float animOutTime = DEFAULT_ALPHA_FADE_OUT_TIME;
  
  public ImageAnimator(PImage image, int width, int height){
    this.image = image; 
    this.width = width; 
    this.height = height; 
  }
  
  public ImageAnimator(PImage image, int width, int height, float animInTime, float animOutTime){
    this.image = image; 
    this.width = width; 
    this.height = height; 
    this.animInTime = animInTime;
    this.animOutTime = animOutTime;
  }
  
  public void draw(PGraphics graphics, float et){
    if(image == null){
      return;   
    }
    
    if(!isPaused()){
      updateAlpha(et);
    }
    
    graphics.tint(255, alpha);  
    graphics.image(image, 0, 0, this.width, this.height);
    graphics.noTint(); 
  }
  
  public void updateAlpha(float et){
    elapsedTime += et; 
    float t = elapsedTime / getAnimTime(); 
    t = min(1.0f, max(t, 0.0f));     
    
    if(state == AnimationState.TransitionIn){
      alpha = (int)(255 * t);         
    } else if(state == AnimationState.TransitionOut){      
      alpha = 255 - (int)(255 * t);
    }
  }
  
  public float getAnimTime(){
    if(state == AnimationState.TransitionIn){
      return animInTime;          
    } else if(state == AnimationState.TransitionOut){      
      return animOutTime;
    }
    
    return Math.min(animInTime, animOutTime);
  }
  
  public boolean isAnimating(){
    return elapsedTime < getAnimTime();  
  }
  
  public void setState(AnimationState state){
    super.setState(state); 
    
    elapsedTime = 0.0f;     
  } 
}
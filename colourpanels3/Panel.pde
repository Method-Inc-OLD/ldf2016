
class Panel{
  
  float delay = 0;
  
  float x, y, xSize, ySize;
  int index;
  
  color currentColour = color( 255,0,0);
  color originalColour = color( 255,0,0);
  color targetColour = color( 0,255,0);
  
  boolean transitionFinished = true;
  float transitionTimer = 0;
  float transitionInterp = 0;
  
  float interSpeed = 0.01;
  
  
  Panel( float initx, float inity, float initSizeX, float initSizeY, int initIndex ){
    x = initx;
    y = inity;
    xSize = initSizeX;
    ySize = initSizeY;
    index = initIndex;
    
  }
  
  public void transitionTo( color newColour, float newDelay ){
    delay = newDelay;
    transitionTo( newColour );
  }
  
  public void transitionTo( color newColour ){
    
    if ( transitionFinished ){
     originalColour = currentColour;
     targetColour = newColour;
     transitionTimer = millis();
     transitionFinished = false;
     transitionInterp = 0;
    } else {
     originalColour = currentColour;
     targetColour = newColour;
     transitionInterp = 0;
    }
      
  }
  
  public void update(){
    
    if ( !transitionFinished && millis() > (transitionTimer + delay) ){
      currentColour = lerpColor( originalColour, targetColour, transitionInterp );
      transitionInterp += interSpeed;
    }
    
    if ( transitionInterp > 1 ){
     transitionInterp = 0;
     transitionFinished = true;
     originalColour = targetColour;
    }
    
  }
  
  public void display(){
    pushMatrix();
    translate( x, y );
      fill(currentColour);
      stroke(currentColour);
      //noStroke();
      //ellipse( 0, 0, size, size );
      rect( 0, 0, xSize, ySize );
      
      //fill( 255, 10 );
      //textFont( font, 24 );
      //textAlign(CENTER, CENTER);
      //text( index, xSize*0.5, ySize*0.5 );
    
    popMatrix();
    
  }
}
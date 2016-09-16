

class Animator{
 
 PGraphics near;
 PGraphics medium;
 PGraphics far;
 
 PGraphics newNear;
 PGraphics newMedium;
 PGraphics newFar;
 
 boolean shouldChangeColours = false;
 float changeInterp = 0;
 
 Sensor sensor;
 
 int state = -1;
 float interpolator = -1;

  
 Animator( Sensor _sensor ){
   println("setting up animator");
   
   sensor = _sensor;
   
 } 
 
 void updateGraphics( PGraphics _near, PGraphics _medium, PGraphics _far ){
   println( "updating graphics" );
   
   newNear = _near;
   newMedium = _medium;
   newFar = _far;
   
   if ( near == null || medium == null || far == null ){
     near = _near;
     medium = _medium;
     far = _far;     
   } else {
     shouldChangeColours = true; 
     changeInterp = 0;
   }

   
 }
 
 
 void update(){
   
   int targetState = sensor.getState(); 
   state = targetState;
   
   float distanceToTarget = abs( targetState - interpolator );
   if ( distanceToTarget > 0.02 ){
    int direction = interpolator > targetState ? -1 : 1;
    interpolator = interpolator + direction * transitionSpeed;     
   } else {
    interpolator = targetState; 
   }
   
      
   
   render();
 }
 
 
 void render(){
   
   
   //println( "INT: " + interpolator + " | " + nearInterp1 );
   
   background(0);

   // ISSUE
   if( interpolator < 0 ){
     float nearInterp = map( interpolator, -1, 0, 0, 1 );
     tint( 255, nearInterp*255 );
     image( near, 0, 0 );
     
   // NEAR
   } else if ( interpolator >= 0 && interpolator < 1 ){
     float nearInterp = sqrt( map( interpolator, 0, 1, 1, 0 ) );
     tint( 255, nearInterp*255 );
     image( near, 0, 0 );
     
     float mediumInterp = sqrt( map( interpolator, 0, 1, 0, 1 ) );
     tint( 255, mediumInterp*255 );
     image( medium, 0, 0 );
   
   // MEDIUM
   } else if( interpolator >= 1 && interpolator < 2 ){
     float mediumInterp = map( interpolator, 1, 2, 1, 0 );
     tint( 255, mediumInterp*255 );
     image( medium, 0, 0 );
     
     float farInterp = map( interpolator, 1, 2, 0, 1 );
     tint( 255, farInterp*255 );
     image( far, 0, 0 );
   } else if ( interpolator >= 2 ){
     tint( 255, 255 );
     image( far, 0, 0 );
   }
   
   
   
   if ( shouldChangeColours ){
    if ( changeInterp < 1 ){
      // changing
      
      println("interpolating");
      
      if( interpolator < 0 ){
        // nothing
        tint( 255, changeInterp*255 );
        image( newNear, 0, 0 );
      } else if ( interpolator >= 0 && interpolator < 1 ){
        tint( 255, changeInterp*255 );
        image( newNear, 0, 0 );
      } else if( interpolator >= 1 && interpolator < 2 ){
        tint( 255, changeInterp*255 );
        image( newMedium, 0, 0 );
      } else if ( interpolator >= 2 ){
        tint( 255, changeInterp*255 );
        image( newFar, 0, 0 );
      }
      
      changeInterp += transitionSpeed;
      
    } else {
      // finished
      changeInterp = 0;
      shouldChangeColours = false;
      println("changed");
      
      near = newNear;
      far = newFar;
      medium = newMedium;
      
    }
   }
   
 }
 
 
 public void changeGraphics(){
   
   println("changing colours");
   
   interpolator = -1;
   
 }
  
}
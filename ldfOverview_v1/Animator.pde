

class Animator{
 
 PGraphics near;
 PGraphics medium;
 PGraphics far;
 
 PGraphics newNear;
 PGraphics newMedium;
 PGraphics newFar;
 
 Sensor sensor;
 
 int state = -1;
 float interpolator = -1;

  
 Animator( Sensor _sensor ){
   println("setting up animator");
   
   sensor = _sensor;
   
 } 
 
 void updateGraphics( PGraphics _near, PGraphics _medium, PGraphics _far ){
   println( "updating graphics" );
   
   near = _near;
   medium = _medium;
   far = _far;
   
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
   
 }
 
 
 public void changeGraphics(){
   
   println("changing colours");
   
   interpolator = -1;
   
 }
  
}
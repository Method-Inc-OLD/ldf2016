
class UltrasonicSensor extends BaseUltrasonicSensor{
  
  final int FAR_DISTANCE = 100000; 
  final int CLOSE_DISTANCE = 5000; 
  
  //int distanceIncrement = 1000; 
    
  UltrasonicSensor(){
    super();     
    
    currentDistance = FAR_DISTANCE;
  }
   
  void update(){
    //if(keyPressed){
    //  if (keyCode == UP) {
    //    currentDistance += distanceIncrement;   
    //  } else if(keyCode == DOWN){
    //    currentDistance -= distanceIncrement; 
    //  }           
    //}
  }
  
  boolean onKeyDown(int keyCode){    
    if(keyCode == UP || keyCode == DOWN){
      currentDistance = currentDistance == FAR_DISTANCE ? CLOSE_DISTANCE : FAR_DISTANCE; // toggle                 
    }
    
    return true; 
  }
   
  boolean isReady(){
    return true;    
  }   
}
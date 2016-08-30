
enum ProximityRange{
  Undefined, 
  Close, 
  Medium,
  MediumFar, 
  Far
}

class BaseUltrasonicSensor{
  
  int currentDistance = 0;
  
  ProximityRange previousRange = ProximityRange.Undefined; 
  ProximityRange currentRange = ProximityRange.Undefined;
    
  BaseUltrasonicSensor(){
      
   }
   
   void update(){
       
   }
   
   boolean isReady(){
    return true;    
  }
  
  boolean onKeyDown(int keyCode){    
    return false; 
  }
  
  ProximityRange getCurrentRange(){
    previousRange = currentRange;
    
    int distance = currentDistance; 
    if(distance > 100000){
      currentRange = ProximityRange.Far;
    } else if(distance >= 80000){
      currentRange = ProximityRange.MediumFar;
    } else if(distance >= 50000){
      currentRange = ProximityRange.Medium;
    } else{
      currentRange = ProximityRange.Close;
    }
    
    return currentRange; 
  }
  
}
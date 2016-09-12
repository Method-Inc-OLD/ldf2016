enum ProximityRange{
  Undefined, 
  Close, 
  Medium, 
  MediumFar, 
  Far 
}

/** factory method **/ 
ProximityDetector createProximityDetector(){
  ProximityDetector pd;
   pd = new MockProximityDetector();
  //pd = new UltrasonicProximityDetector();
  
  return pd; 
}

class ProximityDetector{
  
  final int QUEUE_SIZE = 1;  
  
  float rawDistance = 0.0f; 
  
  FloatList distanceQueue = new FloatList();  
  
  float rangeChangedTimestamp = 0.0f;
  
  int updatesPerSecond = 0; // counter of how many updates occur per second 
  float elapsedTimeSinceUpdate = 0; 
  float lastUpdateTimestamp = 0;
  int updatesPerSecondCounter = 0;
  
  ProximityRange previousRange = ProximityRange.Undefined; 
  ProximityRange currentRange = ProximityRange.Undefined;
  
  ProximityDetector(){
    
  }
  
  public void update(){
    float et = millis() - lastUpdateTimestamp; 
    lastUpdateTimestamp = millis(); 
    
    elapsedTimeSinceUpdate += et;        
    
    if(elapsedTimeSinceUpdate >= 1000){
      updatesPerSecond = updatesPerSecondCounter; 
      updatesPerSecondCounter = 0; 
      elapsedTimeSinceUpdate -= 1000;
    }    
    
    updatesPerSecondCounter += 1;
  }    
  
  boolean onKeyDown(int keyCode){
    return false; 
  }
  
  ProximityRange distanceToProximityRange(float distance){
    return ProximityRange.Undefined;   
  }  
  
  public void setCurrentRange(ProximityRange range){
    if(range != this.currentRange && millis() - rangeChangedTimestamp < 50){
      return; // mitigate flipping between states; only change if a range has been set for longer than X   
    }
    rangeChangedTimestamp = millis(); 
    this.previousRange = this.currentRange; 
    this.currentRange = range; 
  }
  
  public ProximityRange getCurrentRange(){
    return this.currentRange;  
  }
  
  public float getDistance(){
    if(distanceQueue.size() == 0){
      return 0.0f;   
    }
    
    float total = 0.0f; 
    for(int i=0; i<distanceQueue.size(); i++){
      total += distanceQueue.get(i);   
    }
    return total / distanceQueue.size();  
  }
  
  public void setDistance(float distance){
    distanceQueue.append(distance);
    
    while(distanceQueue.size() > QUEUE_SIZE){
      distanceQueue.remove(0); 
    }
    
    
    // update proximity range 
    ProximityRange newRange = distanceToProximityRange(this.getDistance()); 
    setCurrentRange(newRange); 
  }
  
  public boolean isReady(){
    return true;   
  }
}

class MockProximityDetector extends ProximityDetector{
  
  final int DISTANCE_INCREMENT = 50; 
  
  public MockProximityDetector(){
    super(); 
    setDistance(150); 
  }
  
  boolean onKeyDown(int keyCode){    
    if(keyCode == UP){
      setDistance(getDistance() + DISTANCE_INCREMENT); 
      return true; 
    } else if(keyCode == DOWN){
      setDistance(getDistance() - DISTANCE_INCREMENT); 
      return true;
    }
    
    return false; 
  }
  
  ProximityRange distanceToProximityRange(float distance){
    ProximityRange range = ProximityRange.Undefined; 
    
    if(distance > configManager.distanceMedium){
      range = ProximityRange.Far;
    } else if(distance > configManager.distanceClose){
      range = ProximityRange.Medium;
    } else{
      range = ProximityRange.Close;
    }
    
    return range;    
  }
}
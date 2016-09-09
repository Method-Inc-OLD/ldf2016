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
  if(IS_DEV){
    pd = new MockProximityDetector();
  } else{
    //pd = new UltrasonicProximityDetector();  
  }
  
  return pd; 
}

class ProximityDetector{
  
  final int QUEUE_SIZE = 4; 
  
  boolean logging = false; 
  float loggingFrequency = 1000.0f;
  float lastLogTimestamp = 0.0f; 
  
  PrintWriter logPrintWriter;
  
  float rawDistance = 0.0f; 
  
  FloatList distanceQueue = new FloatList();  
  
  float rangeChangedTimestamp = 0.0f; 
  
  ProximityRange previousRange = ProximityRange.Undefined; 
  ProximityRange currentRange = ProximityRange.Undefined;
  
  ProximityDetector(){
    if(logging){
      initLogPrintWriter();   
    }
  }
  
  void setLogging(boolean logging){
    this.logging = logging; 
    if(!this.logging){
      if(logPrintWriter != null){
        logPrintWriter.close(); 
        logPrintWriter = null; 
      }
    } else{
      if(logPrintWriter == null){
        initLogPrintWriter();   
      }
    }
  }
  
  void initLogPrintWriter(){        
    logPrintWriter = createWriter("proximitydetector" + ".log");   
  }
  
  public void update(){
    if(logging){
      updateLog();   
    }
  }
  
  String getLogPrefix(){
    return day() + month() + year() + "-" + hour() + minute();  
  }
  
  void updateLog(){
    if(millis() - lastLogTimestamp < loggingFrequency)
      return; 
    
    lastLogTimestamp = millis(); 
    
    logPrintWriter.println(getLogPrefix() + ": " + getDistance());
    logPrintWriter.flush(); 
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
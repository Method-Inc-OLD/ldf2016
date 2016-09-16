//import processing.io.*;


//class Sensor {
  
//  static final float DISTANCE_MEDIUM = 200;
//  static final float DISTANCE_CLOSE = 130; 
  
//  static final float UP_TICK_THRESHOLD = 10;
//  static final float DOWN_TICK_THRESHOLD = 5;
  
//  static final int GPIO_TRIGGER = 23; 
//  static final int GPIO_ECHO = 24;   

//  public int previousState = -1; 
//  public int state = -1;
  
//  private int stateChangeTicks = 0;   

//  private float previousReading = -1;
//  private float currentReading = -1;   
  
//  Sensor(){
//    println("setting up sensor");
//    initSensor(); 
//  }
  
//  synchronized public int getState(){
//   return state; 
//  }      
  
//  synchronized void setState(int state){
//    this.state = state;   
//  }

//  private void initSensor() {
//    GPIO.pinMode(GPIO_TRIGGER, GPIO.OUTPUT);
//    GPIO.pinMode(GPIO_ECHO, GPIO.INPUT);

//    GPIO.digitalWrite(GPIO_TRIGGER, GPIO.LOW);
//  }

//  void update() {
//    float rawDistance = measureAverage();                 
//    updateDistance(rawDistance);
//  }
   
//  private int measureAverage() {
//    float distance1 = measure();
//    delay(100); 
//    float distance2 = measure();
//    delay(100);
//    float distance3 = measure();

//    return (int)((distance1 + distance2 + distance3)/3.0f);
//  }

//  private int measure() {
//    GPIO.digitalWrite(GPIO_TRIGGER, GPIO.HIGH);
//    //delay(1);  
//    GPIO.digitalWrite(GPIO_TRIGGER, GPIO.LOW);

//    float startTime = millis(); 
//    float stopTime = millis();

//    while (GPIO.digitalRead(GPIO_ECHO) == GPIO.LOW) {
//      startTime = millis();
//    }

//    while (GPIO.digitalRead(GPIO_ECHO) == GPIO.HIGH) {
//      stopTime = millis();
//    }

//    float elapsedTime = stopTime - startTime; 
//    return (int)(((elapsedTime/1000.0f) * 34300.0f) / 2.0f);
//  }

//  private int distanceToState(float distance) {
//    if (distance > DISTANCE_MEDIUM) {
//      return 2;
//    } else if (distance > DISTANCE_CLOSE) {
//      return 1;
//    } else {
//      return 0; 
//    }
//  }  
  
//  private void updateDistance(float distance){
//    previousReading = currentReading;
//    currentReading = distance;
    
//    updateState(); 
//  }
  
//  private void updateState(){
//    int currentState = getState(); 
//    int newState = distanceToState(currentReading);  
    
//    if(currentState == newState){
//      stateChangeTicks = 0; 
//      return; 
//    }    
    
//    stateChangeTicks++; 
    
//    if(currentState == -1 || (newState < currentState && stateChangeTicks >= DOWN_TICK_THRESHOLD) ||
//      (newState > currentState && stateChangeTicks >= UP_TICK_THRESHOLD)){
//      previousState = currentState; 
//      setState(newState);      
//    }    
//  }
//}
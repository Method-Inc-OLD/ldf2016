///**
//References: 
//https://www.raspberrypi.org/blog/now-available-for-download-processing/
//https://github.com/processing/processing/wiki/Raspberry-Pi

//**/
//import processing.io.*;

//class UltrasonicSensor extends BaseUltrasonicSensor{
  
//  static final int GPIO_TRIGGER = 23; 
//  static final int GPIO_ECHO = 24;       
  
//  long lastUpdated = 0; 
  
//  boolean updating = false;     
  
//  UltrasonicSensor(){
    
//    GPIO.pinMode(GPIO_TRIGGER, GPIO.OUTPUT);
//    GPIO.pinMode(GPIO_ECHO, GPIO.INPUT);
    
//    GPIO.digitalWrite(GPIO_TRIGGER, GPIO.LOW);
//  }
  
//  void update(){
//    if(!isReady()){
//      return;   
//    }
    
//    lastUpdated = millis(); 
//    updating = true; 
//    currentDistance = measureAverage();
//    println("currentDistance " + currentDistance); 
//    updating = false;     
//  }
  
//  boolean isReady(){
//    return !updating && (millis() - lastUpdated) >= 1000;   
//  }
  
//  int measureAverage(){
//    int distance1 = measure();
//    delay(100); 
//    int distance2 = measure();
//    delay(100);
//    int distance3 = measure();
    
//    return (distance1 + distance2 + distance3)/3; 
//  }
  
//  int measure(){
//    GPIO.digitalWrite(GPIO_TRIGGER, GPIO.HIGH);
//    delay(1);  
//    GPIO.digitalWrite(GPIO_TRIGGER, GPIO.LOW);
    
//    int startTime = millis(); 
//    int stopTime = millis();
    
//    while(GPIO.digitalRead(GPIO_ECHO) == GPIO.LOW){
//      startTime = millis();   
//    }
    
//    while(GPIO.digitalRead(GPIO_ECHO) == GPIO.HIGH){
//      stopTime = millis();   
//    }
    
//    int elapsedTime = stopTime - startTime; 
//    //return (int)(((elapsedTime/1000.0f) * 34300.0f) / 2.0f);
//    return (elapsedTime * 34300) / 2; 
//  }     
//}
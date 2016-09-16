
import processing.io.*;


class Sensor {
  
  static final int GPIO_TRIGGER = 23; 
  static final int GPIO_ECHO = 24;
 
  private float distance = 0;    
  public int state = -1;
  
  private float[]smoothing;
  
  Sensor(){
    println("setting up sensor");
    
    smoothing = new float[20];
    for( int i = 0; i < smoothing.length; i++ ){
     smoothing[i] = 0; 
    }
    
    GPIO.pinMode(GPIO_TRIGGER, GPIO.OUTPUT);
    GPIO.pinMode(GPIO_ECHO, GPIO.INPUT);
    
    GPIO.digitalWrite(GPIO_TRIGGER, GPIO.LOW);
  }
  
  
  public void update(){
    
    GPIO.digitalWrite(GPIO_TRIGGER, GPIO.HIGH);
    //delay(50);  
    GPIO.digitalWrite(GPIO_TRIGGER, GPIO.LOW);

    float startTime = millis(); 
    float stopTime = millis();

    while (GPIO.digitalRead(GPIO_ECHO) == GPIO.LOW) {
      startTime = millis();
    }

    while (GPIO.digitalRead(GPIO_ECHO) == GPIO.HIGH) {
      stopTime = millis();
    }

    float elapsedTime = stopTime - startTime;
    float elapsedCalc = ((elapsedTime/1000.0f) * 34300.0f) / 2.0f;
    float dst = map( constrain( elapsedTime, 0, 30 ), 0, 30, 0, 1 );        
    
    // shift the array
    for( int i = 0; i < smoothing.length-1; i++ ){
     smoothing[i] = smoothing[i+1]; 
    }
    
    // smooth
    smoothing[smoothing.length-1] = dst;
    float avg = 0;
    for( int i = 0; i < smoothing.length; i++ ){
     float val = smoothing[i];
     avg += val;
    }
    avg = avg/(float)smoothing.length;
    distance = avg;    
    
    if ( distance < distNear ){
     state = 0; 
    } else if ( distance >= distNear && distance < distMedium ){
     state = 1; 
    } else {
      state = 2;
    }
    
    //println( distance + " | " + elapsedCalc +" | "+ dst + " | " + elapsedTime );
    
    // 480 - 17
    
  }
  
  
  
  
  
  
  
  
  
  
  
  
  public int getState(){
   return state; 
  }
  
  public float getDistance(){
   return distance; 
  }
  
}
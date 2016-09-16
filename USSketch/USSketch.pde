
Sensor sensor;
boolean shouldSense = true;
float distNear = 0.3;
float distMedium = 0.5;

void setup(){
  size(600,10);
  
  sensor = new Sensor();
  
  initSensor();
}

void draw(){
  
  background(0);
  stroke(255);
  strokeWeight( 5 );
  float d = sensor.getDistance();
  line( d*width, 0, d*width, height );
  
  println( sensor.getState() + " | " + sensor.getDistance() );
  
}


void initSensor(){
  thread("startSensing");
}
void startSensing(){
  println("Sensing");
  
  //sensor.update();
  while( shouldSense ){
    delay( 60 );
    sense();
  }
  
}
void sense(){
  sensor.update();
}




void keyPressed(){
  if ( key == '1' ){
   sensor.state = 0; 
   sensor.distance = 0.25;
  }
  if ( key == '2' ){
   sensor.state = 1; 
   sensor.distance = 0.5;
  }
  if ( key == '3' ){
   sensor.state = 2; 
   sensor.distance = 0.75;
  }
  if ( key == '0' ){
   sensor.state = -1; 
  }
  
}
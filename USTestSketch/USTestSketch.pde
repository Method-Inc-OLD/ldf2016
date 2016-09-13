
UltrasonicProximityDetector upd; 

void setup() {   
  frameRate(12);
  fullScreen(); 
  
  upd = new UltrasonicProximityDetector(); 
}

void draw(){
  
  float currentDistance = upd.currentDistance;   
  fill(255, 255, 255);
  stroke(255, 255, 255); 
  rect(0,0,width,height);
  
  fill(0, 0, 0);
  stroke(0, 0, 0); 
  textSize(50);
  textAlign(CENTER, CENTER);
  text("Distance " + currentDistance, width/2, height/2);     
  
  if(upd.isReady()){
    thread("updateProximity");   
  }    
}

void updateProximity(){
  upd.update();   
}
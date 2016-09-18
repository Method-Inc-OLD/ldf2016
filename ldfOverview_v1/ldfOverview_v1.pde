
float pingInterval = 300000;
//float pingInterval = 20000;
int mediumLevels = 20;
int farLevels = 5;
boolean fromImage = false;
float transitionSpeed = 0.01;

boolean loadLocal = false;

boolean shouldSense = true;
float distNear = 0.3;
float distMedium = 0.5;



Service service;
Generator generator;
Animator animator;
Sensor sensor;

void setup(){
  size( 720, 480 );
  noCursor();
  //size( 800, 400, P2D);
  //size( 1200, 800, P2D );
  //size( 2000, 1000, P2D);
  
  
  sensor = new Sensor();
  animator = new Animator( sensor );
  generator = new Generator( animator );
  
  service = new Service( generator );
  
  initSensor();
}


void draw(){
  
  animator.update();
   
  if( !service.startedLoading && service.finishedLoading ){
    println("BUM!");
    service.finishedLoading = false;
    service.reGenerate();
    
  }

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



void pingService(){
  thread( "pingTheService" );
}
void pingTheService(){
  println("fetching updates");
  service.ping();
}


void keyPressed(){
  if ( key == '1' ){
   sensor.state = 0; 
  }
  if ( key == '2' ){
   sensor.state = 1; 
  }
  if ( key == '3' ){
   sensor.state = 2; 
  }
  if ( key == '0' ){
   sensor.state = -1; 
  }
  
  if ( key == 'p' ){
   pingService(); 
  }
  
  if ( key == 'r' ){
   animator.changeGraphics();
  }
}
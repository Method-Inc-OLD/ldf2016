

int mediumLevels = 20;
int farLevels = 6;
boolean fromImage = false;
float transitionSpeed = 0.01;


Service service;
Generator generator;
Animator animator;
Sensor sensor;

void setup(){
  size( 720, 480, P2D );
  noCursor();
  //size( 800, 400, P2D);
  //size( 1200, 800, P2D );
  //size( 2000, 1000, P2D);
  
  
  sensor = new Sensor();
  animator = new Animator( sensor );
  generator = new Generator( animator );
  
  service = new Service( generator );
  
}


void draw(){
  
  animator.update();
   
  if( !service.startedLoading && service.finishedLoading ){
    println("BUM!");
    service.finishedLoading = false;
    service.reGenerate();
    
  }
}


void pingService(){
  thread( "pingTheService" );
}
void pingTheService(){
  println("pinging it");
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
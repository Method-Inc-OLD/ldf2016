

int xnum = 30;
int ynum = 20;

PFont font;

PImage photo;

Panel[] panels;

void setup(){
  frameRate(30);
  
  size( 600, 400, P2D );  
  background(0);
  
  font = createFont("helvetica.vlw", 100);
  photo = loadImage( "image.jpg" );
  photo.resize( xnum, ynum );
  photo.loadPixels();
  
  panels = new Panel[xnum*ynum];
  
  int index = 0;

  for ( int yi = 0; yi < ynum; yi++ ){
    for ( int xi = 0; xi < xnum; xi++ ){    
    
      
      panels[index] = new Panel( xi * ( width/(float)xnum ), yi * ( height/(float)ynum ), 
                                        width/(float)xnum, height/(float)ynum, index );
      index++;
      
    }    
  }
  
} // end of setup


void draw(){
  background(0);
  
  for( int i = 0; i < panels.length; i++ ){
    panels[i].update();
    panels[i].display(); 
  }
 
  fill(255, 255, 255);
  text(frameRate, 20, 20);
  
}// end of draw



void allocatePixels( int resolution ){
  
  for ( int x = 0; x < xnum; x++ ){
   for ( int y = 0; y < ynum; y++ ){
    
     int index = x + y*xnum;
     
     int fakex = (x/(int)resolution) * (resolution);
     int fakey = (y/(int)resolution) * (resolution);
     int fakeIndex = fakex + fakey*xnum;
     color pixel = photo.pixels[fakeIndex];
     panels[index].transitionTo( pixel, index*5 );
   }
  }
}


void keyPressed(){
    
  
  
  switch( key ){
    case '1':
      println( "pressed one" );
      color newc = color( random(255),random(255),random(255));      
      for( int i = 0; i < panels.length; i++ ){
        panels[i].transitionTo( newc, i*5 );   
      }
      
    break;
    case '2':
      println( "pressed two" );
      allocatePixels ( 9 );
    break;
    case '3':
      println( "pressed three" );
      allocatePixels ( 8 );
    break;
    case '4':
      println( "pressed four" );
      allocatePixels ( 7 );
    break;
    case '5':
      println( "pressed five" );
      allocatePixels ( 6 );
    break;
    case '6':
      println( "pressed six" );
      allocatePixels ( 5 );
    break;
    case '7':
      println( "pressed seven" );
      allocatePixels ( 4 );
    break;
    case '8':
      println( "pressed eight" );
      allocatePixels ( 3 );
    break;
    case '9':
      println( "pressed nine" );
      allocatePixels ( 2 );
    break;
    case '0':
      println( "pressed ten" );
      allocatePixels ( 1 );
    break;
    default:
    break;
  }
  
  
}
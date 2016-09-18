

class Generator{
 
  float saturationBoost = 0.1;
  float lightnessBoost = 0.1;
  
  Animator animator;
  
  Generator( Animator myanimator ){
    println("Setting up generator");
    
    animator = myanimator;    
  }
  
  // Regenerate images
  public void reGenerate( ArrayList<Colour> allColours, 
                          ArrayList<Colour> mediumColours, 
                          ArrayList<Colour> farColours ){
   
   println("regenerating");
   
   
   PGraphics allColloursImage = generateAll( allColours );
   //image( allColloursImage, 0, 0 );
   
   PGraphics mediumColloursImage = generateLevel( mediumColours );
   //image( mediumColloursImage, 0, 0 );
   
   PGraphics farColloursImage = generateLevel( farColours );
   //image( farColloursImage, 0, 0 );
   
   animator.updateGraphics( allColloursImage, mediumColloursImage, farColloursImage );
    
  } // end of regenerate
  
  
  PGraphics generateAll( ArrayList<Colour> colours ){
    
     Collections.sort( colours, new CompareByHue() );
          
     PGraphics pg = createGraphics( width, height );
     pg.beginDraw();
    
     pg.background(0);
     pg.noStroke();
     pg.colorMode( HSB, 360, 1, 1);
     float cw = width/(float)colours.size();
     for( int i = 0; i < colours.size(); i++ ){
       Colour c = colours.get(i);
       pg.fill( c.hsl[0], c.hsl[1], c.hsl[2] );
       pg.noStroke();
       pg.rect( i*cw, 0, cw, height  );
     }
     pg.endDraw();
     
     return pg;
     //image( pg, 0, 0 );
  }
  
  PGraphics generateLevel( ArrayList<Colour> colours ){
    
    Collections.sort( colours, new CompareByHue() );
    
    PGraphics pg = createGraphics( width, height );
    pg.beginDraw();
    
    pg.background(0);
    pg.noStroke();
    pg.colorMode( HSB, 360, 1, 1);
    
    float x = 0;
    for( int i = 0; i < colours.size(); i++ ){
      Colour c = colours.get(i);
      
      float cw = c.population*width;
      
      pg.fill( c.hsl[0], c.hsl[1] + saturationBoost, c.hsl[2] + lightnessBoost );
      pg.noStroke();
      pg.rect( x, 0, cw, height  );
      x += cw;
    }
    
    pg.endDraw();
    
    return pg;
    
  }
  
}
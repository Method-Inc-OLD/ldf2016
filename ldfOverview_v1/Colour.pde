
import java.util.*;

class Colour{
  
  float[] hsl = new float[3];
  float[] rgb = new float[3];
  float population = 0;
  
  Colour( float[] newhsl, float[] newrgb ){
    hsl = newhsl;
    rgb = newrgb;
  }
  
  Colour( float[] newhsl, float[] newrgb, float newpopulation ){
    hsl = newhsl;
    rgb = newrgb;
    population = newpopulation;
  }
  
  void printOut(){
    println( hsl[0] );
    println( rgb[0] );
  }
}

class CompareByHue implements Comparator{
  @Override
  public int compare( Object o1, Object o2 ){
   Colour c1 = (Colour)o1;
   Colour c2 = (Colour)o2;
    
   //return (int)(c1.hsl[0] - c2.hsl[0]);
   float val = c1.hsl[0] -c2.hsl[0];
   
   if ( val > 0 ){
    return 1;   
   } else if ( val < 0){
     return -1;
   } else {
     return 0;
   }
  }
}

class CompareByLightness implements Comparator{
  @Override
  public int compare( Object o1, Object o2 ){
   Colour c1 = (Colour)o1;
   Colour c2 = (Colour)o2;
   
   float val = c1.hsl[2] -c2.hsl[2];
   
   if ( val > 0 ){
    return 1;   
   } else if ( val < 0){
     return -1;
   } else {
     return 0;
   }
  }
}

class CompareBySaturation implements Comparator{
  @Override
  public int compare( Object o1, Object o2 ){
   Colour c1 = (Colour)o1;
   Colour c2 = (Colour)o2;
    
   float val = c1.hsl[1] -c2.hsl[1];
   
   if ( val > 0 ){
    return 1;   
   } else if ( val < 0){
     return -1;
   } else {
     return 0;
   }
   
  }
}
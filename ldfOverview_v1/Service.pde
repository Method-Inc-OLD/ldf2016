
class Service{
 
  
  
  Generator generator;
  
  public boolean startedLoading = false;
  public boolean finishedLoading = false;
  
  ArrayList<ArrayList<Colour>> latestClrs;
  
  Service( Generator gen ){
   println("Setting up service");
   
   generator = gen;
   
   latestClrs = null;
   
   latestClrs = retreiveColours();
   if ( latestClrs != null ){
     reGenerate();
   }
   //generator.reGenerate( latestClrs.get(0), latestClrs.get(1), latestClrs.get(2) );
      
  } // end of initialise
  
  
  ArrayList<ArrayList<Colour>> retreiveColours(){
     
     // Level 0 (clost) - all colours
     ArrayList<Colour> allColours = new ArrayList();
     
     JSONObject allColoursJson = null;
     JSONObject mediumColoursJson = null;
     JSONObject farColoursJson = null;
     
     if ( loadLocal ){
       
       allColoursJson = loadJSONObject("coloursnear.json");
       mediumColoursJson = loadJSONObject("coloursmedium.json");
       farColoursJson = loadJSONObject("coloursfar.json");
       
     } else {
       try {
         allColoursJson = loadJSONObject("http://instacolour.herokuapp.com/api/ldfcolours");
       } catch (Exception e){
         println("network issue");
       }
       
       
       if( fromImage ){
         try{
           mediumColoursJson = loadJSONObject("http://instacolour.herokuapp.com/api/ldfpalette?from_image=yes&colours=" + mediumLevels);
         } catch (Exception e){
           println("network issue"); 
         }       
       } else {
         try{
           mediumColoursJson = loadJSONObject("http://instacolour.herokuapp.com/api/ldfpalette?colours=" + mediumLevels);
         } catch (Exception e){
           println("network issue"); 
         }
       }
       
       if ( fromImage ){
         try{
           farColoursJson = loadJSONObject("http://instacolour.herokuapp.com/api/ldfpalette?colours=" + farLevels);
         } catch( Exception e ){
           println("network issue"); 
         }
       } else {
         try{
           farColoursJson = loadJSONObject("http://instacolour.herokuapp.com/api/ldfpalette?from_image=yes&colours=" + farLevels);
         } catch( Exception e ){
           println("network issue"); 
         }
       }
     }
     
     if( allColoursJson != null && mediumColoursJson != null && farColoursJson != null ){
       
       
       JSONArray allColoursJsonArr = allColoursJson.getJSONArray("colours");
     
       for ( int i = 0; i < allColoursJsonArr.size(); i++ ){
    
          JSONObject colour = allColoursJsonArr.getJSONObject(i);
          JSONArray hsl = colour.getJSONArray("hsl");
          JSONArray rgb = colour.getJSONArray("rgb");
          
          float[] hsls = new float[3];
          hsls[0] = hsl.getFloat(0);
          //hsls[0] = hsl.getFloat(0) + random(180);
          hsls[1] = hsl.getFloat(1);
          hsls[2] = hsl.getFloat(2);
          
          float[] rgbs = new float[3];
          rgbs[0] = rgb.getFloat(0);
          rgbs[1] = rgb.getFloat(1);
          rgbs[2] = rgb.getFloat(2);
          
          Colour c = new Colour( hsls, rgbs );
          allColours.add( c );
       }
       
       // Level 1 - medium
       ArrayList<Colour> mediumColours = new ArrayList();
       
         
       JSONArray mediumColourSwatches = mediumColoursJson.getJSONObject("palette").getJSONArray("swatches");
       for( int i = 0; i < mediumColourSwatches.size(); i++ ){
         JSONObject colour = mediumColourSwatches.getJSONObject(i);
         JSONArray hsl = colour.getJSONArray("hsl");
         JSONArray rgb = colour.getJSONArray("rgb");
         float population = colour.getFloat("population");
         
         float[] hsls = new float[3];
         //hsls[0] = hsl.getFloat(0) + random(180);
         hsls[0] = hsl.getFloat(0);
         hsls[1] = hsl.getFloat(1);
         hsls[2] = hsl.getFloat(2);
          
         float[] rgbs = new float[3];
         rgbs[0] = rgb.getFloat(0);
         rgbs[1] = rgb.getFloat(1);
         rgbs[2] = rgb.getFloat(2);
         
         Colour c = new Colour( hsls, rgbs, population );
         mediumColours.add( c );
         
       }
       
       //generator.reGenerate( mediumColours );
       
       // Level 2 - far
       ArrayList<Colour> farColours = new ArrayList();
       
       JSONArray farColourSwatches = farColoursJson.getJSONObject("palette").getJSONArray("swatches");
       
       
       for( int i = 0; i < farColourSwatches.size(); i++ ){
         JSONObject colour = farColourSwatches.getJSONObject(i);
         JSONArray hsl = colour.getJSONArray("hsl");
         JSONArray rgb = colour.getJSONArray("rgb");
         float population = colour.getFloat("population");
         
         float[] hsls = new float[3];
         //hsls[0] = hsl.getFloat(0) + random(180);
         hsls[0] = hsl.getFloat(0);
         hsls[1] = hsl.getFloat(1);
         hsls[2] = hsl.getFloat(2);
          
         float[] rgbs = new float[3];
         rgbs[0] = rgb.getFloat(0);
         rgbs[1] = rgb.getFloat(1);
         rgbs[2] = rgb.getFloat(2);
         
         Colour c = new Colour( hsls, rgbs, population );
         farColours.add( c );
         
       }
     
       ArrayList<ArrayList<Colour>> clrs = new ArrayList<ArrayList<Colour>>();
       clrs.add( allColours );
       clrs.add( mediumColours );
       clrs.add( farColours );
       
       return clrs;
       
       
     } else {
       println("Service couldn't load colours");
       return null;       
     }
     
     
   
   } // end of ask for colours
  
  
  public void ping(){
     println("pp pinging");
     startedLoading = true;
     finishedLoading = false;
     latestClrs = retreiveColours();
     finishedLoading = true;
     startedLoading = false;
     //generator.reGenerate( clrs.get(0), clrs.get(1), clrs.get(2) );
  }
  
  public void reGenerate(){
    if( latestClrs != null ){
      generator.reGenerate( latestClrs.get(0), latestClrs.get(1), latestClrs.get(2) );
    }
  }
}
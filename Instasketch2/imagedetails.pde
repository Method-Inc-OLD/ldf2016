
class ImageDetails{
  int swatchIndex = 0; 
  JSONObject obj; 
  color myColour; 
  String myColourName = "";
  
  ImageDetails(JSONObject obj, int swatchIndex){
    this.obj = obj; 
    this.swatchIndex = swatchIndex;
    
    myColour = getColor(); 
    myColourName = getColourName(); 
  }
  
  float getRed(){
      return red(myColour); 
  }
  
  float getGreen(){
      return green(myColour); 
  }
  
  float getBlue(){
      return blue(myColour); 
  }
  
  color getColor(){
      JSONObject rgbCluster = getRGBClusters().getJSONObject(swatchIndex); 
      JSONArray rgb = rgbCluster.getJSONArray("rgb");  
      return color(rgb.getInt(0), rgb.getInt(1), rgb.getInt(2));
  }
  
  String getColourName(){
      JSONObject rgbCluster = getRGBClusters().getJSONObject(swatchIndex);
      if(rgbCluster.isNull("name")){
        return "";  
      } 
      return rgbCluster.getString("name");   
  }
  
  JSONArray getRGBClusters(){
    return obj.getJSONArray("rgb_clusters");  
  }
  
  String getImageSrc(){
    return obj.getString("img_src");   
  }
  
  String getImageId(){
    return obj.getString("id");
  }
}
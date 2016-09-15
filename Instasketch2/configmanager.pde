
import java.net.InetAddress;
import java.net.NetworkInterface; 
import java.net.UnknownHostException;
import java.util.Enumeration;

public class ConfigManager{  
  
  public int piIndex = -1; 
  public String name = "";  
  
  /** how frequently to update the image **/ 
  public long imageUpdateFrequency = 300000; 
  /** elapsed time within the TransitionOut state before updating the image **/ 
  public long elapsedStateIdleTimeBeforeImageUpdate = 30000; 
  /** max width to which the downloaded images will be resized to - used to aspect fil resizing **/ 
  public int offscreenBufferMaxWidth = 500; 
  /** how many 'levels' of details the images is decomposed into for the in and out transition **/ 
  public int levelsOfDetail = 7; 
  /** x resolution the images is reduced to for pixelation **/ 
  public int resolutionX = 32;
  /** y resolution the images is reduced to for pixelation **/
  public int resolutionY = 24;
  /** how frequently the pi will register itself **/ 
  public int registerFrequency = 1800000;
  /** how frequently the pi will ping (aka heartbeat) **/
  public int pingFrequency = 120000;
  /** distance used to determine when the user in within proximity **/ 
  public float distanceMedium = 120; 
  /** distance used to determine when the user is 'close' **/ 
  public float distanceClose = 50;
  /** how many times the range state has to be different than the current state before being updated (when transitioning up i.e. close -> far ) **/ 
  public int proximityRangeUpChangeThreshold = 10;
  /** how many times the range state has to be different than the current state before being updated (when transitioning up i.e. far -> close ) **/
  public int proximityRangeDownChangeThreshold = 5;
  
  public float lastServerPing =  0;
  public float lastRegisterRequest =  0;
  
  public String hostAddress;
  public String hostName;
  public ArrayList pairs = new ArrayList();
  
  private boolean initilised = false; 
  private boolean finishedInitilising = false; 
  
  private String currentImageId = "";
  private int stateChangedCounter = 0;
  
  public ConfigManager(){
    initFromFile();     
  }
  
  public void init(){
    initIPAddress();         
    register();  
    initilised = true; 
  }
  
  public boolean isInitilised(){
    return initilised;    
  }
  
  public boolean isFinishedInitilising(){
    boolean res = false; 
    if(initilised && !finishedInitilising){
      res = true; 
      finishedInitilising = true; 
    }
    
    return res; 
  }
  
  public boolean isMaster(){
    return piIndex == 0;   
  }
  
  public void update(int stateChangedCounter){
    if(hostAddress == null){
      return;   
    }
    
    this.stateChangedCounter += stateChangedCounter;
    
    // only the master registers 
    if((millis() - lastRegisterRequest) > registerFrequency){
        register();   
      }
    
    if((millis() - lastServerPing) > pingFrequency){
      ping();    
    }
  }
  
  public void register(){
    lastRegisterRequest = millis(); 
        
    final String url = "http://instacolour.herokuapp.com/api/registerpi?pi_index=" + piIndex + "&hostaddress=" + hostAddress;
    
    println("registering " + url); 
    
    JSONObject responseJSON = loadJSONObject(url);
    if(responseJSON == null){
      // TODO; handle exception 
      return; 
    }        
    
    // only add the master (central coordiantor) 
    if(!responseJSON.isNull("pairs")){
      ArrayList newPairs = new ArrayList();
      
      JSONArray pairsArray = responseJSON.getJSONArray("pairs"); 
      for(int i=0; i<pairsArray.size(); i++){
        JSONObject pairJSON = pairsArray.getJSONObject(i);
        int pairPIIndex = pairJSON.getInt("pi_index");
    
        // is self? 
        if(pairPIIndex == piIndex)
          continue; 
          
        // is master?
        if(pairPIIndex != 0)
          continue; 
        
        String pairHostAddress = pairJSON.getString("hostaddress");
        
        println("adding pair " + pairPIIndex + ": " + pairHostAddress); 
        
        newPairs.add(new Pair(pairPIIndex, pairHostAddress));         
      }
      
      syncPairs(newPairs);
    }        
  }
  
  public void ping(){
     lastServerPing = millis(); 
     
     final String url = "http://instacolour.herokuapp.com/api/piping?pi_index=" + piIndex + "&hostaddress=" + hostAddress + "&image_id=" + currentImageId
       + "&state_change_counter=" + stateChangedCounter;
     
     println("pinging: " + url); 
     
     JSONObject responseJSON = loadJSONObject(url);         
    
    if(!responseJSON.isNull("pairs")){
      ArrayList newPairs = new ArrayList();
      
      JSONArray pairsArray = responseJSON.getJSONArray("pairs"); 
      for(int i=0; i<pairsArray.size(); i++){
        JSONObject pairJSON = pairsArray.getJSONObject(i);
        int pairPIIndex = pairJSON.getInt("pi_index");
        
        if(pairPIIndex == piIndex)
          continue; 
        
        String pairHostAddress = pairJSON.getString("hostaddress");
        
        println("adding pair " + pairPIIndex + ": " + pairHostAddress); 
        
        newPairs.add(new Pair(pairPIIndex, pairHostAddress));         
      }
      
      syncPairs(newPairs);
    }        
       
     stateChangedCounter = 0; 
  }
  
  void initFromFile(){
    //try{
    //  JSONObject json = loadJSONObject("/home/pi/instacolour.json");
    //  if(json != null){
    //    piIndex = json.getInt("pi_index");
    //    name = json.getString("name");
    //  }
    //} catch(Exception e){}
    
    JSONObject json = loadJSONObject("data/config.json");
    if(piIndex == -1){
      piIndex = json.getInt("pi_index");
      name = json.getString("name");
    }
    
    imageUpdateFrequency = json.getInt("image_update_frequency");
    elapsedStateIdleTimeBeforeImageUpdate = json.getInt("elapsed_state_idle_time_before_image_update");
    offscreenBufferMaxWidth = json.getInt("offscreen_buffer_max_width"); 
    levelsOfDetail = json.getInt("levels_of_detail"); 
    resolutionX = json.getInt("resolution_x"); 
    resolutionY = json.getInt("resolution_y");
    pingFrequency = json.getInt("ping_frequency");
    registerFrequency = json.getInt("register_frequency");
    distanceMedium = json.getFloat("distance_medium");
    distanceClose = json.getInt("distance_close");
    proximityRangeUpChangeThreshold = json.getInt("proximity_range_up_change_threshold");
    proximityRangeDownChangeThreshold = json.getInt("proximity_range_down_change_threshold");
  }
  
  void initIPAddress(){
    boolean found = false; 
    try{
      Enumeration en = NetworkInterface.getNetworkInterfaces();
      while(en.hasMoreElements() && !found){
        NetworkInterface ni=(NetworkInterface) en.nextElement();
        Enumeration ee = ni.getInetAddresses();
        while(ee.hasMoreElements() && !found) {
          InetAddress addr = (InetAddress) ee.nextElement();
          //byte[] ipAddr = addr.getAddress();
          String raw_addr = addr.toString();
          String[] list = split(raw_addr,'/');
          String tmpHostAddress = list[1];
          String tmpHostName = addr.getHostName();
          
          //println("host address " + tmpHostAddress + ", host name " + tmpHostName + ", " + !tmpHostName.equals("localhost") + ", " + tmpHostAddress.split("\\.").length);
          
          if(!tmpHostName.equals("localhost") && tmpHostAddress.split("\\.").length == 4){
            hostAddress = tmpHostAddress; 
            hostName = tmpHostName;
            println("host address " + hostAddress + ", host name " + hostName);
            found = true; 
          }                              
        }
      }
    }catch(Exception e){}
  }
  
  private void syncPairs(ArrayList otherPairs){
    for(int i=0; i<otherPairs.size(); i++){
      Pair otherPair = (Pair)otherPairs.get(i);
      Pair existingPair = getPairWithIndex(otherPair.index); 
      
      if(existingPair == null){
        pairs.add(otherPair);     
      } else{
        existingPair.hostAddress = otherPair.hostAddress; 
      }
    }
  }
  
  public Pair getMaster(){
    for(int i=0; i<pairs.size(); i++){
      if(((Pair)pairs.get(i)).index == 0){
        return (Pair)pairs.get(i);   
      }
    }
    
    return null; 
  }
  
  public Pair getPairWithIndex(int index){
    for(int i=0; i<pairs.size(); i++){
      if(((Pair)pairs.get(i)).index == index){
        return (Pair)pairs.get(i);   
      }
    }
    
    // didn't find the pair so create a new one 
    println("Couldn't find pair with index " + index + ", creating a new instance"); 
    Pair newPair = new Pair(index); 
    pairs.add(newPair); 
    
    return newPair; 
  }
  
  public int getPairCount(){
    return pairs.size();   
  }
  
  public Pair getPairAtIndex(int i){
    return (Pair)this.pairs.get(i);   
  }
}

class Pair{
  
  public int index = -1; 
  public String hostAddress = "";  
  
  public String currentImageId = "";
  public boolean waitingForImage = false;
  public int currentAnimationState = -1;
  
  public int currentAction = -1; 
  
  public String currentMessage = "";
  
  public Pair(){}
  
  public Pair(int index){
    this.index = index; 
  }
  
  public Pair(int index, String hostAddress){
    this.index = index; 
    this.hostAddress = hostAddress; 
  }
}

import java.net.InetAddress;
import java.net.NetworkInterface; 
import java.net.UnknownHostException;
import java.util.Enumeration;

public class ConfigManager{  
  
  public int piIndex = -1; 
  public String name = "";  
  
  public long imageUpdateFrequency = 300000; 
  public long elapsedStateIdleTimeBeforeImageUpdate = 30000; 
  public int offscreenBufferMaxWidth = 500; 
  public int levelsOfDetail = 7; 
  public int resolutionX = 32; 
  public int resolutionY = 24; 
  public int registerFrequency = 1800000;
  public int pingFrequency = 120000;
  public float distanceMedium = 120; 
  public float distanceClose = 50;
  
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
  
  public void update(String currentImageId, int stateChangedCounter){
    if(hostAddress == null){
      return;   
    }
    
    this.currentImageId = currentImageId; 
    this.stateChangedCounter += stateChangedCounter;
    
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
    JSONObject json = loadJSONObject("data/config.json");
    piIndex = json.getInt("pi_index");
    name = json.getString("name");
    
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
    
    return null; 
  }
}

class Pair{
  
  public int index = -1; 
  public String hostAddress = "";  
  
  public String currentImageId = "";
  public boolean waitingForImage = false; 
  
  public Pair(){}
  
  public Pair(int index, String hostAddress){
    this.index = index; 
    this.hostAddress = hostAddress; 
  }
}
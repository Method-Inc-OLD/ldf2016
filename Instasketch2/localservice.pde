import processing.net.*;

/**
https://processing.org/tutorials/network/
https://processing.org/reference/libraries/net/Server.html
https://processing.org/reference/libraries/net/Client.html
**/
class LocalService{
  
  public static final int ACTION_UPDATE_IMAGE = 10; 

  private int port = 8888;
  
  private ConfigManager config; 
  
  private float lastInitTimestamp = 0.0f; 
  
  private Server server; 
  private Client client; 
  
  private int retryCounter = 0; 

  LocalService(ConfigManager config){
    println("setting up local connection"); 
    this.config = config; 
    
    this.port = config.p2pPort; 
    
    init(); 
  }
  
  private void init(){
    // throttle how frequently this is called 
    if(millis() - lastInitTimestamp < 500){
      return;   
    }
    
    if(getPIIndex() == 0){
      initServer();         
    } else{
      initClient();   
    }
    
    lastInitTimestamp = millis(); 
  }
  
  private void initServer(){
    retryCounter -= 1; 
    
    if(retryCounter > 0){
      return;   
    }
    
    retryCounter = 0; 
    
    if(server != null){
      if(server.active()){
        server.stop();         
      }
      server = null; 
    }
    
    println("initServer: " + config.hostAddress);    
    try{
      server = new Server(MainPApplet(), port, config.hostAddress);  // Start a simple server on a port=
    } catch(Exception e){
      retryCounter = 10;
    }
  }
  
  private void initClient(){
    retryCounter -= 1; 
    
    if(retryCounter > 0){
      return;   
    }
    
    retryCounter = 0; 
    
    if(client != null){
      if(client.active()){
        client.stop();         
      }
      client = null; 
    }
    
    if(config.getMaster() == null){
      //println("config.getMaster() == null"); 
      return; 
    }
    
    println("initClient: " + config.getMaster().hostAddress);
    try{
      client = new Client(MainPApplet(), config.getMaster().hostAddress, port);
    } catch(Exception e){
      client = null; 
      retryCounter = 500;   
    }
  }
  
  public boolean updatePairsOfNewImageId(String imageId, int imageNumber){
    if(imageId == null) return false; 
    
    if(server != null && isConnected()){
      
      // flag waiting for update from all images 
      for(int i=0; i<config.pairs.size(); i++){
          Pair clientPair = (Pair)config.pairs.get(i); 
          clientPair.waitingForImage = true; 
      }
      
      println("SERVER: updatePairsOfNewImageId: writing " + config.piIndex + ":IMAGEID:" + imageId + ":IMAGENUM:" + imageNumber + "\n");      
      server.write(config.piIndex + ":IMAGEID:" + imageId + ":IMAGENUM:" + imageNumber + "\n");  
    } else if(client != null && isConnected()){
      println("CLIENT: updatePairsOfNewImageId: writing " + config.piIndex + ":IMAGEID:" + imageId + ":IMAGENUM:" + imageNumber + "\n");      
      client.write(config.piIndex + ":IMAGEID:" + imageId + "\n");
    }        
    
    return true; 
  }
  
  public boolean updatePairsOfNewAnimationState(int state){
    if(server != null && isConnected()){      
      println("SERVER: updatePairsOfNewAnimationState: writing " + config.piIndex + ":ANIMSTATE:" + state + "\n");
      try{
        server.write(config.piIndex + ":ANIMSTATE:" + state + "\n");
      } catch(Exception e){ server = null; } 
    } else if(client != null && isConnected()){
      println("CLIENT: updatePairsOfNewAnimationState: writing " + config.piIndex + ":ANIMSTATE:" + state + "\n");
      try{
        client.write(config.piIndex + ":ANIMSTATE:" + state + "\n");
      } catch(Exception e){ client = null; } 
    }        
    
    return true; 
  }
  
  public boolean updatePairsOfAction(int action){
    if(server != null && isConnected()){      
      println("SERVER: updatePairsOfAction: writing " + config.piIndex + ":ACTION:" + action + "\n");
      try{
        server.write(config.piIndex + ":ACTION:" + action + "\n");
      } catch(Exception e){ server = null; } 
    } else if(client != null && isConnected()){
      println("CLIENT: updatePairsOfAction: writing " + config.piIndex + ":ACTION:" + action + "\n");
      try{
        client.write(config.piIndex + ":ACTION:" + action + "\n");
      } catch(Exception e){ client = null; } 
    }        
    
    return true; 
  }
  
  public void update(float et){
    try{
      _update(et);   
    } catch(Exception e){}
  }
  
  private void _update(float et){
    if(!isConnected()){
      init(); 
      return; 
    }
    
    // *** CLIENT *** 
    if(client != null){
      if (client.available() > 0) {    
        String input = client.readString();
        println("Data from server " + input); 
        String lines[] = input.split("\n");
        
        if(lines != null && lines.length > 0){
          for(int i=0; i<lines.length; i++){
            processPairMessage(lines[i]);                     
          }
        }
      } 
    } 
    
    // *** SERVER *** 
    else if(server != null){
      Client pairClient = server.available();  
      while(pairClient != null){
        String input = pairClient.readString();
        println("Data from client " + pairClient.ip() + " " + input);
        String lines[] = input.split("\n");
        if(lines != null && lines.length > 0){
          for(int i=0; i<lines.length; i++){
            processPairMessage(lines[i]); 
          }
        }
                
        pairClient = server.available();
      }       
    }
  }  
  
  private void processPairMessage(String line){
    if(line == null || line.length() == 0){
      return;   
    }
    
    String[] lineComponents = line.split(":"); 
    int clientIndex = int(lineComponents[0]);
    String command = lineComponents[1]; 
    String data = lineComponents[2];
    
    /*** IMAGEID **/ 
    if(command.equals("IMAGEID")){            
      int imageNumber = int(lineComponents[4]);
      
      if(isClient() && imageNumber > 1){
        setRequestedToFetchNextImage(true);     
      }
      
      Pair p = config.getPairWithIndex(clientIndex);
      if(p != null){ 
        p.currentImageId = data;
        p.currentImageNumber = imageNumber; 
        if(isServer()){
          p.waitingForImage = false;   
        } else{
          p.currentAction = -1;  
        }
      }
    }
    
    /*** ANIMSTATE **/ 
    else if(command.equals("ANIMSTATE")){
      Pair p = config.getPairWithIndex(clientIndex);
      if(p != null){ 
        p.currentAnimationState = int(data);             
      }
    }
    
    /*** ACTION **/ 
    else if(command.equals("ACTION")){
      Pair p = config.getPairWithIndex(clientIndex);
      if(p != null){ 
        p.currentAction = int(data);
        setRequestedToTransitionToNextImage(true); 
      }
    }
  }
  
  public int getPIIndex(){
    return config.piIndex;   
  }
  
  public boolean isClient(){
    return client != null;   
  }
  
  public boolean isServer(){
    return server != null;   
  }
  
  public boolean isConnected(){
    if(getPIIndex() == 0){
      return server != null && server.active();
    } else{
      return client != null && client.active();   
    }
  }
}
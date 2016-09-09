import processing.net.*;

/**
https://processing.org/tutorials/network/
https://processing.org/reference/libraries/net/Server.html
https://processing.org/reference/libraries/net/Client.html
**/
class LocalService{

  private int port = 8888;
  
  private ConfigManager config; 
  
  private Server server; 
  private Client client; 

  LocalService(ConfigManager config){
    this.config = config; 
    init(); 
  }
  
  private void init(){
    if(getPIIndex() == 0){
      initServer();         
    } else{
      initClient();   
    }
  }
  
  private void initServer(){
    if(server != null){
      if(server.active()){
        server.stop();         
      }
      server = null; 
    }
    
    println("initServer: " + config.hostAddress);    
    server = new Server(MainPApplet(), port, config.hostAddress);  // Start a simple server on a port=        
  }
  
  private void initClient(){
    if(client != null){
      if(client.active()){
        client.stop();         
      }
      client = null; 
    }
    
    if(config.getMaster() == null){
      println("config.getMaster() == null"); 
      return; 
    }
    
    println("initClient: " + config.getMaster().hostAddress);
    client = new Client(MainPApplet(), config.getMaster().hostAddress, port);        
  }
  
  public boolean updatePairsOfNewImageId(String imageId){
    if(imageId == null) return false; 
    
    if(server != null && isConnected()){
      
      // flag waiting for update from all images 
      for(int i=0; i<config.pairs.size(); i++){
          Pair clientPair = (Pair)config.pairs.get(i); 
          clientPair.waitingForImage = true; 
      }
      
      println("SERVER: updatePairsOfNewImageId: writing " + config.piIndex + ":IMAGEID:" + imageId + "\n");      
      server.write(config.piIndex + ":IMAGEID:" + imageId + "\n");  
    } else if(client != null && isConnected()){
      println("CLIENT: updatePairsOfNewImageId: writing " + config.piIndex + ":IMAGEID:" + imageId + "\n");      
      client.write(config.piIndex + ":IMAGEID:" + imageId + "\n");
    }        
    
    return true; 
  }
  
  public void update(float et){
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
            
    if(command.equals("IMAGEID")){
      if(isClient()){
        requestedToUpdateImage = true;   
      }
      
      Pair p = config.getPairWithIndex(clientIndex);
      if(p != null){ 
        p.currentImageId = data;
        if(isServer()){
          p.waitingForImage = false;   
        }             
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
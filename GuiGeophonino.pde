/*Geophonino is an Arduino-based seismic recorder for vertical geophones.  
The computer programming consists of: 
Geophonino.ino: The Arduino Sketch.
GuiGeophonino.pde: The user interface developed by using Processing software.

Last update: 21/10/2015

Email contact: jl.soler@ua.es, juanjo@dfists.ua.es*/


import controlP5.*;
import processing.serial.*;

/*Initialization of variables*/
Serial myPort;
String val; //store data received in the serial port
boolean firstContact = false;  //is false while Processing isn't connected to Arduino
ControlP5 cp5; //cp5 printer for GUI
DropdownList ddlCom,ddlGain,ddlSr; //DDL Drop Down List objtects

PFont fontTit = createFont("arial",20);
PFont fontTex = createFont("arial",12);
PFont fontTexMini = createFont("arial",10);

Textfield status; //Text field for notifications to the user

int myColorBackground = 255; //Default Background

int state=1; //1-Conf. connection 2-Conf. acquisition 3-Ready for data acquisition 4-Acquiring data 5-Reciving file 7-File Recived

OutputStream OutputFileRecived; //Writer for file received over serial port
  
byte [] FileBuffer=new byte[0];

String folder=null; //Folder when the file downloaded from Arduino will be saved

String overwriteFile="N"; //When selected name already exist, user can overwrite it. By default, N=false.

/* Variables progress bar */
int count=0;
int ini=0;
Integer duration=0;
Integer tamFile=0;
/* End variables progress bar */

void setup() {
  size(800,500); //Window size
  
   
  cp5 = new ControlP5(this);
   // Print Status bar
  cp5.addTextlabel("textWarnings").setText("Current status: ")
  .setPosition(50,470).setColorValue(0).setFont(fontTex);
    
  cp5.addTextfield("Status")
     .setPosition(150,470)
     .setSize(550,20)
     .setFocus(true)
     .setFont(fontTex)
     .setColorValue(255)
     .setColorBackground(color(200, 200, 200));

   status = ((Textfield)cp5.getController("Status"));
   status.setValue("Welcome Geophonino configuration");
   
  cp5.addTextlabel("Connection").setText("1º Connection configuration")
  .setPosition(50,20).setColorValue(0).setFont(fontTit)     ;
  
  cp5.addTextlabel("txtSerial").setText("Select the Geophonino connection port")
  .setPosition(50,60).setColorValue(0).setFont(fontTex); 
  
  ddlCom = cp5.addDropdownList("serial").setPosition(270, 75);
  for (int i = 0; i < Serial.list().length; i = i+1) {
    ddlCom.addItem(Serial.list()[i], i+1); 
  }
  if (Serial.list().length==0)
  {
     status.setValue("Error, COM Port not detected, connect Geophonino and press CONNECT... button.");
  }
  customizeDl(ddlCom);
  
  cp5.addButton("Connect...")
     .setValue(0)
     .setPosition(380,60)
     .setSize(100,14)
     .setId(1);
   
   cp5.addButton("Refresh port list")
     .setValue(0)
     .setPosition(500,60)
     .setSize(100,14)
     .setId(2);
   
 

  cp5.addTextlabel("ConfAcquisition").setText("2º Data acquisition configuration")
  .setPosition(50,100).setColorValue(0).setFont(fontTit)     ;
  
  cp5.addTextlabel("Comment").setText("Set configuration parameters and press SEND CONFIGURATION button")
  .setPosition(50,140).setColorValue(0).setFont(fontTex);
  
  cp5.addTextlabel("txtNameFile").setText("File name: ")
  .setPosition(50,180).setColorValue(0).setFont(fontTex);
  
  cp5.addTextlabel("WarningNameFile").setText("(max. 8 characters)")
  .setPosition(240,180).setColorValue(0).setFont(fontTexMini);
  
  cp5.addTextfield("fileName")
     .setPosition(135,178)
     .setSize(100,18)
     .setFocus(true)
     .setFont(fontTex)
     .setColorValue(255)
     .setColorBackground(color(200, 200, 200))
      .getCaptionLabel().hide();;
     
  cp5.addTextlabel("txtDura").setText("Duration (s): ")
  .setPosition(350,180).setColorValue(0).setFont(fontTex);
  
  cp5.addTextfield("dura")
     .setPosition(430,178)
     .setSize(100,18)
     .setFocus(true)
     .setFont(fontTex)
     .setColorValue(255)
     .setColorBackground(color(200, 200, 200))
     .setColorCaptionLabel(200)
     .getCaptionLabel().hide();
    
     
  cp5.addButton("Send configuration")
     .setValue(0)
     .setPosition(50,260)
     .setSize(100,14)
     .setId(3); 
     
  cp5.addButton("Get configuration")
     .setValue(0)
     .setPosition(180,260)
     .setSize(100,14)
     .setId(4)
     .setVisible(false);
      
 
     
  cp5.addTextlabel("txtBits").setText("Amplification:")
  .setPosition(50,220).setColorValue(0).setFont(fontTex); 
  
  ddlGain = cp5.addDropdownList("x").setPosition(135, 235);
  ddlGain.addItem("0.5", 1);
  ddlGain.addItem("1.0", 2);
  ddlGain.addItem("2.0", 3);  
  customizeDl(ddlGain);
 
  cp5.addTextlabel("txtSps").setText("Sampling Rate (ms/sps):")
  .setPosition(290,218).setColorValue(0).setFont(fontTex); 
  
  ddlSr = cp5.addDropdownList("ms/sps").setPosition(430, 235);
  ddlSr.addItem("10.0 ms/100 sps",0);
  ddlSr.addItem("4.0 ms/250 sps", 1);
  ddlSr.addItem("2.0 ms/500 sps", 2);
  ddlSr.addItem("1.0 ms/1000 sps", 3);
  customizeDl(ddlSr);
 
 
 cp5.addTextlabel("AcquireData").setText("3º Data Acquisition")
  .setPosition(50,310).setColorValue(0).setFont(fontTit)     ;
  
  

  
  cp5.addButton("    Acquire data")
     .setValue(0)
     .setPosition(50,360)
     .setSize(80,14)
     .setId(5); 
     
   cp5.addButton("    Get Data File")
     .setValue(0)
     .setPosition(50,390)
     .setSize(80,14)
     .setId(6);   
     
   cp5.addButton("New Data Acquisition")
     .setValue(0)
     .setPosition(50,425)
     .setSize(100,14)
     .setId(7);   
  
  textFont(fontTex); //It select font type for every field that don't define font type
  
}

void customizeDl(DropdownList ddl) {
  // Format DropDownList
  ddl.enableCollapse();
  ddl.setBackgroundColor(color(190));
  ddl.actAsPulldownMenu(true);
  ddl.setItemHeight(20);
  ddl.setBarHeight(15);
  ddl.captionLabel().style().marginTop = 3;
  ddl.captionLabel().style().marginLeft = 3;
  ddl.valueLabel().style().marginTop = 10;
  ddl.setColorBackground(color(200, 200, 200));
  ddl.setColorActive(color(0, 128));
  ddl.setColorLabel(color(0,0,0));
}


void draw() {
  background(myColorBackground);
  switch(state)
  {

    case(1)://1º Configure Connection
      rect(0,90,width,height-135);
      fill(150);
      cp5.controller("New Data Acquisition").setVisible(false);
    break;
    
    case(2)://2º Configure Data acquisition
      rect(0,0,width,90);
      fill(150);
      rect(0,290,width,150);
      fill(150);  
     
      cp5.controller("New Data Acquisition").setVisible(false);
    break;
    
    case(3): //3º Waiting for acquire data
        rect(0,0,width,300);
        fill(150);
       
        cp5.controller("New Data Acquisition").setVisible(true);
    break;
    
    case(4)://4º Acquiring data from sensor
      fill(150);
      rect(0,0,width,350);
      fill(244,3,3);
      noStroke();
      rect(160,355,map(count-ini,0,duration,0,200),19);
      fill(0,0,0);
      text(count-ini+"/"+duration+"s",240,370);
      text("<-Data acquisition progress",370,370);
      noFill();
      stroke(0);
      rect(160,355,200,19);
       cp5.controller("New Data Acquisition").setVisible(true);
   break;
   
   case(5)://5º Downloading File
      fill(150);
      rect(0,0,width,380);
      fill(244,3,3);
      noStroke();
      rect(160,385,map(count-ini,0,tamFile,0,200),19);
      fill(0,0,0);
      text((count*100)/tamFile +" %",250,400);
      //text(count-ini+"/"+tamFile+" bytes",200,470);
      text("<-Download file progress",370,480);
      noFill();
      stroke(0);
      rect(160,385,200,19);
       cp5.controller("New Data Acquisition").setVisible(true);
    break;   
    
    case(6): //not used
    break;   
    case(7): //7º File Downloaded
      fill(150);
      rect(0,0,width,380);
      fill(244,3,3);
      noStroke();
      rect(160,385,map(250,0,250,0,200),19);
      fill(0,0,0);
      text("100 %",250,400); //200,420
      text("<-Download file progress",370,400);
      noFill();
      stroke(0);
      rect(160,385,200,19);
       cp5.controller("New Data Acquisition").setVisible(true);
     
    break;   
    
  }
}


void controlEvent(ControlEvent theEvent) {
  // DropdownList is of type ControlGroup.
  // A controlEvent will be triggered from inside the ControlGroup class.
  // therefore you need to check the originator of the Event with
  // if (theEvent.isGroup())
  // to avoid an error message thrown by controlP5.

  if (theEvent.isGroup()) {
    // check if the Event was triggered from a ControlGroup
    println("event from group : "+theEvent.getGroup().getValue()+" from "+theEvent.getGroup());
  } 
  else if (theEvent.isController()) {
    switch(theEvent.getController().getId()) {
      
    case(1): //Connect with Geophonino in the seleccted port
         int portSel=int(ddlCom.getValue());//Get selected port
         println(portSel);
         if (portSel==0)
         {
           status.setValue("Error, COM Port not selected.");
         }
         else
         {
           myPort = new Serial(this, Serial.list()[portSel-1], 115200);
           myPort.bufferUntil('\n');
           state=2; //When the connection is configured the state is changed
         } 
    break;  //END Connect with Geophonino in the seleccted port
    
    case(2)://Refresh port list
        println("Refresh port list");
        String[][]itemsddlCom= ddlCom.getListBoxItems();
        println(itemsddlCom.length);
        if(Serial.list().length>itemsddlCom.length)
        {
          for (int i = 0; i < Serial.list().length; i = i+1)
          {
                ddlCom.addItem(Serial.list()[i], i+1); 
          }
        }
        if (Serial.list().length==0)
        {
           status.setValue("Error, COM Port not tetected, connect Geophonino and press Refresh... button.");
        }
    break;//END Refresh port list
    
    case(3): //Send data acquisition configuration to Geophonino
      println("Send Configuration");
      
      String fileName= cp5.get(Textfield.class,"fileName").getText();
      String dura=cp5.get(Textfield.class,"dura").getText();
      duration= int(cp5.get(Textfield.class,"dura").getText());
      int srSel=int(ddlSr.getValue());
      int gainSel=int(ddlGain.getValue());
      
      if (fileName.equals(""))
        status.setValue("You must enter a file name");
      else
        if(fileName.length()>8)
        {
          Textfield fileNameField = ((Textfield)cp5.getController("fileName"));
          fileName=fileName.substring(0,8);
          fileNameField.setValue(fileName);
          status.setValue("File name have been shorted to 8 characters, press SendConfiguration again");
        }
        else
          if(duration<=0)
            status.setValue("You must enter a numeric value in duration");
          else
            if(gainSel<1)
              status.setValue("You must select amplification value");
            else
              if(srSel<0)
              status.setValue("You must select sample rate");
              else //All parrameters are OK, send configuration to Geophonino already
              {

                String configComand="conf_adq" + "&nomF="+fileName+"&overW="+overwriteFile+"&Gain="+gainSel+"&tR="+duration+"&sR="+srSel+"\n";
                print(configComand);
                myPort.write(configComand);
                state=3; //When data acquisition is configured the state is changed
                if (overwriteFile=="Y")
                {
                  status.setValue("Configuration sent successfully, file will be overwrited");
                  overwriteFile="N";
                }
                else
                  status.setValue("Configuration sent successfully");  
              }
    break; //END Send data acquisition configuration to Geophonino
    
    case(5): //Acquire data
      println("Acquire data");
      String command="adq_now\n";
      println(command);
      myPort.write(command);
      status.setValue("Initializing data acquisition...");
      state=4; //When acquisition starts the state is changed
      count=0; 
    break;//END Acquire data Now
    
    case(6): //Get File
      getLastFileNow();
    break;
    
    case(7):
      println("7");
      state=2;
    break;      
  }
  }
}

/*It's called when user select a folder to store datafile or close nagitation folder window*/
void folderSelected(File selection) 
{
  if (selection == null) 
  {
    println("Window was closed or the user press cancel.");
    folder="";
  } 
  else 
  {
    println("User selected " + selection.getAbsolutePath());
    folder=selection.getAbsolutePath();
    String rutaFile= selection.getAbsolutePath() + "\\" + cp5.get(Textfield.class,"fileName").getText();
    println(rutaFile);
    OutputFileRecived = createOutput(rutaFile);
  }
}

/*Request last file recorded to Geophonino*/
void getLastFileNow()
{
  String command="";
   waitForFolder();
      println("waiting");
      if (folder==null | folder=="")
      {
        command="getF_ko\n";
        println(command);
        myPort.write(command);
      }
      else
      {
        command="getF_now\n";
        println(command);
        myPort.write(command);
      }
}

/*Program still waiting while user select a folder to store data file*/
void waitForFolder() {
  folder = null;
  selectFolder("Select a folder to store data file:", "folderSelected");
  while (folder == null)   delay(200);
}


/*It's called when Geophonino is sending a data file*/
void getFile()
{
      byte[] buffer = new byte[64]; 
      int readBytes = myPort.readBytes(buffer);  
      for(int i = 0; i < readBytes; i++) 
      { 
        FileBuffer = append(FileBuffer, buffer[i]); 
      }
      if (FileBuffer.length>=50000)
      {
        try 
        { 
          OutputFileRecived.write(FileBuffer); 
          OutputFileRecived.flush(); 
          FileBuffer=null; 
          FileBuffer=new byte[0];
        } 
        catch (IOException e) 
        {} 
        
      }
      
      println("Bytes received: " + FileBuffer.length); 
      count=count+readBytes;
      if(tamFile != 0 && count >= tamFile) 
      { 
        myPort.clear(); 
        println("Received"); 
        saveFile(); 
      } 
}
/*It's called when data file have been received*/
void saveFile() 
{ 
  print( "Writing "); 
  print(FileBuffer.length); 
  println( " bytes to disk..."); 
  try 
  { 
    OutputFileRecived.write(FileBuffer); 
    OutputFileRecived.flush(); 
    OutputFileRecived.close(); 
    
    count=tamFile;
    status.setValue("File received succesfully");
    state=7;
    tamFile=0;

    FileBuffer=new byte[0];
  } 
  catch (IOException e) 
  {} 
  println( "DONE!"); 
} 

void delay(int ms) 
{ 
  int time = millis(); 
  while (millis () - time < ms); 
} 

/*It's called when data is available in the serial port*/
void serialEvent(Serial myPort) 
{
  if (state==5) //getting file
    {
      getFile();
    }
    else
    {
  //Write the incoming data into a String. '\n' is the end delimiter indicating the end of a complete packet
  val = myPort.readStringUntil('\n'); 
  if (val != null) 
  {
    //Trim whitespace and formatting characters (like carriage return)
    val = trim(val);
    println(val);
    
  
    if (firstContact == false) //no connection yet
    {
      if (val.equals("A")) {
        myPort.clear();
        firstContact = true;
        myPort.write("Contacted\n");
        println("Contact");
        status.setValue("Connection established succesfully");
      }
    }
    else //If we've already established contact, it keeps getting and parsing data 
    { 
      if(val.equals("conf_adq_filexist"))
      {
        status.setValue("Filename already exists, select other filename or press send configuration again for overwrite it");
        overwriteFile="Y";
        state=2;
      }
      if(val.equals("conf_adq_ok"))
        status.setValue("Configuration was received succesfully by Geophonino");
        
      if(val.equals("adq_now_ok"))
        status.setValue("Data acquisition inicialized by Geophonino");
      else
        if(val.indexOf("adq_now_ok")>-1)
        {
           status.setValue("Acquiring samples for second: " + val.substring(10,val.length()));
           count=int(val.substring(10,val.length())); //Update counter for progress bar
           if (count==duration)
           {
             status.setValue("Data file " + cp5.get(Textfield.class,"fileName").getText() + " generated suscesfully." );
           }
         }
      if(val.indexOf("sendF_size")>-1) 
       {
           println("sendF_size");
           tamFile=int(val.substring(10,val.length()));
           println(tamFile);
       }       
      if(val.equals("sendF_now")) 
       {
           println("sendF_nowRecibido");
           state=5;
           status.setValue("File " + cp5.get(Textfield.class,"fileName").getText() + " open succesfully");  
       }
     } //if we've already established contact, keep getting and parsing data 
  }
}
}

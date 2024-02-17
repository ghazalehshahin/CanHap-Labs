/**
 **********************************************************************************************************************
 * @file       Lab_2_Emotions.pde
 * @author     Rishav Banerjee
 * @version    V0.0.1
 * @date       16-February-2024
 * @brief      Showcase 3 emotions
 **********************************************************************************************************************

/* library imports *****************************************************************************************************/ 
import processing.serial.*;
import static java.util.concurrent.TimeUnit.*;
import java.util.concurrent.*;
/* end library imports *************************************************************************************************/  

/* scheduler definition ************************************************************************************************/ 
private final ScheduledExecutorService scheduler      = Executors.newScheduledThreadPool(1);
/* end scheduler definition ********************************************************************************************/ 

/* device block definitions ********************************************************************************************/
Board             haplyBoard;
Device            widgetOne;
Mechanisms        pantograph;

FWorld            world;
HVirtualCoupling  endEffector;
float             worldWidth                          = 25.0;  
float             worldHeight                         = 10.0; 

float             edgeTopLeftX                        = 0.0; 
float             edgeTopLeftY                        = 0.0; 
float             edgeBottomRightX                    = worldWidth; 
float             edgeBottomRightY                    = worldHeight;
byte              widgetOneID                         = 5;
int               CW                                  = 0;
int               CCW                                 = 1;
boolean           rendering_force                     = false;
long              baseFrameRate                       = 120;
float             pixelsPerMeter                      = 4000.0;
PVector           angles                              = new PVector(0, 0);
PVector           torques                             = new PVector(0, 0);
PVector           posEE                               = new PVector(0, 0);
PVector           fEE                                 = new PVector(0, 0); 
final int         worldPixelWidth                     = 1000;
final int         worldPixelHeight                    = 650;
PShape            eeAvatar;


void setup(){
  
  size(1000, 650);
  
  haplyBoard = new Board(this, Serial.list()[2], 0);
  widgetOne           = new Device(widgetOneID, haplyBoard);
  pantograph          = new Pantograph();
  
  widgetOne.set_mechanism(pantograph);
  
  widgetOne.add_actuator(1, CCW, 2);
  widgetOne.add_actuator(2, CCW, 1);
 
  widgetOne.add_encoder(1, CCW, 172, 4880, 2);
  widgetOne.add_encoder(2, CCW, 8, 4880, 1);
  
  hAPI_Fisica.init(this); 
  hAPI_Fisica.setScale(pixelsPerMeter); 
  world = new FWorld();
  world.draw();
  
  widgetOne.device_set_parameters();
  
  eeAvatar = createShape(ELLIPSE, 0, 0, 50, 50);
  eeAvatar.setFill(color(100));
  
  frameRate(baseFrameRate);
  
  SimulationThread st = new SimulationThread();
  scheduler.scheduleAtFixedRate(st, 1, 1, MILLISECONDS);
}

void draw(){
  background(255); 
  world.draw();
}

class SimulationThread implements Runnable{
  
  public void run(){
    
    rendering_force = true;
    
    if(haplyBoard.data_available()){
      widgetOne.device_read_data();
    
      angles.set(widgetOne.get_device_angles()); 
      posEE.set(widgetOne.get_device_position(angles.array()));
      posEE.set(posEE.copy().mult(200)); 
    }
    
    endEffector.setToolPosition(edgeTopLeftX+worldWidth/2-(posEE).x, edgeTopLeftY+(posEE).y-7); 
    endEffector.updateCouplingForce();

    fEE.set(-endEffector.getVirtualCouplingForceX(), endEffector.getVirtualCouplingForceY());
    fEE.div(100000);
    
    torques.set(widgetOne.set_device_torques(fEE.array()));
    widgetOne.device_write_torques();
    world.step(1.0f/1000.0f);
  }
}

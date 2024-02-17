/**
 **********************************************************************************************************************
 * @file       Lab_2_Emotions.pde
 * @author     Rishav Banerjee
 * @version    V1.1.0
 * @date       08-January-2021
 * @brief      Emotions Showcase using Haptics only 
**/

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

byte              widgetOneID                         = 5;
int               CW                                  = 0;
int               CCW                                 = 1;
boolean           renderingForce                      = false;

int               hardwareVersion                     = 3;
/* end device block definition *****************************************************************************************/

/* framerate definition ************************************************************************************************/
long              baseFrameRate                       = 120;
float             currTime;
float[]           slowWindowTimings                       = {0.1, 0.3, 0.5, 0.7};
float[]           normalWindowTimings                     = {0.1, 0.2, 0.3, 0.4};
float[]           fastWindowTimings                       = {0.1, 0.15, 0.2, 0.25};

/* end framerate definition ********************************************************************************************/ 

/* elements definition *************************************************************************************************/

/* Screen and world setup parameters */
float             pixelsPerCentimeter                 = 40.0;

/* generic data for a 2DOF device */
/* joint space */
PVector           angles                              = new PVector(0, 0);
PVector           torques                             = new PVector(0, 0);

/* task space */
PVector           posEE                               = new PVector(0, 0);
PVector           fEE                                = new PVector(0, 0); 

/* World boundaries in centimeters */
FWorld            world;
float             worldWidth                          = 25.0;  
float             worldHeight                         = 16.0; 

float             edgeTopLeftX                        = 0.0; 
float             edgeTopLeftY                        = 0.0; 
float             edgeBottomRightX                    = worldWidth; 
float             edgeBottomRightY                    = worldHeight;

/* Initialization of virtual tool */
HVirtualCoupling  coupledEndEffector;
PImage            haplyAvatar;

/* end elements definition *********************************************************************************************/ 

/* setup section *******************************************************************************************************/
void setup(){
    /* put setup code here, run once: */
    
    /* screen size definition */
    size(1000, 650);
    
    /* device setup */

    haplyBoard          = new Board(this, Serial.list()[0], 0);
    widgetOne           = new Device(widgetOneID, haplyBoard);
    pantograph          = new Pantograph(hardwareVersion);
    
    widgetOne.set_mechanism(pantograph);
    
    if(hardwareVersion == 2){
        widgetOne.add_actuator(1, CCW, 2);
        widgetOne.add_actuator(2, CW, 1);
    
        widgetOne.add_encoder(1, CCW, 241, 10752, 2);
        widgetOne.add_encoder(2, CW, -61, 10752, 1);
    }
    else if(hardwareVersion == 3){
        widgetOne.add_actuator(1, CW, 2);
        widgetOne.add_actuator(2, CW, 1);
    
        widgetOne.add_encoder(1, CCW, 180, 4880, 2);
        widgetOne.add_encoder(2, CCW, 0, 4880, 1); 
    }
    else{
        widgetOne.add_actuator(1, CCW, 2);
        widgetOne.add_actuator(2, CCW, 1);
    
        widgetOne.add_encoder(1, CCW, 168, 4880, 2);
        widgetOne.add_encoder(2, CCW, 12, 4880, 1); 
    }
    
    widgetOne.device_set_parameters();
    
    /* 2D physics scaling and world creation */
    hAPI_Fisica.init(this); 
    hAPI_Fisica.setScale(pixelsPerCentimeter); 
    world                  = new FWorld();
        
    /* Haptic Tool Initialization */
    coupledEndEffector     = new HVirtualCoupling((1)); 
    coupledEndEffector.h_avatar.setDensity(4);  
    coupledEndEffector.init(world, edgeTopLeftX+worldWidth/2, edgeTopLeftY+2); 
    
    haplyAvatar = loadImage("../img/Haply_avatar.png"); 
    haplyAvatar.resize((int)(hAPI_Fisica.worldToScreen(1)), (int)(hAPI_Fisica.worldToScreen(1)));
    coupledEndEffector.h_avatar.attachImage(haplyAvatar); 

    /* world conditions setup */
    world.setGravity((0.0), (1000.0)); //1000 cm/(s^2)
    // world.setEdges((edgeTopLeftX-1), (edgeTopLeftY-1), (edgeBottomRightX+1), (edgeBottomRightY-1)); 
    // world.setEdgesRestitution(0.4);
    // world.setEdgesFriction(0.5);
    
    world.draw();
    
    /* setup framerate speed */
    frameRate(baseFrameRate);
    
    /* setup simulation thread to run at 1kHz */ 
    SimulationThread st = new SimulationThread();
    scheduler.scheduleAtFixedRate(st, 1, 1, MILLISECONDS);
}
/* end setup section ***************************************************************************************************/

/* draw section ********************************************************************************************************/
void draw(){
  /* put graphical code here, runs repeatedly at defined framerate in setup, else default at 60fps: */
    if(renderingForce == false){
        background(255);
        world.draw();
    }
}
/* end draw section ****************************************************************************************************/

/* simulation section **************************************************************************************************/
class SimulationThread implements Runnable{
    public void run(){
        /* put haptic simulation code here, runs repeatedly at 1kHz as defined in setup */
        renderingForce = true;
        
        if(haplyBoard.data_available()){
            /* GET END-EFFECTOR STATE (TASK SPACE) */
            widgetOne.device_read_data();
            
            angles.set(widgetOne.get_device_angles()); 
            posEE.set(widgetOne.get_device_position(angles.array()));
            
            if(hardwareVersion == 2){
                posEE.set(posEE.copy().mult(200));
            }
            else if(hardwareVersion == 3){
                posEE.set(posEE.copy().mult(150));
            }
        }
        
        coupledEndEffector.setToolPosition(edgeTopLeftX+worldWidth/2-(posEE).x, edgeTopLeftY+(posEE).y-7); 
        
        coupledEndEffector.updateCouplingForce();

        fEE.set(-coupledEndEffector.getVirtualCouplingForceX(), coupledEndEffector.getVirtualCouplingForceY());
        fEE.div(100000); //dynes to newtons
        
        torques.set(widgetOne.set_device_torques(fEE.array()));
        widgetOne.device_write_torques();

        float timeStep = 1.0f/1000.0f;

        currTime += timeStep;
        handleHeart(currTime);
        
        world.step(timeStep);
        renderingForce = false;
    }
}
/* end simulation section **********************************************************************************************/

void handleHeart(float currTime){
    float yPos = coupledEndEffector.getToolPositionY();
    int currTimeInt = int(currTime);
    int onediff = currTimeInt%2;
    float twoSecWindow = currTime - (currTimeInt - onediff);
    if(yPos<-2){
        beatHeart(twoSecWindow, slowWindowTimings, 60, 30);
    }
    else if (yPos>7){
        float halfSecondWindow = twoSecWindow;
        if(halfSecondWindow>1) halfSecondWindow-=1;
        if(halfSecondWindow>0.5) halfSecondWindow-=0.5;
        beatHeart(halfSecondWindow, fastWindowTimings, 60, 30);
    }
    else{
        float oneSecondWindow = twoSecWindow;
        if(oneSecondWindow>1) oneSecondWindow-=1;
        beatHeart(oneSecondWindow, normalWindowTimings, 60, 30);
    }
}

void beatHeart(float timeSlot, float[] windowTimings, int higherStrength, int lowerStrength) {
    int windowIndex = -1;
    for (int i = 0; i < windowTimings.length; i++) {
        if (timeSlot < windowTimings[i]) {
            windowIndex = i;
            break;
        }
    }

    switch (windowIndex) {
        case 0:
            coupledEndEffector.setAvatarVelocity(0, -higherStrength);
            break;
        case 1:
            coupledEndEffector.setAvatarVelocity(0, higherStrength);
            break;
        case 2:
            coupledEndEffector.setAvatarVelocity(0, -lowerStrength);
            break;
        case 3:
            coupledEndEffector.setAvatarVelocity(0, lowerStrength);
            break;
        default:
            coupledEndEffector.setAvatarVelocity(0, 0);
            break;
    }
}

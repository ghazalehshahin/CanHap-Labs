/**
 **********************************************************************************************************************
 * @file       Lab_1_Maze.pde
 * @author     Rishav Banerjee
 * @version    V0.0.1
 * @date       04-February-2024
 * @brief      Maze game for using 2-D physics engine
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

byte              widgetOneID                         = 5;
int               CW                                  = 0;
int               CCW                                 = 1;
boolean           renderingForce                      = false;
/* end device block definition *****************************************************************************************/

/* framerate definition ************************************************************************************************/
long              baseFrameRate                       = 120;
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
PVector           fEE                                 = new PVector(0, 0); 

/* World boundaries */
FWorld            world;
float             worldWidth                          = 32.0;  
float             worldHeight                         = 18.0; 

float             edgeTopLeftX                        = 0.0; 
float             edgeTopLeftY                        = 0.0; 
float             edgeBottomRightX                    = worldWidth; 
float             edgeBottomRightY                    = worldHeight;

float             gravityAcceleration                 = 980; //cm/s2
/* Initialization of virtual tool */
HVirtualCoupling  s;

/* define maze blocks */
FBox              b1;
FBox              b2;
FBox              b3;
FBox              b4;
FBox              b5;
FBox              l1;

/* define start and stop button */
FCircle           c1;
FCircle           c2;

/* define game ball */
FCircle           g2;
FBox              g1;

/* define game start */
boolean           gameStart                           = false;

/* text font */
PFont             f;

/* end elements definition *********************************************************************************************/  



/* setup section *******************************************************************************************************/
void setup(){
    /* put setup code here, run once: */

    /* screen size definition */
    size(1280, 720);
    
    /* set font type and size */
    f                   = createFont("Arial", 16, true);

    haplyBoard          = new Board(this, Serial.list()[2], 0);
    widgetOne           = new Device(widgetOneID, haplyBoard);
    pantograph          = new Pantograph();
    
    widgetOne.set_mechanism(pantograph);

    widgetOne.add_actuator(1, CCW, 2);
    widgetOne.add_actuator(2, CW, 1);
    
    widgetOne.add_encoder(1, CCW, 241, 10752, 2);
    widgetOne.add_encoder(2, CW, -61, 10752, 1);
    
    
    widgetOne.device_set_parameters();
    
    
    /* 2D physics scaling and world creation */
    hAPI_Fisica.init(this); 
    hAPI_Fisica.setScale(pixelsPerCentimeter); 
    world               = new FWorld();
    
    /* Start Button */
    c1                  = new FCircle(2.0); // diameter is 2
    c1.setPosition(edgeTopLeftX+2.5, edgeTopLeftY+worldHeight/2.0-3);
    c1.setFill(0, 255, 0);
    c1.setStaticBody(true);
    world.add(c1);
    
    /* Finish Button */
    c2                  = new FCircle(2.0);
    c2.setPosition(worldWidth-2.5, edgeTopLeftY+worldHeight/2.0);
    c2.setFill(200,0,0);
    c2.setStaticBody(true);
    c2.setSensor(true);
    world.add(c2);
    
    
    /* Setup the Virtual Coupling Contact Rendering Technique */
    s                   = new HVirtualCoupling((0.75)); 
    s.h_avatar.setDensity(4); 
    s.h_avatar.setFill(255,255,0); 
    s.h_avatar.setSensor(true);

    s.init(world, edgeTopLeftX+worldWidth/2, edgeTopLeftY+2); 
    
    /* World conditions setup */
    world.setGravity((0.0), gravityAcceleration); //1000 cm/(s^2)
    world.setEdges((edgeTopLeftX), (edgeTopLeftY), (edgeBottomRightX), (edgeBottomRightY)); 
    world.setEdgesRestitution(.4);
    world.setEdgesFriction(0.5);

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
        textFont(f, 22);
    
        if(gameStart){
        fill(0, 0, 0);
        textAlign(CENTER);
        text("Touch the green circle to reset", width/2, 90);
        }
        else{
        fill(128, 128, 128);
        textAlign(CENTER);
        text("Touch the green circle to start the maze", width/2, 60);
        }
    
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
        posEE.set(posEE.copy().mult(200));  
        }
        
        s.setToolPosition(edgeTopLeftX+worldWidth/2-(posEE).x, edgeTopLeftY+(posEE).y-7); 
        s.updateCouplingForce();
    
    
        fEE.set(-s.getVirtualCouplingForceX(), s.getVirtualCouplingForceY());
        fEE.div(100000); //dynes to newtons
        
        torques.set(widgetOne.set_device_torques(fEE.array()));
        widgetOne.device_write_torques();
        
        if (s.h_avatar.isTouchingBody(c1)){
            gameStart = true;
            s.h_avatar.setSensor(false);
        }

        if(s.h_avatar.isTouchingBody(c2)){
            gameStart = false;
            s.h_avatar.setSensor(true);
        }
    
        /* Viscous layer codes */
        if (s.h_avatar.isTouchingBody(l1)){
        s.h_avatar.setDamping(400);
        }
        else{
        s.h_avatar.setDamping(10); 
        }  
    
        world.step(1.0f/1000.0f);
    
        renderingForce = false;
    }
}
/* end simulation section **********************************************************************************************/

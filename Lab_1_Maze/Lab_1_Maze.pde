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
Board haplyBoard;
Device widgetOne;
Mechanisms pantograph;

byte widgetOneID = 5;
int CW = 0;
int CCW = 1;
boolean renderingForce = false;
/* end device block definition *****************************************************************************************/

/* framerate definition ************************************************************************************************/
long baseFrameRate = 120;
/* end framerate definition ********************************************************************************************/ 

/* Screen and world setup parameters */
float pixelsPerCentimeter = 65.0;

/* generic data for a 2DOF device */
/* joint space */
PVector angles = new PVector(0, 0);
PVector torques = new PVector(0, 0);

/* task space */
PVector posEE = new PVector(0, 0);
PVector fEE = new PVector(0, 0); 

/* World boundaries */
FWorld world;
float worldWidth = 13.0;  
float worldHeight = 13.0; 

int range = 20; 

/* Initialization of virtual tool */
HVirtualCoupling  endEffector;

/* define maze blocks */
ArrayList<FWall> walls = new ArrayList<FWall>();
FWall wall1;
FWall wall2;
FWall wall3;
FWall wall4;
FWall wall5;
FWall wall6;
FWall wall7;
FWall wall8;
FWall wall9;
FWall wall10;
FWall wall11;
FWall wall12;
FWall wall13;
FWall wall14;
FWall wall15;
FWall wall16;

/* define start and stop button */
FBox startPoint;
FCircle endPoint;

/* define game start */
boolean gameStart = false;

/* text font */
PFont f;

PImage gate;
PImage treasure;
PImage player;

/* end elements definition *********************************************************************************************/  



/* setup section *******************************************************************************************************/
void setup(){
    /* put setup code here, run once: */

    /* screen size definition */
    size(840, 840);
    
    /* set font type and size */
    f = createFont("Arial", 16, true);

    haplyBoard = new Board(this, Serial.list()[0], 0);
    widgetOne = new Device(widgetOneID, haplyBoard);
    pantograph = new Pantograph();
    
    widgetOne.set_mechanism(pantograph);

    widgetOne.add_actuator(1, CCW, 2);
    widgetOne.add_actuator(2, CW, 1);
    
    widgetOne.add_encoder(1, CCW, 241, 10752, 2);
    widgetOne.add_encoder(2, CW, -61, 10752, 1);
    
    widgetOne.device_set_parameters();
    
    /* 2D physics scaling and world creation */
    hAPI_Fisica.init(this); 
    hAPI_Fisica.setScale(pixelsPerCentimeter); 
    world = new FWorld();
    
    /* Walls Creation */
    wall1 = new FWall(1, 1, 5, 1);
    walls.add(wall1);
    world.add(wall1);

    wall2 = new FWall(1, 1, 1, 5);
    walls.add(wall2);
    world.add(wall2);

    wall3 = new FWall(1, 5, 5, 1);
    walls.add(wall3);
    world.add(wall3);

    wall4 = new FWall(3, 5, 1, 3);
    walls.add(wall4);
    world.add(wall4);

    wall5 = new FWall(3, 7, 7, 1);
    walls.add(wall5);
    world.add(wall5);

    wall6 = new FWall(5, 7, 1, 3);
    walls.add(wall6);
    world.add(wall6);

    wall7 = new FWall(5, 9, 5, 1);
    walls.add(wall7);
    world.add(wall7);

    wall8 = new FWall(7, 5, 1, 3);
    walls.add(wall8);
    world.add(wall8);

    wall9 = new FWall(7, 1, 1, 3);
    walls.add(wall9);
    world.add(wall9);

    wall10 = new FWall(3, 3, 7, 1);
    walls.add(wall10);
    world.add(wall10);

    wall11 = new FWall(7, 1, 5, 1);
    walls.add(wall11);
    world.add(wall11);

    wall12 = new FWall(9, 5, 3, 1);
    walls.add(wall12);
    world.add(wall12);

    wall13 = new FWall(11, 1, 1, 11);
    walls.add(wall13);
    world.add(wall13);

    wall14 = new FWall(1, 11, 11, 1);
    walls.add(wall14);
    world.add(wall14);

    wall15 = new FWall(1, 7, 1, 5);
    walls.add(wall15);
    world.add(wall15);

    wall16 = new FWall(3, 9, 1, 3);
    walls.add(wall16);
    world.add(wall16);

    /* Start Button */
    startPoint = new FBox(1.0, 1.0);
    startPoint.setPosition(worldWidth/2, 1);
    startPoint.setStaticBody(true);
    startPoint.setSensor(true);
    world.add(startPoint);

    gate = loadImage("../imgs/gate.png"); 
    gate.resize((int)(hAPI_Fisica.worldToScreen(1)), (int)(hAPI_Fisica.worldToScreen(1)));
    startPoint.attachImage(gate);
    
    /* Finish Button */
    endPoint = new FCircle(1.0);
    endPoint.setPosition(1.5, worldHeight/2);
    endPoint.setStaticBody(true);
    endPoint.setSensor(true);
    world.add(endPoint);

    treasure = loadImage("../imgs/treasure.png"); 
    treasure.resize((int)(hAPI_Fisica.worldToScreen(1)), (int)(hAPI_Fisica.worldToScreen(1)));
    endPoint.attachImage(treasure);
    
    
    /* Setup the Virtual Coupling Contact Rendering Technique */
    endEffector = new HVirtualCoupling((0.75)); 
    endEffector.h_avatar.setDensity(4); 
    endEffector.h_avatar.setFill(255,255,0); 
    endEffector.h_avatar.setSensor(true);

    player = loadImage("../imgs/person.png"); 
    player.resize((int)(hAPI_Fisica.worldToScreen(1)), (int)(hAPI_Fisica.worldToScreen(1)));
    endEffector.h_avatar.attachImage(player);

    endEffector.init(world, worldWidth/2, 2); 

    /* World conditions setup */
    world.setEdges((0), (0), (worldWidth), (worldHeight)); 
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
    if(renderingForce == false){
        background(255);
        textFont(f, 22);
        world.draw();
    }
    /* put graphical code here, runs repeatedly at defined framerate in setup, else default at 60fps: */
    if(gameStart){
        for(FWall wall : walls){
            if(wall.getBumpedState() == true) {
                wall.setFill(0, 0, 0);
            }
            else{
                wall.setFill(255, 255, 255);
            }
        }
    }
    else{
        for(FWall wall : walls){
            wall.setFill(255, 255, 255);
        }
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
        
        endEffector.setToolPosition(worldWidth/2-(posEE).x, (posEE).y-7); 
        endEffector.updateCouplingForce();
    
    
        fEE.set(-endEffector.getVirtualCouplingForceX(), endEffector.getVirtualCouplingForceY());
        fEE.div(100000); //dynes to newtons
        
        torques.set(widgetOne.set_device_torques(fEE.array()));
        widgetOne.device_write_torques();
        
        if (endEffector.h_avatar.isTouchingBody(startPoint)){
            gameStart = true;
            endEffector.h_avatar.setSensor(false);
        }

        if(endEffector.h_avatar.isTouchingBody(endPoint)){
            gameStart = false;
            endEffector.h_avatar.setSensor(true);
            for(FWall wall : walls){
                wall.setBumpedState(false);
            }
        }

        for(FWall wall : walls){
            if(endEffector.h_avatar.isTouchingBody(wall)){
                wall.setBumpedState(true);
            }
        }
    
        world.step(1.0f/1000.0f);
    
        renderingForce = false;
    }
}
/* end simulation section **********************************************************************************************/

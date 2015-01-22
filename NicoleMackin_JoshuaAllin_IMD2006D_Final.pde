// Uses the Standard Firmata on the arduino to control an analog in and 
// a digital output
// Assumptions/Setup
// - potentiometer on A0

// Import required libraries for Arduino
import processing.serial.*;
import cc.arduino.*;

Arduino arduino; // create an arduino class instance (we may have more than one!

int sensorPie = 0;
int sensorPot = 1;

//basic variables used throughout
int pie;
int sensorValue;
int fade;
int bubblespawner = 0;
float[] randx;
float[] randz;
ArrayList<Bubbles> bubbles = new ArrayList<Bubbles>();

//sets color
color off = color(4, 79, 111);
color on = color(84, 145, 158);

// gets images from the folder
PImage img;
PImage bg;

class Bubbles {
  
   //starting point for bubbles
   int x = width/2;
   int y = 2*height/3;
   int z = width*2 + 1;
   float randx;
   float randz;
   
   Bubbles(){ //initializer
    
    //for (int q = 0; q < 10; q++)
       randx = random(-5.0,5.0);  
  
    //for (int e = 0; e < 10; e++)
       randz = random(-5.0); 
       
       initializeSphere(30,30);
   }
   
  // Sphere Variables
    //Detail
  int ptsW = 30;
  int ptsH = 30;
    //Number of points
  int numPointsW;
  int numPointsH_2pi; 
  int numPointsH;
    //Coordinates
  float[] coorX;
  float[] coorY;
  float[] coorZ;
  float[] multXZ;
  int counter = 0;
  
  void draw(int fade){
    
    counter++;
    if (counter > 5)
    {   
    x+= randx;
    z+= randz;
    y -= 2;
    
    }
    pushMatrix();
    translate(x,y,z);
    rotateX(180);
    //print(fade);
    sphereTexture(fade, fade, fade, img);
    popMatrix();
    
  }
  
  void initializeSphere(int numPtsW, int numPtsH_2pi) {

  // The number of points around the width and height
  numPointsW=numPtsW+1;
  numPointsH_2pi=numPtsH_2pi;  // How many actual pts around the sphere (not just from top to bottom)
  numPointsH=numPointsH_2pi/2+1;  // How many pts from top to bottom (abs(....) b/c of the possibility of an odd numPointsH_2pi)

  coorX=new float[numPointsW];   // All the x-coor in a horizontal circle radius 1
  coorY=new float[numPointsH];   // All the y-coor in a vertical circle radius 1
  coorZ=new float[numPointsW];   // All the z-coor in a horizontal circle radius 1
  multXZ=new float[numPointsH];  // The radius of each horizontal circle (that you will multiply with coorX and coorZ)

  for (int i=0; i<numPointsW ;i++) {  // For all the points around the width
    float thetaW=i*2*PI/(numPointsW-1);
    coorX[i]=sin(thetaW);
    coorZ[i]=cos(thetaW);
  }
  
  for (int i=0; i<numPointsH; i++) {  // For all points from top to bottom
    if (int(numPointsH_2pi/2) != (float)numPointsH_2pi/2 && i==numPointsH-1) {  // If the numPointsH_2pi is odd and it is at the last pt
      float thetaH=(i-1)*2*PI/(numPointsH_2pi);
      coorY[i]=cos(PI+thetaH); 
      multXZ[i]=0;
    } 
    else {
      //The numPointsH_2pi and 2 below allows there to be a flat bottom if the numPointsH is odd
      float thetaH=i*2*PI/(numPointsH_2pi);

      //PI+ below makes the top always the point instead of the bottom.
      coorY[i]=cos(PI+thetaH); 
      multXZ[i]=sin(thetaH);
    }
  }
}
 
 //SPHERE TEXTURE
 void sphereTexture(float rx, float ry, float rz, PImage t) { 
  // These are so we can map certain parts of the image on to the shape 
  float changeU=t.width/(float)(numPointsW-1); 
  float changeV=t.height/(float)(numPointsH-1); 
  float u=0;  // Width variable for the texture
  float v=0;  // Height variable for the texture

  beginShape(TRIANGLE_STRIP);
  texture(t);
  for (int i=0; i<(numPointsH-1); i++) {  // For all the rings but top and bottom
    // Goes into the array here instead of loop to save time
    float coory=coorY[i];
    float cooryPlus=coorY[i+1];

    float multxz=multXZ[i];
    float multxzPlus=multXZ[i+1];

    for (int j=0; j<numPointsW; j++) {  // For all the pts in the ring
      normal(coorX[j]*multxz, coory, coorZ[j]*multxz);
      vertex(coorX[j]*multxz*rx, coory*ry, coorZ[j]*multxz*rz, u, v);
      normal(coorX[j]*multxzPlus, cooryPlus, coorZ[j]*multxzPlus);
      vertex(coorX[j]*multxzPlus*rx, cooryPlus*ry, coorZ[j]*multxzPlus*rz, u, v+changeV);
      u+=changeU;
    }
    v+=changeV;
    u=0;
  }
  endShape();
  }
}//END BUBBLES CLASS

void setup() {
  size(700, 700, P3D);
  
  background(0); 
  
  noStroke();
  img=loadImage("b_texture.jpg");
  bg=loadImage("bg.jpg");
  
  println(Arduino.list());
  arduino = new Arduino(this, Arduino.list()[0], 57600); //sets to appropriate driver (Most are 0, Mac's are 5 from testing)
  
}

void draw() {

  background(bg);  // creates a background with an image

  camera(width/2.0, height/2.0, (width*2.0 + 1) / tan(PI*30.0 / 180.0), width/2.0, height/2.0, 0, 0, 1, 0); // sets camera view

  sensorPie = arduino.analogRead(0);
  sensorPot = arduino.analogRead(1);
  
  fade = int(map(sensorPot, 0, 1023, 0, 255)); // note Pot value in float
  pie = int(map(sensorPie, 0, 1023, 0, 100)); //outputs Piezo value in float
  if(pie > 100)
  {
    pie = 100;
  }
  pie = 100-pie; // turns pie into the difference between reading from Piezo and 100*/
  //println(pie); //tests pie value as lower
  
if(pie < 70){ 
  if (bubblespawner++ > pie) {
    bubbles.add(new Bubbles());
    bubblespawner = 0;
    pie = 0;
    
  }
}
    for(int i = 0; i <bubbles.size(); i++)
  {
    bubbles.get(i).draw(fade); //
  }
 }
  
// Toggle between 0 and 1 based on time and requested speed 
long last = 0;
int state = 0;
  
 int toggle(int speed) {
   long cur = millis();
   
   if ((cur - last) > speed) {
     state = 1 - state;
     last = cur;
   }
   return state;
 }


int stripeWidth = 500.0;
int segmentLength = 2;
int segmentWidth = 70;
int roadLength = 20000;
Segment[] road; 

int drawSegments = 200;

float camZ = 0.0;
int camHeight = 20;
int camY; // changes with the road
int camX = 0;

int hScreenW = 320;

float screenDist = 500.0;

// helper vars
float rz, rz2, ry, ry2, rx, rx2, sx;
int currentSegment;

PImage car, carup, cardown, carleft, carright, clouds;
int direction = 0;
float speed = 0;
int maxSpeed = 20;

void setup() {
  size(640, 480);
  background(255);
  fill(0);
  noStroke();
  //noLoop();
  frameRate(25);

  createRoad();

  car = loadImage("car.png");
  carup = loadImage("car-up.png");
  cardown = loadImage("car-down.png");
  carleft = loadImage("car-left.png");
  carright = loadImage("car-right.png");
  clouds = loadImage("clouds.png");
}

void draw() {
  background(50,200,50);

  camZ += speed;
  currentSegment = (int)(camZ / segmentLength);
  camY = camHeight + road[currentSegment].y;
  
  drawRoad();
  
  //image(clouds, 0, 0);
  drawCar();

  if (speed > 0)
    speed -= 0.05;
  else
    speed = 0
}

void drawRoad() {
  
  int corner = 0;
  for(int i = currentSegment; i<currentSegment+drawSegments; i++) {
    corner += road[i].corner;
    road[i].x = corner;
  }
  
  // do not draw the entire road
  for (int i=currentSegment+drawSegments; i>currentSegment && i<roadLength; i--) {
    fill(road[i].col);

    // world -> cam
    rz = road[i].z - camZ;
    rz2 = road[i].z + segmentLength - camZ;
    ry = road[i].y - camY;
    ry2 = road[i].y2 - camY;
    rx = 0;
    rx2 = 0;

    // cam -> screeny 
    ry = -1 * screenDist*ry / rz;
    ry2 = -1 * screenDist*ry2 / rz2;

    rx = ((screenDist*segmentWidth) / rz);
    rx2 = ((screenDist*segmentWidth) / rz2);

    // tarmac
    quad(
      hScreenW-rx2/2 + road[i].x - camX,ry2, 
      hScreenW+rx2/2 + road[i].x - camX,ry2, 
      hScreenW+rx/2 + road[i].x - camX,ry, 
      hScreenW-rx/2 + road[i].x - camX,ry
    );

    if (road[i].stripe) {
      fill(255);
      sx = stripeWidth / rz;
      rect(hScreenW-sx/2 + road[i].x - camX, ry2, sx, ry-ry2);
    }
  }
}

void keyPressed() {
  if (speed > 0) {
    if (keyCode == LEFT) {
      direction = -1;
      camX -= 10;
    } else if (keyCode == RIGHT) {
      direction = 1;
      camX += 10;
    }
  }
  if (keyCode == UP) {
    if (speed < maxSpeed)
      speed += 0.1;
  }
}

void keyReleased() {
  if (keyCode == LEFT) {
    direction = 0;
  } else if (keyCode == RIGHT) {
    direction = 0;
  }
  if (keyCode == UP) {
    if (speed > 0)
      speed -= 0.1;
  }

}

void drawCar() {
  if (direction == -1)
    image(carleft, 240, 350, carleft.width*2, carleft.height*2);
  else if (direction == 1)
    image(carright, 240, 350, carright.width*2, carright.height*2);
  else if (road[currentSegment].up)
    image(carup, 240, 350, carup.width*2, carup.height*2);
  else if (road[currentSegment].down)
    image(cardown, 240, 350, cardown.width*2, cardown.height*2);
  else
    image(car, 240, 350, car.width*2, car.height*2); 
}

class Segment {
  int z, x, y, y2;
  float corner;
  color col;
  boolean stripe, up, down;
  
  Segment(z, col) {
    this.z = z;
    if (col == 0)
      this.col = color(100,100,100);
    else
      this.col = color(150,150,150);
  }  
}

void createRoad() {
  // 0: straight, 1: left corner, 2: right corner, 3: hill, 4: depress
  int[] chunks = {0,0,0,1,2,3,4};
  int chunkLength = 200;

  road = new Segment[roadLength];
  
  for (int i=0;i<roadLength/chunkLength;i++) {
    createChunk(chunks[(int)random(chunks.length())], i*chunkLength, i*chunkLength + chunkLength);
  }
}

void createChunk(int kind, int b, int e) {
  int color = 0;
  boolean stripe = false;

  float current = 0;
  float[] inc = {0, 0.1, -0.1, 0.2, -0.2};
  float[] max = {0, 1, 1, 20, 20};

  // ease in
  for (int i=b; i<b+((e-b)/4); i++) {
    // stripe and color
    if (i%13 == 0 )
      color = 1-color;
    if (i%7 == 0 )
      stripe = !stripe;
    
    road[i] = new Segment(i*segmentLength, color);
    road[i].stripe = stripe;

    // corners and hills
    if (kind == 1) {
      if (abs(current) < max[kind])
        current += inc[kind];
      road[i].corner = current;
    } else if (kind == 2) {
      if (abs(current) < max[kind])
        current += inc[kind];
      road[i].corner = current;
    } else if (kind == 3) {
      road[i].y = current;
      if (abs(current) < max[kind])
        current += inc[kind];
      road[i].y2 = current;
      road[i].up = true;
    } else if (kind == 4) {
      road[i].y = current;
      if (abs(current) < max[kind])
        current += inc[kind];
      road[i].y2 = current;
      road[i].down = true;
    }
  }
  // middle
  for (int i=b+((e-b)/4); i<e - ((e-b)/4); i++) {
    // stripe and color
    if (i%13 == 0 )
      color = 1-color;
    if (i%7 == 0 )
      stripe = !stripe;
    
    road[i] = new Segment(i*segmentLength, color);
    road[i].stripe = stripe;

    // corners and hills
    if (kind == 1) {
      road[i].corner = current;
    } else if (kind == 2) {
      road[i].corner = current;
    } else if (kind == 3) {
      road[i].y = current;
      road[i].y2 = current;
    } else if (kind == 4) {
      road[i].y = current;
      road[i].y2 = current;
    }
  }
  // ease out
  for (int i =e-((e-b)/4); i < e; i ++) {
    // stripe and color
    if (i%13 == 0 )
      color = 1-color;
    if (i%7 == 0 )
      stripe = !stripe;
    
    road[i] = new Segment(i*segmentLength, color);
    road[i].stripe = stripe;

    // corners and hills
    if (kind == 1) {
      if (abs(current) > 0)
        current -= inc[kind];
      road[i].corner = current;
    } else if (kind == 2) {
      if (abs(current) > 0)
        current -= inc[kind];
      road[i].corner = current;
    } else if (kind == 3) {
      road[i].y = current;
      if (abs(current) > 0)
        current -= inc[kind];
      road[i].y2 = current;
      road[i].down = true;
    } else if (kind == 4) {
      road[i].y = current;
      if (abs(current) > 0)
        current -= inc[kind];
      road[i].y2 = current;
      road[i].up = true;
    }
  }
}

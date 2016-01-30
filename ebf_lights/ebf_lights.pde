import codeanticode.syphon.*;
import ddf.minim.analysis.*;
import ddf.minim.*;

SyphonClient client;
PImage img;

OPC opc;

/** Constants **/
static int NumLEDsPerStrip = 30;
static int NumStrips = 16;
static float WidthInches = 90;
static float HeightInches = 28;
static float LEDInches = 38;
static float SpacingBetweenLEDs = LEDInches / NumLEDsPerStrip;
static float DistanceBetweenStrips = 5.625;
static float ScalingFactor = 10;

void settings() {
  size(int(WidthInches * ScalingFactor), int(WidthInches * ScalingFactor*9.0/16.0), P3D);
  PJOGL.profile = 1;
}

void setup()
{
  client = new SyphonClient(this);

  // Connect to the local instance of fcserver
  opc = new OPC(this, "127.0.0.1", 7890);
  opc.showLocations(false);
  opc.setDithering(false);
  opc.setInterpolation(false);

  float calibrationNudgeX = DistanceBetweenStrips*ScalingFactor/2 - 4;
  float calibrationNudgeY = -16.5;

  PVector startLeft = new PVector(calibrationNudgeX,height/4 + calibrationNudgeY);
  PVector endRight = new PVector(0,LEDInches);
  endRight.mult(ScalingFactor);
  endRight.rotate(-PI/4);

  PVector startRight = new PVector(width - calibrationNudgeX,height/4 + calibrationNudgeY);
  PVector endLeft = new PVector(0,LEDInches);
  endLeft.mult(ScalingFactor);
  endLeft.rotate(PI/4);

  for(int i = 0; i < NumStrips/2; i++) {
    int index = i * NumLEDsPerStrip;
    ledStripBetweenPoints(index, NumLEDsPerStrip, startLeft, PVector.add(startLeft, endRight), true);
    startLeft.x += DistanceBetweenStrips * ScalingFactor;
  }

  for(int i = 0; i < NumStrips/2; i++) {
    int index = NumStrips/2*NumLEDsPerStrip + i*NumLEDsPerStrip;
    ledStripBetweenPoints(index, NumLEDsPerStrip, startRight, PVector.add(startRight, endLeft), true);
    startRight.x -= DistanceBetweenStrips * ScalingFactor;
  }
}

void draw()
{
  background(0);
  noStroke();
  if (client.newFrame()) {
    img = client.getImage(img); // load the pixels array with the updated image info (slow)
    // img = client.getImage(img, false); // does not load the pixels array (faster)
  }
  if (img != null) {
    image(img, 0, 0, width, height);
  }
  //
  // fill(0,255,0);
  // rightTriangle(width/2, height/4 + 10, 600);
  //
  // fill(255,0,0);
  // pushMatrix();
  // translate(250, 337);
  // rotate(PI);
  // rightTriangle(0,0, 600);
  // popMatrix();
  //
  // fill(0,0,255);
  // pushMatrix();
  // translate(width-250, 337);
  // rotate(PI);
  // rightTriangle(0,0, 600);
  // popMatrix();
  // Calibration crosshairs
  // noStroke();
  // rect(width/2-1, 0,2,height);
  // rect(0,height/2-1,width,2);
}

void ledStripBetweenPoints(int index, int stripLength, PVector start, PVector end, boolean reverse) {
  for(int i = 0; i < stripLength; i++) {
    if (reverse) {
      opc.led(
        index + (stripLength - 1 - i),
        int(lerp(start.x, end.x, float(i)/float(stripLength))),
        int(lerp(start.y, end.y, float(i)/float(stripLength)))
      );
    } else {
      opc.led(
        index + i,
        int(lerp(start.x, end.x, float(i)/float(stripLength))),
        int(lerp(start.y, end.y, float(i)/float(stripLength)))
      );
    }
  }
}

void rightTriangle( float topX, float topY, float sideLength ) {
  pushMatrix();
  beginShape();

  float h = sideLength*sqrt(2);
  translate( topX, topY );
  vertex(0,0);
  vertex( -h/2, .5*sideLength*sqrt(2));
  vertex( +h/2, .5*sideLength*sqrt(2));

  endShape( CLOSE );
  popMatrix();
}

import ddf.minim.analysis.*;
import ddf.minim.*;

OPC opc;

// Audio Stuff
Minim minim;
AudioPlayer song;
FFT fft;
float[] fftFilter;

String songFilename = "jaar.mp3";
float decay = 0.97;


/** Constants **/
static int NumLEDsPerStrip = 30;
static int NumStrips = 16;
static float WidthInches = 90;
static float HeightInches = 28;
static float LEDInches = 38;
static float SpacingBetweenLEDs = LEDInches / NumLEDsPerStrip;
static float DistanceBetweenStrips = 5.625;
static float ScalingFactor = 10;

// The fft filter buffer length is 256
static int LFStartIndex = 4;
static int LFEndIndex = 5;
static int HFStartIndex = 32;
static int HFEndIndex = 64;


void setup()
{
  size(int(WidthInches * ScalingFactor), int(HeightInches * ScalingFactor));
      
  setupAudio();

  // Connect to the local instance of fcserver
  opc = new OPC(this, "127.0.0.1", 7890);
  
  float rotate1 = (13 * PI) / 4;
  float spacing = SpacingBetweenLEDs * ScalingFactor;
  float startX = (LEDInches / sqrt(2) / 2) * ScalingFactor;
  float incrementX = DistanceBetweenStrips * ScalingFactor;
  float y = height / 2;

  for (int i = 0; i < NumStrips / 2; i++) {
    int index = i * NumLEDsPerStrip;
    float x = startX + i * incrementX;
    opc.ledStrip(index, NumLEDsPerStrip, x, y, spacing, rotate1, false);
  }

  float rotate2 = (7 * PI) / 4;
  startX = startX + incrementX * 3.5;

  for (int i = 0; i < NumStrips / 2; i++) {
    int index = (NumStrips - i - 1) * NumLEDsPerStrip;
    float x = startX + i * incrementX;
    opc.ledStrip(index, NumLEDsPerStrip, x, y, spacing, rotate2, false);
  }
}

void setupAudio() {
  minim = new Minim(this);
 
 // Small buffer size!
  song = minim.loadFile(songFilename, 512);
  fft = new FFT(song.bufferSize(), song.sampleRate());
  fftFilter = new float[fft.specSize()]; 
}

void keyPressed()
{
  
  // S to start song at position
  if (key == 's' || key == 'S') {
    song.cue(200000);
    song.play();
  }
}

void draw()
{
  background(0);
  
  drawFrequencyBars();
}

void drawFrequencyBars() {
  // Pass the audio data through an fft.
  fft.forward(song.mix);  
  for (int i = 0; i < fftFilter.length; i++) {
    fftFilter[i] = max(fftFilter[i] * decay, log(1 + fft.getBand(i)));
  }
  
  // Average the values in the low frequency range of the fft (defined in constants).
  float lfAverage = 0;
  for (int i = LFStartIndex; i <= LFEndIndex; i++) {
    lfAverage += fftFilter[i];
  }
  lfAverage /= LFEndIndex - LFStartIndex;

  // Average the values in the high frequency range of the fft (defined in constants).
  float hfAverage = 0;
  for (int i = HFStartIndex; i <= HFEndIndex; i++) {
    hfAverage += fftFilter[i];
  }
  hfAverage /= HFEndIndex - HFStartIndex;

  // Scale the averages
  float lfScalingValue = scaledValueFromAverage(lfAverage, 4);
  float hfScalingValue = scaledValueFromAverage(hfAverage, 2);

  // Draw a rect on the left half of the screen scaled by the low frequencies.
  for (int i = 0; i < 8; i++) {
    rect(0, height, width / 2, -height * lfScalingValue);
  }

  // Draw a rect on the right half of the screen scaled by the high frequencies.
  for (int i = 8; i < 16; i++) {
    rect(width / 2, height, width / 2, -height * hfScalingValue);
  }
}

float scaledValueFromAverage(float average, float scale) {
  // pow(average, 0.75) * pow(60/(60-i), 0.4);
  return pow(average, 0.75) / scale;
}


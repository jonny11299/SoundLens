import java.util.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.signals.*;
import ddf.minim.spi.*;
import ddf.minim.ugens.*;


/************************************************/
//final String FILE_NAME = "Technicolour Beat.mp3";
//final String FILE_NAME = "Purple Gusher.mp3";
//final String FILE_NAME = "Table Flipping.mp3";
//final String FILE_NAME = "01 Everything in Its Right Place.mp3";
//final String FILE_NAME = "visual test.mp3";
//final String FILE_NAME = "white noise test.mp3";
//final String FILE_NAME = "Here to Stay.mp3";
//final String FILE_NAME = "Nova.mp3";
//final String FILE_NAME = "Ascension.mp3";
//final String FILE_NAME = "Forgotten.mp3";
//final String FILE_NAME = "City Nights.mp3";
//final String FILE_NAME = "Fade to Grey.mp3";
final String FILE_NAME = "Dreamsters.mp3";
//final String FILE_NAME = "04 How to Disappear Completely.mp3";
//final String FILE_NAME = "06 Black Wave.mp3";
//final String FILE_NAME = "01 BOOGIE.mp3";
//final String FILE_NAME = "01 Big Question Small Head.mp3";
//final String FILE_NAME = "05 Treefingers.mp3";
//final String FILE_NAME = "06 Velours.wav";
/************************************************/
  
  
Minim minim;
AudioPlayer player;
AudioPlayer song;
AudioInput input;
AudioMetaData meta;
FFT fft;
List<LinkedList<Float>> fftBands;
float[] fftBandsAvg; //the average length over the past [SMOOTHING] samples in fftBands
final int SMOOTHING = 8;
final float C1 = 2; //C1 is intensity constant for vibration of each ring
final float C2 = 21; //C2 is spacing constant between each ring
final float CENTER_SIZE = 0; //size of the very middle ring
final int SAMPLE_RATE = 1024;
final int STROKE_WEIGHT = 1; //stroke weight of the line
final float STROKE_STRENGTH = 256; //stroke strength of the line
 
final float FLOAT_PI = (float) Math.PI + 0.005;

final float RED_ZONE = 50; //UNUSED //Used to determine how loud music must be for the ring to change from green to red
final float COLOR_SMOOTHING = 15; //how smooth the transition from green to red is
final float BLUE_OSC = 0.01; //how quickly the blue color oscilates
final float RING_COLOR_DIFF = 0.2; //how much the blue changes ring to ring

//float prevMaxVariation = -1;
//float maxVariation = 0;

int masterCount = 0; //counts how many frames have passed
//negative propogates outwards, positive propogates inwards
 
final int BAND_STRENGTH_MOD = 3; //don't worry about this variable, it's for an unused subroutine

void setup()
{
  size(800, 800, P2D);
  //size(800, 800);
 
  minim = new Minim(this);
  
  player = minim.loadFile(FILE_NAME, SAMPLE_RATE);
  song = minim.loadFile(FILE_NAME);
  input = minim.getLineIn();
  //meta = player.getMetaData();
  fft = new FFT(player.bufferSize(), player.sampleRate());
  
  fftBands = new ArrayList<LinkedList<Float>>(fft.specSize());
  fftBandsAvg = new float[fft.specSize()];
  for (int i = 0 ; i < fft.specSize() ; i++){
    fftBandsAvg[i] = 0;
    fftBands.add(new LinkedList<Float>());
    for (int j = 0 ; j < SMOOTHING ; j++){
      fftBands.get(i).add(new Float(0));
    }
  }
  
  player.play();
  //player.mute();
  //song.play();
  
  strokeWeight(STROKE_WEIGHT);
}
 
int ys = 15;
int yi = 15;
 
void draw()
{
  background(0);
  //displayMetaData();
  drawMyWay();
  //drawOnlineWay();
  
  /* This stuff is for testing:
  int numLines = 15;
  Point[] points = new Point[numLines];
  stroke(255, 0, 255);
  
  for (int j = 0 ; j < numLines ; j++){  
    float variation = C1 * sin(j);
    float y = map((float) j, 0.0, numLines, FLOAT_PI/2, 3 * FLOAT_PI/2);
    float freq = C2;
    
    points[j] = new Point(g(variation, y, freq, "cos"),
                          g(variation, y, freq, "sin"));
    //points[j] = new Point(y * freq, variation + height/2);
  }

    
  for (int n = 0 ; n < numLines - 1 ; n++){
    line(points[n].getx(), points[n].gety(), points[n + 1].getx(), points[n + 1].gety());
  }
  */
}


void drawMyWay(){
  fill(255, 255, 255);
  
  //drawRawBands();
  //drawBottomEQ();
  fft.forward(player.mix);
  calculateSmoothFreq();  //do NOT run simultaneously with drawBottomEQ()
  //drawLeftCircle();
  //drawRightCircle();
  drawMixCircle();
  
  /*
  if (maxVariation > prevMaxVariation){
    println("New max variation of: " + maxVariation);
    prevMaxVariation = maxVariation;
  }
  */
  
  masterCount++;
}



void drawMixCircle(){
  
  int numFrames = player.mix.size();
  stroke(0, 255, 255);
  
  int curRing = 0;
  //i1 is the EQ band it's grabbing information from. 
  //i2 is used to increment it using the fibonacci sequence
  int i2 = 2;
  for(int i1 = 1; i1 < fft.specSize() + 1; i1 = i2 - i1)
  {
    int i = i1 - 1;
    Point[] points = new Point[numFrames];
    float freq = C2 * (curRing + CENTER_SIZE);
    
    for(int j = 0; j < numFrames; j++){
      
      //float variation = log (player.left.get(j) * fft.getBand(i) + 1); //without smoothing
      //float variation = log (player.mix.get(j) * fftBandsAvg[i] + 1); //with smoothing
      double variable = Math.cbrt(player.mix.get(j) * fftBandsAvg[i] + 1); //with smoothing
      float variation = new Float(variable*variable);
      variation *= curRing + 1;
      /*
      if (fftBandsAvg[i] > maxVariation){
        maxVariation = variation;
      }
      */
      
      float y = map((float) j, 0.0, (float) numFrames, FLOAT_PI / 2, 3 * FLOAT_PI / 2);
      
      points[j] = new Point(g(variation, y, freq, "cos"),
                            g(variation, y, freq, "sin"));
    }
    
    float x = 1024/FLOAT_PI * atan((C1 * fftBandsAvg[i])/COLOR_SMOOTHING);
 
    //float red = map(C1 * fftBandsAvg[i], 0, RED_ZONE, 0, 512);
    //float green = map(C1 * fftBandsAvg[i], 0, RED_ZONE, 512, 0);

    
    float red = x;
    float green = 512 - x;
    
    //println("Red: " + red + "  ||  Green: " + green + "  ||  x: " + x + "  || fftBandsAvg[i] " + fftBandsAvg[i]);
    float blue = map(sin(BLUE_OSC * masterCount + curRing * RING_COLOR_DIFF * (-1)), -1, 1, 0, 256);
    stroke(red, green, blue);
    //stroke(red, green, blue, STROKE_STRENGTH);
    for (int n = 0 ; n < numFrames - 1 ; n++){
      line(points[n].getx(), points[n].gety(), points[n + 1].getx(), points[n + 1].gety());
      //line(points[n].getx(), height - points[n].gety(), points[n + 1].getx(), height - points[n + 1].gety()); //when split vertically
      line(width - points[n].getx(), points[n].gety(), width - points[n + 1].getx(), points[n + 1].gety());
    }
    
    curRing++;
    i2 += i1;
  }
}

float g(float variation, float y, float freq, String funct){
  
  float trig = y;
  float offset = 0;
  if (funct.toLowerCase() == "sin"){
    trig = sin(y);
    offset = height/2;
  }else if (funct.toLowerCase() == "cos"){
    trig = cos(y);
    offset = width/2;
  }else{
    print("Strange case");
  }
    
  return ((C1*variation) + freq) * trig + offset;
}


void calculateSmoothFreq(){ //do NOT run simultaneously with drawBottomEQ()
  int i2 = 2;
  for(int i1 = 1; i1 < fft.specSize() + 1; i1 = i2 - i1)
  {
    int i = i1 - 1;
    
    fftBandsAvg[i] += fft.getBand(i) / SMOOTHING;
    fftBandsAvg[i] -= fftBands.get(i).removeLast() / SMOOTHING;
    fftBands.get(i).push(new Float(fft.getBand(i)));
    
    i2 += i1;
  }
}










//UNUSED
//***************************


void drawLeftCircle(){
  
  int numFrames = player.left.size();
  stroke(0, 255, 255);
  
  int curRing = 0;
  //i1 is the EQ band it's grabbing information from. 
  //i2 is used to increment it using the fibonacci sequence
  int i2 = 2;
  for(int i1 = 1; i1 < fft.specSize() + 1; i1 = i2 - i1)
  {
    int i = i1 - 1;
    Point[] points = new Point[numFrames];
    float freq = C2 * (curRing + CENTER_SIZE);
    
    for(int j = 0; j < numFrames; j++){
      
      //float variation = log (player.left.get(j) * fft.getBand(i) + 1); //without smoothing
      //float variation = log (player.mix.get(j) * fftBandsAvg[i] + 1); //with smoothing
      double variable = Math.cbrt(player.left.get(j) * fftBandsAvg[i] + 1); //with smoothing
      float variation = new Float(variable*variable);
      variation *= curRing + 1;
      /*
      if (fftBandsAvg[i] > maxVariation){
        maxVariation = variation;
      }
      */
      
      float y = map((float) j, 0.0, (float) numFrames, 3 * FLOAT_PI / 2, 1 * FLOAT_PI / 2 - 0.0075);
      
      points[j] = new Point(g(variation, y, freq, "cos"),
                            g(variation, y, freq, "sin"));
    }
    
    float red = map(C1 * fftBandsAvg[i], 0, RED_ZONE, 0, 512);
    float green = map(C1 * fftBandsAvg[i], 0, RED_ZONE, 512, 0);
    stroke(red, green, 0);
    for (int n = 0 ; n < numFrames - 1 ; n++){
      line(points[n].getx(), points[n].gety(), points[n + 1].getx(), points[n + 1].gety());
      //line(points[n].getx(), height - points[n].gety(), points[n + 1].getx(), height - points[n + 1].gety()); //when split vertically
    }
    
    curRing++;
    i2 += i1;
  }
}

void drawRightCircle(){
  
  int numFrames = player.left.size();
  stroke(0, 255, 255);
  
  int curRing = 0;
  //i1 is the EQ band it's grabbing information from. 
  //i2 is used to increment it using the fibonacci sequence
  int i2 = 2;
  for(int i1 = 1; i1 < fft.specSize() + 1; i1 = i2 - i1)
  {
    int i = i1 - 1;
    Point[] points = new Point[numFrames];
    float freq = C2 * (curRing + CENTER_SIZE);
    
    for(int j = 0; j < numFrames; j++){
      
      //float variation = log (player.left.get(j) * fft.getBand(i) + 1); //without smoothing
      //float variation = log (player.mix.get(j) * fftBandsAvg[i] + 1); //with smoothing
      double variable = Math.cbrt(player.right.get(j) * fftBandsAvg[i] + 1); //with smoothing
      float variation = new Float(variable*variable);
      variation *= curRing + 1;
      /*
      if (fftBandsAvg[i] > maxVariation){
        maxVariation = variation;
      }
      */
      
      float y = map((float) j, 0.0, (float) numFrames, 3 * FLOAT_PI / 2, 5 * FLOAT_PI / 2);
      
      points[j] = new Point(g(variation, y, freq, "cos"),
                            g(variation, y, freq, "sin"));
    }
    
    float red = map(C1 * fftBandsAvg[i], 0, RED_ZONE, 0, 512);
    float green = map(C1 * fftBandsAvg[i], 0, RED_ZONE, 512, 0);
    stroke(red, green, 0);
    for (int n = 0 ; n < numFrames - 1 ; n++){
      line(points[n].getx(), points[n].gety(), points[n + 1].getx(), points[n + 1].gety());
      //line(points[n].getx(), height - points[n].gety(), points[n + 1].getx(), height - points[n + 1].gety()); //when split vertically
    }
    
    curRing++;
    i2 += i1;
  }
}

void drawRawBands(){
  float xSilence = width/2;
  float leftxSilence = width/4;
  float rightxSilence = 3 * width/4;
  int numFrames = player.mix.size();  
  
  float x, leftx, rightx;
  float y, lefty, righty;
  float prevleftx = leftxSilence;
  float prevx = xSilence;
  float prevrightx = rightxSilence;
  float prevlefty = 0;
  float prevy = 0;
  float prevrighty = 0;
  
  for(int i = 0; i < numFrames; i++) {
    leftx = map(player.left.get(i), 1, -1, leftxSilence - width/6, leftxSilence + width/6);
    x = map(player.mix.get(i), 1, -1, xSilence - width/6, xSilence + width/6);
    rightx = map(player.right.get(i), 1, -1, rightxSilence - width/6, rightxSilence + width/6);
    lefty = map(i, 0, numFrames - 1, 0, height);
    y = map(i, 0, numFrames - 1, 0, height);
    righty = map(i, 0, numFrames - 1, 0, height);
    
    stroke(255, 255, 255);
    line(prevleftx, prevlefty, leftx, lefty);
    stroke(255, 255, 255);
    line(prevx, prevy, x, y);
    stroke(255, 255, 255);
    line(prevrightx, prevrighty, rightx, righty);
    
    prevleftx = leftx; prevlefty = lefty;
    prevx = x; prevy = y;
    prevrightx = rightx; prevrighty = righty;
  }
}  

void drawBottomEQ(){
  fft.forward(player.mix);
  stroke(255, 255, 0, 128);
  fill(255, 0, 255, 128);
  float specWidth = log(fft.specSize());
  float x = 0;
  for(int i = 0; i < fft.specSize(); i++)
  {
    fftBandsAvg[i] += fft.getBand(i) / SMOOTHING;
    fftBandsAvg[i] -= fftBands.get(i).removeLast() / SMOOTHING;
    fftBands.get(i).push(new Float(fft.getBand(i)));
    
    x = map(log(i + 1), 0, specWidth, 0, width);
    float bandStrength = fftBandsAvg[i];
    rect(x, height - bandStrength*BAND_STRENGTH_MOD, map(log(i + 2) - log(i + 1), 0, specWidth, 0, width), 
                                                                        bandStrength * BAND_STRENGTH_MOD);
    
    //with no smoothing:
    //x = map(log(i + 1), 0, specWidth, 0, width);
    //float bandStrength = fft.getBand(i);
    //rect(x, height - bandStrength*5, map(log(i + 2) - log(i + 1), 0, specWidth, 0, width), bandStrength * 5);
  }
  
  fill(255, 255, 255, 128);
  int i2 = 2;
  for(int i1 = 1; i1 < fft.specSize() + 1; i1 = i2 - i1)
  {
    int i = i1 - 1;
    fftBandsAvg[i] += fft.getBand(i) / SMOOTHING;
    fftBandsAvg[i] -= fftBands.get(i).removeLast() / SMOOTHING;
    fftBands.get(i).push(new Float(fft.getBand(i)));
    
    x = map(log(i + 1), 0, specWidth, 0, width);
    float bandStrength = fftBandsAvg[i];
    rect(x, height - bandStrength*BAND_STRENGTH_MOD, map(log(i + 2) - log(i + 1), 0, specWidth, 0, width), 
                                                                        bandStrength * BAND_STRENGTH_MOD);
    
    //with no smoothing:
    //x = map(log(i + 1), 0, specWidth, 0, width);
    //float bandStrength = fft.getBand(i);
    //rect(x, height - bandStrength*5, map(log(i + 2) - log(i + 1), 0, specWidth, 0, width), bandStrength * 5);
    i2 += i1;
  }
}




void drawOnlineWay(){
  stroke(0, 255, 255);
  for(int i = 0; i < player.bufferSize() - 1; i++)
  {
    line(i, 50 + player.left.get(i)*50, i+1, 50 + player.left.get(i+1)*50);
    line(i, 150 + player.right.get(i)*50, i+1, 150 + player.right.get(i+1)*50);
  }
}

void displayMetaData(){
  int y = ys;
  text("File Name: " + meta.fileName(), 5, y);
  text("Length (in milliseconds): " + meta.length(), 5, y+=yi);
  text("Title: " + meta.title(), 5, y+=yi);
  text("Author: " + meta.author(), 5, y+=yi); 
  text("Album: " + meta.album(), 5, y+=yi);
  text("Date: " + meta.date(), 5, y+=yi);
  text("Comment: " + meta.comment(), 5, y+=yi);
  text("Track: " + meta.track(), 5, y+=yi);
  text("Genre: " + meta.genre(), 5, y+=yi);
  text("Copyright: " + meta.copyright(), 5, y+=yi);
  text("Disc: " + meta.disc(), 5, y+=yi);
  text("Composer: " + meta.composer(), 5, y+=yi);
  text("Orchestra: " + meta.orchestra(), 5, y+=yi);
  text("Publisher: " + meta.publisher(), 5, y+=yi);
  text("Encoded: " + meta.encoded(), 5, y+=yi);
}

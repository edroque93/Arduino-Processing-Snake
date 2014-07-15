import processing.serial.*;
import cc.arduino.*;
import java.util.*;

private Arduino arduino;
private int scale=20;
private int cols, rows;
private int dir=1;
private boolean override=false;
private int points=0;
private List<Coord> snake;
private Coord apple;
private int[] pad={2,3,4,5};
/*
  0 - Up;
  1 - Right;
  2 - Down;
  3 - Left;
*/

class Coord{
  public int x, y;
  
  public Coord(){
    x=0;
    y=0; 
  }
  
  public Coord(int x, int y){
    this.x=x;
    this.y=y;
  } 
}

public void setup(){
  if(Arduino.list().length!=0){
    println("\nIntentando comunicar con Arduino...");
    
    if((arduino=new Arduino(this,Arduino.list()[0],57600))!=null)
      println("Arduino conectado correctamente.");
      
    for(int i=0; i<pad.length; i++)
      arduino.pinMode(pad[i], Arduino.INPUT);
  }else{
    println("\nError al conectar con Arduino.");
    exit();
    return;
  }
  
  size(640,480);
  textFont(loadFont("Andalus-25.vlw")); 
  noCursor();  
  fill(255);
  background(0);
  
  cols=width/scale;
  rows=height/scale;
  
  snake=new ArrayList<Coord>();
  apple=new Coord();
  snake.add(new Coord(cols/2,rows/2));
  dropApple(apple);
  
  thread("game");
}

public void draw(){
  if(override) return;
  
  frame.setTitle("Snake "+round(frameRate)+"fps - Puntos: "+points); 
  
  background(0);
 fill(232,171,40);
  for (int i = 0; i<cols; i++)
    for (int j = 0; j<rows; j++)
      rect(i*scale,j*scale,scale,scale); 
      
  fill(104,173,40);
  Iterator i=snake.iterator();
  while(i.hasNext()){
    Coord s=(Coord)i.next();
    rect(s.x*scale,s.y*scale,scale,scale);
  } 
  
  fill(255,0,0,220);
  rect(apple.x*scale,apple.y*scale,scale,scale);  

  strokeText("ThePirateCat",5,475,new int[]{50,222,222}, new int[]{0,0,0});
}

public void readControls(){
  if(arduino.digitalRead(pad[0])!=Arduino.LOW && dir!=2) dir=0; // Up
  else if(arduino.digitalRead(pad[1])!=Arduino.LOW && dir!=3) dir=1; // Right
  else if(arduino.digitalRead(pad[2])!=Arduino.LOW && dir!=0) dir=2; // Down 
  else if(arduino.digitalRead(pad[3])!=Arduino.LOW && dir!=1) dir=3; // Left
}

public void moveSnake(){
  for(int i=snake.size()-1; i>0; i--){
    snake.get(i).x=snake.get(i-1).x;
    snake.get(i).y=snake.get(i-1).y;
  } 
  
  switch(dir){
    case 0: snake.get(0).y--;
            break;
    case 1: snake.get(0).x++;
            break;
    case 2: snake.get(0).y++;
            break;
    case 3: snake.get(0).x--;       
  }
}

public void checkBounds(){
  int x=snake.get(0).x;
  int y=snake.get(0).y;
  
  // Selfeating om nom nom
  
  Iterator i=snake.iterator();
  i.next(); // Head
  while(i.hasNext()){
    Coord s=(Coord)i.next();
    if(x==s.x && y==s.y) lose();
  } 
  
  // Borders
  
  if(x>cols-1 || y>rows-1 || x<0 || y<0) lose();
  
  // What about an apple? hey apple!
  
  if(x==apple.x && y==apple.y){
    points+=10;
    
    snake.add(new Coord(-1,-1)); // Array space
    
    for(int ix=snake.size()-1; ix>1; ix--){
      snake.get(ix).x=snake.get(ix-1).x;
      snake.get(ix).y=snake.get(ix-1).y;
    } 

    dropApple(apple);
  }
}

public void dropApple(Coord A){
  A.x=round(random(0,cols-1));
  A.y=round(random(0,rows-1));
  
  Iterator i=snake.iterator();
  while(i.hasNext()){
    Coord s=(Coord)i.next();
    if(s.x==A.x && s.y==A.y){ 
      dropApple(A);
      return;
    }
  } 
}

public void lose(){
  override=!override;
  int time;
  
  for(int i=0; i<100; i++){
    fill(216,55,55,i);
    rect(0,0,width,height);
    
    time=millis();
    while(millis()-time < 15);
  }
  
  fill(0);

  text("La serpiente ha muerto dejando atrás a su mujer e hijos :(",25,200);
  textFont(loadFont("Chiller-Regular-80.vlw"));
  
  time=millis();
  while(millis()-time < 1200);
  
  pushMatrix();
  rotate(-0.2f);
  strokeText("¿Resucitarás?",100,350,new int[]{0,0,0},new int[]{255,0,0});
  popMatrix();

  while(arduino.digitalRead(pad[0])!=Arduino.HIGH &&
        arduino.digitalRead(pad[1])!=Arduino.HIGH &&
        arduino.digitalRead(pad[2])!=Arduino.HIGH &&
        arduino.digitalRead(pad[3])!=Arduino.HIGH);
  
  textFont(loadFont("Andalus-25.vlw"));
  dropApple(apple);
  snake.clear();
  snake.add(new Coord(cols/2,rows/2));
  points=0;
  override=!override;
}

public synchronized void game(){
  int time;
  
  while(true){
    readControls();
    moveSnake();
    checkBounds();

    time = millis();
    while(millis()-time < 5000/round(frameRate));
  } 
}

public void strokeText(String message, int x, int y, int[] r, int[] i){
  fill(r[0],r[1],r[2]);
  text(message, x-1, y);
  text(message, x, y-1);
  text(message, x+1, y);
  text(message, x, y+1);
  fill(i[0],i[1],i[2]);
  text(message, x, y);
}

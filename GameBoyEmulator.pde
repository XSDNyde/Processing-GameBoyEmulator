import java.nio.file.Files;
import java.nio.file.Paths;

import java.io.FileOutputStream;
import java.io.FileNotFoundException;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;

SOC_LR35902 soc;
// Emulator Specific
Screen_DMG screen;
Reader_DMGCartridge romReader;
Cartridge_DMG cartridge;
Viewer_TileSet viewerTileSet;
Viewer_TileMap viewerTileMap;

double deltaTime, then, now;


boolean DEBUG_OUTPUT = false;
boolean DEBUG_OUT_ONE_LINE = false;
boolean DEBUG_TO_FILE = false;


void setup()
{
  size( 1600, 900 );
  noSmooth();
  frameRate( 60 );
  
  if( DEBUG_TO_FILE )
  {
    try
    {
      PrintStream fileOut = new PrintStream( new FileOutputStream( sketchPath( "debug.log" ) ), true /*auto-flush*/, StandardCharsets.UTF_8 );
      System.setOut( fileOut );
      Runtime.getRuntime().addShutdownHook( new Thread( () -> fileOut.close() ) );
    }
    catch ( FileNotFoundException fnfe ) {}
  }
  
  screen = new Screen_DMG();
  
  romReader = new Reader_DMGCartridge( "/roms/dmg/The_Bouncing_Ball_v0.1.0_(Gameboy)/", "THEBOUNCINGBALL.GB" );
  //romReader = new Reader_DMGCartridge( "/roms/dmg/MurderMansion_rom/", "game.gb" );
  //romReader = new Reader_DMGCartridge( "/roms/dmg/cpu_instrs/", "cpu_instrs.gb" );
  //romReader = new Reader_DMGCartridge( "/roms/dmg/snake/", "snake.gb" );
  //romReader = new Reader_DMGCartridge( "/roms/dmg/", "tetris.gb" );
  //romReader = new Reader_DMGCartridge( "/roms/dmg/", "drmario.gb" );
  //romReader = new Reader_DMGCartridge( "/roms/dmg/", "pokebluejp.gb" );
  
  romReader.printCartridgeHeader();
  cartridge = new Cartridge_DMG( romReader.getROMData() );
  
  println();
  println( "Megahertz: " + MHZ );
  println( "Nanoseconds per tick: " + TICK_NS );
  then = System.nanoTime();
  
  soc = new SOC_LR35902();
  soc.reset();
  soc.plugin( cartridge );
  println( "\n" + soc );
  
  int[] tileSetOffsets = { 0x0000, 0x0800, 0x1000 }; 
  viewerTileSet = new Viewer_TileSet( soc.getVRAM().data, tileSetOffsets );
                   
  int[] tileMapOffsets = { 0x1800, 0x1C00 };                          
  viewerTileMap = new Viewer_TileMap( soc.getVRAM().data, tileMapOffsets, soc.getIORegisters().data, viewerTileSet.tiles );
  
  then = millis();
}



void draw()
{
  now = millis();
  deltaTime = now - then;
  then = now;
  
  surface.setTitle( "CPU STEP " + soc.getStepCount() + ", PC: " + soc.getPC() );
  
  // ### UPDATE ###
  soc.update( deltaTime );
   //<>//
  viewerTileSet.update();
  viewerTileMap.update();
  
  background( color( 0, 63, 127 ) );
  
  float scale;
  int margin;
  
  // show the Tile Sets [0x8000,0x9800[
  pushMatrix();
  scale = 4f;
  margin = 5;
  translate( 644+margin, 0+margin );
  imageMode( CORNER );
  viewerTileSet.present( scale );
  popMatrix();
  
  // show the Tile Map [0x9800,0xA000[
  pushMatrix();
  scale = 1.5f;
  margin = 5;
  translate( 1160+margin, 0+margin );
  imageMode( CORNER );
  viewerTileMap.present( scale );
  popMatrix();
  
  // show the output of the actual emulation
  pushMatrix();
  scale = 4f;
  translate( 0*width/4+margin, 0*height/2+margin );
  imageMode( CORNER );
  screen.present( scale );
  popMatrix();
}

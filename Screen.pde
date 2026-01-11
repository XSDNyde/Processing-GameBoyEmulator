


class Screen_DMG
{
  final int PIXELS_X = 160;
  final int PIXELS_Y = 144;
  final float ASPECT_RATIO = (float)PIXELS_X / PIXELS_Y;
  final color[] COLORS_HARDWARE_LCD = { color( #214231 ), color( #426b29 ), color( #6c9421 ), color( #8cad28 ) }; 
  
  PGraphics buffer;
  
  
  public Screen_DMG()
  {
    this.buffer = createGraphics( PIXELS_X, PIXELS_Y );
    this.buffer.beginDraw();
    this.buffer.noStroke();
    this.buffer.fill( COLORS_HARDWARE_LCD[0] );
    this.buffer.rect( 0, 0,                            buffer.width/2, buffer.height/2 );
    this.buffer.fill( COLORS_HARDWARE_LCD[1] );
    this.buffer.rect( buffer.width/2, 0,               buffer.width/2, buffer.height/2 );
    this.buffer.fill( COLORS_HARDWARE_LCD[2] );
    this.buffer.rect( 0, buffer.height/2,              buffer.width/2, buffer.height/2 );
    this.buffer.fill( COLORS_HARDWARE_LCD[3] );
    this.buffer.rect( buffer.width/2, buffer.height/2, buffer.width/2, buffer.height/2 );
    this.buffer.endDraw();
  }
  
  
  public void present( float scaleFactorInEmulator )
  {
    image( buffer, 0, 0, PIXELS_X*scaleFactorInEmulator, PIXELS_Y*scaleFactorInEmulator );
  }
}

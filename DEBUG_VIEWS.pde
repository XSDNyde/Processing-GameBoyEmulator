


class Viewer_TileSet
{
  final int TILE_X = 8;
  final int TILE_Y = 8;
  final int TILES_X = 16;
  final int TILES_PER_BLOCK = 128;
  final int TILES_Y_PER_BLOCK = TILES_PER_BLOCK / TILES_X;
  final int NUM_BLOCKS = 3;
  
  private byte[] vRAMData;
  private int [] tileSetOffsets;
  private Tile[] tiles;
  private PGraphics buffer;
  
  
  public Viewer_TileSet( byte[] vRAMData, int[] tileSetOffsets )
  {
    this.vRAMData = vRAMData;
    this.tileSetOffsets = tileSetOffsets;
    this.tiles = new Tile[TILES_PER_BLOCK*NUM_BLOCKS];
    this.buffer = createGraphics( TILE_X*TILES_X, NUM_BLOCKS*TILE_Y*TILES_Y_PER_BLOCK );
    this.buffer.beginDraw();
    this.buffer.noStroke();
    this.buffer.fill( color( 255, 0, 255 ) );
    this.buffer.rect( 0, 0, buffer.width, buffer.height );
    this.buffer.endDraw();
  }
  
  
  public void update()
  {
    generateTilesFromBlocks();
  }
  
  
  public void present( float scaleFactorInEmulator )
  {
    drawTilesToBuffer();
    image( buffer, 0, 0, buffer.width*scaleFactorInEmulator, buffer.height*scaleFactorInEmulator );
  }
  
  
  private void generateTilesFromBlocks()
  {
    final int bytesPerTile = 16;
    for ( int block = 0; block < NUM_BLOCKS; block++ )
      for ( int i = 0; i < TILES_PER_BLOCK; i++ )
      {
        //println("IDX"+tileSetOffsets[block] + i*bytesPerTile);
        tiles[block*TILES_PER_BLOCK+i] = new Tile();
        tiles[block*TILES_PER_BLOCK+i].setToIndices( vRAMData, tileSetOffsets[block] + i*bytesPerTile );
      }
  }
  
  
  private void drawTilesToBuffer()
  {
    this.buffer.beginDraw();
    this.buffer.imageMode( CORNER );
    int
      tX = 0,
      tY = 0;
    for( int i = 0; i < tiles.length; i++ )
    {
      this.buffer.image( tiles[i].pImage, tX, tY );
      tX = tX + TILE_X;
      if ( tX >= TILE_X * TILES_X )
      {
        tX = 0;
        tY += TILE_Y;
      }
    }
    this.buffer.endDraw();
  }
}




class Viewer_TileMap
{
  final int TILE_X = 8;
  final int TILE_Y = 8;
  final int TILES_X = 32;
  final int TILES_Y = 32;
  final int TILES_PER_MAP = TILES_X*TILES_Y;
  final int BYTES_PER_MAP = TILES_PER_MAP*1;
  final int NUM_MAPS = 2;
  
  private byte[] vRAMData;
  private int [] tileMapOffsets;
  private Tile[] tileSets;
  private PGraphics buffer;
  
  final private int LCDC_IDX = 0x40;
  final private int BG_WIN_ADDR_MODE_BIT = 4;
  final private int SCY_IDX = 0x42;
  final private int SCX_IDX = 0x43;
  final private ByteArrayByteSlice LCDC, SCY, SCX;
  
  
  public Viewer_TileMap( byte[] vRAMData, int[] tileMapOffsets, byte[] ioRegistersData, Tile[] tileSets )
  {
    assert tileSets.length == 3*128 : "Supply three tile sets!";
    this.vRAMData = vRAMData;
    this.tileMapOffsets = tileMapOffsets;
    this.LCDC = new ByteArrayByteSlice( ioRegistersData, LCDC_IDX );
    this.SCY  = new ByteArrayByteSlice( ioRegistersData, SCY_IDX );
    this.SCX  = new ByteArrayByteSlice( ioRegistersData, SCX_IDX );
    this.tileSets = tileSets;
    this.buffer = createGraphics( TILE_X*TILES_X, TILE_Y*TILES_Y*NUM_MAPS );
    this.buffer.beginDraw();
    this.buffer.noStroke();
    this.buffer.fill( color( 0, 255, 255 ) );
    this.buffer.rect( 0, 0, buffer.width, buffer.height );
    this.buffer.endDraw();
  }
  
  
  public void update() {}
  
  
  private void drawTilesToBuffer()
  {
    // use TileSet 1+2 or 2+3?
    int tileSetOffset = LCDC.isBitSet( 0, BG_WIN_ADDR_MODE_BIT ) ? 0 : 128;
    
    this.buffer.beginDraw();
    this.buffer.background( color( 0, 255, 255 ) );
    this.buffer.imageMode( CORNER );
    int
      tX = 0,
      tY = 0;
    for( int map = 0; map < NUM_MAPS; map++ )
      for( int i = 0; i < TILES_PER_MAP; i++ )
      {
        this.buffer.image( tileSets[ tileSetOffset + vRAMData[ tileMapOffsets[map] + i ] & 0xFF ].pImage, tX, tY );
        tX = tX + TILE_X;
        if ( tX >= TILE_X * TILES_X )
        {
          tX = 0;
          tY += TILE_Y;
        }
      }
      
    // Draw Viewport
    int vpXl = SCX.get();
    int vpXr = ( vpXl + 159 ) % 256;
    int vpYt = SCY.get();
    int vpYb = ( vpYt + 143 ) % 256;
    
    this.buffer.stroke( color( 255, 127, 0 ) );
    this.buffer.strokeWeight( 1 );
    
    // l -> r
    this.buffer.line( vpXl, vpYt, min( vpXl+159, 256 ), vpYt );
    this.buffer.line( vpXl, vpYb, min( vpXl+159, 256 ), vpYb );
    // r -> l
    this.buffer.line( max( vpXr-159, 0 ), vpYt, vpXr, vpYt );
    this.buffer.line( max( vpXr-159, 0 ), vpYb, vpXr, vpYb );
    // t -> b
    this.buffer.line( vpXl, vpYt, vpXl, min( vpYt+143, 256 ) );
    this.buffer.line( vpXr, vpYt, vpXr, min( vpYt+143, 256 ) );
    // b -> t
    this.buffer.line( vpXl, max( vpYb-143, 0 ), vpXl, vpYb );
    this.buffer.line( vpXr, max( vpYb-143, 0 ), vpXr, vpYb );
    
    this.buffer.endDraw();
  }
  
  
  public void present( float scaleFactorInEmulator )
  {
    drawTilesToBuffer();
    image( buffer, 0, 0, buffer.width*scaleFactorInEmulator, buffer.height*scaleFactorInEmulator );
  }
}

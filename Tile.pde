


class Tile
{
  color[][] palettes = { { color( 0 ), color( 85 ), color( 170 ), color( 255 ) },
                         { color( #214231 ), color( #426b29 ), color( #6c9421 ), color( #8cad28 ) } };
  final int TILE_X = 8;
  final int TILE_Y = 8;
  final int BIT_DEPTH = 2;
  final int BYTES_PER_TILE = TILE_X*TILE_Y*BIT_DEPTH/8;
  
  int palette = 0;
  boolean transparent00 = false;
  
  PImage pImage;
  
  
  public Tile()
  {
    pImage = createImage( TILE_X, TILE_Y, ARGB );
  }
  
  
  public void setToIndices( byte[] indices, int offset )
  {
    // A tile has 16 Bytes for 8x8 pixels, hence 2 bits per pixel
    assert indices.length >= offset + BYTES_PER_TILE : "Last index out of bounds!";
    int p = 0;
    //pImage.loadPixels();
    for ( int i = 0; i < BYTES_PER_TILE; i += 2 )  // 2 bytes decoded in each row
    {
      //println( "\n" + String.format("0x%1$02X", indices[offset+i+1] ) + ", " + String.format("0x%1$02X", indices[offset+i] ) + " decodes to: " );
      for ( int j = 7; j >= 0; j-- ) //decode 2 bits per pixel
      {
        //print( " " + ( ( ( ( indices[i+1] & ( 1 << j ) ) >> j ) << 1 ) | ( ( indices[i] & ( 1 << j ) ) >> j ) ) );
        pImage.pixels[p++] = palettes[palette][ ( ( ( indices[offset+i+1] & ( 1 << j ) ) >> j ) << 1 ) | ( ( indices[offset+i] & ( 1 << j ) ) >> j ) ];
      }
      //println();
    }
    pImage.updatePixels();
  }
}

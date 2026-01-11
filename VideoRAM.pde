


class VideoRAM implements BusSubscriber
{
  boolean DEBUG_READ = true;
  boolean DEBUG_WRITE = false;
  
  
  final byte[] data = new byte[0x2000];
  
  
  @Override
  int read( int address )
  {
    assert address >= 0 && address < data.length : "Address " + address + " is outside the Video RAM!";
    if( DEBUG_OUTPUT | DEBUG_READ ) println( "[DEBUG] [VRAM] READ " + HEX( data[ address ] ) + " FROM " + HEX2( address ) );
    return data[ address ] & 0xFF;
  }
  
  
  @Override
  void write( int address, int value )
  {
    assert address >= 0 && address < data.length : "Address " + address + " is outside the Video RAM!";
    if( DEBUG_OUTPUT | DEBUG_WRITE ) println( "[DEBUG] [VRAM] WRITE " + HEX( value ) + " TO " + HEX2( address ) );
    data[ address ] = (byte) value;
  }
  
  
  @Override
  String toString()
  {
    return this.getClass().getSimpleName();
  }
  
  
  @Override
  public int getLength() { return data.length; }
}

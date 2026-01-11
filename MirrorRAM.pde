


class MirrorRAM implements BusSubscriber
{
  private final int LENGTH = 0x1E00;
  private final byte[] mirroredRAMData;
  
  
  MirrorRAM( WorkRAM toBeMirrored )
  {
    this.mirroredRAMData = toBeMirrored.data;
  }
  
  
  @Override
  int read( int address )
  {
    assert address >= 0 && address < LENGTH : "Address " + address + " is outside the Mirror RAM!";
    if( DEBUG_OUTPUT ) println( "[DEBUG] [MirRAM] READ " + HEX( mirroredRAMData[ address ] ) + " FROM " + HEX2( address ) );
    return mirroredRAMData[ address ] & 0xFF;
  }
  
  
  @Override
  void write( int address, int value )
  {
    assert address >= 0 && address < LENGTH : "Address " + address + " is outside the Mirror RAM!";
    if( DEBUG_OUTPUT ) println( "[DEBUG] [MirRAM] WRITE " + HEX( value ) + " TO " + HEX2( address ) );
    mirroredRAMData[ address ] = (byte) value;
  }
  
  
  @Override
  String toString()
  {
    return this.getClass().getSimpleName();
  }
  
  
  @Override
  public int getLength() { return LENGTH; }
}

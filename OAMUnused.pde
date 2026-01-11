


class OAMUnused implements BusSubscriber
{
  private final int LENGTH = 0x0060;
  
  
  @Override
  int read( int address )
  {
    assert address >= 0 && address < LENGTH : "Address " + address + " is outside the UNUSED OAM AREA!";
    if( DEBUG_OUTPUT ) println( "[DEBUG] [OAM] READ 0x00 FROM " + HEX2( address ) );
    return 0x00;
  }
  
  
  @Override
  void write( int address, int value )
  {
    assert address >= 0 && address < LENGTH : "Address " + address + " is outside the UNUSED OAM AREA!";
    if( DEBUG_OUTPUT ) println( "[DEBUG] [OAM] WRITE IGNORED TO " + HEX2( address ) );
  }
  
  
  @Override
  String toString()
  {
    return this.getClass().getSimpleName();
  }
  
  
  @Override
  public int getLength() { return LENGTH; }
}

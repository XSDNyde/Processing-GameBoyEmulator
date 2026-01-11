


interface BusSubscriber
{
  public int read( int address );
  public void write( int address, int value );
  
  public int getLength();
}



class DebugSubscriber implements BusSubscriber
{
  private int numAddresses;
  
  
  public DebugSubscriber( int numAddresses )
  {
    this.numAddresses = numAddresses;
  }
  
  @Override
  int read( int address )
  {
    assert false : "[DebugSubscriber] Length: " + HEX2( getLength() ) + " fullfills READ OF " + HEX( 0xFF ) + " FROM " + HEX2( address );
    if( DEBUG_OUTPUT ) println( "DebugSubscriber fullfills READ OF " + HEX( 0xFF ) + " FROM " + HEX2( address ) );
    return 0xFF;
  }
  
  
  @Override
  void write( int address, int value )
  {
    //assert false : "[DebugSubscriber] Length: " + HEX2( getLength() ) + " fullfills WRITE " + HEX( value ) + " TO " + HEX2( address );
    if( DEBUG_OUTPUT ) println( "DebugBusSubscriber fullfills WRITE " + HEX( value ) + " TO " + HEX2( address ) );
  }
  
  
  @Override
  String toString()
  {
    return this.getClass().getSimpleName();
  }
  
  
  @Override
  public int getLength() { return numAddresses; }
}

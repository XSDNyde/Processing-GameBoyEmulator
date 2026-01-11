


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
    if( DEBUG_OUTPUT ) println( "DebugBusSubscriber fullfills READ OF " + HEX( 0xFF ) + " FROM " + HEX2( address ) );
    return 0xFF;
  }
  
  
  @Override
  void write( int address, int value )
  {
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

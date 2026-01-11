


class UnusableAddressesBusSubscriber implements BusSubscriber
{
  @Override
  int read( int address )
  {
    assert false : "Address " + HEX2( address ) + " requested of UnusableAddressesBussubscriber Memory!";
    return 0xFF;
  }
  
  
  @Override
  void write( int address, int value )
  {
    //assert false : "Address " + HEX2( address ) + " set to " + HEX( value ) + " requested of UnusableAddressesBussubscriber Memory!";
  }
  
  
  @Override
  String toString()
  {
    return this.getClass().getSimpleName();
  }
  
  
  @Override
  public int getLength() { return 0x0060; }
}

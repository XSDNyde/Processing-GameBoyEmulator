


class IERegister implements BusSubscriber
{
  final byte[] data = new byte[0x0001];
  
  
  @Override
  int read( int address )
  {
    assert address >= 0 && address < data.length : "Address " + address + " is outside the Interrupt Enable Register!";
    if( DEBUG_OUTPUT ) println( "[DEBUG] [IE Reg] READ " + HEX( data[ address ] ) + " FROM " + HEX2( address ) );
    return data[ address ] & 0xFF;
  }
  
  
  @Override
  void write( int address, int value )
  {
    assert address >= 0 && address < data.length : "Address " + address + " is outside the Interrupt Enable Register!";
    if( DEBUG_OUTPUT ) println( "[DEBUG] [IE Reg] WRITE " + HEX( value ) + " TO " + HEX2( address ) );
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

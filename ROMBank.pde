


class ROMBank implements BusSubscriber
{
  byte[] romData;
  int bankBegin;
  int bankLength;
  
  
  public ROMBank( byte[] romData, int bankBegin, int bankLength )
  {
    this.romData = romData;
    this.bankBegin = bankBegin;
    this.bankLength = bankLength;
  }
  
  
  @Override
  int read( int address )
  {
    assert address >= 0 && address < bankLength : "Trying to access an element outside this bank!";
    int value = romData[ address ] & 0xFF;
    if( DEBUG_OUTPUT ) println( "Cartridge ROM Bank READ " + HEX( value ) + " FROM " + HEX2( address ) );
    return value;
  }
  
  
  @Override
  void write( int address, int value )
  {
    assert address >= 0 && address < bankLength : "Trying to access an element outside this bank!";
    
    assert false : "WRITING TO CARTRIDGE ROM NOT SUPPORTED. Used for MBC Configuration! Address: " + HEX2( address ) + ", Value: " + HEX( value );
    
    //romData[ address ] = (byte) ( value &= 0xFF );
    //if( DEBUG_OUTPUT ) println( "Cartridge ROM Bank WRITE " + String.format( "0x" + "%1$02X", value ) + " TO " + String.format( "0x" + "%1$04X", address ) );
  }
  
  
  @Override
  String toString()
  {
    return this.getClass().getSimpleName();
  }
  
  
  @Override
  public int getLength() { return bankLength; }
}

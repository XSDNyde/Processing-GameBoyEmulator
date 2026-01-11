


class MemoryBankController implements BusSubscriber
{
  // MBC also covers [0xA000,0xBFFF] when using RAM! There is a hole from [0x8000,0x9FFF] used by Video RAM!
  final protected int length = 0x8000;
  
  protected Bus_LR35902 bus;
  
  protected ROMBank[] romBanks;
  protected ROMBank mappedBank00;
  protected ROMBank mappedBankNN;
  
  
  void mapBanks( Bus_LR35902 bus )
  {
    this.bus = bus;
    // assuming no MBC and two 16 kiB ROM banks
    mappedBank00 = romBanks[ 0 ];
    mappedBankNN = romBanks[ 1 ];
    
    bus.attach( 0x0000, mappedBank00, true, false );  // ROM responds to reads only
    bus.attach( 0x4000, mappedBankNN, true, false );  // ROM responds to reads only
    bus.attach( 0x0000, this, false, true );  // MBC responds to writes only
  }
  
  
  void setROMBanks( ROMBank[] romBanks )
  {
    this.romBanks = romBanks;
  }
  
  
  @Override
  int read( int address )
  {
    assert address >= 0 && address < length : "Trying to access an element outside the MBC!";
    if( DEBUG_OUTPUT ) println( "MBC READ AT " + HEX2( address ) );
    assert false : "MBC should not be read!";
    return 0xFF;
  }
  
  
  @Override
  void write( int address, int value )
  {
    assert address >= 0 && address < length : "Trying to access an element outside the MBC!";
    assert value == 0x00 : "MBC Configuration Write! Address: " + HEX2( address ) + ", Value: " + HEX( value ) + " Only value 0x00 --> ROM Bank Mode is implemented!";
    if( DEBUG_OUTPUT ) println( "MBC Configuration Write! Address: " + HEX2( address ) + ", Value: " + HEX( value ) );
  }
  
  
  @Override
  String toString()
  {
    return this.getClass().getSimpleName();
  }
  
  
  @Override
  public int getLength() { return length; }
}



class NoMBC extends MemoryBankController
{
  
}



class MBC1 extends MemoryBankController
{
  @Override
  void write( int address, int value )
  {
    assert address >= 0 && address < length : "Trying to access an element outside the MBC!";
    if( DEBUG_OUTPUT ) println( "[MBC1] Configuration Write! Address: " + HEX2( address ) + ", Value: " + HEX( value ) );
    if( true ) println( "[MBC1] Configuration Write! Address: " + HEX2( address ) + ", Value: " + HEX( value ) );
    
    // TODO: 0x0000 RAM Enable
    // TODO: 0x2000 ROM Bank
    // TODO: 0x4000 RAM Bank / 2 bit of ROM Bank
    // TODO: 0x6000 ROM / RAM Mode
    
    int newBank;
    // lowest 5 bit are cehcked if 0 and if set to 1
    if ( ( value & 0b0001_1111 ) == 0 )
      value |= 0b0000_0001;
    newBank = value & 0b0001_1111;// TODO: incorporate 2 more bits from 4000h-5FFF write
    
    assert newBank > 0x00 & newBank < romBanks.length : "[MBC1] Tried to map ROM Bank " + HEX( newBank ) + " but it does not exist!";
    
    bus.detach( mappedBankNN );
    mappedBankNN = romBanks[ newBank ];
    bus.attach( 0x4000, mappedBankNN, true, false );
    
    if( true ) println( "[MBC1] Attached Bank: " + HEX( newBank ) + " to the bus!" );
  }
}

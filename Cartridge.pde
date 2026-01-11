 


class Cartridge_DMG
{
  private MemoryBankController mbc;
  private ROMBank[] romBanks;
  
  
  public Cartridge_DMG( byte[] romData )
  {
    // check MBC type and ROM length
    int t = romData[ 0x0147 ] & 0xFF;
    if ( t == 0x00 )
      mbc = new NoMBC();
    else if ( t == 0x01 || t == 0x02 || t == 0x03 )
      mbc = new MBC1();
    else
      throw new MemoryBankControllerTypeNotSupported( romData[ 0x0147 ] );
      
    int numBanks = 2 << romData[ 0x0148 ];
    romBanks = new ROMBank[ numBanks ];
    for ( int i = 0; i < romBanks.length; i++ )
      romBanks[i] = new ROMBank( romData, i*0x4000, 0x4000 );
      
    mbc.setROMBanks( romBanks );
  }
  
  
  @Override
  public String toString()
  {
    return "---{ Game Cartridge DMG }---\n";
  }
  
  
  private class MemoryBankControllerTypeNotSupported extends RuntimeException
  {
    public MemoryBankControllerTypeNotSupported( int romData0x0147 )
    {
        super( "MemoryBankControllerType is not supported: " + HEX( romData0x0147 ) );
    }
  }
}

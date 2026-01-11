 


class Cartridge_DMG
{
  private MemoryBankController mbc;
  private ROMBank[] romBanks;
  
  
  public Cartridge_DMG( byte[] romData )
  {
    // check MBC type and ROM length
    if ( romData[ 0x0147 ] == 0x00 )
      mbc = new NoMBC();
    else if ( romData[ 0x0147 ] == 0x01 )
      mbc = new MBC1();
      
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
}

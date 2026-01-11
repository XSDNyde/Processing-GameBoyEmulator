


class IntegratedCircuit {}



class SOC_LR35902 extends IntegratedCircuit
{
  Bus_LR35902 bus;
  CPU_DMG cpu;
  PPU_DMG ppu;
  VideoRAM videoRAM;
  OAM oam;
  IORegisters ioRegisters;
  
  
  private long nsSinceLastStep;
  private long stepCount;
  
  
  public SOC_LR35902()
  {
    this.bus         = new Bus_LR35902();
    this.videoRAM    = new VideoRAM();
    this.oam         = new OAM();
    this.ioRegisters = new IORegisters();
    this.cpu         = new CPU_DMG( bus, videoRAM, oam, ioRegisters );
    this.ppu         = new PPU_DMG();
    
    this.nsSinceLastStep = 0l;
  }
  
  
  // @param deltaTime : expected in milliseconds
  public void update( double deltaTime )
  {
    // update when TICK_NS has elapsed since last step
    // since dT is much larger than the tick peroid, multitiple steps should be done per update!
    // TODO: calculate amount of steps necessary to catch up to elapsed time!
    //this.cpu.step();
    
    
    // DEBUG MODE : Step once per second
    nsSinceLastStep += deltaTime * 1_000_000d;
    while( nsSinceLastStep > 1_000l )
    {
      //if( stepCount >= 47_925 ) // leaving bootrom
      //if( stepCount >= 72_570 )
      //if( stepCount >= 73_800 )
      //if( stepCount >= 273_800 )
      if( stepCount >= 1_000_800 )
      {
        DEBUG_OUTPUT = true;
        nsSinceLastStep -= 1_000_000l;
      }
      else
      {
        nsSinceLastStep -= 1_000_00l;
      }
      this.cpu.step();
      this.stepCount++;
      //println( getPC() );

    }
  }
  
  
  public void reset()
  {
    this.cpu.reset();
  }
  
  
  public void plugin( Cartridge_DMG cartridge )
  {
    cartridge.mbc.mapBanks( bus );
    
    // if cart also has RAM, attach it now
    //this.bus.attach( 0xA000, 0x2000, cartridge.ram ); 
  }
  
  
  @Override
  public String toString()
  {
    return
    "-----{ System-On-Chip }-----\n" +
    cpu + "\n" +
    ppu;
  }
  
  
  public VideoRAM getVRAM() { return videoRAM; }
  public IORegisters getIORegisters() { return ioRegisters; }
  public long getStepCount() { return stepCount; }
  public int getPC() { return cpu.getPC(); }
}

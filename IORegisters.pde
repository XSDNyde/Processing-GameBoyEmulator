import java.util.Map;
import java.util.function.Consumer;



class IORegisters implements BusSubscriber
{
  boolean DEBUG_READ = false;
  boolean DEBUG_WRITE = false;
  
  
  final byte[] data = new byte[0x0080];
  
  CPU_DMG cpu;
  
  final Map<Byte,Consumer<Byte>> readFunctions = new HashMap<>();
  final Map<Byte,Consumer<Byte>> writeFunctions = new HashMap<>();
  
  
  public IORegisters()
  {
    // NR52: https://gbdev.io/pandocs/Audio_Registers.html#ff26--nr52-audio-master-control
     readFunctions.put( (byte) 0x26, v -> { if( DEBUG_OUTPUT | DEBUG_READ  ) println( "[DEBUG] R# " + HEX( v ) + " Audio Master Control" ); } );
    writeFunctions.put( (byte) 0x26, v -> { if( DEBUG_OUTPUT | DEBUG_WRITE ) println( "[DEBUG] #W " + HEX( v ) + " Audio Master Control" ); } );
    
    // LCDC: https://gbdev.io/pandocs/LCDC.html#ff40--lcdc-lcd-control
     readFunctions.put( (byte) 0x40, v -> { if( DEBUG_OUTPUT | DEBUG_READ  ) println( "[DEBUG] R# " + HEX( v ) + " LCD Control" ); } );
    writeFunctions.put( (byte) 0x40, v -> { if( DEBUG_OUTPUT | DEBUG_WRITE ) println( "[DEBUG] #W " + HEX( v ) + " LCD Control" ); } );
    
    // SCY: https://gbdev.io/pandocs/Scrolling.html#ff42ff43--scy-scx-background-viewport-y-position-x-position
     readFunctions.put( (byte) 0x42, v -> { if( DEBUG_OUTPUT | DEBUG_READ  ) println( "[DEBUG] R# " + HEX( v ) + " Background Viewport Y Position" ); } );
    writeFunctions.put( (byte) 0x42, v -> { if( DEBUG_OUTPUT | DEBUG_WRITE ) println( "[DEBUG] #W " + HEX( v ) + " Background Viewport Y Position" ); } );
    
    // LY: https://gbdev.io/pandocs/STAT.html#ff44--ly-lcd-y-coordinate-read-only
     readFunctions.put( (byte) 0x44, v -> { if( DEBUG_OUTPUT | DEBUG_READ  ) println( "[DEBUG] R# " + HEX( v ) + " LCD Y Coordinate" ); } );
    writeFunctions.put( (byte) 0x44, v -> { if( DEBUG_OUTPUT | DEBUG_WRITE ) println( "[DEBUG] #W " + HEX( v ) + " LCD Y Coordinate IS FORBIDDEN FOR CPU!" ); } );
    
    // BGP: https://gbdev.io/pandocs/Palettes.html#ff47--bgp-non-cgb-mode-only-bg-palette-data
     readFunctions.put( (byte) 0x47, v -> { if( DEBUG_OUTPUT | DEBUG_READ  ) println( "[DEBUG] R# " + HEX( v ) + " Background Palette Data" ); } );
    writeFunctions.put( (byte) 0x47, v -> { if( DEBUG_OUTPUT | DEBUG_WRITE ) println( "[DEBUG] #W " + HEX( v ) + " Background Palette Data" ); } );
  }
  
  
  public void registerCPU( CPU_DMG cpu )
  {
    this.cpu = cpu;
    
    // see: https://gbdev.io/pandocs/Power_Up_Sequence.html#monochrome-models-dmg0-dmg-mgb
    writeFunctions.put( (byte) 0x50,  v -> { cpu.detachBootstrapROM(); if( DEBUG_OUTPUT | DEBUG_WRITE ) println( "[DEBUG] #W " + HEX( v ) + " BOOTSTRAP ROM UNMAPPED!" ); } );
  }
  
  
  @Override
  int read( int address )
  {
    assert address >= 0 && address < data.length : "Address " + address + " is outside the IO Register Memory!";
    if( DEBUG_OUTPUT | DEBUG_READ ) println( "[DEBUG] [I/O Registers] READ " + HEX( data[ address ] ) + " FROM " + HEX2( address ) );
    Consumer<Byte> c = readFunctions.get( (byte) address );
    if( c != null ) c.accept( (byte) data[ address ] );
    return data[ address ] & 0xFF;
  }
  
  
  @Override
  void write( int address, int value )
  {
    assert address >= 0 && address < data.length : "Address " + address + " is outside the IO Register Memory!";
    if( DEBUG_OUTPUT | DEBUG_WRITE ) println( "[DEBUG] [I/O Registers] WRITE " + HEX( value ) + " TO " + HEX2( address ) );
    Consumer<Byte> c = writeFunctions.get( (byte) address );
    if( c != null ) c.accept( (byte) value );
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

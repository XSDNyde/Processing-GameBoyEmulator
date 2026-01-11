import java.util.Arrays;
import java.nio.charset.Charset;



class Reader_DMGCartridge
{
  byte[] romData;
  
  
  public Reader_DMGCartridge( String cartridgeFolder, String cartridgeFile )
  {
    String[] readme = loadStrings( cartridgeFolder + "readme.txt" );
    String romFile = sketchPath( cartridgeFolder + cartridgeFile );
    try {
      romData = Files.readAllBytes( Paths.get( romFile ) );
    } catch ( IOException ioe ) {
      ioe.printStackTrace();
    }
    assert romFile != null : "Could not load rom file: " + romFile;
    
    if ( readme != null )
    {
      println( "[[ --- README.TXT --- ]]" );
      for ( String s : readme )
        println( s );
    }
  }
  
  
  byte[] getROMData() { return romData; }
  
  
  byte[] getROMData( int address, int lengthInBytes )
  {
    assert address >= 0 : "Cartridge ROM does not contain address " + HEX2( address );
    assert romData.length > ( address+lengthInBytes-1 ) : "Cartridge ROM does not contain address " + HEX2( address+lengthInBytes-1 );
    return Arrays.copyOfRange( romData, address, address+lengthInBytes );
  }
  
  
  public void printCartridgeHeader()
  {
    println( "[[ --- CARTRIDGE HEADER --- ]]" );
    int o = 0x0000;
    int n = 0x0100;
    print( "0100-0103 - Entry Point: (End of boot process leaves program counter [PC] here at 0x0100)\n\t" );
    printNBytesAsHex( romData, o += n, n = 4 );
    print( "\n0104-0133 - Nintendo Logo:\n\t" );
    printNBytesAsHex( romData, o += n, n = 48 );
    print( "\n\t" ); printExpectedLogoHex(); print( " - EXPECTED" );
    print( "\n0134-0143 - Title:\n\t" );
    printNBytesAsASCII( romData, o += n, n = 16 );
    //print( "\n013F-0142 - Manufacturer Code:\n\t" );
    //printNBytesAsHex( romData, o += n, n = 0x0010 );
    //print( "\n0143 - CGB Flag:\n\t" );
    //printNBytesAsHex( romData, o += n, n = 0x0001 );
    print( "\n0144-0145 - New Licensee Code:\n\t" );
    printNBytesAsHex( romData, o += n, n = 2 );
    print( "\n0146 - SGB Flag:\n\t" );
    printNBytesAsHex( romData, o += n, n = 1 );
    print( "\n0147 - Cartridge Type: "+decode0x0147(romData[o+1])+"\n\t" );
    printNBytesAsHex( romData, o += n, n = 1 );
    print( "\n0148 - ROM Size: "+decode0x0148(romData[o+1])+"\n\t" );
    printNBytesAsHex( romData, o += n, n = 1 );
    print( "\n0149 - RAM Size:\n\t" );
    printNBytesAsHex( romData, o += n, n = 1 );
    print( "\n014A - Destination Code:\n\t" );
    printNBytesAsHex( romData, o += n, n = 1 );
    print( "\n014B - Old Licensee Code:\n\t" );
    printNBytesAsHex( romData, o += n, n = 1 );
    print( "\n014C - Mask ROM Version number:\n\t" );
    printNBytesAsHex( romData, o += n, n = 1 );
    print( "\n014D - Header Checksum:\n\t" );
    printNBytesAsHex( romData, o += n, n = 1 );
    int x = 0; for ( int i = 308; i < 333; i++ ) { x = x-romData[i]-1; }
    print( "\n\t" +  HEX( x & 0xFF ) + " - CALCULATED" );
    print( "\n014E-014F - Global Checksum:\n\t" );
    // Contains a 16 bit checksum (upper byte first) across the whole cartridge ROM. Produced by adding all bytes of the cartridge (except for the two checksum bytes).
    printNBytesAsHex( romData, o += n, n = 2 );
    print( "\n" );
    // Actual Program:
    print( "\n0000-0400 First 512 Bytes of Cartridge ROM Data:\n\t" );
    printNBytesAsHex( romData, 0x0000, 1*512 );
    //printNBytesAsHex( romData, 0x0, 64*1024 );
    print( "\n" );
    //// Tile Set Data
    //printNBytesAsHex( romData, 0x8000, 0x1800 );
    //print( "\n" );
    //// Tile Map Data
    //printNBytesAsHex( romData, 0x9800, 0x0800 );
    //print( "\n" );
  }
  
  
  private String decode0x0147( byte c )
  {
    switch ( c & 0x00FF )
    {
      case 0x00 : return "ROM Only";
      case 0x01 : return "MBC1";
      case 0x02 : return "MBC1 with RAM";
      case 0x03 : return "MBC1 with RAM and Battery";
      case 0x05 : return "MBC2";
      case 0x06 : return "MBC2 with RAM and Battery";
      case 0x08 : return "ROM with RAM";
      case 0x09 : return "ROM with RAM and Battery";
      case 0x0B : return "MMM1";
      case 0x0C : return "MMM1 with RAM";
      case 0x0D : return "MMM1 with RAM and Battery";
      case 0x0F : return "MBC3 with Timer and Battery";
      case 0x10 : return "MBC3 with RAM and Timer and Battery";
      case 0x11 : return "MBC3";
      case 0x12 : return "MBC3 with RAM";
      case 0x13 : return "MBC3 with RAM and Battery";
      case 0x19 : return "MBC5";
      case 0x1A : return "MBC5 with RAM";
      case 0x1B : return "MBC5 with RAM and Battery";
      case 0x1C : return "MBC5 with Rumble";
      case 0x1D : return "MBC5 with RAM and Rumble";
      case 0x1E : return "MBC5 with RAM and Battery and Rumble";
      case 0x20 : return "MBC6 with RAM and Battery";
      case 0x22 : return "MBC7 with RAM and Battery and Accelerometer";
      case 0xFC : return "POCKET CAMERA";
      case 0xFD : return "BANDAI TAMA5";
      case 0xFE : return "HuC3";
      case 0xFF : return "HuC1 + RAM + Battery";
      default : return "Cartridge Type UNKNOWN";
    }
  }
  
  
  private String decode0x0148( byte c )
  {
    switch ( c & 0x00FF )
    {
      case 0x00 : return "32 kiB ( 2 banks )";
      case 0x01 : return "64 kiB ( 4 banks )";
      case 0x02 : return "128 kiB ( 8 banks )";
      case 0x03 : return "256 kiB ( 16 banks )";
      case 0x04 : return "512 kiB ( 32 banks )";
      case 0x05 : return "1 MiB ( 64 banks )";
      case 0x06 : return "2 MiB ( 128 banks )";
      case 0x07 : return "4 MiB ( 256 banks )";
      case 0x08 : return "8 MiB ( 512 banks )";
      default : return "ROM Type UNKNOWN";
    }
  }
      
  private void printNBytesAsHex( byte[] hexData, int offset, int numberBytes )
  {
    for ( int i = 0; i < numberBytes; i++ )
      print( HEX( hexData[offset+i] ) + " " );
  }
  
  
  private void printNBytesAsASCII( byte[] hexData, int offset, int numberBytes )
  {
    print( new String( hexData, offset, numberBytes, Charset.forName("US-ASCII") ) );
  }
  
  
  private void printExpectedLogoHex()
  {
    print( "CE ED 66 66 CC 0D 00 0B 03 73 00 83 00 0C 00 0D 00 08 11 1F 88 89 00 0E DC CC 6E E6 DD DD D9 99 BB BB 67 63 6E 0E EC CC DD DC 99 9F BB B9 33 3E" );
  }
}

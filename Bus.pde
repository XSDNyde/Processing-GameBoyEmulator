import java.util.List;
import java.util.Comparator;



class Bus_LR35902
{
  boolean DEBUG_READ = false;
  boolean DEBUG_WRITE = false;
  
  
  private final int
    ADDRESS_WIDTH,
    DATA_WIDTH;
  private List<AddressMapper> subscribers;
  
  
  public Bus_LR35902()
  {
    this.ADDRESS_WIDTH = 16;
    this.DATA_WIDTH = 8;
    this.subscribers = new ArrayList<>();
    this.attach( 0xE000, new DebugSubscriber( 0x1E00 ) );
  }
  
  
  public int read( int address )
  {
    if( DEBUG_OUTPUT | DEBUG_READ ) println( "[DEBUG] [BUS] READ FROM " + HEX2( address ) );
    for( AddressMapper am : subscribers )
    {
      if( am.firstAddress > address )
        continue;
      if( am.firstAddress + am.lengthBytes - 1 < address )
        continue;
      if( ! am.readEnabled )
        continue;
      
      var internalAddress = address - am.firstAddress;
      return am.attachee.read( internalAddress );
    }
    assert false : "Bus Read of address " + HEX2( address ) + " did not hit a mapped resource!";
    return 0x00;
  }
  
  
  public void write( int address, int value )
  {
    //if( address == 0x8000 )
    //  DEBUG_OUTPUT = true;
    value &= 0xFF;
    if( DEBUG_OUTPUT | DEBUG_WRITE ) println( "[DEBUG] [BUS] WRITE " + HEX( value ) + " TO " + HEX2( address ) );
    for( AddressMapper am : subscribers )
    {
      if( am.firstAddress + am.lengthBytes - 1 < address )
        continue;
      if( ! am.writeEnabled )
        continue;
        
      var internalAddress = address - am.firstAddress;
      am.attachee.write( internalAddress, value );
      return;
    }
    assert false : "Bus Write of " + HEX( value ) + " to address " + HEX2( address ) + " did not hit a mapped resource!";
    return;
  }
  
  
  // TODO: This requires more attention. Should the Emulator take care of splitting up attached subscribers? Or does the developer need to take care?
  public void attach( int firstAddress, BusSubscriber attachee ) { attach( firstAddress, attachee, 0, true, true ); }
  public void attach( int firstAddress, BusSubscriber attachee, int priority ) { attach( firstAddress, attachee, priority, true, true ); }
  public void attach( int firstAddress, BusSubscriber attachee, boolean readEnabled, boolean writeEnabled ) { attach( firstAddress, attachee, 0, readEnabled, writeEnabled ); }
  public void attach( int firstAddress, BusSubscriber attachee, int priority, boolean readEnabled, boolean writeEnabled )
  {
    subscribers.add( new AddressMapper( firstAddress, attachee.getLength(), attachee, readEnabled, writeEnabled ) );
    
    // sort preserves relativ order -> important for priority answering e.g. bootstrap
    subscribers.sort( Comparator.comparingInt( am -> am.firstAddress ) );
  }
  
  
  // will remove the first found subscriber. there must not be multiple of the same attached.
  public void detach( BusSubscriber detachee )
  {
    for ( AddressMapper am : subscribers )
    {
      if ( am.attachee == detachee )
      {
        subscribers.remove( am );
        if( DEBUG_OUTPUT ) println( "[DEBUG] [BUS] Subscriber removed: " + detachee );
        return;  // avoid concurrency conflict
      }
    }
    
    println( "Tried to remove " + detachee + " from the bus, but did not find a match!" );
  }
  
  
  @Override
  String toString()
  {
    return "--{ Bus }--{ " + subscribers.size() + " Elements }--" +
      subscribers.stream().map( s -> s.toString()+" " ).reduce( "", ( s, k ) -> s+"\n"+k ) +
      "\n---------------------------";
  }
  
  
  class AddressMapper
  {
    int firstAddress;
    int lengthBytes;
    BusSubscriber attachee;
    boolean readEnabled;
    boolean writeEnabled;
    
    
    AddressMapper( int firstAddress, int lengthBytes, BusSubscriber attachee ) { this( firstAddress, lengthBytes, attachee, true, true ); }
    AddressMapper( int firstAddress, int lengthBytes, BusSubscriber attachee, boolean readEnabled, boolean writeEnabled )
    {
      this.firstAddress = firstAddress;
      this.lengthBytes = lengthBytes;
      this.attachee = attachee;
      this.readEnabled = readEnabled;
      this.writeEnabled = writeEnabled;
    }
    
    
    @Override
    String toString()
    {
      return "Start:" + HEX2( firstAddress ) + "  Last:" + HEX2( firstAddress+lengthBytes-1 ) + "  Type:" + attachee;
    }
  }
}

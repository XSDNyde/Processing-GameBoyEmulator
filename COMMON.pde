


// hex output for Byte input
public static String HEX ( int value ) { return HEX( value & 0xFF, 1 ); }
public static String HEX2( int value ) { return HEX( value & 0xFFFF, 2 ); }
public static String HEX ( int value, int numBytes ) { return String.format( "0x%1$0"+(2*numBytes)+"X", value ); }


// reference to a segment of an existing byte[]
public class ByteArraySlice
{
  final protected byte[] data;
  final protected int offset;
  final protected int length;
  
  
  public ByteArraySlice( byte[] data, int offset, int length )
  {
    this.data = data;
    this.offset = offset;
    this.length = length;
  }
  
  
  public int get( int i ) { ass(i); return data[ offset + i ] & 0xFF; }
  public int getSigned( int i ) { ass(i); return data[ offset + i ]; }
  public void set( int i, int v ) { ass(i); data[ offset + i ] = (byte) ( v & 0xFF ); }
  
  public byte    bit        ( int i, int b ) { ass(i,b); return (byte) ( data[ offset + i ] & ( 1 << b ) ); }
  public boolean isBitSet   ( int i, int b ) { ass(i,b); return ( data[ offset + i ] & ( 1 << b ) ) != 0; }
  public boolean isBitNotSet( int i, int b ) { ass(i,b); return ( data[ offset + i ] & ( 1 << b ) ) == 0; }
  public void    setBit     ( int i, int b ) { ass(i,b); data[ offset + i ] |= ( 1 << b ); }
  public void    resetBit   ( int i, int b ) { ass(i,b); data[ offset + i ] &= ~( 1 << b ); }
  
  private void ass( int i ) { assert ( i >= 0 ) & ( i < length ) : "byte index must be between [0,"+(length-1)+"]"; }
  private void ass( int i, int b ) { ass( i ); assert ( b >= 0 ) & ( b < 7 ) : "bit index must be between [0,7]"; }
}

// reference to a single Byte of an existing byte[]
public class ByteArrayByteSlice extends ByteArraySlice
{
  public ByteArrayByteSlice( byte[] data, int offset )
  {
    super( data, offset, 1 );
  }
  
  
  public int get() { return get( 0 ); }
  public int getSigned() { return getSigned( 0 ); }
  public void set( int v ) { set( 0, v ); }
}

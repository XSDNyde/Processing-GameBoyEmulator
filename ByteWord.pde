import java.util.BitSet;



class BitN
{
  int validBits;
  BitSet bits;
  
  
  public BitN( int bitCount )
  {
    this.validBits = bitCount;
    this.bits = new BitSet( bitCount );
  }
  
  
  public void set( int index, boolean value ) { bits.set( index, value ); }
  public boolean get( int index ) { return bits.get( index ); }
  
  
  public void increment()
  {
    int i = bits.nextClearBit(0);
    bits.clear(0, i);
    if( i < validBits )
      bits.set(i);
  }
  
  
  public void decrement()
  {
    int i = bits.nextSetBit( 0 );
    if ( i < 0 || i >= validBits )
    {
        bits.set( 0, validBits );
        return;
    }
    
    bits.clear( i );
    bits.set( 0, i );
  }


  @Override
  String toString()
  {
    String s = "";
    for( int i = 0; i < validBits; i++ )
    {
      s = ( bits.get( i ) ? "1" : "0" ) + s;
    }
    //s += bits.toLongArray()[0] & ( ( 1 << validBits ) - 1 );
    return "0b" + s + " " + String.format("%1$0"+(1+validBits*2/8)+"d", Long.valueOf( s, 2 ) ) + " 0x" + String.format("%1$0"+validBits/4+"X", Long.valueOf( s, 2 ) ) + "";
  }
}



class B8 extends BitN
{
  public B8()
  {
    super( 8 );
  }
  
  
  public void setByte( int b )
  {
    b &= 0xFF;
    for( int i = 0; i < 8; i++ )
    {
      bits.set( i, ( b & ( 1 << i ) ) != 0 );
    }
  }
  
  
  public int getByte()
  {
    int value = 0;
    for ( int i = 0; i < 8; i++ )
      if ( bits.get( i ) )
        value |= ( 1 << i );
    return value;
  }
}



class B16 extends BitN
{  
  public B16()
  {
    super( 16 );
  }
  
  
  public void setDoubleByte( int highByte, int lowByte )
  {
    this.setDoubleByte( ( ( highByte << 8 ) & 0xFF00 ) | ( lowByte & 0x00FF ) );
  }
  
  
  public void setDoubleByte( int db )
  {
    db &= 0xFFFF;
    for( int i = 0; i < 16; i++ )
    {
      bits.set( i, ( db & ( 1 << i ) ) != 0 );
    }
  }
  
  
  public int getDoubleByte()
  {
    int value = 0;
    for ( int i = 0; i < 16; i++ )
      if ( bits.get( i ) )
        value |= ( 1 << i );
    return value;
  }
}



class B16Split extends B16
{
  B8 highByte, lowByte;
  
  
  public B16Split( B8 highByte, B8 lowByte )
  {
    this.highByte = highByte;
    this.lowByte = lowByte;
  }
  
  
  public void set( int index, boolean value ) { assert false : "B16Split does not implement set( idx, val )!"; }
  public boolean get( int index ) { assert false : "B16Split does not implement val get( idx )!"; return false; }
  
  
  public void setDoubleByte( int db )
  {
    highByte.setByte( ( db & 0xFF00 ) >> 8 );
    lowByte.setByte( db & 0x00FF );
  }
  
  
  public int getDoubleByte()
  {
    return ( ( highByte.getByte() << 8 ) | ( lowByte.getByte() ) ) & 0xFFFF;
  }
  
  
  public int getHighByte()
  {
    return highByte.getByte() & 0x00FF;
  }
  
  
  public int getLowByte()
  {
    return lowByte.getByte() & 0x00FF;
  }
  
  
  public void increment()
  {
    if( lowByte.getByte() == 0xFF )
    {
      lowByte.setByte( 0x00 );
      highByte.increment();
    }
    else lowByte.increment();
  }
  
  
  public void decrement()
  {
    if( lowByte.getByte() == 0x00 )
    {
      lowByte.setByte( 0xFF );
      highByte.decrement();
    }
    else lowByte.decrement();
  }
  
  
  @Override
  String toString()
  {
    super.setDoubleByte( ( highByte.getByte() << 8 ) | ( lowByte.getByte() ) );
    return super.toString();
  }
}


class FlagRegister extends B8
{
  public void setByte( int b )
  {
    super.setByte( b & 0b11110000 );  //writes to the lower 4 flag bits have no effect
  }
  
  
  public int getByte()
  {
    return super.getByte() & 0b11110000;  // lower 4 flag bits always read 0
  }
  
  
  public boolean getZ() { return get( 7 ); }
  public boolean getN() { return get( 6 ); }
  public boolean getH() { return get( 5 ); }
  public boolean getC() { return get( 4 ); }
  
  public void setZTo( boolean value ) { set( 7, value ); }
  public void setNTo( boolean value ) { set( 6, value ); }
  public void setHTo( boolean value ) { set( 5, value ); }
  public void setCTo( boolean value ) { set( 4, value ); }
  
  public void setZ() { set( 7, true ); }
  public void setN() { set( 6, true ); }
  public void setH() { set( 5, true ); }
  public void setC() { set( 4, true ); }
  
  public void resetZ() { set( 7, false ); }
  public void resetN() { set( 6, false ); }
  public void resetH() { set( 5, false ); }
  public void resetC() { set( 4, false ); }
}

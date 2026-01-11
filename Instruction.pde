


class Instruction
{
  String mnemonic;
  String descriptionExplizit;
  int length;
  int[] cycles;
  char[] flags;
  String addr;
  String group;
  String
    operand1,
    operand2;
  
  
  void setDescriptionExplizit( String desc ) { this.descriptionExplizit = desc; }
  String getDescriptionExplicit() { return descriptionExplizit; }
  
  
  String completeMnemonic()
  {
    if ( operand1 == null && operand2 == null )
      return mnemonic;
    if ( operand2 == null )
      return mnemonic + " " + operand1;
    return mnemonic + " " + operand1 + ", " + operand2; 
  }
  
  
  @Override
  public String toString()
  {
    assert cycles.length >= 1;
    assert flags.length == 4;
    return "[Instruction] " + String.format( "%-6s", mnemonic ) + " : " +
      length + 
      String.format( "%3s", cycles[0] ) + 
      " {Z:" + flags[0] + "|N:" + flags[1] + "|H:" + flags[2] + "|C:" + flags[3] + "} " +
      String.format( "%-5s", addr ) + 
      String.format( "%-13s", group ) + 
      String.format( "%-5s", operand1 ) +
      String.format( "%-5s", operand2 );
  }
}

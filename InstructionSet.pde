//import com.google.gson.*;



//class InstructionSet
//{
//  private Instruction[][] lut;
  
  
//  //public void setLUT( Instruction[][] instructions )
//  //{
//  //  lut = instructions;
    
//  //  assert lut.length == 2 : "DMG requires two arrays of instructions, 0:no prefix, 1:prefixed by 0xCB";
//  //  assert lut[0].length == 256 : "DMG requires unprefixed array of instructions to have 0xFF entries";
//  //  assert lut[1].length == 256 : "DMG requires prefixed of instructions to have 0xFF entries";
//  //}
  
  
//  public Instruction decode( int instructionCode ) { return this.decode( instructionCode, false ); }
//  public Instruction decode( int instructionCode, boolean prefixed0xCB )
//  {
//    instructionCode &= 0xFF;  // make it a positive value [0,255]
//    assert instructionCode >= 0 && instructionCode < 256 : "[ERROR] --Instruction Set-- does not contain an entry for " + ( prefixed0xCB ? "0xCB + " : "" )
//        + HEX( instructionCode );
    
//    Instruction out = lut[ prefixed0xCB ? 1 : 0 ][ instructionCode ]; //<>//
//    return out;
//  }
  
  
//  public void initialize()
//  {
//    lut = new Instruction[][] { new Instruction[256], new Instruction[256] };
//    loadInstructionSetFromJSONFile( "/assets/instruction set/opcodes.json", lut );
//  }
  
  
//  public void loadInstructionSetFromJSONFile( String file, Instruction[][] instructions )
//  {
//    Gson gson = new GsonBuilder().create();
    
//    JSONObject jsonFile = loadJSONObject( file ); //<>//
//    JSONObject jsonInstruction;
    
//    String[] objs = { "unprefixed", "cbprefixed" };
//    for ( int s = 0; s < 2; s++ )
//    {
//      JSONObject jsonIS = jsonFile.getJSONObject( objs[s] );
//      for ( int i = 0; i < instructions[s].length; i++ )
//      {
//        jsonInstruction = jsonIS.getJSONObject( String.format( "0x%1$02x", i ) );  // note the small "x"
//        if ( jsonInstruction != null )
//        {
//          instructions[s][i] = gson.fromJson( jsonInstruction.toString(), Instruction.class );
//        }
//      }
//    }
//  }
//}

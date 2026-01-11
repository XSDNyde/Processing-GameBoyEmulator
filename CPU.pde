import java.util.Map;



class CPU_DMG
{
  /* High language convenience stuff*/
  private Map<String,Operand> operandMap;
  //private InstructionSet instructionSet;
  private DmgInstructionSet instructionSet;
  private int currentInstructionCode;
  private Instruction currentInstruction;
  private int currentNumReads;
  private int currentNumOperandsBytes;
  private int[] currentOperandsBytes;
  
  private boolean IME = false; // Interrupt Master Enable
  private Registers registers;
  private BusSubscriber romBootstrapMemory;
  private VideoRAM videoRAM;
  private IORegisters ioRegisters;
  private OAM oam;
  
  private Bus_LR35902 bus;
  
  
  public CPU_DMG( Bus_LR35902 bus, VideoRAM videoRAM, OAM oam, IORegisters ioRegisters )
  {
    this.bus = bus;
    this.registers = new Registers();
    this.romBootstrapMemory = new ROM_DMGBootstrapMemory();
    this.videoRAM = videoRAM;
    this.oam = oam;
    this.ioRegisters = ioRegisters;
    this.ioRegisters.registerCPU( this );
    
    initialize();
  }


  // startup routine
  private void initialize()
  {
    operandMap = new java.util.HashMap<>();
    //operandMap.put( "null", null );
    operandMap.put( "A",     new Operand().setOperand( registers.A ) );
    operandMap.put( "B",     new Operand().setOperand( registers.B ) );
    operandMap.put( "C",     new Operand().setOperand( registers.C ) );
    operandMap.put( "(C)",   new Operand().setOperand( registers.C, true ) );
    operandMap.put( "D",     new Operand().setOperand( registers.D ) );
    operandMap.put( "E",     new Operand().setOperand( registers.E ) );
    operandMap.put( "H",     new Operand().setOperand( registers.H ) );
    operandMap.put( "L",     new Operand().setOperand( registers.L ) );
    operandMap.put( "AF",    new Operand().setOperand( registers.AF ) );
    operandMap.put( "BC",    new Operand().setOperand( registers.BC ) );
    operandMap.put( "DE",    new Operand().setOperand( registers.DE ) );
    operandMap.put( "HL",    new Operand().setOperand( registers.HL ) );
    operandMap.put( "SP",    new Operand().setOperand( registers.SP ) );
    operandMap.put( "PC",    new Operand().setOperand( registers.PC ) );
    operandMap.put( "(BC)",  new Operand().setOperand( registers.BC, true ) );
    operandMap.put( "(DE)",  new Operand().setOperand( registers.DE, true ) );
    operandMap.put( "(HL)",  new Operand().setOperand( registers.HL, true ) );
    operandMap.put( "(HL+)", new Operand().setOperand( registers.HL, true, +1 ) );
    operandMap.put( "(HL-)", new Operand().setOperand( registers.HL, true, -1 ) );
    // RST targets
    operandMap.put( "00H",   new Operand().setOperandValueB16( 0x0000 ) );
    operandMap.put( "08H",   new Operand().setOperandValueB16( 0x0008 ) );
    operandMap.put( "10H",   new Operand().setOperandValueB16( 0x0010 ) );
    operandMap.put( "18H",   new Operand().setOperandValueB16( 0x0018 ) );
    operandMap.put( "20H",   new Operand().setOperandValueB16( 0x0020 ) );
    operandMap.put( "28H",   new Operand().setOperandValueB16( 0x0028 ) );
    operandMap.put( "30H",   new Operand().setOperandValueB16( 0x0030 ) );
    operandMap.put( "38H",   new Operand().setOperandValueB16( 0x0038 ) );
    
    //instructionSet = new InstructionSet();
    //instructionSet.initialize();
    instructionSet = new DmgInstructionSet();
    
    bus.attach( 0x0000, romBootstrapMemory );
    bus.attach( 0x8000, videoRAM );
    //bus.attach( 0xA000, 0x2000, cartridgeRAM ); // will be set by plugin in cartridge
    bus.attach( 0xA000, new DebugSubscriber( 0x2000 ) );
    WorkRAM w;
    bus.attach( 0xC000, w = new WorkRAM() );
    bus.attach( 0xE000, new MirrorRAM( w ) );
    bus.attach( 0xFE00, oam );
    bus.attach( 0xFEA0, new OAMUnused() );
    bus.attach( 0xFF00, ioRegisters );
    bus.attach( 0xFF80, new HighRAM() );
    bus.attach( 0xFFFF, new IERegister() );
  }
  
  
  // does MHZ many steps per second
  public void step()
  {
    //if( registers.PC.getDoubleByte() == 0x00E6 )
    //  DEBUG_OUTPUT = true;
      
    if( DEBUG_OUTPUT ) println( "\n[DEBUG] [CPU] begins new step!" );
    
    currentNumReads = 0;
    
    if( DEBUG_OUTPUT ) println( "[DEBUG] [PC] is at " + HEX2( registers.PC.getDoubleByte() ) );
    
    //if( registers.PC.getDoubleByte() == 0x0100 ) exit();
    
    fetchNextInstructionCodeByte();
    if( DEBUG_OUTPUT ) println( "[DEBUG] Instruction Code " + HEX( currentInstructionCode ) + " has been loaded into the CPU!" );
    
    //currentInstruction = instructionSet.decode( currentInstructionCode );
    currentInstruction = instructionSet.decode( currentInstructionCode );
    if( DEBUG_OUTPUT ) println( "[DEBUG] " + currentInstruction );
    
    if( currentInstruction.mnemonic.equalsIgnoreCase( "PREFIX" ) )
    {
      if( DEBUG_OUTPUT ) println( "[DEBUG] PREFIX Signaled! Reading another byte from program!" );
      fetchNextInstructionCodeByte();
      if( DEBUG_OUTPUT ) println( "[DEBUG] Instruction Code " + HEX( currentInstructionCode ) + " has been loaded into the CPU!" );
      
      currentInstruction = instructionSet.decode( currentInstructionCode, true );
      if( DEBUG_OUTPUT ) println( "[DEBUG] " + currentInstruction );
    }
    
    // find out how many bytes have operand data
    currentNumOperandsBytes = currentInstruction.length - currentNumReads;
    if( DEBUG_OUTPUT ) println( "[DEBUG] Instruction carries " + currentNumOperandsBytes + " operand bytes" );
    
    // load the operands' data bytes
    switch ( currentNumOperandsBytes )
    {
      case 2 :
        currentOperandsBytes = new int[] { readNextProgramByte(), readNextProgramByte() };
        break;
      case 1 :
        currentOperandsBytes = new int[] { readNextProgramByte() };
        break;
      case 0 :
      default :
        currentOperandsBytes = new int[] {};
        break;
    }
    if( DEBUG_OUTPUT && currentOperandsBytes.length > 0 )
    {
      println( "[DEBUG] Operand bytes are:" );
      for( var b : currentOperandsBytes )
        println( "[DEBUG] \t"+HEX( b ) );
    }
    
    //// turn operands bytes into values
    //int targetBusAddress;
    //int sourceBusAddress;
    //int jumpTarget;
    //int relativeJump;
    //int immediateData;
    //int offsetSP;
    
    //if ( currentInstruction.operand2.equalsIgnoreCase( "a16" ) )
    //  jumpTarget = ( currentOperandsBytes[ 1 ] << 8 ) | ( currentOperandsBytes[ 0 ] & 0xFF );
    
    //if ( currentInstruction.operand1.equalsIgnoreCase( "(a8)" ) )
    //  targetBusAddress = 0xFF00 | ( currentOperandsBytes[ 0 ] & 0xFF );
    //if ( currentInstruction.operand2.equalsIgnoreCase( "(a8)" ) )
    //  sourceBusAddress = 0xFF00 | ( currentOperandsBytes[ 0 ] & 0xFF );
      
    //if ( currentInstruction.operand1.equalsIgnoreCase( "(a16)" ) )
    //  targetBusAddress = ( currentOperandsBytes[ 1 ] << 8 ) | ( currentOperandsBytes[ 0 ] & 0xFF );
    //if ( currentInstruction.operand2.equalsIgnoreCase( "(a16)" ) )
    //  sourceBusAddress = ( currentOperandsBytes[ 1 ] << 8 ) | ( currentOperandsBytes[ 0 ] & 0xFF );
      
    //if ( currentInstruction.operand2.equalsIgnoreCase( "d8" ) )
    //  immediateData = currentOperandsBytes[ 0 ] & 0xFF;
    //if ( currentInstruction.operand2.equalsIgnoreCase( "d16" ) )
    //  immediateData = ( ( currentOperandsBytes[ 1 ] << 8 ) | ( currentOperandsBytes[ 0 ] ) ) & 0xFFFF;
      
    //if ( currentInstruction.operand2.equalsIgnoreCase( "r8" ) )
    //  relativeJump = currentOperandsBytes[ 0 ];  // keep twos complement value. This value can be negative [-128,127]
      
    //if ( currentInstruction.operand2.equalsIgnoreCase( "SP+r8" ) )
    //  offsetSP = currentOperandsBytes[ 0 ]; // TODO: not sure what this does. increase SP? offset SP?
    
    Operand operand1 = new Operand();
    Operand operand2 = new Operand();
    
    if ( currentInstruction.operand1 != null )
      switch ( currentInstruction.operand1.toLowerCase() )
      {
        case "(a8)" :
          operand1.setOperandValueB16( 0xFF00 | currentOperandsBytes[0], true );
          break;
        case "a16" :
          operand1.setOperandValueB16( ( (currentOperandsBytes[1] & 0xFF ) << 8 ) | ( currentOperandsBytes[0] & 0xFF ) );
          break;
        case "(a16)" :
          operand1.setOperandValueB16( ( (currentOperandsBytes[1] & 0xFF ) << 8 ) | ( currentOperandsBytes[0] & 0xFF ), true );
          break;
        case "d8" : 
          operand1.setOperandValueB8( currentOperandsBytes[0] & 0xFF );
          break;
        case "d16" :
          operand1.setOperandValueB16( ( (currentOperandsBytes[1] & 0xFF ) << 8 ) | ( currentOperandsBytes[0] & 0xFF ) );
          break;
        case "r8" :
          operand1.setOperandValueB8( currentOperandsBytes[0] );
          break;
          
        default :
          operand1 = operandMap.get( currentInstruction.operand1 );
          break;
      }
    
    if ( currentInstruction.operand2 != null )
      switch ( currentInstruction.operand2.toLowerCase() )
      {
        case "(a8)" :
          operand2.setOperandValueB16( 0xFF00 | currentOperandsBytes[0], true );
          break;
        case "a16" :
          operand2.setOperandValueB16( ( (currentOperandsBytes[1] & 0xFF ) << 8 ) | ( currentOperandsBytes[0] & 0xFF ) );
          break;
        case "(a16)" :
          operand2.setOperandValueB16( ( (currentOperandsBytes[1] & 0xFF ) << 8 ) | ( currentOperandsBytes[0] & 0xFF ), true );
          break;
        case "d8" : 
          operand2.setOperandValueB8( currentOperandsBytes[0] & 0xFF );
          break;
        case "d16" :
          operand2.setOperandValueB16( ( (currentOperandsBytes[1] & 0xFF ) << 8 ) | ( currentOperandsBytes[0] & 0xFF ) );
          break;
        case "r8" :
          operand2.setOperandValueB8( currentOperandsBytes[0] );
          break;
          
        default :
          operand2 = operandMap.get( currentInstruction.operand2 );
          break;
      }
    
    // now select what to do
    // first approach, switch case
    int lowByte;
    int highByte;
    boolean doJump;
    //print( currentInstruction.mnemonic + " " );
    switch ( currentInstruction.mnemonic.toUpperCase() )
    {
      case "ADC" :
        // A <-- A + OP1 + Cy
        lowByte = registers.A.getByte( ) + operand1.getByte() + ( getCarryFlag() ? 1 : 0 );
        registers.A.setByte( lowByte & 0xFF );
        setZeroFlagTo( ( lowByte & 0xFF ) == 0x00 );
        resetSubtractionFlag();
        // TODO: setHalfCarryFlagTo( ??? );
        setCarryFlagTo( ( lowByte & 0b1_0000_0000 ) != 0 );
        break;
      case "ADD" :
        // A <-- A + OP1
        if( currentInstruction.operand1.equalsIgnoreCase( "HL" ) )
        {
          int v = registers.HL.getDoubleByte( ) + operand1.getDoubleByte();
          setCarryFlagTo( ( v & 0x1_0000 ) != 0 );
          v &= 0xFFFF;
          registers.HL.setDoubleByte( v );
          setZeroFlagTo( v == 0x0000 );
          resetSubtractionFlag();
          // TODO: setHalfCarryFlagTo( ??? );
        }
        else if( currentInstruction.operand1.equalsIgnoreCase( "SP" ) )
          assert false : "ADD SP,r8";
        else // OP1 == A
        {
          lowByte = registers.A.getByte( ) + operand1.getByte();
          registers.A.setByte( lowByte & 0xFF );
          setZeroFlagTo( ( lowByte & 0xFF ) == 0x00 );
          resetSubtractionFlag();
          // TODO: setHalfCarryFlagTo( ??? );
          setCarryFlagTo( ( lowByte & 0b1_0000_0000 ) != 0 );
        }
        break;
      case "AND" :
        // A <-- A & OP1
        registers.A.setByte( registers.A.getByte( ) & operand1.getByte() );
        setZeroFlagTo( operand1.getByte() == 0x00 );
        resetSubtractionFlag();
        setHalfCarryFlag();
        resetCarryFlag();
        break;
      case "BIT" :
        setZeroFlagTo( ( ( 1 << Integer.parseInt( currentInstruction.operand1 ) ) & operand2.getByte() ) == 0 );
        resetSubtractionFlag();
        setHalfCarryFlag();
        if( DEBUG_OUTPUT ) println( "[DEBUG] [OP] [BIT] Zeroflag " + ( ( ( 1 << Integer.parseInt( currentInstruction.operand1 ) ) & operand2.getByte() ) == 0 ? "SET" : "NOT SET" ) );
        break;
      case "CALL" :
        // (--SP) <-- PC high Byte
        registers.SP.decrement();
        bus.write( registers.SP.getDoubleByte(), ( registers.PC.getDoubleByte() >> 8 ) & 0x00FF );
        // (--SP) <-- PC low Byte
        registers.SP.decrement();
        bus.write( registers.SP.getDoubleByte(), registers.PC.getDoubleByte() & 0x00FF );
        // PC <-- OP2 << 8 | OP1 
        registers.PC.setDoubleByte( currentOperandsBytes[ 1 ], currentOperandsBytes[ 0 ] );
        // = registers.PC.setDoubleByte( operand1.getDoubleByte() );
        break;
      case "CP" :
        lowByte = registers.A.getByte() - operand1.getByte();
        setZeroFlagTo( ( lowByte & 0xFF ) == 0 );
        setSubtractionFlag();
        // TODO: setHalfCarryFlagTo( ??? )
        setCarryFlagTo( ( lowByte & 0b1_0000_0000 ) != 0 );
        break;
      case "DEC" :
        operand1.setValue( operand1.getValue() - 1 );
        if( operand1.type == OperandType.REGISTER_B8 )
        {
          setZeroFlagTo( operand1.getByte() == 0x00 );
          setSubtractionFlag();
          // TODO: setHalfCarryFlagTo( ??? );
        }
        break;
      case "DI" :
        IME = false;
        if( DEBUG_OUTPUT ) println( "[DEBUG] [IME] " + ( IME ? "ENABLED" : "DISABLED" ) );
        break;
      case "EI" :
        IME = true;
        if( DEBUG_OUTPUT ) println( "[DEBUG] [IME] " + ( IME ? "ENABLED" : "DISABLED" ) );
        break;
      case "NOP" :
        // let's not do anything
        break;
      case "INC" :
        operand1.setValue( operand1.getValue() + 1 );
        if( operand1.type == OperandType.REGISTER_B8 )
        {
          setZeroFlagTo( operand1.getByte() == 0x00 );
          resetSubtractionFlag();
          // TODO: setHalfCarryFlagTo( ??? );
        }
        break;
      case "JP" :
        doJump = true;
        switch ( currentInstruction.operand1.toUpperCase() )
        {
          case "C" :
            doJump =   getCarryFlag();
            break;
          case "NC" :
            doJump = ! getCarryFlag();
            break;
          case "Z" :
            doJump =   getZeroFlag();
            break;
          case "NZ" :
            doJump = ! getZeroFlag();
            break;
        }
        if( doJump )
        {
          registers.PC.setDoubleByte(  ( operand2 == null ) || ( operand2.type == OperandType.NONE ) ? operand1.getDoubleByte() : operand2.getDoubleByte() );
          if( DEBUG_OUTPUT ) println( "[DEBUG] JP JUMP TAKEN!" );
        }
        else
          if( DEBUG_OUTPUT ) println( "[DEBUG] JP jump NOT taken!" );
        if( DEBUG_OUTPUT ) println( "[DEBUG] [PC] is now " + HEX2( registers.PC.getDoubleByte() ) );
        break;
      case "JR" :
        doJump = true;
        switch ( currentInstruction.operand1.toUpperCase() )
        {
          case "C" :
            doJump =   getCarryFlag();
            break;
          case "NC" :
            doJump = ! getCarryFlag();
            break;
          case "Z" :
            doJump =   getZeroFlag();
            break;
          case "NZ" :
            doJump = ! getZeroFlag();
            break;
        }
        if( doJump )
          registers.PC.setDoubleByte( registers.PC.getDoubleByte() + (byte) ( ( operand2 == null ) || ( operand2.type == OperandType.NONE ) ? operand1.getByte() : operand2.getByte() ) );
        if( DEBUG_OUTPUT ) println( "[DEBUG] Conditional Jump " + ( doJump ? "" : "NOT" ) + " TAKEN!" );
        if( DEBUG_OUTPUT ) println( "[DEBUG] [PC] is now " + HEX2( registers.PC.getDoubleByte() ) );
        break;
      case "LDH" :
        operand1.setValue( operand2.getValue() );
        break;
      case "LD" :
        operand1.setValue( operand2.getValue() );
        break;
      case "OR" :
        // A <-- A | OP1
        registers.A.setByte( registers.A.getByte() | operand1.getByte() );
        setZeroFlagTo( operand1.getByte() == 0x00 );
        resetSubtractionFlag();
        resetHalfCarryFlag();
        resetCarryFlag();
        break;
      case "POP" :
        lowByte = bus.read( registers.SP.getDoubleByte() );
        registers.SP.increment();
        highByte = bus.read( registers.SP.getDoubleByte() );
        registers.SP.increment();
        operand1.setDoubleByte( ( highByte << 8 ) | lowByte );
        break;
      case "PUSH" :
        // (--SP) <-- OP2
        registers.SP.decrement();
        bus.write( registers.SP.getDoubleByte(), operand1.getHighByte() );
        // (--SP) <-- OP1
        registers.SP.decrement();
        bus.write( registers.SP.getDoubleByte(), operand1.getLowByte() );
        break;
      case "RET" :
        lowByte = bus.read( registers.SP.getDoubleByte() );
        registers.SP.increment();
        highByte = bus.read( registers.SP.getDoubleByte() );
        registers.SP.increment();
        registers.PC.setDoubleByte( ( highByte << 8 ) | lowByte );
        break;
      case "RLA" :
        // rotate left; bit 0 <-- Carry; Carry <-- bit 8;
        operandMap.get( "A" ).rotateLeft( false );
        resetZeroFlag();
        resetSubtractionFlag();
        resetHalfCarryFlag();
        break;
      case "RLCA" :
        // rotate left; bit 0 <-- bit 8;
        operandMap.get( "A" ).rotateLeft( true );
        resetZeroFlag();
        resetSubtractionFlag();
        resetHalfCarryFlag();
        break;
      case "RLC" :
        // rotate left; bit 0 <-- bit 8;
        operand1.rotateLeft( true );
        setZeroFlagTo( operand1.getByte() == 0x00 );
        resetSubtractionFlag();
        resetHalfCarryFlag();
        break;
      case "RL" :
        // rotate left; bit 0 <-- Carry; Carry <-- bit 8;
        operand1.rotateLeft( false );
        setZeroFlagTo( operand1.getByte() == 0x00 );
        resetSubtractionFlag();
        resetHalfCarryFlag();
        break;
      case "RRA" :
        int fill = getCarryFlag() ? 0b1000_0000 : 0b0000_0000;
        int out = registers.A.getByte();
        setCarryFlagTo( ( out & 0b0000_0001 ) != 0 );
        out = ( ( ( out & 0xFF ) >> 1 ) & 0b0111_1111 ) | fill;
        registers.A.setByte( out );
        resetZeroFlag();
        resetSubtractionFlag();
        resetHalfCarryFlag();
        break;
      case "RR" :
        // rotate left; bit 0 <-- Carry; Carry <-- bit 8;
        operand1.rotateRight( false );
        setZeroFlagTo( operand1.getByte() == 0x00 );
        resetSubtractionFlag();
        resetHalfCarryFlag();
        break;
      case "RST" :
        // (--SP) <-- PC high Byte
        registers.SP.decrement();
        bus.write( registers.SP.getDoubleByte(), ( registers.PC.getDoubleByte() >> 8 ) & 0x00FF );
        // (--SP) <-- PC low Byte
        registers.SP.decrement();
        bus.write( registers.SP.getDoubleByte(), registers.PC.getDoubleByte() & 0x00FF );
        // PC <-- Jump targets are 0x0000, 0x0008, 0x0010, 0x0018, 0x0020, 0x0028, 0x0030 and 0x0038
        registers.PC.setDoubleByte( operand1.getDoubleByte() );
        break;
      case "SRL" :
        operand1.shiftRightArithmetic();
        setZeroFlagTo( operand1.getByte() == 0x00 );
        resetSubtractionFlag();
        resetHalfCarryFlag();
        break;
      case "SUB" :
        // A <-- A - OP1
        lowByte = registers.A.getByte( ) - operand1.getByte();
        registers.A.setByte( lowByte & 0xFF );
        setZeroFlagTo( ( lowByte & 0xFF ) == 0x00 );
        setSubtractionFlag();
        // TODO: setHalfCarryFlagTo( ??? );
        setCarryFlagTo( ( lowByte & 0b1_0000_0000 ) != 0 );
        break;
      case "XOR" :
        // A <-- A ^ OP1
        registers.A.setByte( registers.A.getByte( ) ^ operand1.getByte() );
        setZeroFlagTo( operand1.getByte() == 0x00 );
        resetSubtractionFlag();
        resetHalfCarryFlag();
        resetCarryFlag();
        break;
        
      default :
        assert false : "[ERROR] Unkown Command: " + currentInstruction.mnemonic.toUpperCase();
    }
    
    if( DEBUG_OUTPUT ) println( registers );
    //println( summary );
  }
  
  
  // side effect: increases PC by 1
  private void fetchNextInstructionCodeByte()
  {
    currentInstructionCode = readNextProgramByte();
  }
  
  
  private int readNextProgramByte()
  {
    int b = bus.read( registers.PC.getDoubleByte() );
    registers.PC.increment();
    if( DEBUG_OUTPUT ) println( "[DEBUG] [PC] is now " + HEX2( registers.PC.getDoubleByte() ) );
    currentNumReads++;
    
    return b;
  }
  
  
  public void reset()
  {
    registers.reset();
        
    // DEBUG PURPOSE:
    bus.write( 0xFF44, 0x90 ); //LCD Y coordinate can only be written from PPU!
  }
  
  
  public void resetPostBootROM()
  {
    registers.resetPostBootROM();
        
    // DEBUG PURPOSE:
    //bus.write( 0xFF44, 0x90 ); //LCD Y coordinate can only be written from PPU!
    
    bus.write( 0xFF05, 0x00 ); //TIMA
    bus.write( 0xFF06, 0x00 ); //TMA
    bus.write( 0xFF07, 0x00 ); //TAC
    bus.write( 0xFF10, 0x80 ); //NR10
    bus.write( 0xFF11, 0xBF ); //NR11
    bus.write( 0xFF12, 0xF3 ); //NR12
    bus.write( 0xFF14, 0xBF ); //NR14
    bus.write( 0xFF16, 0x3F ); //NR21
    bus.write( 0xFF17, 0x00 ); //NR22
    bus.write( 0xFF19, 0xBF ); //NR24
    bus.write( 0xFF1A, 0x7F ); //NR30
    bus.write( 0xFF1B, 0xFF ); //NR31
    bus.write( 0xFF1C, 0x9F ); //NR32
    bus.write( 0xFF1E, 0xBF ); //NR33
    bus.write( 0xFF20, 0xFF ); //NR41
    bus.write( 0xFF21, 0x00 ); //NR42
    bus.write( 0xFF22, 0x00 ); //NR43
    bus.write( 0xFF23, 0xBF ); //NR30
    bus.write( 0xFF24, 0x77 ); //NR50
    bus.write( 0xFF25, 0xF3 ); //NR51
    bus.write( 0xFF26, 0xF1 ); //NR52 on GB
    //bus.write( 0xFF26, 0xF0 ); //NR52 on SGB
    bus.write( 0xFF40, 0x91 ); //LCDC
    bus.write( 0xFF42, 0x00 ); //SCY
    bus.write( 0xFF43, 0x00 ); //SCX
    bus.write( 0xFF45, 0x00 ); //LYC
    bus.write( 0xFF47, 0xFC ); //BGP
    bus.write( 0xFF48, 0xFF ); //OBP0
    bus.write( 0xFF49, 0xFF ); //OBP1
    bus.write( 0xFF4A, 0x00 ); //WY
    bus.write( 0xFF4B, 0x00 ); //WX
    bus.write( 0xFFFF, 0x00 ); //IE
  }
  
  
  @Override
  public String toString()
  {
    return
    "---{ Central Processing Unit }---\n" +
    registers +
    bus;
  }
  
  
  private class Registers
  {
    FlagRegister 
      F;
    B8
      A,   //Accumulator
      B, C,
      D, E,
      H, L;
    B16
      SP,      //Stack Pointer
      PC,      //Program Counter
      AF,      // View of A (high Byte) and F (low Byte)
      BC,      // View of B (high Byte) and C (low Byte)
      DE,      // View of D (high Byte) and E (low Byte)
      HL;      // View of H (high Byte) and L (low Byte)
      
  
    Registers()
    {
      this.A = new B8();
      this.F = new FlagRegister();
      this.B = new B8();
      this.C = new B8();
      this.D = new B8();
      this.E = new B8();
      this.H = new B8();
      this.L = new B8();
      this.SP = new B16();
      this.PC = new B16();
      this.AF = new B16Split( this.A, this.F );
      this.BC = new B16Split( this.B, this.C );
      this.DE = new B16Split( this.D, this.E );
      this.HL = new B16Split( this.H, this.L );
    }
    
    
    public void reset()
    {
      this.A.setByte( 0x00 );
      this.F.setByte( 0x00 );
      this.B.setByte( 0x00 );
      this.C.setByte( 0x00 );
      this.D.setByte( 0x00 );
      this.E.setByte( 0x00 );
      this.H.setByte( 0x00 );
      this.L.setByte( 0x00 );
      this.SP.setDoubleByte( 0x0000 );
      this.PC.setDoubleByte( 0x0000 );
    }
    
    
    public void resetPostBootROM()
    {
      this.A.setByte( 0x01 );
      this.F.setByte( 0xB0 );
      this.B.setByte( 0x00 );
      this.C.setByte( 0x13 );
      this.D.setByte( 0x00 );
      this.E.setByte( 0xD8 );
      this.H.setByte( 0x01 );
      this.L.setByte( 0x4D );
      this.SP.setDoubleByte( 0xFFFE );
      this.PC.setDoubleByte( 0x0100 );
    }
    
    
    @Override
    String toString()
    {
      return
      "--{ Registers }--\n" +
      "A: " + A + "\tF: " + F + "\tAF:" + AF + "\n" +
      "B: " + B + "\tC: " + C + "\tBC:" + BC + "\n" +
      "D: " + D + "\tE: " + E + "\tDE:" + DE + "\n" +
      "H: " + H + "\tL: " + L + "\tHL:" + HL + "\n" +
      "SP Stack Pointer:\t" + SP + "\n" +
      "PC Program Counter:\t" + PC + "\n" +
      "Flags:\tZ:" + ( getZeroFlag() ? "1" : "0" ) + "\tN:" + ( getSubtractionFlag() ? "1" : "0" ) + "\tH:" + ( getHalfCarryFlag() ? "1" : "0" ) + "\tC:" + ( getCarryFlag() ? "1" : "0" ) + "\n" +
      "-----------------\n";
    }
  }
  
  
  // comfort FLAG access for the CPU
  public boolean getZeroFlag       () { return registers.F.getZ(); }
  public boolean getSubtractionFlag() { return registers.F.getN(); }
  public boolean getHalfCarryFlag  () { return registers.F.getH(); }
  public boolean getCarryFlag      () { return registers.F.getC(); }
  
  public void setZeroFlagTo       ( boolean value ) { registers.F.set( 7, value ); }
  public void setSubtractionFlagTo( boolean value ) { registers.F.set( 6, value ); }
  public void setHalfCarryFlagTo  ( boolean value ) { registers.F.set( 5, value ); }
  public void setCarryFlagTo      ( boolean value ) { registers.F.set( 4, value ); }
  
  public void setZeroFlag       () { registers.F.set( 7, true ); }
  public void setSubtractionFlag() { registers.F.set( 6, true ); }
  public void setHalfCarryFlag  () { registers.F.set( 5, true ); }
  public void setCarryFlag      () { registers.F.set( 4, true ); }
  
  public void resetZeroFlag       () { registers.F.set( 7, false ); }
  public void resetSubtractionFlag() { registers.F.set( 6, false ); }
  public void resetHalfCarryFlag  () { registers.F.set( 5, false ); }
  public void resetCarryFlag      () { registers.F.set( 4, false ); }
  
  
  
  public class Operand
  {
    OperandType type;
    boolean isBusAddress = false;
    int postAdd = 0;
    
    B8 registerB8;
    B16 registerB16;
    int value;
    boolean flag;
    
    
    public Operand() { this.type = OperandType.NONE; }
    
    
    public Operand setOperand( B8 registerB8 ) { return setOperand( registerB8, false ); }
    public Operand setOperand( B8 registerB8, boolean isBusAddress )
    {
      this.type = OperandType.REGISTER_B8;
      this.isBusAddress = isBusAddress;
      this.registerB8 = registerB8;
      return this;
    }
    
    
    public Operand setOperand( B16 registerB16 ) { return setOperand( registerB16, false, 0 ); }
    public Operand setOperand( B16 registerB16, boolean isBusAddress ) { return setOperand( registerB16, isBusAddress, 0 ); }
    public Operand setOperand( B16 registerB16, boolean isBusAddress, int postAdd )
    {
      this.type = OperandType.REGISTER_B16;
      this.isBusAddress = isBusAddress;
      this.postAdd = postAdd;
      this.registerB16 = registerB16;
      return this;
    }
    
    
    public Operand setOperandValueB8( int value )
    {
      this.type = OperandType.VALUE_B8;
      this.value = value & 0xFF;
      return this;
    }
    
    
    public Operand setOperandValueB16( int value ) { return setOperandValueB16( value, false ); }
    public Operand setOperandValueB16( int value, boolean isBusAddress )
    {
      this.type = OperandType.VALUE_B16;
      this.isBusAddress = isBusAddress;
      this.value = value & 0xFFFF;
      return this;
    }
    
    
    public Operand setOperand( boolean flag )
    {
      this.type = OperandType.FLAG;
      this.flag = flag;
      return this;
    }
    
    
    public int getValue()
    {
      int out;
      switch ( type )
      {
        case REGISTER_B8 :
          out = registerB8.getByte();
          if( isBusAddress )
            out = bus.read( 0xFF00 | out );
          return out;
        case REGISTER_B16 :
          out = registerB16.getDoubleByte();
          if( isBusAddress )
            out = bus.read( out );
          if( postAdd == 1 )
            registerB16.increment();
          else if( postAdd == -1 )
            registerB16.decrement();
          return out;
        case VALUE_B8 :
          return value;
        case VALUE_B16 :
          if( isBusAddress )
            return bus.read( value );
          else
            return value;
        case FLAG :
          assert false : "getByte() from Flag is illegel!";
        default :
          return 0x00;
      }
    }
    
    
    public void setValue( int value )
    {
      switch ( type )
      {
        case REGISTER_B8 :
          if( isBusAddress )
            bus.write( 0xFF00 | registerB8.getByte(), value );
          else
            registerB8.setByte( value );
          return;
        case REGISTER_B16 :
          if( isBusAddress )
            bus.write( registerB16.getDoubleByte(), value );
          else
            registerB16.setDoubleByte( value );
          if( postAdd == 1 )
            registerB16.increment();
          else if( postAdd == -1 )
            registerB16.decrement();
          break;
        case VALUE_B8 :
          if( isBusAddress )
            bus.write( ( 0xFF00 | this.value ), value );
          else
            assert false : "Trying to write Byte on a direct value!";
        case VALUE_B16 :
          if( isBusAddress )
            bus.write( this.value, value );
          else
            assert false : "Trying to write on a direct value!";
          break;
        case FLAG :
          assert false : "setDoubleByte() to Flag is illegel!";
        default :
          break;
      }
    }
    
    
    public int getByte()
    {
      switch ( type )
      {
        case REGISTER_B8 :
          int out = registerB8.getByte();
          if( isBusAddress )
            out = bus.read( 0xFF00 | out );
          return out;
        case REGISTER_B16 :
          assert isBusAddress : "getByte() from 2 Byte Register is illegal!";
          out = registerB16.getDoubleByte();
          if( isBusAddress )
            out = bus.read( out );
          if( postAdd == 1 )
            registerB16.increment();
          else if( postAdd == -1 )
            registerB16.decrement();
          return out;
        case VALUE_B8 :
          return value & 0xFF;
        case VALUE_B16 :
          assert false : "getByte() from 2 Byte Immediate Value is illegal!";
        case FLAG :
          assert false : "getByte() from Flag is illegel!";
        default :
          return 0x00;
      }
    }
    
    
    public void setByte( int value )
    {
      switch ( type )
      {
        case REGISTER_B8 :
          if( isBusAddress )
            bus.write( 0xFF00 | registerB8.getByte(), value );
          else
            registerB8.setByte( value );
          return;
        case REGISTER_B16 :
          if( isBusAddress )
            bus.write( registerB16.getDoubleByte(), value );
          else
            assert false : "setByte() to 2 Byte Register is illegal!";
        case VALUE_B8 :
          if( isBusAddress )
            bus.write( ( 0xFF00 | this.value ), value );
          else
            assert false : "Trying to write Byte on a direct value!";
        case VALUE_B16 :
          if( isBusAddress )
            bus.write( this.value, value );
          else
            assert false : "Trying to write DoubleByte on a direct value!";
        case FLAG :
          assert false : "setByte() to Flag is illegel!";
        default :
          return;
      }
    }
    
    
    public int getDoubleByte()
    {
      switch ( type )
      {
        case REGISTER_B8 :
          assert false : "getDoubleByte() from 1 Byte Register is illegal!";
        case REGISTER_B16 :
          int out = registerB16.getDoubleByte();
          if( isBusAddress )
            out = bus.read( out );
          if( postAdd == 1 )
            registerB16.increment();
          else if( postAdd == -1 )
            registerB16.decrement();
          return out;
        case VALUE_B8 :
          assert false : "getByte() from 1 Byte Value is illegal!";
        case VALUE_B16 :
          return value;
        case FLAG :
          assert false : "getByte() from Flag is illegel!";
        default :
          return 0x0000;
      }
    }
    
    
    public void setDoubleByte( int value )
    {
      switch ( type )
      {
        case REGISTER_B8 :
          assert false : "setDoubleByte() to 1 Byte Register is illegal!";
        case REGISTER_B16 :
          if( isBusAddress )
            assert false : "Cannot write DoubleByte to bus!";
            //bus.write( registerB16.getDoubleByte(), value );
          else
            registerB16.setDoubleByte( value );
          if( postAdd == 1 )
            registerB16.increment();
          else if( postAdd == -1 )
            registerB16.decrement();
          break;
        case VALUE_B8 :
          assert false : "setDoubleByte() to 1 Byte Value is illegal!";
        case VALUE_B16 :
          if( isBusAddress )
            assert false : "setDoubleByte() to bus address is illegal!";
          else
            assert false : "Trying to write on a direct value!";
          break;
        case FLAG :
          assert false : "setDoubleByte() to Flag is illegel!";
        default :
          break;
      }
    }
    
    
    public int getHighByte()
    {
      switch ( type )
      {
        case REGISTER_B8 :
          assert false : "getHighByte() from 1 Byte Register is illegal!";
        case REGISTER_B16 :
          int out = ( registerB16.getDoubleByte() & 0xFF00 ) >> 8;
          if( isBusAddress )
            assert false : "getHighByte() from Bus Address is illegal!";
          if( postAdd == 1 )
            registerB16.increment();
          else if( postAdd == -1 )
            registerB16.decrement();
          return out;
        case VALUE_B8 :
          assert false : "getHighByte() from 1 Byte Value is illegal!";
        case VALUE_B16 :
          return ( value >> 8 ) & 0x00FF;
        case FLAG :
          assert false : "getHighByte() from Flag is illegel!";
        default :
          return 0x0000;
      }
    }
    
    
    public int getLowByte()
    {
      switch ( type )
      {
        case REGISTER_B8 :
          assert false : "getHighByte() from 1 Byte Register is illegal!";
        case REGISTER_B16 :
          int out = registerB16.getDoubleByte() & 0x00FF;
          if( isBusAddress )
            assert false : "getHighByte() from Bus Address is illegal!";
          if( postAdd == 1 )
            registerB16.increment();
          else if( postAdd == -1 )
            registerB16.decrement();
          return out;
        case VALUE_B8 :
          assert false : "getHighByte() from 1 Byte Value is illegal!";
        case VALUE_B16 :
          return value & 0x00FF;
        case FLAG :
          assert false : "getHighByte() from Flag is illegel!";
        default :
          return 0x0000;
      }
    }
    
    
    public void rotateLeft( boolean circular )
    {
      int out;
      int fill = getCarryFlag() ? 0b1 : 0b0;
      switch ( type )
      {
        case REGISTER_B8 :
          out = registerB8.getByte();
          setCarryFlagTo( ( out & 0b1000_0000 ) != 0 );
          if( circular )
            fill = ( out >> 7 ) & 0b0000_0001;
          out = ( ( ( out & 0xFF ) << 1 ) & 0b1_1111_1110 ) | fill;
          registerB8.setByte( out );
          return;
        case REGISTER_B16 :
          if( ! isBusAddress )
            assert false : "rotateLeft() from 2 Byte Register is illegal!";
          int address = registerB16.getDoubleByte();
          out = bus.read( address );
          setCarryFlagTo( ( out & 0b1000_0000 ) != 0 );
          if( circular )
            fill = ( out >> 7 ) & 0b0000_0001;
          out = ( ( ( out & 0xFF ) << 1 ) & 0b1_1111_1110 ) | fill;
          bus.write( address, out );
        case VALUE_B8 :
        case VALUE_B16 :
          assert false : "rotateLeft() from 2 Byte Immediate Value is illegal!";
        case FLAG :
          assert false : "rotateLeft() from Flag is illegel!";
        default :
          return;
      }
    }
    
    
    public void rotateRight( boolean circular )
    {
      int out;
      int fill = getCarryFlag() ? 0b1000_0000 : 0b0000_0000;
      switch ( type )
      {
        case REGISTER_B8 :
          out = registerB8.getByte();
          setCarryFlagTo( ( out & 0b0000_0001 ) != 0 );
          if( circular )
            fill = ( ( out << 7 ) & 0b1000_0000 );
          out = ( ( ( out & 0xFF ) >> 1 ) & 0b0111_1111 ) | fill;
          registerB8.setByte( out );
          return;
        case REGISTER_B16 :
          if( ! isBusAddress )
            assert false : "rotateRight() from 2 Byte Register is illegal!";
          int address = registerB16.getDoubleByte();
          out = bus.read( address );
          setCarryFlagTo( ( out & 0b0000_0001 ) != 0 );
          if( circular )
            fill = ( ( out << 7 ) & 0b1000_0000 );
          out = ( ( ( out & 0xFF ) >> 1 ) & 0b0111_1111 ) | fill;
          bus.write( address, out );
        case VALUE_B8 :
        case VALUE_B16 :
          assert false : "rotateRight() from 2 Byte Immediate Value is illegal!";
        case FLAG :
          assert false : "rotateRight() from Flag is illegel!";
        default :
          return;
      }
    }
    
    
    public void shiftRightArithmetic()
    {
      int out;
      int fill = getCarryFlag() ? 0b1 : 0b0;
      switch ( type )
      {
        case REGISTER_B8 :
          out = registerB8.getByte();
          setCarryFlagTo( ( out & 0b0000_0001 ) != 0 );
          out = ( out >> 1 ) & 0b0111_1111 ;
          registerB8.setByte( out );
          return;
        case REGISTER_B16 :
          if( ! isBusAddress )
            assert false : "shiftRightArithmetic() from 2 Byte Register is illegal!";
          int address = registerB16.getDoubleByte();
          out = bus.read( address );
          setCarryFlagTo( ( out & 0b0000_0001 ) != 0 );
          out = ( out >> 1 ) & 0b0111_1111 ;
          bus.write( address, out );
        case VALUE_B8 :
        case VALUE_B16 :
          assert false : "shiftRightArithmetic() from 2 Byte Immediate Value is illegal!";
        case FLAG :
          assert false : "shiftRightArithmetic() from Flag is illegel!";
        default :
          return;
      }
    }
    
    
    @Override
    public String toString()
    {
      return this.type.name();
    }
  }
  
  
  void detachBootstrapROM()
  {
    bus.detach( romBootstrapMemory );
  }
  
  
  int getPC() { return registers.PC.getDoubleByte() & 0xFFFF; }
}

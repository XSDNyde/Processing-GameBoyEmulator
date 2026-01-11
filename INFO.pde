/*
### Clocks: ###
CPU @ 4194304 Hz 2^22
RAM @ 1048576 Hz 2^20
PPU @ 4194304 Hz 2^22
VRAM@ 2097152 HZ 2^21

### SCREEN ###
Screen Size  - 2.6"
Resolution   - 160x144 (20x18 tiles)
Max sprites  - Max 40 per screen, 10 per line
Sprite sizes - 8x8 or 8x16
Palettes     - 1x4 BG, 2x3 OBJ (for CGB: 8x4 BG, 8x3 OBJ)
Colors       - 4 grayshades (32768 colors for CGB)
Horizontal Sync - 9198 KHz (9420 KHz for SGB)
Vertical Sync   - 59.73 Hz (61.17 Hz for SGB)

### ADDRESS Ranges: ###
Addressable range: [0x0000,0xFFFF]  2^16
ROM (Cartr)  @ [0000,8000[ - Split into Bank0 @ [0000,3FFF] and Bank[1,n] @ [4000,7FFF]
|---> Boot ROM     @ [0000,0100[
Video RAM    @ [8000,A000[ - TileSetA @ [8000,9000[; TileSetB @ [8800,9800[; TileMapBG @ [9800,9C00[; TileMapWindow @ [9C00,A000[;
External RAM @ [A000,C000[
Internal RAM @ [C000,E000[
Mirrored RAM @ [E000,FE00[
OAM RAM      @ [FE00,FEA0[
Forbidden    @ [FEA0,FF00[
ZeroPage:
I/O          @ [FF00,FF80[ - Details see: https://bgb.bircd.org/pandocs.htm#lcdcontrolregister
HRAM         @ [FF80,FFFF[
Interrupt En @ [FFFF]
*/

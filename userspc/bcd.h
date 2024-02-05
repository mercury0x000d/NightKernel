/*
        BCD.H - Functions for dealing with BCD representations.
                Based on code written by J. Pyle in DOS 6 Developer's
                Guide. The original source code is copyrighted by
                SAMS Publishing and/or J. Pyle

*/

#ifndef BCD_UTL_
#define BCD_UTL_

WORD BCD_ASC ( char bcd );
WORD BCD_Bin ( UBYTE bcd );
UBYTE ASC_BCD ( UBYTE hi, UBYTE lo);
UBYTE Bin_BCD ( UBYTE bin );

#endif
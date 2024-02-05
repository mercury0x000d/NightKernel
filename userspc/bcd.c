/*
        BCD.C - Functions for dealing with BCD representations.
                Based on code written by J. Pyle in DOS 6 Developer's
                Guide. The original source code is copyrighted by
                SAMS Publishing and/or J. Pyle

                The code was slightly modified from it's original form
                to improve clarity and to add constant declarations.

*/

#include "const.h"


WORD BCD_ASC ( UBYTE bcd )
{
  WORD retval;

        asm xor ah, ah;
        asm mov al, bcd;
        asm mov cl, 4;
        asm shl ax, cl;
        asm shr al, cl;
        asm xchg ah, al;
        asm add ax, 0x3030;
        asm mov retval, ax;
        return (retval);
}

WORD BCD_Bin ( UBYTE bcd )
{
  WORD retval;

        asm xor ah, ah;
        asm mov al, bcd;
        asm mov cl, 4;
        asm shl ax, cl;
        asm shr al, cl;
        asm xor bx, bx;
        asm xchg ah, al;
        asm mov ch, 10;
        asm mul ch;
        asm add ax, bx;
        asm mov retval, ax;
        return (retval);
}

WORD ASC_BCD ( UBYTE hi, UBYTE lo)
{
   WORD retval;

        asm mov ah, hi;                  /* convert to unpacked BCD */
        asm mov al, lo;
        asm and ax, 0x0F0F;
        asm mov cl, 4;                   /* pack up the BCD         */
        asm shl al, cl;
        asm shr ax, cl;
        asm mov retval, ax;
        return (retval);
}

WORD Bin_BCD ( UBYTE bin )
{
  WORD retval;

        asm mov al, bin;                /* convert to unpacked BCD */
        asm aam;
        asm mov cl, 4;                  /* pack up the BCD         */
        asm shl al, cl;
        asm shr ax, cl;
        asm mov retval, ax;
        return ( retval );
}
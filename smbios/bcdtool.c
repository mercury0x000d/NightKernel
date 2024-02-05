/*

	SoftEnviron Operating System
	Version 1.0
	Copyright (C) CTx Technologies, Ltd

	FILENAME: BCDTOOLS.C

	DESCRIPTION: Contains functions for dealing with binary coded
		     decimals

*/



int BCD_ASC( char bcd )
{
	asm xor ah, ah;
	asm mov al, bcd;
	asm mov cl, 4;
	asm shl ax, cl;         /* unpack the BCD */
	asm shr al, cl;
	asm xchg ah, al;        /* convert to ASCII */
	asm add ax, 0x3030;
}

int BCD_Bin( char bcd )
{
	asm xor ah, ah;
	asm mov al, bcd;
	asm mov cl, 4;
	asm shl ax, cl;
	asm shr al, cl
	asm xor bx, bx;
	asm xchg bl, al;
	asm xchg ah, al;
	asm mov ch, 10;
	asm mul ch;
	asm add ax, bx;
}

char ASC_BCD(char hi, char lo)
{
	asm mov ah, hi;
	asm mov al, lo;
	asm and ax, 0x0F0F;
	asm mov cl, 4;
	asm shl al, cl;
	asm shr ax, cl;
}

char Bin_BCD ( char bin )
{
	asm mov al, bin;
	asm aam;
	asm mov cl, 4;
	asm shl al, cl;
	asm shr ax, cl;
}

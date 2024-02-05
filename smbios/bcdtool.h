/*

	SoftEnviron Operating System
	Version 1.0
	Copyright (C) CTx Technologies, Ltd

	FILENAME: BCDTOOLS.H
*/

#ifndef BCD_UTL_
#define BCD_UTL_

int BCD_ASC( char bcd );
int BCD_Bin( char bcd );
char ASC_BCD( char hi, char lo );
char Bin_BCD( char bin );

#endif

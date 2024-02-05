#ifndef __CTYPE_H
#define __CTYPE_H

//************************************************************************
//
//              ctypes.h
//
//              NIGHTDOS Character Macros
//
//************************************************************************
#ifdef __cplusplus
extern "C"
{
#endif

extern char _ctype[];

#define CT_UP   0x01    /* upper case                   */
#define CT_LOW  0x02    /* lower case                   */
#define CT_DIG  0x04    /* digit                        */
#define CT_CTL  0x08    /* control                      */
#define CT_PUN  0x10    /* punctuation                  */
#define CT_WHT  0x20    /* white space (space/cr/lf/tab */
#define CT_HEX  0x40    /* hex digit                    */
#define CT_SP   0x80    /* hard space (0x20             */

/* Macros to determine the type of character in a string */

#define isalnum(c)      ((_ctype + 1)[(unsigned) (c)] & (CT_UP | CT_LOW | CT_DIG))
#define isalpha(c)      ((_ctype + 1)[(unsigned) (c)] & (CT_UP | CT_LOW))
#define iscntrl(c)      ((_ctype + 1)[(unsigned) (c)] & (CT_CTL))
#define isdigit(c)      ((_ctype + 1)[(unsigned) (c)] & (CT_DIG))
#define isgraph(c)      ((_ctype + 1)[(unsigned) (c)] & (CT_PUN | CT_UP | CT_LOW | CT_DIG))
#define islower(c)      ((_ctype + 1)[(unsigned) (c)] & (CT_LOW))
#define isprint(c)      ((_ctype + 1)[(unsigned) (c)] & (CT_PUN | CT_UP | CT_LOW | CT_DIG | CT_SP))
#define ispunct(c)      ((_ctype + 1)[(unsigned) (c)] & (CT_PUN))
#define isspace(c)      ((_ctype + 1)[(unsigned) (c)] & (CT_WHT))
#define isupper(c)      ((_ctype + 1)[(unsigned) (c)] & (CT_UP))
#define isxdigit(c)     ((_ctype + 1)[(unsigned) (c)] & (CT_DIG | CT_HEX))
#define isascii(c)      ((unsigned) (c) <= 0x7F)
#define toascii(c)      ((unsigned) (c) & 0x7F)
#define tolower(c)      (isupper(c) ? c + 'a' - 'A' : c)
#define toupper(c)      (islower(c) ? c + 'A' - 'a' : c)

#ifdef __cplusplus
}
#endif

#endif
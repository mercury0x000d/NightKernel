#ifndef __STRING_H
#define __STRING_H

//************************************************************************
//
//      string.h
//
//      NIGHTDOS Standard C string routines
//
//************************************************************************

#include <size_t.h>


int memcmp(const void*, const void*, size_t);
void* memcpy(void* __restrict, const void* __restrict, size_t);
void* memmove(void*, const void*, size_t);
void* memset(void*, int, size_t);
size_t strlen(const char*);

#endif

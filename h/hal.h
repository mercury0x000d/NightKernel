#ifndef __HAL_H
#define	__HAL_H

//****************************************************************************
//**
//**    hal.h
//**    - [FILE DESCRIPTION]
//**
//****************************************************************************
//============================================================================
//    INTERFACE REQUIRED HEADERS
//============================================================================
#include <stdint.h>

//============================================================================
//    INTERFACE DEFINITIONS / ENUMERATIONS / SIMPLE TYPEDEFS
//============================================================================

#ifdef __cplusplus
extern "C"
{
#endif

#pragma pack (push, 1)

struct gdt_descriptor {
    uint16_t        limit;
    uint16_t        baseLo;
    uint8_t         baseMid;
    uint16_t        flags;
    uint8_t         baseHi;   
}

struct gdtr {
    uint16_t        m_limit;
    uint32_t        m_base;
}


#pragma pack (pop, 1)


#endif
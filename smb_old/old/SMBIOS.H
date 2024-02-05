#ifndef _SMBIOS_H
#define _SMBIOS_H              1

#ifdef __WATCOMC__
#include <stdint.h>
#else
#include "stdint.h"
#endif

#define SMBIOS_SP	0xf000
#define SMBIOS_LN	0x1000
#define SMBIOS_STP	0x10
#define SMBIOS_SIG	"_SM_"
#define SMBIOS64_SIG	"_SM3_"
#define SMBIOS_DMI_SIG	"_DMI_"
typedef void far *FP;

#ifndef MK_FP
#define MK_FP(seg,ofs)  ((FP)((unsigned long)(seg) << 16 | (ofs)))
#endif
#define SMBIOS_GET8(b, o)	(*(uint8_t *)((b) + (o)))
#define SMBIOS_GET16(b, o)	(*(uint16_t *)((b) + (o)))
#define SMBIOS_GET32(b, o)	(*(uint32_t *)((b) + (o)))


typedef uint8_t ENUM;
typedef uint8_t str_id;
  #pragma pack(push, 1)
  typedef struct {                      // Offset in hex
    char anchor[4];                     // 00
    uint8_t eps_checksum;                  // 04
    uint8_t entrypointlength;              // 05
    uint8_t majorversion;                  // 06
    uint8_t minorversion;                  // 07
    uint16_t maxstructsize;                 // 08
    uint8_t entrypointrevision;            // 0A
    char formattedarea[5];              // 0B
    char intermediateanchor[5];         // 10
    uint8_t intermediatechecksum;          // 15
    uint16_t tablelength;                   // 16
    char * tableaddress;                    // 18
    uint16_t smbiosstructcnt;
    uint8_t revision;
  } SMBIOS, far * LPSMBIOS;

  typedef struct Entry {
    struct Entry* next;
    struct header* HEADER;
  } Entry;


  typedef struct {
    uint8_t Type;
    uint8_t Length;
    uint16_t Handle;
  } HEADER;

  typedef struct {
	// 2.0
	str_id  vendor;
	str_id  version;
	uint16_t  starting_segment;
	str_id  release_date;
	uint8_t  rom_size;
	uint32_t characteristics1; /* high portion */
	uint32_t characteristics2; /* low portion */
	// 2.4
	uint8_t ext_char1;
	uint8_t ext_char2;
	uint8_t sb_major;
	uint8_t sb_minor;
	uint8_t ec_major;
	uint8_t uint8_t;
} BIOSINFO, * PBIOSINFO;
  enum {
	smbios_type_bios_info                   =   0, // Required
	smbios_type_system_info                 =   1, // Required
	smbios_type_baseboard_info              =   2,
	smbios_type_module_info                 =   2,
	smbios_type_system_enclosure            =   3, // Required
	smbios_type_system_chassis              =   3, // Required
	smbios_type_processor_info              =   4, // Required
	smbios_type_memory_controller_info      =   5, // Obsolete
	smbios_type_memory_module_info          =   6, // Obsolete
	smbios_type_cache_info                  =   7, // Required
	smbios_type_port_connector_info         =   8,
	smbios_type_system_slots                =   9, // Required
	smbios_type_onboard_device_info         =  10, // Obsolete
	smbios_type_oem_strings                 =  11,
	smbios_type_system_config_options       =  12,
	smbios_type_language_info               =  13,
	smbios_type_group_associations          =  14,
	smbios_type_system_event_log            =  15,
	smbios_type_memory_array                =  16, // Required
	smbios_type_memory_device               =  17, // Required
	smbios_type_memory_error_info_32bit     =  18,
	smbios_type_memory_array_mapped_addr    =  19, // Required
	smbios_type_memory_device_mapped_addr   =  20,
	smbios_type_builtin_pointing_device     =  21,
	smbios_type_portable_battery            =  22,
	smbios_type_system_reset                =  23,
	smbios_type_hardware_security           =  24,
	smbios_type_system_power_controls       =  25,
	smbios_type_voltage_probe               =  26,
	smbios_type_cooling_device              =  27,
	smbios_type_temperature_probe           =  28,
	smbios_type_electrical_current_probe    =  29,
	smbios_type_out_of_band_remote_access   =  30,
	smbios_type_bis_entry_point             =  31, // Required
	smbios_type_system_boot_info            =  32, // Required
	smbios_type_memory_error_info_64bit     =  33,
	smbios_type_management_device           =  34,
	smbios_type_management_device_component =  35,
	smbios_type_management_device_threshold =  36,
	smbios_type_memory_channel              =  37,
	smbios_type_ipmi_device_info            =  38,
	smbios_type_system_power_supply         =  39,
	smbios_type_additional_info             =  40,
	smbios_type_onboard_device_extinfo      =  41,
	smbios_type_management_controller_host  =  42,
	smbios_type_inactive                    = 126,
	smbios_type_end_of_table                = 127, // Always last structure
};

FP findSMBIOS ();
FP findSMBIOSUEFI ();
FP findSMBIOS2 ();
uint16_t FindStructure (char * TableAddress, uint16_t StructureCount, uint8_t Type);
#endif



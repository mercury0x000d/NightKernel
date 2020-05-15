; Night Kernel
; Copyright 2015 - 2020 by mercury0x0d
; CPU defines.inc is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
; License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
; version.

; The Night Kernel is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along with the Night Kernel. If not, see
; <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the GPL License by which this program is covered.





; constant definitions

%define kCPU_sse3								00		; Prescott New Instructions-SSE3 (PNI)
%define kCPU_pclmulqdq							01		; PCLMULQDQ
%define kCPU_dtes64								02		; 64-bit debug store
%define kCPU_monitor							03		; MONITOR and MWAIT instructions (SSE3)
%define kCPU_dscpl								04		; CPL qualified debug store
%define kCPU_vmx								05		; Virtual Machine eXtensions
%define kCPU_smx								06		; Safer Mode Extensions (LaGrande)
%define kCPU_est								07		; Enhanced SpeedStep
%define kCPU_tm2								08		; Thermal Monitor 2
%define kCPU_ssse3								09		; Supplemental SSE3 instructions
%define kCPU_cnxtid								10		; L1 Context ID
%define kCPU_sdbg								11		; Silicon Debug interface
%define kCPU_fma								12		; Fused multiply-add (FMA3)
%define kCPU_cx16								13		; CMPXCHG16B instruction
%define kCPU_xtpr								14		; Can disable sending task priority messages
%define kCPU_pdcm								15		; Perfmon & debug capability
%define kCPU_reserved01							16
%define kCPU_pcid								17		; Process context identifiers
%define kCPU_dca								18		; Direct cache access for DMA writes
%define kCPU_sse41								19		; SSE4.1 instructions
%define kCPU_sse42								20		; SSE4.2 instructions
%define kCPU_x2apic								21		; x2APIC
%define kCPU_movbe								22		; MOVBE instruction
%define kCPU_popcnt								23		; POPCNT instruction
%define kCPU_tscdeadline						24		; APIC implements one-shot operation using a TSC deadline value
%define kCPU_aes								25		; AES instruction set
%define kCPU_xsave								26		; XSAVE, XRESTOR, XSETBV, XGETBV
%define kCPU_osxsave							27		; XSAVE enabled by OS
%define kCPU_avx								28		; Advanced Vector Extensions
%define kCPU_f16c								29		; F16C (half-precision) FP feature
%define kCPU_rdrnd								30		; RDRAND (on-chip random number generator) feature
%define kCPU_hypervisor							31		; Hypervisor present (always zero on physical CPUs)

%define kCPU_fpu								32		; Onboard x87 FPU
%define kCPU_vme								33		; Virtual 8086 mode extensions (such as VIF, VIP, PIV)
%define kCPU_de									34		; Debugging extensions
%define kCPU_pse								35		; Page Size Extension
%define kCPU_tsc								36		; Time Stamp Counter
%define kCPU_msr								37		; Model-specific registers
%define kCPU_pae								38		; Physical Address Extension
%define kCPU_mce								39		; Machine Check Exception
%define kCPU_cx8								40		; CMPXCHG8 (compare-and-swap) instruction
%define kCPU_apic								41		; Onboard Advanced Programmable Interrupt Controller
%define kCPU_reserved02							42
%define kCPU_sep								43		; SYSENTER and SYSEXIT instructions
%define kCPU_mtrr								44		; Memory Type Range Registers
%define kCPU_pge								45		; Page Global Enable bit in CR4
%define kCPU_mca								46		; Machine check architecture
%define kCPU_cmov								47		; Conditional move and FCMOV instructions
%define kCPU_pat								48		; Page Attribute Table
%define kCPU_pse36								49		; 36-bit page size extension
%define kCPU_psn								50		; Processor Serial Number
%define kCPU_clfsh								51		; CLFLUSH instruction (SSE2)
%define kCPU_reserved03							52
%define kCPU_ds									53		; Debug store: save trace of executed jumps
%define kCPU_acpi								54		; Onboard thermal control MSRs for ACPI
%define kCPU_mmx								55		; MMX instructions
%define kCPU_fxsr								56		; FXSAVE, FXRESTOR instructions
%define kCPU_sse								57		; SSE / Katmai instructions
%define kCPU_sse2								58		; SSE2 instructions
%define kCPU_ss									59		; CPU cache implements self-snoop
%define kCPU_htt								60		; Hyper-threading
%define kCPU_tm									61		; Thermal monitor automatically limits temperature
%define kCPU_ia64								62		; IA64 processor emulating x86
%define kCPU_pbe								63		; Pending Break Enable (PBE# pin) wakeup capability

%define kCPU_fsgsbase							64		; Access to base of %fs and %gs
%define kCPU_ia32_tsc_adjust					65
%define kCPU_sgx								66		; Software Guard Extensions
%define kCPU_bmi1								67		; Bit Manipulation Instruction Set 1
%define kCPU_hle								68		; TSX Hardware Lock Elision
%define kCPU_avx2								69		; Advanced Vector Extensions 2
%define kCPU_reserved04							70
%define kCPU_smep								71		; Supervisor Mode Execution Prevention
%define kCPU_bmi2								72		; Bit Manipulation Instruction Set 2
%define kCPU_erms								73		; Enhanced REP MOVSB/STOSB
%define kCPU_invpcid							74		; INVPCID instruction
%define kCPU_rtm								75		; TSX Restricted Transactional Memory
%define kCPU_pqm								76		; Platform Quality of Service Monitoring
%define kCPU_fpucs_ds_deprecated				77		; FPU CS and FPU DS deprecated
%define kCPU_mpx								78		; Intel MPX (Memory Protection Extensions)
%define kCPU_pqe								79		; Platform Quality of Service Enforcement
%define kCPU_avx512_f							80		; AVX-512 Foundation
%define kCPU_avx512_dq							81		; AVX-512 Doubleword and Quadword Instructions
%define kCPU_rdseed								82		; RDSEED instruction
%define kCPU_adx								83		; Intel ADX (Multi-Precision Add-Carry Instruction Extensions)
%define kCPU_smap								84		; Supervisor Mode Access Prevention
%define kCPU_avx512_ifma						85		; AVX-512 Integer Fused Multiply-Add Instructions
%define kCPU_pcommit							86		; PCOMMIT instruction
%define kCPU_clflushopt							87		; CLFLUSHOPT instruction
%define kCPU_clwb								88		; CLWB instruction
%define kCPU_intel_pt							89		; Intel Processor Trace
%define kCPU_avx512_pf							90		; AVX-512 Prefetch Instructions
%define kCPU_avx512_er							91		; AVX-512 Exponential and Reciprocal Instructions
%define kCPU_avx512_cd							92		; AVX-512 Conflict Detection Instructions
%define kCPU_sha								93		; Intel SHA extensions
%define kCPU_avx512_bw							94		; AVX-512 Byte and Word Instructions
%define kCPU_avx512_vl							95		; AVX-512 Vector Length Extensions

%define kCPU_prefetchwt1						96		; PREFETCHWT1 instruction
%define kCPU_avx512_vbmi						97		; AVX-512 Vector Bit Manipulation Instructions
%define kCPU_umip								98		; User-mode Instruction Prevention
%define kCPU_pku								99		; Memory Protection Keys for User-mode pages
%define kCPU_ospke								100		; PKU enabled by OS
%define kCPU_waitpkg							101
%define kCPU_avx512_vbmi2						102		; AVX-512 Vector Bit Manipulation Instructions 2
%define kCPU_shstk								103
%define kCPU_gfni								104		; Galois Field instructions
%define kCPU_vaes								105		; Vector AES instruction set (VEX-256/EVEX)
%define kCPU_vpclmulqdq							106		; CLMUL instruction set (VEX-256/EVEX)
%define kCPU_avx512_vnni						107		; AVX-512 Vector Neural Network Instructions
%define kCPU_avx512_bitalg						108		; AVX-512 BITALG instructions
%define kCPU_reserved05							109
%define kCPU_avx512_vpopcntdq					110		; AVX-512 Vector Population Count Double and Quad-word
%define kCPU_reserved06							111
%define kCPU_5levelpaging						112
%define kCPU_mawau0								113		; The value of userspace MPX Address-Width Adjust used by the BNDLDX and BNDSTX Intel MPX instructions in 64-bit mode
%define kCPU_mawau1								114
%define kCPU_mawau2								115
%define kCPU_mawau3								116
%define kCPU_mawau4								117
%define kCPU_rdpid								118		; Read Processor ID and IA32_TSC_AUX
%define kCPU_reserved07							119
%define kCPU_reserved08							120
%define kCPU_cldemote							121		; Cache line demote
%define kCPU_reserved09							122
%define kCPU_movdiri							123
%define kCPU_movdir64b							124
%define kCPU_enqcmd								125		; Enqueue Stores
%define kCPU_sgx_lc								126		; SGX Launch Configuration
%define kCPU_reserved10							127

%define kCPU_reserved11							128
%define kCPU_reserved12							129
%define kCPU_avx512_4vnniw						130		; AVX-512 4-register Neural Network Instructions
%define kCPU_avx512_4fmaps						131		; AVX-512 4-register Multiply Accumulation Single precision
%define kCPU_fsrm								132		; Fast Short REP MOVSB
%define kCPU_reserved13							133
%define kCPU_reserved14							134
%define kCPU_reserved15							135
%define kCPU_avx512_vp2intersect				136		; AVX-512 VP2INTERSECT Doubleword and Quadword Instructions
%define kCPU_reserved16							137
%define kCPU_md_clear							138		; VERW instruction clears CPU buffers
%define kCPU_reserved17							139
%define kCPU_reserved18							140
%define kCPU_tsx_force_abort					141
%define kCPU_serialize							142		; Serialize instruction execution
%define kCPU_hybrid								143
%define kCPU_tsxldtrk							144		; TSX suspend load address tracking
%define kCPU_reserved19							145
%define kCPU_pconfig							146		; Platform configuration (Memory Encryption Technologies Instructions)
%define kCPU_reserved20							147
%define kCPU_ibt								148
%define kCPU_reserved21							149
%define kCPU_reserved22							150
%define kCPU_reserved23							151
%define kCPU_reserved24							152
%define kCPU_reserved25							153
%define kCPU_ibrs_ibpb_specctrl					154		; Speculation Control, part of Indirect Branch Control (IBC): Indirect Branch Restricted Speculation (IBRS) and Indirect Branch Prediction Barrier (IBPB)
%define kCPU_stibp						 		155		; Single Thread Indirect Branch Predictor, part of IBC
%define kCPU_reserved26							156
%define kCPU_ia32_arch_capabilities				157		; Speculative Side Channel Mitigations
%define kCPU_ia32_core_capabilities				158
%define kCPU_ssbd								159		; Speculative Store Bypass Disable, as mitigation for Speculative Store Bypass (IA32_SPEC_CTRL)

%define kCPU_reserved27							160
%define kCPU_reserved28							161
%define kCPU_reserved29							162
%define kCPU_reserved30							163
%define kCPU_reserved31							164
%define kCPU_avx512_bf16						165		; AVX-512 BFLOAT16 instructions
%define kCPU_reserved32							166
%define kCPU_reserved33							167
%define kCPU_reserved34							168
%define kCPU_reserved35							169
%define kCPU_reserved36							170
%define kCPU_reserved37							171
%define kCPU_reserved38							172
%define kCPU_reserved39							173
%define kCPU_reserved40							174
%define kCPU_reserved41							175
%define kCPU_reserved42							176
%define kCPU_reserved43							177
%define kCPU_reserved44							178
%define kCPU_reserved45							179
%define kCPU_reserved46							180
%define kCPU_reserved47							181
%define kCPU_reserved48							182
%define kCPU_reserved49							183
%define kCPU_reserved50							184
%define kCPU_reserved51							185
%define kCPU_reserved52							186
%define kCPU_reserved53							187
%define kCPU_reserved54							188
%define kCPU_reserved55							189
%define kCPU_reserved56							190
%define kCPU_reserved57							191





; declare functions as global
global CPUInit
global CPUProbe

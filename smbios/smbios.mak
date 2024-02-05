.AUTODEPEND

.PATH.obj = C:\OUTPUT

#		*Translator Definitions*
CC = tcc +SMBIOS.CFG
TASM = TASM
TLIB = tlib
TLINK = tlink
LIBPATH = C:\BORLAND\TC\LIB;
INCLUDEPATH = C:\BORLAND\TC\INCLUDE;


#		*Implicit Rules*
.c.obj:
  $(CC) -c {$< }

.cpp.obj:
  $(CC) -c {$< }

#		*List Macros*


EXE_dependencies =  \
 sbiotest.obj \
 smbios.obj

#		*Explicit Rules*
c:\output\smbios.exe: smbios.cfg $(EXE_dependencies)
  $(TLINK) /v/x/c/L$(LIBPATH) @&&|
c0s.obj+
c:\output\sbiotest.obj+
c:\output\smbios.obj
c:\output\smbios
		# no map file
emu.lib+
maths.lib+
cs.lib
|


#		*Individual File Dependencies*
sbiotest.obj: smbios.cfg sbiotest.cpp 

smbios.obj: smbios.cfg smbios.cpp 

#		*Compiler Configuration File*
smbios.cfg: smbios.mak
  copy &&|
-v
-vi-
-w-ret
-w-nci
-w-inl
-wpin
-wamb
-wamp
-w-par
-wasm
-wcln
-w-cpt
-wdef
-w-dup
-w-pia
-wsig
-wnod
-w-ill
-w-sus
-wstv
-wucp
-wuse
-w-ext
-w-ias
-w-ibc
-w-pre
-w-nst
-nC:\OUTPUT
-I$(INCLUDEPATH)
-L$(LIBPATH)
| smbios.cfg



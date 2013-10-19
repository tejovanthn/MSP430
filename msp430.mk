#
# Makefile for msp430
#
# 'make' builds everything
# 'make clean' deletes everything except source files and Makefile
# You need to set TARGET, MCU and SOURCES for your project.
# TARGET is the name of the executable file to be produced 
# $(TARGET).elf $(TARGET).hex and $(TARGET).txt nad $(TARGET).map are all generated.
# The TXT file is used for BSL loading, the ELF can be used for JTAG use
# 
TARGET     = ${notdir ${shell dirname ${CURDIR}}}
PAR        = ../par/
#TARGET     =${notdir ${CURDIR}}
MCU        = msp430f5529
# List all the source files here
# eg if you have a source file foo.c then list it here
CORES = ""

LIBRARY = ""

SOURCES = ${TARGET}.c
# Include are located in the Include directory
INCLUDES = -IInclude
# Add or subtract whatever MSPGCC flags you want. There are plenty more
#######################################################################################
CFLAGS   = -mmcu=$(MCU) -g -Os -Wall -Wunused $(INCLUDES)   
ASFLAGS  = -mmcu=$(MCU) -x assembler-with-cpp -Wa,-gstabs
LDFLAGS  = -mmcu=$(MCU) -Wl,-Map=$(PAR)$(TARGET).map
########################################################################################
CC       = msp430-gcc
LD       = msp430-ld
AR       = msp430-ar
AS       = msp430-gcc
GASP     = msp430-gasp
NM       = msp430-nm
OBJCOPY  = msp430-objcopy
RANLIB   = msp430-ranlib
STRIP    = msp430-strip
SIZE     = msp430-size
READELF  = msp430-readelf
MAKETXT  = srec_cat
CP       = cp -p
RM       = rm -f
MV       = mv
########################################################################################
# the file which will include dependencies
DEPEND = $(PAR)$(SOURCES:.c=.d)
# all the object files
OBJECTS = $(PAR)$(SOURCES:.c=.o)

all: $(PAR)$(TARGET).elf $(PAR)$(TARGET).hex $(PAR)$(TARGET).txt 

$(PAR)$(TARGET).elf: $(OBJECTS)
	echo ${notdir ${CURDIR}}
	echo "Linking $@"
	$(CC) $(OBJECTS) $(LDFLAGS) $(LIBS) -o $(PAR)$@
	echo
	echo ">>>> Size of Firmware <<<<"
	$(SIZE) $(PAR)$(TARGET).elf
	echo

$(PAR)%.hex: $(PAR)%.elf
	$(OBJCOPY) -O ihex $< $@

$(PAR)%.txt: $(PAR)%.hex
	$(MAKETXT) -O $@ -TITXT $< -I
	unix2dos $(PAR)$(TARGET).txt
#  The above line is required for the DOS based TI BSL tool to be able to read the txt file generated from linux/unix systems.

$(PAR)%.o: %.c
	echo "Compiling $<"
	$(CC) -c $(CFLAGS) -o $(PAR)$@ $<

# rule for making assembler source listing, to see the code
$(PAR)%.lst: %.c
	$(CC) -c $(ASFLAGS) -Wa,-anlhd $< > $@

# include the dependencies unless we're going to clean, then forget about them.
ifneq ($(MAKECMDGOALS), clean)
-include $(DEPEND)
endif

# dependencies file
# includes also considered, since some of these are our own
# (otherwise use -MM instead of -M)
$(PAR)%.d: %.c
	echo "Generating dependencies $@ from $<"
	$(CC) -M ${CFLAGS} $< >$(PAR)$@

install: $(PAR)$(TARGET).elf
	mspdebug -q --force-reset rf2500 "prog $(PAR)$(TARGET).elf"

.SILENT:
.PHONY:	clean
clean:
	-$(RM) $(PAR)*

.PHONY: tags
tags:
	ctags -d $(TARGET).c

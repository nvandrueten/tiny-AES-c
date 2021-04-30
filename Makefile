#CC           = avr-gcc
#CFLAGS       = -Wall -mmcu=atmega16 -Os -Wl,-Map,test.map
#OBJCOPY      = avr-objcopy
CC           = gcc
RCC          = riscv64-unknown-elf-gcc
ROBJDUMP     = riscv64-unknown-elf-objdump
LD           = gcc
AR           = ar
ARFLAGS      = rcs

CFLAGS       = -Wall -Os -c
LDFLAGS      = -Wall -Os -Wl,-Map,test.map
ifdef AES192
CFLAGS += -DAES192=1
endif
ifdef AES256
CFLAGS += -DAES256=1
endif
RCFLAGS      = -I/home/niels/gitrepos/param/core/c-class/verification/riscv-tests/env -I/home/niels/gitrepos/param/core/c-class/verification/riscv-tests/benchmarks/common -I/home/niels/gitrepos/param/core/c-class/verification/riscv-tests/env/p -DPREALLOCATE=1 -mcmodel=medany -static -std=gnu99 -O2 -ffast-math -fno-common -fno-builtin-printf -static -nostdlib -nostartfiles -lm -lgcc  -T/home/niels/gitrepos/param/core/c-class/verification/riscv-tests/benchmarks/common/test.ld
ROBJDUMPFLAGS= --disassemble-all --disassemble-zeroes --section=.text --section=.text.startup --section=.data
OBJCOPYFLAGS = -j .text -O ihex
OBJCOPY      = objcopy

# include path to AVR library
INCLUDE_PATH = /usr/lib/avr/include
# splint static check
SPLINT       = splint test.c aes.c -I$(INCLUDE_PATH) +charindex -unrecog

default: test.elf riscv

.SILENT:
.PHONY:  lint clean

test.hex : test.elf
	echo copy object-code to new image and format in hex
	$(OBJCOPY) ${OBJCOPYFLAGS} $< $@

test.o : test.c aes.h aes.o
	echo [CC] $@ $(CFLAGS)
	$(CC) $(CFLAGS) -o  $@ $<

aes.o : aes.c aes.h
	echo [CC] $@ $(CFLAGS)
	$(CC) $(CFLAGS) -o $@ $<

test.elf : aes.o test.o
	echo [LD] $@
	$(LD) $(LDFLAGS) -o $@ $^

aes.a : aes.o
	echo [AR] $@
	$(AR) $(ARFLAGS) $@ $^

lib : aes.a


riscv: aes.elf aes.elf.dump

aes.elf: aes.c test.c syscalls.c crt.S
	echo [RCC] $(RCFLAGS) $< -o $@
	$(RCC) $(RCFLAGS) aes.c test.c syscalls.c crt.S -o $@

aes.elf.dump: aes.elf
	echo [RDUMP] $(ROBJDUMPFLAGS) $<
	$(ROBJDUMP) $(ROBJDUMPFLAGS) $< > $@
clean:
	rm -f *.OBJ *.LST *.o *.gch *.out *.hex *.map *.elf *.a *.elf.dump

test:
	make clean && make && ./test.elf
	make clean && make AES192=1 && ./test.elf
	make clean && make AES256=1 && ./test.elf

lint:
	$(call SPLINT)

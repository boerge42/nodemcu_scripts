MCU				= attiny45
TARGET_ARCH     = -mmcu=$(MCU)
OBJECTS         = main.o
FLASH_CMD       = avrdude -p $(MCU) -c usbasp


CC      = avr-gcc
CFLAGS  = -O3 -g -Wall -I. 
ASFLAGS = -Os -g -Wall -I.
LDFLAGS = -g
MODULES = $(OBJECTS)


all:	main.hex

clean:
	rm -f main.hex *.o *.elf

main.elf: $(MODULES)
	$(LINK.o) -o $@ $(MODULES)

main.hex: main.elf
	avr-objcopy -j .text -j .data -O ihex main.elf main.hex
	avr-size main.hex

disasm: main.elf
	avr-objdump -S main.elf

flash:	main.hex
	$(FLASH_CMD) -U flash:w:main.hex

main.o: main.c

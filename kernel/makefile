CC = arm-none-eabi-gcc
AS = arm-none-eabi-as
LD = arm-none-eabi-ld
OBJCOPY = arm-none-eabi-objcopy
CFLAGS = -O2 -mfpu=vfp -mfloat-abi=hard -march=armv6zk -mtune=arm1176jzf-s
CFLAGS += -ffreestanding -nostdlib -Wall
LDFLAGS = -nostdlib -nostartfiles --script=ldscript.lds
OBJS = boot.o main.o vccomm.o debug.o

kernel.img: $(OBJS)
	$(LD) $(LDFLAGS) -o kernel.o $^
	$(OBJCOPY) -O binary kernel.o $@

clean:
	rm -f $(OBJS) kernel.o kernel.img

boot.o: boot.s
	$(AS) $< -o $@

%.o: %.c
	$(CC) $(CFLAGS) -c $<

debug.o: debug.c debug.h
main.o: main.c vccomm.h
vccomm.o: vccomm.c vccomm.h debug.h


CC = arm-none-eabi-gcc
AS = arm-none-eabi-as
LD = arm-none-eabi-ld
OBJCOPY = arm-none-eabi-objcopy
CFLAGS = -O2 -mfpu=vfp -mfloat-abi=hard -march=armv6zk -mtune=arm1176jzf-s
CFLAGS += -ffreestanding -nostdlib -Wall
LDFLAGS = -nostdlib -nostartfiles
OBJS = boot.o main.o

kernel.img: $(OBJS)
	$(LD) $(LDFLAGS) -o kernel.o $^
	$(OBJCOPY) -O binary kernel.o kernel.bin

clean:
	rm $(OBJS) kernel.o kernel.bin

boot.o: boot.s
	$(AS) $< -o $@

main.o: main.c
	$(CC) $(CFLAGS) -c $<

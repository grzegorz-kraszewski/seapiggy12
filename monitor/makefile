CC = gcc
LD = ld
CFLAGS = -noixemul -nostdlib -O2 -fomit-frame-pointer -m68000 -mregparm=2 -D__NOLIBBASE__ -DUSE_INLINE_STDARG
LDFLAGS = -noixemul -nostartfiles -nostdlib
LIBS = -L. -lustring
OBJS = start.o main.o displayinfo.o
EXE = SeaPiggy

all: $(OBJS) libustring
	@echo "Linking $(EXE)..."
	@$(LD) $(LDFLAGS) -o $(EXE).db $(OBJS) $(LIBS)
	@strip -s --remove-section .comment -o $(EXE) $(EXE).db
	Protect $(EXE) +E
clean:
	rm -f $(OBJS) $(EXE)

libustring:
	make -C libustring-m68k
	
start.o: start.c
	@echo "Compiling $@..."
	@$(CC) $(CFLAGS) -fwritable-strings -c -o $@ $<

%.o: %.c
	@echo "Compiling $@..."
	@$(CC) $(CFLAGS) -c -o $@ $<

# dependencies

main.o: main.c

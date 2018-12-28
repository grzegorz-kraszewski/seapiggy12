ASM = as
ASMOPTS = --defsym CPU=68000
OBJS = allocvecpooled.o freevecpooled.o clonemem.o clonemempooled.o utf8size.o \
 strcopy.o strcopyw.o strcopyl.o strsize.o strsizew.o strsizel.o strclone.o \
 strclonew.o strclonel.o strclonepooled.o strclonepooledw.o strclonepooledl.o \
 strcount.o strcountw.o strcountl.o utf8dec.o utf8enc.o
SRCS = allocvecpooled.s freevecpooled.s clonemem.s clonemempooled.s utf8size.s \
 strcopy.s strcopyw.s strcopyl.s strsize.s strsizew.s strsizel.s strclone.s \
 strclonew.s strclonel.s strclonepooled.s strclonepooledw.s strclonepooledl.s \
 strcount.s strcountw.s strcountl.s

OUTPUT = ../libustring.a

lib: $(OBJS)
	ar r $(OUTPUT) $(OBJS)

doc: $(SRCS)
	Join $(SRCS) AS doc.tmp
	Robodoc doc.tmp libvstring.doc SORT ASCII
	Robodoc doc.tmp libvstring.guide SORT GUIDE TOC
	rm doc.tmp

%.o:%.s
	$(ASM) $(ASMOPTS) -o $@ $<

clean:
	rm *.o -f
  

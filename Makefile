.PHONY: run all clean

ASMFILE=jarvis

all: run

clean:
	rm -f $(ASMFILE) $(ASMFILE).o

run: $(ASMFILE)
	./$<

$(ASMFILE): $(ASMFILE).o
	gcc -fPIC $< -o $@ -fno-pie -no-pie -z noexecstack --for-linker /lib64/ld-linux-x86-64.so.2 -lX11

$(ASMFILE).o: $(ASMFILE).asm
	nasm -felf64 -Fdwarf -g $< -o $@

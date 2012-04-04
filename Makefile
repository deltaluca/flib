default:
	@echo "to compile use option 'flib' together with an architecture mode ARCH=windows or ARCH=unix"
	@echo "to clean use option 'clean'"
	@echo "to tar flib, use option 'tar'"
	
flib:
	@echo "--------------------------------"
	@echo "compiling flib with ARCH=$(ARCH)"
	@echo "--------------------------------"
	caxe -o src cx-src --times
	haxe -cp src -main Main -neko bin/flib.n -D $(ARCH) -resource bin/template.swf
	nekotools boot bin/flib.n

release:
	make flib ARCH=unix
	mv bin/flib.n bin/flib_unix.n
	make flib ARCH=windows
	mv bin/flib.n bin/flib_windows.n

as3lib:
	caxe -o src cx-src --times
	haxe -cp src --macro "include('flib')" -swf flib.swc -swf-version 10

server-tar:
	rm -f flib.tar.gz
	tar cvfz flib.tar.gz cx-src Makefile bin/template.swf
	scp flib.tar.gz deltaluca.me.uk:flib/flib.tar.gz

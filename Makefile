default:
	@echo "to compile use option 'flib' together with an architecture mode ARCH=windows or ARCH=unix"
	@echo "to clean use option 'clean'"
	@echo "to tar flib, use option 'tar'"
	
flib:
	@echo "--------------------------------"
	@echo "compiling flib with ARCH=$(ARCH)"
	@echo "--------------------------------"
	caxe -o src cx-src --times
	mkdir -p bin
	haxe -cp src -main Main -neko bin/flib.n -D $(ARCH)
	nekotools boot bin/flib.n

clean:
	@echo "-------------"
	@echo "cleaning flib"
	@echo "-------------"
	rm -r bin

tar:
	@echo "------------"
	@echo "tarring flib"
	@echo "------------"
	tar cvfz flib.tar.gz cx-src Makefile

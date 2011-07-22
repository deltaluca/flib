default:
	@echo "to compile use option 'flib' together with an architecture mode ARCH=windows or ARCH=unix"
	@echo "to clean use option 'clean'"
	
flib:
	@echo "--------------------------------"
	@echo "compiling flib with ARCH=$(ARCH)"
	@echo "--------------------------------"
	caxe -o src cx-src --times
	mkdir -p bin
	haxe -cp src -main Main -neko bin/flib.n -D $(ARCH)
	nekotools boot bin/flib.n

clean:
	rm -r bin

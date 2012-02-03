all:
	haxe -cp . -main Preloader -swf preloader.swf -swf-header 800:60:30:333333
	haxe -cp . -main Main -swf main.swf -swf-header 550:400:60:ffffff
	flib --combine preloader.swf main.swf combined.swf
	debugfp combined.swf

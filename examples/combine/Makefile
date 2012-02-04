all:
	haxe -cp . -main Preloader -swf preloader.swf -swf-header 80:60:30:333333
	haxe -cp . -main Main -swf main.swf -swf-header 800:600:60:0000ff
	flib --combine preloader.swf main.swf combined.swf
	debugfp combined.swf

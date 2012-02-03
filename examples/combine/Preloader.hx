package;

import flash.events.Event;
import flash.display.Sprite;
import flash.text.TextField;
import flash.Lib;

class Preloader extends Sprite {
	static function main() {
		Lib.current.addChild(new Preloader());
	}
	function new() {
		super();
		if(stage!=null) init();
		else addEventListener(Event.ADDED_TO_STAGE,init);
	}
	function init(?ev) {
		if(ev!=null) removeEventListener(Event.ADDED_TO_STAGE,init);

		//preloader shit
		var txt = new TextField();
		txt.text = "in Preloader!";
		addChild(txt);
		txt.x = Lib.current.stage.stageWidth/2;
		txt.y = Lib.current.stage.stageHeight/2;

		haxe.Timer.delay(function () {
			Lib.current.dispatchEvent(new Event("nextFrame"));
		}, 2000);
	}
}

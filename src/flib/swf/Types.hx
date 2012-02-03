package flib.swf;
import haxe.io.Bytes;
import haxe.Int32;
typedef Swf={
    var compress:Bool;
    var version:Int;
    var width:Int;
    var height:Int;
    var framerate:Float;
    var framecount:Int;
    var tags:Array<Tag>;
}
typedef RECT={
    var xmin:Int;
    var xmax:Int;
    var ymin:Int;
    var ymax:Int;
}
enum Tag{
    tUnknown(tagcode:Int,data:Bytes);
    tFileAttributes(directBlit:Bool,useGPU:Bool,hasMetadata:Bool,useAS3:Bool,useNetwork:Bool);
    tEnd;
    tDoABC(abc:Bytes);
    tDefABC(lazy:Bool,name:String,abc:Bytes);
    tDefineBinaryData(tag:Int,data:Bytes);
    tSetBackgroundColor(rgb:Int);
    tShowFrame;
    tSymbolClass(symbols:Array<{
        tag:Int,name:String
    }
    >);
}
class TagId{
    public static inline var End=0;
    public static inline var ShowFrame=1;
    public static inline var SetBackgroundColor=9;
    public static inline var FileAttributes=69;
    public static inline var DoABC=72;
    public static inline var DefABC=82;
    public static inline var DefineBinaryData=87;
    public static inline var SymbolClass=76;
}

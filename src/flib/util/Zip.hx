package flib.util;
import haxe.io.Bytes;
#if neko import neko.zip.Uncompress;
import neko.zip.Compress;
#elseif cpp import cpp.zip.Uncompress;
import cpp.zip.Compress;
#elseif flash9 import flash.utils.ByteArray;
#end class Zip{
    public static function uncompress(bytes:Bytes):Bytes{
        #if(neko||cpp)return Uncompress.run(bytes);
        #elseif flash9 var data=bytes.getData();
        data.uncompress();
        return Bytes.ofData(data);
        #else throw "Operation not supported on current platform";
        #end
    }
    public static function compress(bytes:Bytes):Bytes{
        #if(neko||cpp)return Compress.run(bytes,-1);
        #elseif flash9 var data=bytes.getData();
        data.compress();
        return Bytes.ofData(data);
        #else throw "Operation not supported on current platform";
        #end
    }
}

package flib.util;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import haxe.Int32;
class BitFields{
    public inline static function bits_signed(v:Int32){
        if(Int32.compare(v,(Int32.ofInt(0)))==0)return 0;
        else if(Int32.compare(v,(Int32.make(0xffff,0xffff)))==0)return 2;
        else{
            var sign=if(Int32.compare(v,(Int32.ofInt(0)))<0)(Int32.ofInt(1))else(Int32.ofInt(0));
            var cbit=31;
            while(Int32.compare((Int32.ushr((Int32.and(v,(Int32.shl((Int32.ofInt(1)),cbit)))),cbit)),sign)==0)cbit--;
            return cbit+2;
        }
    }
    public inline static function bits_unsigned(v:Int32){
        if(Int32.compare(v,(Int32.ofInt(0)))==0)return 0;
        else{
            var cbit=31;
            while(Int32.compare((Int32.ushr((Int32.and(v,(Int32.shl((Int32.ofInt(1)),cbit)))),cbit)),(Int32.ofInt(0)))==0)cbit--;
            return cbit+1;
        }
    }
    public inline static function floating_int(v:Float){
        var sbot=Std.int(v*65536.0)&0xffff;
        if(sbot<0)sbot=-sbot;
        var stop=Std.int(v);
        if(stop<0)stop=-stop;
        var vt=(Int32.or((Int32.ofInt(sbot)),(Int32.shl((Int32.ofInt(stop)),16))));
        if(v<0)vt=(Int32.neg(vt));
        return vt;
    }
    public inline static function bits_floating(v:Float)return bits_signed(floating_int(v))
}

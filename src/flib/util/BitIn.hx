package flib.util;
import haxe.Int32;
import haxe.io.Input;
import flib.util.BitFields;
class BitIn{
    public var o:Input;
    public var bit:Int;
    public var cbyte:Int;
    private var readBytes:Int;
    public function new(o:Input){
        this.o=o;
        readBytes=0;
        bit=0;
        cbyte=0;
    }
    private inline function readBits(num:Int){
        var ret=(Int32.ofInt(0));
        for(i in 0...num){
            if(bit==0){
                cbyte=o.readByte();
                readBytes++;
            }
            var pos=7-bit;
            var mask=1<<pos;
            var bitval=(Int32.ofInt((cbyte&mask)>>>pos));
            ret=(Int32.or(ret,(Int32.shl(bitval,num-i-1))));
            if(++bit==8)bit=0;
        }
        return ret;
    }
    public inline function flushBits(){
        if(bit!=0)readBits(8-bit);
        readBytes=0;
    }
    public inline function getBytes(){
        return readBytes;
    }
    public inline function read(num:Int32){
        flushBits();
        if((Int32.compare(num,(Int32.make(0x7fff,0xffff)))<0)&&(Int32.compare(num,(Int32.ofInt(0)))>=0))return o.read((Int32.toNativeInt(num)));
        else return null;
    }
    public inline function readAll(){
        flushBits();
        return o.readAll();
    }
    public inline function readByte(){
        flushBits();
        return o.readByte();
    }
    public inline function readUInt16(){
        flushBits();
        return o.readUInt16();
    }
    public inline function readUInt24(){
        flushBits();
        return o.readUInt24();
    }
    public inline function readInt8(){
        flushBits();
        return o.readInt8();
    }
    public inline function readInt16(){
        flushBits();
        return o.readInt16();
    }
    public inline function readInt24(){
        flushBits();
        return o.readInt24();
    }
    public inline function readInt32(){
        flushBits();
        return o.readInt32();
    }
    public inline function readDouble(){
        flushBits();
        return o.readDouble();
    }
    public inline function readUnsigned(nb:Int)return readBits(nb)public inline function readSigned(nb:Int){
        if(nb==0)return(Int32.ofInt(0));
        else{
            var uv=readBits(nb);
            var sign=(Int32.ushr((Int32.and(uv,(Int32.shl((Int32.ofInt(1)),nb-1)))),nb-1));
            for(i in nb...32)uv=(Int32.or(uv,(Int32.shl(sign,i))));
            return uv;
        }
    }
    public inline function readFloating(nb:Int){
        if(nb==0)return 0.0;
        else{
            var uv=readSigned(nb);
            var neg=(Int32.compare(uv,(Int32.ofInt(0)))<0);
            if(neg)uv=(Int32.neg(uv));
            var top=(Int32.toNativeInt((Int32.ushr(uv,16))));
            var bot=(Int32.toNativeInt((Int32.and(uv,(Int32.ofInt(0xffff))))));
            var val=bot/65536.0+top;
            if(neg)val=-val;
            return val;
        }
    }
    public inline function encReadUnsigned30()return(Int32.toNativeInt((Int32.and(encReadUnsigned(),(Int32.make(0x3fff,0xffff))))))public inline function encReadUnsigned(){
        return encReadSigned();
    }
    private inline function pad(num:Int32,bit:Int){
        if(Int32.compare((Int32.ofInt(0)),(Int32.and(num,(Int32.shl((Int32.ofInt(1)),bit-1)))))!=0)num=(Int32.or(num,(Int32.shl((Int32.ushr((Int32.make(0xffff,0xffff)),bit)),bit))));
        return num;
    }
    public inline function encReadSigned(){
        var a=readByte();
        if(a<128)return(Int32.ofInt(a));
        else{
            a&=0x7f;
            var b=readByte();
            if(b<128)return(Int32.ofInt((b<<7)|a));
            else{
                b&=0x7f;
                var c=readByte();
                if(c<128)return(Int32.ofInt((c<<14)|(b<<7)|a));
                else{
                    c&=0x7f;
                    var d=readByte();
                    if(d<128)return(Int32.ofInt((d<<21)|(c<<14)|(b<<7)|a));
                    else{
                        d&=0x7f;
                        var e=readByte();
                        var small=(Int32.ofInt((d<<21)|(c<<14)|(b<<7)|a));
                        var big=(Int32.shl((Int32.ofInt(e)),28));
                        return(Int32.or(big,small));
                    }
                }
            }
        }
    }
    public inline function readFixed(){
        var bot=readUInt16();
        var top=readInt16();
        return top+bot/65536.0;
    }
    public inline function readFixed8(){
        var bot=readByte();
        var top=readInt8();
        return top+bot/256.0;
    }
    public inline function readFloat16(){
        var b=readByte();
        var a=readByte();
        var sign=a>>>7;
        var expo=(a&0x7c)>>>2;
        var mant=((a&0x03)<<8)|b;
        if(expo==2){
            if(mant==0)return 0.0;
            else return Math.pow(-1,sign)*mant/1024.0*Math.pow(2,-15);
        }
        else if(expo==0x1f){
            if(mant==0){
                if(sign==0)return Math.POSITIVE_INFINITY;
                else return Math.NEGATIVE_INFINITY;
            }
            else return Math.NaN;
        }
        else return Math.pow(-1,sign)*(1+mant/1024.0)*Math.pow(2,expo-16);
    }
    public inline function readString(){
        var ret=new StringBuf();
        var ch;
        while((ch=readByte())!=0)ret.addChar(ch);
        return ret.toString();
    }
    public inline function readStringNum(num:Int){
        var ret=new StringBuf();
        for(i in 0...num)ret.addChar(readByte());
        return ret.toString();
    }
}

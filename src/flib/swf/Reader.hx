package flib.swf;
import flib.swf.Types;
import flib.util.BitFields;
import flib.util.BitIn;
import flib.util.Zip;
import haxe.io.Input;
import haxe.io.BytesOutput;
import haxe.io.BytesInput;
import haxe.io.Bytes;
import haxe.Int32;
class Reader{
    private var o:BitIn;
    public function new(o:Input){
        this.o=new BitIn(o);
    }
    public function readSwf(){
        var c0=o.readByte();
        var c1=o.readByte();
        var c2=o.readByte();
        if((c0!=67&&c0!=70)||c1!=87||c2!=83)throw "Swf ID =/= (C|F)WS";
        var compressed=c0==67;
        var version=o.readByte();
        var fileLength=o.readInt32();
        if(compressed){
            var rest=o.readAll();
            var bar=new BytesOutput();
            bar.writeBytes(rest,0,rest.length);
            o=new BitIn(new BytesInput(Zip.uncompress(bar.getBytes())));
        }
        var stage=readRect();
        var framerate=o.readFixed8();
        var framecount=o.readUInt16();
        var tags=readTagList();
        return{
            compress:compressed,version:version,width:Std.int((stage.xmax-stage.xmin)/20),height:Std.int((stage.ymax-stage.ymin)/20),framerate:framerate,framecount:framecount,tags:tags
        };
    }
    private function readTagList(){
        var tags=new Array<Tag>();
        while(true){
            var tag=readTag();
            if(tag==null){
                tags.push(tEnd);
                break;
            }
            tags.push(tag);
        }
        return tags;
    }
    private function readTag(){
        var tagcl=o.readUInt16();
        var tagc=tagcl>>>6;
        var tagl=(Int32.ofInt(tagcl&0x3f));
        if((Int32.toNativeInt(tagl))==0x3f)tagl=o.readInt32();
        return switch(tagc){
            default:tUnknown(tagc,o.read(tagl));
            case TagId.FileAttributes:o.flushBits();
            o.readUnsigned(1);
            var dblit=(Int32.compare(o.readUnsigned(1),(Int32.ofInt(1)))==0);
            var ugpu=(Int32.compare(o.readUnsigned(1),(Int32.ofInt(1)))==0);
            var hmeta=(Int32.compare(o.readUnsigned(1),(Int32.ofInt(1)))==0);
            var uas3=(Int32.compare(o.readUnsigned(1),(Int32.ofInt(1)))==0);
            o.readUnsigned(2);
            var unet=(Int32.compare(o.readUnsigned(1),(Int32.ofInt(1)))==0);
            o.readUnsigned(24);
            tFileAttributes(dblit,ugpu,hmeta,uas3,unet);
            case TagId.End:null;
            case TagId.DoABC:tDoABC(o.read(tagl));
            case TagId.DefABC:var lazy=(Int32.compare(o.readInt32(),(Int32.ofInt(1)))==0);
            var name=o.readString();
            tDefABC(lazy,name,o.read((Int32.sub(tagl,(Int32.ofInt(4+name.length+1))))));
            case TagId.DefineBinaryData:var tag=o.readUInt16();
            o.readInt32();
            var data=o.read((Int32.sub(tagl,Int32.ofInt(8))));
            tDefineBinaryData(tag,data);
            case TagId.SetBackgroundColor:var r=o.readByte();
            var g=o.readByte();
            var b=o.readByte();
            tSetBackgroundColor((r<<16)|(g<<8)|b);
            case TagId.ShowFrame:tShowFrame;
            case TagId.SymbolClass:var symbols:Array<{
                tag:Int,name:String
            }
            >=[];
            var num=o.readUInt16();
            while(num-->0){
                var tag=o.readUInt16();
                var str=o.readString();
                symbols.push({
                    tag:tag,name:str
                });
            }
            tSymbolClass(symbols);
        };
    }
    private inline function readRect(){
        o.flushBits();
        var nb=(Int32.toNativeInt(o.readUnsigned(5)));
        return{
            xmin:(Int32.toNativeInt(o.readSigned(nb))),xmax:(Int32.toNativeInt(o.readSigned(nb))),ymin:(Int32.toNativeInt(o.readSigned(nb))),ymax:(Int32.toNativeInt(o.readSigned(nb)))
        }
    }
}

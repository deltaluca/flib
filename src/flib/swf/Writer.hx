package flib.swf;
import flib.swf.Types;
import flib.util.BitFields;
import flib.util.BitOut;
import flib.util.Zip;
import haxe.io.Output;
import haxe.io.BytesOutput;
import haxe.io.BytesInput;
import haxe.io.Bytes;
import haxe.Int32;
class Writer{
    private var o:BitOut;
    private var origo:Array<BitOut>;
    private var byteso:Array<BytesOutput>;
    private function pushOut(){
        origo.push(o);
        var bytesout=new BytesOutput();
        byteso.push(bytesout);
        o=new BitOut(bytesout);
    }
    private function popOut(){
        var data_o=o;
        o=origo.pop();
        var data_bytes=byteso.pop().getBytes();
        return data_bytes;
    }
    public function new(o:Output){
        this.o=new BitOut(o);
        origo=new Array<BitOut>();
        byteso=new Array<BytesOutput>();
    }
    public function writeSwf(ret:Swf){
        var c0=if(ret.compress)67 else 70;
        o.writeByte(c0);
        o.writeByte(87);
        o.writeByte(83);
        o.writeByte(ret.version);
        pushOut();
        writeRect({
            xmin:0,ymin:0,xmax:ret.width*20,ymax:ret.height*20
        });
        o.writeFixed8(ret.framerate);
        o.writeUInt16(ret.framecount);
        writeTagList(ret.tags);
        var bar=popOut();
        o.writeInt32((Int32.ofInt(bar.length+8)));
        if(ret.compress)bar=Zip.compress(bar);
        o.writeBytes(bar,0,bar.length);
    }
    public inline function writeTagHeader(tagc,tagl){
        var tagcl=tagc<<6;
        if(tagl>=0x3f||tagc==20||tagc==36||tagc==19||tagc==21||tagc==35||tagc==90){
            tagcl|=0x3f;
            o.writeUInt16(tagcl);
            o.writeInt32((Int32.ofInt(tagl)));
        }
        else{
            tagcl|=tagl;
            o.writeUInt16(tagcl);
        }
    }
    public function writeTagList(tags:Array<Tag>){
        for(tag in tags){
            switch(tag){
                case tUnknown(tagc,data):writeTagHeader(tagc,data.length);
                o.writeBytes(data,0,data.length);
                case tEnd:writeTagHeader(TagId.End,0);
                case tFileAttributes(dblit,gpu,meta,as3,net):writeTagHeader(TagId.FileAttributes,4);
                o.writeUnsigned((Int32.ofInt(0)),1);
                o.writeUnsigned(dblit?(Int32.ofInt(1)):(Int32.ofInt(0)),1);
                o.writeUnsigned(gpu?(Int32.ofInt(1)):(Int32.ofInt(0)),1);
                o.writeUnsigned(meta?(Int32.ofInt(1)):(Int32.ofInt(0)),1);
                o.writeUnsigned(as3?(Int32.ofInt(1)):(Int32.ofInt(0)),1);
                o.writeUnsigned((Int32.ofInt(0)),2);
                o.writeUnsigned(net?(Int32.ofInt(1)):(Int32.ofInt(0)),1);
                o.writeUnsigned((Int32.ofInt(0)),24);
                case tDoABC(abc):pushOut();
                o.writeBytes(abc,0,abc.length);
                popWriteHeader(TagId.DoABC);
                case tDefABC(lazy,name,abc):pushOut();
                o.writeInt32(lazy?(Int32.ofInt(1)):(Int32.ofInt(0)));
                o.writeString(name);
                o.writeBytes(abc,0,abc.length);
                popWriteHeader(TagId.DefABC);
                case tDefineBinaryData(tag,data):pushOut();
                o.writeUInt16(tag);
                o.writeInt32(Int32.ofInt(0));
                o.writeBytes(data,0,data.length);
                popWriteHeader(TagId.DefineBinaryData);
                case tSetBackgroundColor(rgb):pushOut();
                o.writeByte((rgb>>16)&0xff);
                o.writeByte((rgb>>8)&0xff);
                o.writeByte(rgb&0xff);
                popWriteHeader(TagId.SetBackgroundColor);
                case tShowFrame:pushOut();
                popWriteHeader(TagId.ShowFrame);
                case tSymbolClass(symbols):pushOut();
                o.writeUInt16(symbols.length);
                for(sym in symbols){
                    o.writeUInt16(sym.tag);
                    o.writeString(sym.name);
                }
                popWriteHeader(TagId.SymbolClass);
                default:
            }
        }
    }
    private inline function popWriteHeader(tagc){
        var bar=popOut();
        writeTagHeader(tagc,bar.length);
        o.writeBytes(bar,0,bar.length);
    }
    public inline function writeRect(r){
        o.flushBits();
        var rs=[r.xmin,r.xmax,r.ymin,r.ymax];
        var nb={
            var nb=0;
            for(x in rs){
                var nbn=BitFields.bits_signed((Int32.ofInt(x)));
                if(nbn>nb)nb=nbn;
            }
            nb;
        };
        o.writeUnsigned((Int32.ofInt(nb)),5);
        o.writeSigned((Int32.ofInt(r.xmin)),nb);
        o.writeSigned((Int32.ofInt(r.xmax)),nb);
        o.writeSigned((Int32.ofInt(r.ymin)),nb);
        o.writeSigned((Int32.ofInt(r.ymax)),nb);
    }
}

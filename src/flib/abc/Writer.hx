package flib.abc;
import flib.abc.Types;
import flib.util.BitIn;
import flib.util.BitOut;
import flib.util.Zip;
import flib.util.BitFields;
import haxe.io.Output;
import haxe.Int32;
class Writer{
    private var o:BitOut;
    public function new(o:Output){
        this.o=new BitOut(o);
    }
    public function writeCPool(cpool:CPool){
        {
            var count=cpool.ints.length;
            if(count!=0)count++;
            o.encWriteUnsigned30(count);
            for(i in cpool.ints)o.encWriteSigned(i);
        };
        {
            var count=cpool.uints.length;
            if(count!=0)count++;
            o.encWriteUnsigned30(count);
            for(i in cpool.uints)o.encWriteUnsigned(i);
        };
        {
            var count=cpool.doubles.length;
            if(count!=0)count++;
            o.encWriteUnsigned30(count);
            for(i in cpool.doubles)o.writeDouble(i);
        };
        {
            var count=cpool.strings.length;
            if(count!=0)count++;
            o.encWriteUnsigned30(count);
            for(i in cpool.strings){
                o.encWriteUnsigned30(i.length);
                o.writeStringNum(i,i.length);
            };
        };
        {
            var count=cpool.nspaces.length;
            if(count!=0)count++;
            o.encWriteUnsigned30(count);
            for(i in cpool.nspaces){
                writeCTYPE(i.type);
                o.encWriteUnsigned30(i.name);
            };
        };
        {
            var count=cpool.nssets.length;
            if(count!=0)count++;
            o.encWriteUnsigned30(count);
            for(i in cpool.nssets){
                o.encWriteUnsigned30(i.length);
                for(j in i)o.encWriteUnsigned30(j);
            };
        };
        {
            var count=cpool.names.length;
            if(count!=0)count++;
            o.encWriteUnsigned30(count);
            for(i in cpool.names){
                switch(i){
                    case mQName(a,b,c):o.writeByte(a?0x0d:0x07);
                    o.encWriteUnsigned30(b);
                    o.encWriteUnsigned30(c);
                    case mRTQName(a,b):o.writeByte(a?0x10:0x0f);
                    o.encWriteUnsigned30(b);
                    case mRTQNameL(a):o.writeByte(a?0x12:0x11);
                    case mMultiname(a,b,c):o.writeByte(a?0x0e:0x09);
                    o.encWriteUnsigned30(b);
                    o.encWriteUnsigned30(c);
                    case mMultinameL(a,b):o.writeByte(a?0x1c:0x1b);
                    o.encWriteUnsigned30(b);
                    case mGenericName(t,p):o.writeByte(0x1d);
                    o.encWriteUnsigned30(t);
                    o.encWriteUnsigned30(p.length);
                    for(i in p)o.encWriteUnsigned30(i);
                    default:
                }
            };
        };
    }
    public function writeCTYPE(x:NSType){
        var ret=switch(x){
            case nsPrivateNs:0x05;
            case nsNamespace:0x08;
            case nsPackageNs:0x16;
            case nsPackIntNs:0x17;
            case nsProtectNs:0x18;
            case nsExplicitNs:0x19;
            case nsStatProtNs:0x1a;
            case nsOther(o):o;
        }
        o.writeByte(ret);
    }
    public function writeTrait(t:Trait){
        o.encWriteUnsigned30(t.name);
        var flag=if(t.metadata.length>0)0x40 else 0;
        if(t.final)flag|=0x10;
        if(t.overriden)flag|=0x20;
        switch(t.data){
            case tdSlot(const,a,b,c,d):flag|=const?6:0;
            o.writeByte(flag);
            o.encWriteUnsigned30(a);
            o.encWriteUnsigned30(b);
            o.encWriteUnsigned30(c);
            if(c!=0)writeCTYPE(d);
            case tdClass(a,b):flag|=4;
            o.writeByte(flag);
            o.encWriteUnsigned30(a);
            o.encWriteUnsigned30(b);
            case tdFunction(a,b):flag|=5;
            o.writeByte(flag);
            o.encWriteUnsigned30(a);
            o.encWriteUnsigned30(b);
            case tdMethod(x,a,b):flag|=switch(x){
                case mtMethod:1;
                case mtGetter:2;
                case mtSetter:3;
            };
            o.writeByte(flag);
            o.encWriteUnsigned30(a);
            o.encWriteUnsigned30(b);
        }
        if(t.metadata.length>0){
            o.encWriteUnsigned30(t.metadata.length);
            for(i in t.metadata)o.encWriteUnsigned30(i);
        }
    }
    public function writeABC(abc:ABC){
        o.writeUInt16(abc.minor);
        o.writeUInt16(abc.major);
        writeCPool(abc.cpool);
        {
            if(true)o.encWriteUnsigned30(abc.methods.length);
            for(i in abc.methods){
                o.encWriteUnsigned30(i.param_types.length);
                o.encWriteUnsigned30(i.return_type);
                for(x in i.param_types)o.encWriteUnsigned30(x);
                o.encWriteUnsigned30(i.name);
                var flags=0;
                if(i.need_arg_obj)flags|=1;
                if(i.need_act)flags|=2;
                if(i.need_rest)flags|=4;
                if(i.set_dxns)flags|=0x40;
                if(i.optionals.length>0)flags|=8;
                if(i.param_names.length>0)flags|=0x80;
                o.writeByte(flags);
                if(i.optionals.length>0){
                    o.encWriteUnsigned30(i.optionals.length);
                    for(x in i.optionals){
                        o.encWriteUnsigned30(x.value);
                        writeCTYPE(x.kind);
                    }
                }
                for(x in i.param_names)o.encWriteUnsigned30(x);
            };
        };
        {
            if(true)o.encWriteUnsigned30(abc.metadata.length);
            for(i in abc.metadata){
                o.encWriteUnsigned30(i.name);
                o.encWriteUnsigned30(i.items.length);
                for(x in i.items){
                    o.encWriteUnsigned30(x.key);
                    if(x.key!=0)o.encWriteUnsigned30(x.value);
                }
            };
        };
        {
            if(true)o.encWriteUnsigned30(abc.instances.length);
            for(i in abc.instances){
                o.encWriteUnsigned30(i.name);
                o.encWriteUnsigned30(i.superc);
                o.writeByte(i.flags);
                if((i.flags&0x08)!=0)o.encWriteUnsigned30(i.ns);
                o.encWriteUnsigned30(i.interfaces.length);
                for(x in i.interfaces)o.encWriteUnsigned30(x);
                o.encWriteUnsigned30(i.iinit);
                o.encWriteUnsigned30(i.traits.length);
                for(x in i.traits)writeTrait(x);
            };
        };
        {
            if(false)o.encWriteUnsigned30(abc.classes.length);
            for(i in abc.classes){
                o.encWriteUnsigned30(i.cinit);
                o.encWriteUnsigned30(i.traits.length);
                for(x in i.traits)writeTrait(x);
            };
        };
        {
            if(true)o.encWriteUnsigned30(abc.scripts.length);
            for(i in abc.scripts){
                o.encWriteUnsigned30(i.init);
                o.encWriteUnsigned30(i.traits.length);
                for(x in i.traits)writeTrait(x);
            };
        };
        {
            if(true)o.encWriteUnsigned30(abc.mbodies.length);
            for(i in abc.mbodies){
                o.encWriteUnsigned30(i.method);
                o.encWriteUnsigned30(i.max_st);
                o.encWriteUnsigned30(i.l_cnt);
                o.encWriteUnsigned30(i.init_sc);
                o.encWriteUnsigned30(i.sc_depth);
                o.encWriteUnsigned30(i.avm.length);
                o.writeBytes(i.avm,0,i.avm.length);
                o.encWriteUnsigned30(i.exceptions.length);
                for(x in i.exceptions){
                    o.encWriteUnsigned30(x.from);
                    o.encWriteUnsigned30(x.to);
                    o.encWriteUnsigned30(x.target);
                    o.encWriteUnsigned30(x.exc_type);
                    o.encWriteUnsigned30(x.var_name);
                }
                o.encWriteUnsigned30(i.traits.length);
                for(x in i.traits)writeTrait(x);
            };
        };
    }
}

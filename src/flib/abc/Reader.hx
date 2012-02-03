package flib.abc;
import flib.abc.Types;
import flib.util.BitIn;
import flib.util.BitOut;
import flib.util.Zip;
import flib.util.BitFields;
import haxe.io.Input;
import haxe.Int32;
class Reader{
    private var o:BitIn;
    public function new(o:Input){
        this.o=new BitIn(o);
    }
    public function readABC(){
        var minor=o.readUInt16();
        var major=o.readUInt16();
        var cpool=readCPool();
        var methods={
            var cnt=o.encReadUnsigned30();
            var ret=[];
            for(i in 0...cnt)ret.push({
                var pcount=o.encReadUnsigned30();
                var retype=o.encReadUnsigned30();
                var ptypes=[];
                for(i in 0...pcount)ptypes.push(o.encReadUnsigned30());
                var name=o.encReadUnsigned30();
                var flags=o.readByte();
                var need_arg_obj=(flags&0x01)!=0;
                var need_act=(flags&0x02)!=0;
                var need_rest=(flags&0x04)!=0;
                var set_dxna=(flags&0x40)!=0;
                var options=[];
                if((flags&0x08)!=0){
                    var ocount=o.encReadUnsigned30();
                    for(i in 0...ocount){
                        var value=o.encReadUnsigned30();
                        var kind=readCTYPE(o.readByte());
                        options.push({
                            value:value,kind:kind
                        });
                    }
                }
                var pnames=[];
                if((flags&0x80)!=0)for(i in 0...pcount)pnames.push(o.encReadUnsigned30());
                {
                    return_type:retype,name:name,need_arg_obj:need_arg_obj,need_act:need_act,need_rest:need_rest,set_dxns:set_dxna,param_types:ptypes,param_names:pnames,optionals:options
                };
            });
            ret;
        };
        var metadata={
            var cnt=o.encReadUnsigned30();
            var ret=[];
            for(i in 0...cnt)ret.push({
                var name=o.encReadUnsigned30();
                var count=o.encReadUnsigned30();
                var items=[];
                for(i in 0...count){
                    var key=o.encReadUnsigned30();
                    var value=if(key!=0)o.encReadUnsigned30()else 0;
                    items.push({
                        key:key,value:value
                    });
                }
                {
                    name:name,items:items
                };
            });
            ret;
        };
        var instances={
            var cnt=o.encReadUnsigned30();
            var ret=[];
            for(i in 0...cnt)ret.push({
                var name=o.encReadUnsigned30();
                var superc=o.encReadUnsigned30();
                var flags=o.readByte();
                var ns=if((flags&0x08)!=0)o.encReadUnsigned30()else 0;
                var count=o.encReadUnsigned30();
                var interfaces=[];
                for(i in 0...count)interfaces.push(o.encReadUnsigned30());
                var iinit=o.encReadUnsigned30();
                var count=o.encReadUnsigned30();
                var traits=[];
                for(i in 0...count)traits.push(readTrait());
                {
                    name:name,superc:superc,ns:ns,iinit:iinit,flags:flags,interfaces:interfaces,traits:traits
                };
            });
            ret;
        };
        var classes={
            var cnt=instances.length;
            var ret=[];
            for(i in 0...cnt)ret.push({
                var cinit=o.encReadUnsigned30();
                var count=o.encReadUnsigned30();
                var traits=[];
                for(i in 0...count)traits.push(readTrait());
                {
                    cinit:cinit,traits:traits
                };
            });
            ret;
        };
        var scripts={
            var cnt=o.encReadUnsigned30();
            var ret=[];
            for(i in 0...cnt)ret.push({
                var init=o.encReadUnsigned30();
                var count=o.encReadUnsigned30();
                var traits=[];
                for(i in 0...count)traits.push(readTrait());
                {
                    init:init,traits:traits
                };
            });
            ret;
        };
        var mbodies={
            var cnt=o.encReadUnsigned30();
            var ret=[];
            for(i in 0...cnt)ret.push({
                var method=o.encReadUnsigned30();
                var max_st=o.encReadUnsigned30();
                var l_cnt=o.encReadUnsigned30();
                var init_sc=o.encReadUnsigned30();
                var sc_depth=o.encReadUnsigned30();
                var size=o.encReadUnsigned30();
                var avm=o.read((Int32.ofInt(size)));
                var count=o.encReadUnsigned30();
                var excs=[];
                for(i in 0...count)excs.push({
                    var a=o.encReadUnsigned30();
                    var b=o.encReadUnsigned30();
                    var c=o.encReadUnsigned30();
                    var d=o.encReadUnsigned30();
                    var e=o.encReadUnsigned30();
                    {
                        from:a,to:b,target:c,exc_type:d,var_name:e
                    };
                });
                var count=o.encReadUnsigned30();
                var traits=[];
                for(i in 0...count)traits.push(readTrait());
                {
                    method:method,max_st:max_st,l_cnt:l_cnt,init_sc:init_sc,sc_depth:sc_depth,avm:avm,exceptions:excs,traits:traits
                };
            });
            ret;
        };
        return{
            minor:minor,major:major,cpool:cpool,methods:methods,metadata:metadata,instances:instances,classes:classes,scripts:scripts,mbodies:mbodies
        };
    }
    public function readTrait(){
        var name=o.encReadUnsigned30();
        var flag=o.readByte();
        var dx=(flag&0xf);
        var data=if(dx==0||dx==6){
            var a=o.encReadUnsigned30();
            var b=o.encReadUnsigned30();
            var c=o.encReadUnsigned30();
            var d=if(c!=0)readCTYPE(o.readByte())else null;
            tdSlot(dx==6,a,b,c,d);
        }
        else if(dx==4){
            var a=o.encReadUnsigned30();
            var b=o.encReadUnsigned30();
            tdClass(a,b);
        }
        else if(dx==5){
            var a=o.encReadUnsigned30();
            var b=o.encReadUnsigned30();
            tdFunction(a,b);
        }
        else{
            var a=o.encReadUnsigned30();
            var b=o.encReadUnsigned30();
            tdMethod([mtMethod,mtGetter,mtSetter][dx-1],a,b);
        }
        var metadata=[];
        if((flag&0x40)!=0){
            var count=o.encReadUnsigned30();
            for(i in 0...count)metadata.push(o.encReadUnsigned30());
        }
        return{
            name:name,metadata:metadata,data:data,final:(flag&0x10)!=0,overriden:(flag&0x20)!=0
        };
    }
    public function readCTYPE(o:Int){
        return switch(o){
            case 0x05:nsPrivateNs;
            case 0x08:nsNamespace;
            case 0x16:nsPackageNs;
            case 0x17:nsPackIntNs;
            case 0x18:nsProtectNs;
            case 0x19:nsExplicitNs;
            case 0x1a:nsStatProtNs;
            default:nsOther(o);
        }
    }
    public function readCPool(){
        var ints={
            var ret=[];
            var count=o.encReadUnsigned30();
            if(count!=0)count--;
            for(i in 0...count)ret.push(o.encReadSigned());
            ret;
        };
        var uints={
            var ret=[];
            var count=o.encReadUnsigned30();
            if(count!=0)count--;
            for(i in 0...count)ret.push(o.encReadUnsigned());
            ret;
        };
        var doubles={
            var ret=[];
            var count=o.encReadUnsigned30();
            if(count!=0)count--;
            for(i in 0...count)ret.push(o.readDouble());
            ret;
        };
        var strings={
            var ret=[];
            var count=o.encReadUnsigned30();
            if(count!=0)count--;
            for(i in 0...count)ret.push({
                var size=o.encReadUnsigned30();
                o.readStringNum(size);
            });
            ret;
        };
        var nspaces={
            var ret=[];
            var count=o.encReadUnsigned30();
            if(count!=0)count--;
            for(i in 0...count)ret.push({
                var type=readCTYPE(o.readByte());
                var name=o.encReadUnsigned30();
                {
                    type:type,name:name
                };
            });
            ret;
        };
        var nssets={
            var ret=[];
            var count=o.encReadUnsigned30();
            if(count!=0)count--;
            for(i in 0...count)ret.push({
                var count=o.encReadUnsigned30();
                var nss=[];
                for(i in 0...count)nss.push(o.encReadUnsigned30());
                nss;
            });
            ret;
        };
        var names={
            var ret=[];
            var count=o.encReadUnsigned30();
            if(count!=0)count--;
            for(i in 0...count)ret.push({
                var kind=o.readByte();
                switch(kind){
                    case 0x07:var a=o.encReadUnsigned30();
                    var b=o.encReadUnsigned30();
                    mQName(false,a,b);
                    case 0x0d:var a=o.encReadUnsigned30();
                    var b=o.encReadUnsigned30();
                    mQName(true,a,b);
                    case 0x0f:var a=o.encReadUnsigned30();
                    mRTQName(false,a);
                    case 0x10:var a=o.encReadUnsigned30();
                    mRTQName(true,a);
                    case 0x11:mRTQNameL(false);
                    case 0x12:mRTQNameL(true);
                    case 0x09:var a=o.encReadUnsigned30();
                    var b=o.encReadUnsigned30();
                    mMultiname(false,a,b);
                    case 0x0e:var a=o.encReadUnsigned30();
                    var b=o.encReadUnsigned30();
                    mMultiname(true,a,b);
                    case 0x1b:var a=o.encReadUnsigned30();
                    mMultinameL(false,a);
                    case 0x1c:var a=o.encReadUnsigned30();
                    mMultinameL(true,a);
                    case 0x1d:var type=o.encReadUnsigned30();
                    var count=o.encReadUnsigned30();
                    var params=[];
                    for(i in 0...count)params.push(o.encReadUnsigned30());
                    mGenericName(type,params);
                }
            });
            ret;
        };
        return{
            ints:ints,uints:uints,doubles:doubles,strings:strings,nspaces:nspaces,nssets:nssets,names:names
        };
    }
}

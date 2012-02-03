package ;
import haxe.Int32;
import haxe.io.BytesOutput;
import haxe.io.BytesInput;
import haxe.io.Bytes;
import neko.Sys;
import neko.Lib;
import neko.io.File;
import neko.io.Path;
import flib.abc.Types;
import flib.swf.Types;
import flib.util.BitFields;
using StringTools;
typedef SIZE={
    size:Int,str:String
};
class Main{
    static function grab(src:String,keeplib=true):{
        swc:Bool,src:String,swf:Swf
    }
    {
        var swc=StringTools.endsWith(src,".swc");
        if(swc){
            #if windows if(Sys.command("7z",["-y","e",src,"library.swf"])!=0){
                Lib.println("ERROR please make sure 7z has been added to PATH variable");
                Sys.exit(1);
            }
            #elseif unix Sys.command("unzip",[src,"library.swf"]);
            #else Lib.println("Please specify compiler flag windows or unix on compilation of flib");
            Sys.exit(1);
            #end src="library.swf";
        }
        var inp=File.read(src,true);
        var reader=new flib.swf.Reader(inp);
        var swf=reader.readSwf();
        inp.close();
        if(swc&&!keeplib){
            #if windows Sys.command("del",["library.swf"]);
            #else Sys.command("rm",["library.swf"]);
            #end
        }
        return{
            swc:swc,src:src,swf:swf
        };
    }
    static function main(){
        var args=Sys.args();
        if(args.length<1){
            Lib.println("For help use --help option");
            Sys.exit(1);
        }
        if(args[0]=="--help"){
            Lib.println("Usage: flib lib.swf/swc");
            Lib.println("\tvar x(flibget_x,flibset_x), has 'x' removed, and flibget_x flibset_x turned to native getter/setters. flibget_x flibset_x must be inlined to avoid haxe code being destroyed");
            Lib.println("\t@:ns(\"flibdel\") inline function x() {} get's removed from the swc entirely, make sure this method is also inlined and is not used dynamicaly through down-casting/reflection or else it will break haxe code");
            Lib.println("\tfunction flibopts_#(){} with # replaced by integer, ensures that constructors for the class have the correct number of optional arguments set in the swf/swc as haxe makes them all optional");
            Lib.println("\n");
            Lib.println("Alternatively: flib --report lib.swf/swc to report method sizes throughout");
            Lib.println("\n");
            Lib.println("ALTERNATIVELY: flib --combine preloader.swf main.swf out.swf to combine the two swf's together into a single swf loading the preloader in first frame, and on dispatch of a flash event \"nextFrame\" will continue to frame 2 and load the main swf. Properties of the final swf is taken from main.swf (dimensions,bgcolor,fps)");
            Sys.exit(0);
        }
        switch(args[0]){
            case "--report":if(args.length<2){
                Lib.println("ERROR --report needs argument");
                Sys.exit(0);
            }
            report(args[1]);
            case "--combine":if(args.length<4){
                Lib.println("ERROR --combine needs 3 arguments");
                Sys.exit(0);
            }
            var pre=args[1];
            var main=args[2];
            var outf=args[3];
            combine(pre,main,outf);
            default:process(args[0]);
        }
    }
    static function report(src:String){
        var swf=grab(src,false).swf;
        var ret:Array<SIZE>=[];
        var cls=new Hash<Int>();
        for(tag in swf.tags){
            switch(tag){
                default:case tDoABC(abcdata):doreport(abcdata,ret,cls);
                case tDefABC(_,_,abcdata):doreport(abcdata,ret,cls);
            }
        }
        var total=0;
        ret.sort(function(a,b)return b.size-a.size);
        for(i in ret){
            Lib.println(i.str);
            total+=i.size;
        }
        Lib.println("\n");
        Lib.println("--------");
        var carr=new Array<SIZE>();
        for(x in cls.keys())carr.push({
            size:cls.get(x),str:x
        });
        carr.sort(function(a,b)return b.size-a.size);
        for(i in carr){
            var str=""+duh(i.size);
            while(str.length<10)str+=" ";
            str+=i.str;
            Lib.println(str);
        }
        Lib.println("\n");
        Lib.println("--------");
        Lib.println("total: "+duh(total));
    }
    static function process(src:String){
        var swcswf=grab(src);
        var swf=swcswf.swf;
        var ntags=[];
        for(tag in swf.tags){
            ntags.push(switch(tag){
                default:tag;
                case tDoABC(abcdata):tDoABC(doABC(abcdata));
                case tDefABC(lazy,name,abcdata):tDefABC(lazy,name,doABC(abcdata));
            });
        }
        swf.tags=ntags;
        #if windows Sys.command("del",[swcswf.src]);
        #else Sys.command("rm",[swcswf.src]);
        #end var out=File.write(swcswf.src,true);
        var writer=new flib.swf.Writer(out);
        writer.writeSwf(swf);
        out.flush();
        out.close();
        if(swcswf.swc){
            #if windows Sys.command("7z",["-y","a","-tzip",src,"library.swf"]);
            Sys.command("del",["library.swf"]);
            #else Sys.command("zip",[src,"-d","library.swf"]);
            Sys.command("zip",[src,"library.swf"]);
            Sys.command("rm",["library.swf"]);
            #end
        }
    }
    static function combine(pre_src:String,main_src:String,out_src:String){
        var mainswf=grab(main_src,false).swf;
        var fattr:Tag=null;
        var setbg:Tag=null;
        for(tag in mainswf.tags){
            switch(tag){
                default:case tFileAttributes(_,_,_,_,_):fattr=tag;
                case tSetBackgroundColor(_):setbg=tag;
            }
            if(fattr!=null&&setbg!=null)break;
        }
        var bin=Sys.getEnv("FLIB");
        if(bin==null){
            Lib.println("ERROR: Please make sure FLIB env-var is setup to point to the flib bin for template.swf");
            Sys.exit(1);
        }
        var template=grab(bin+"/template.swf").swf;
        var inp=File.read(pre_src,true);
        var predat=tDefineBinaryData(0xfff0,inp.readAll());
        inp.close();
        var inp=File.read(main_src,true);
        var maindat=tDefineBinaryData(0xfff2,inp.readAll());
        inp.close();
        template.tags.shift();
        template.tags.shift();
        template.tags.unshift(setbg);
        template.tags.unshift(fattr);
        template.tags.splice(1,1);
        template.tags.insert(5,predat);
        template.tags.insert(7,maindat);
        var symbols=switch(template.tags[4]){
            default:null;
            case tSymbolClass(xs):xs;
        };
        symbols.push({
            tag:0xfff0,name:"LoaderBytes"
        });
        template.tags.insert(7,tSymbolClass([{
            tag:0xfff2,name:"MainBytes"
        }
        ]));
        var out=File.write(out_src,true);
        var writer=new flib.swf.Writer(out);
        writer.writeSwf(template);
        out.flush();
        out.close();
    }
    private static inline function duh(bytes:Int){
        if(bytes<1024)return bytes+"B";
        else if(bytes<1024*1024)return(Std.int((bytes/1024)*100)/100)+"KiB";
        else return(Std.int((bytes/1024/1024)*100)/100)+"MiB";
    }
    private static function doreport(abcdata:Bytes,ret:Array<SIZE>,cls:Hash<Int>){
        var reader=new flib.abc.Reader(new BytesInput(abcdata));
        var abc=reader.readABC();
        var names=new Array<String>();
        var cnames=new Array<String>();
        for(i in abc.instances){
            var clsname=({
                var n2=abc.cpool.names[i.name-1];
                switch(n2){
                    case mQName(_,ns,name):var pck=abc.cpool.nspaces[ns-1];
                    var pckstr=abc.cpool.strings[pck.name-1];
                    var nstr=abc.cpool.strings[name-1];
                    if(pckstr.length!=0)pckstr+"."+nstr;
                    else nstr;
                    case mRTQName(_,name):abc.cpool.strings[name-1];
                    case mMultiname(_,name,_):abc.cpool.strings[name-1];
                    default:"";
                }
            });
            for(t in i.traits){
                switch(t.data){
                    case tdMethod(type,_,mid):var name=({
                        var n2=abc.cpool.names[t.name-1];
                        switch(n2){
                            case mQName(_,ns,name):var pck=abc.cpool.nspaces[ns-1];
                            var pckstr=abc.cpool.strings[pck.name-1];
                            var nstr=abc.cpool.strings[name-1];
                            if(pckstr.length!=0)pckstr+"."+nstr;
                            else nstr;
                            case mRTQName(_,name):abc.cpool.strings[name-1];
                            case mMultiname(_,name,_):abc.cpool.strings[name-1];
                            default:"";
                        }
                    });
                    if(Type.enumEq(type,mtMethod))names[mid]=clsname+"::"+name;
                    else if(Type.enumEq(type,mtGetter))names[mid]=clsname+"::set "+name;
                    else names[mid]=clsname+"::get "+name;
                    cnames[mid]=clsname;
                    default:
                }
            }
            names[i.iinit]=clsname+"::new";
            cnames[i.iinit]=clsname;
        }
        var ind=0;
        for(i in abc.classes){
            var clsname=({
                var n2=abc.cpool.names[abc.instances[ind].name-1];
                switch(n2){
                    case mQName(_,ns,name):var pck=abc.cpool.nspaces[ns-1];
                    var pckstr=abc.cpool.strings[pck.name-1];
                    var nstr=abc.cpool.strings[name-1];
                    if(pckstr.length!=0)pckstr+"."+nstr;
                    else nstr;
                    case mRTQName(_,name):abc.cpool.strings[name-1];
                    case mMultiname(_,name,_):abc.cpool.strings[name-1];
                    default:"";
                }
            });
            ind++;
            for(t in i.traits){
                switch(t.data){
                    case tdMethod(type,_,mid):var name=({
                        var n2=abc.cpool.names[t.name-1];
                        switch(n2){
                            case mQName(_,ns,name):var pck=abc.cpool.nspaces[ns-1];
                            var pckstr=abc.cpool.strings[pck.name-1];
                            var nstr=abc.cpool.strings[name-1];
                            if(pckstr.length!=0)pckstr+"."+nstr;
                            else nstr;
                            case mRTQName(_,name):abc.cpool.strings[name-1];
                            case mMultiname(_,name,_):abc.cpool.strings[name-1];
                            default:"";
                        }
                    });
                    if(Type.enumEq(type,mtMethod))names[mid]=clsname+"."+name;
                    else if(Type.enumEq(type,mtGetter))names[mid]=clsname+".set "+name;
                    else names[mid]=clsname+".get "+name;
                    cnames[mid]=clsname;
                    default:
                }
            }
            names[i.cinit]=clsname+".__init__";
            cnames[i.cinit]=clsname;
        }
        for(m in abc.mbodies){
            if(names[m.method]!=null){
                var str=""+duh(m.avm.length);
                while(str.length<10)str+=" ";
                str+=names[m.method];
                ret.push({
                    size:m.avm.length,str:str
                });
                var cname=cnames[m.method];
                var cn=if(cls.exists(cname))cls.get(cname)else 0;
                cls.set(cname,cn+m.avm.length);
            }
        }
    }
    private static function doABC(abcdata:Bytes){
        var reader=new flib.abc.Reader(new BytesInput(abcdata));
        var abc=reader.readABC();
        for(i in abc.instances){
            var meth=abc.methods[i.iinit];
            var count=-1;
            for(t in i.traits){
                switch(t.data){
                    case tdMethod(type,x,y):if(Type.enumEq(type,mtMethod)){
                        var flibd=({
                            var n2=abc.cpool.names[t.name-1];
                            switch(n2){
                                case mQName(_,ns,name):var n3=abc.cpool.nspaces[ns-1];
                                abc.cpool.strings[n3.name-1];
                                default:"";
                            }
                        });
                        var name=({
                            var n2=abc.cpool.names[t.name-1];
                            switch(n2){
                                case mQName(_,_,name):abc.cpool.strings[name-1];
                                case mRTQName(_,name):abc.cpool.strings[name-1];
                                case mMultiname(_,name,_):abc.cpool.strings[name-1];
                                default:"";
                            }
                        });
                        if(name.substr(0,9)=="flibopts_")count=Std.parseInt(name.substr(9));
                    }
                    default:
                }
            }
            if(count==-1)continue;
            while(meth.optionals.length!=count)meth.optionals.shift();
        }
        var methodid=new Array<Int>();
        var id=0;
        for(i in abc.methods)methodid.push(id++);
        for(i in abc.instances){
            var properties=new Hash<{
                x:Trait,y:Trait
            }
            >();
            var flibrem=new Hash<Void>();
            for(t in i.traits){
                switch(t.data){
                    case tdMethod(type,x,y):if(Type.enumEq(type,mtMethod)){
                        var flibd=({
                            var n2=abc.cpool.names[t.name-1];
                            switch(n2){
                                case mQName(_,ns,name):var n3=abc.cpool.nspaces[ns-1];
                                abc.cpool.strings[n3.name-1];
                                default:"";
                            }
                        });
                        var name=({
                            var n2=abc.cpool.names[t.name-1];
                            switch(n2){
                                case mQName(_,_,name):abc.cpool.strings[name-1];
                                case mRTQName(_,name):abc.cpool.strings[name-1];
                                case mMultiname(_,name,_):abc.cpool.strings[name-1];
                                default:"";
                            }
                        });
                        if(flibd=="flibdel")flibrem.set(name,null);
                        if(flibd==""&&name.substr(0,8)=="flibdel_"&&name.length>8){
                            flibrem.set(name,null);
                            flibrem.set(name.substr(8),null);
                        }
                        if(name.length>8&&name.startsWith("flibset_")){
                            var varn=name.substr(8);
                            if(properties.exists(varn))properties.get(varn).y=t;
                            else properties.set(varn,{
                                x:null,y:t
                            });
                            t.data=tdMethod(mtSetter,x,y);
                        }
                        if(name.length>8&&name.startsWith("flibget_")){
                            var varn=name.substr(8);
                            if(properties.exists(varn))properties.get(varn).x=t;
                            else properties.set(varn,{
                                x:t,y:null
                            });
                            t.data=tdMethod(mtGetter,x,y);
                        }
                    }
                    case tdSlot(const,sid,_,_,_):var flibd=({
                        var n2=abc.cpool.names[t.name-1];
                        switch(n2){
                            case mQName(_,ns,name):var n3=abc.cpool.nspaces[ns-1];
                            abc.cpool.strings[n3.name-1];
                            default:"";
                        }
                    });
                    var name=({
                        var n2=abc.cpool.names[t.name-1];
                        switch(n2){
                            case mQName(_,_,name):abc.cpool.strings[name-1];
                            case mRTQName(_,name):abc.cpool.strings[name-1];
                            case mMultiname(_,name,_):abc.cpool.strings[name-1];
                            default:"";
                        }
                    });
                    if(flibd=="flibdel")flibrem.set(name,null);
                    if(flibd==""&&name.substr(0,8)=="flibdel_"&&name.length>8){
                        flibrem.set(name,null);
                        flibrem.set(name.substr(8),null);
                    }
                    default:
                }
            }
            var ntraits=[];
            for(t in i.traits){
                switch(t.data){
                    case tdMethod(type,_,id):if(Type.enumEq(type,mtMethod)){
                        var name=({
                            var n2=abc.cpool.names[t.name-1];
                            switch(n2){
                                case mQName(_,_,name):abc.cpool.strings[name-1];
                                case mRTQName(_,name):abc.cpool.strings[name-1];
                                case mMultiname(_,name,_):abc.cpool.strings[name-1];
                                default:"";
                            }
                        });
                        if(!flibrem.exists(name))ntraits.push(t);
                        else{
                            methodid.remove(id);
                        }
                    }
                    else ntraits.push(t);
                    case tdSlot(const,_,_,_,_):var name=({
                        var n2=abc.cpool.names[t.name-1];
                        switch(n2){
                            case mQName(_,_,name):abc.cpool.strings[name-1];
                            case mRTQName(_,name):abc.cpool.strings[name-1];
                            case mMultiname(_,name,_):abc.cpool.strings[name-1];
                            default:"";
                        }
                    });
                    if(flibrem.exists(name))continue;
                    if(!const){
                        if(properties.exists(name)){
                            var p=properties.get(name);
                            if(p.x!=null)p.x.name=t.name;
                            if(p.y!=null)p.y.name=t.name;
                            continue;
                        }
                    }
                    ntraits.push(t);
                    default:ntraits.push(t);
                }
            }
            i.traits=ntraits;
        }
        for(i in abc.classes){
            var properties=new Hash<{
                x:Trait,y:Trait
            }
            >();
            var flibrem=new Hash<Void>();
            for(t in i.traits){
                switch(t.data){
                    case tdMethod(type,x,y):if(Type.enumEq(type,mtMethod)){
                        var flibd=({
                            var n2=abc.cpool.names[t.name-1];
                            switch(n2){
                                case mQName(_,ns,name):var n3=abc.cpool.nspaces[ns-1];
                                abc.cpool.strings[n3.name-1];
                                default:"";
                            }
                        });
                        var name=({
                            var n2=abc.cpool.names[t.name-1];
                            switch(n2){
                                case mQName(_,_,name):abc.cpool.strings[name-1];
                                case mRTQName(_,name):abc.cpool.strings[name-1];
                                case mMultiname(_,name,_):abc.cpool.strings[name-1];
                                default:"";
                            }
                        });
                        if(flibd=="flibdel")flibrem.set(name,null);
                        if(flibd==""&&name.substr(0,8)=="flibdel_"&&name.length>8){
                            flibrem.set(name,null);
                            flibrem.set(name.substr(8),null);
                        }
                        if(name.length>8&&name.startsWith("flibset_")){
                            var varn=name.substr(8);
                            if(properties.exists(varn))properties.get(varn).y=t;
                            else properties.set(varn,{
                                x:null,y:t
                            });
                            t.data=tdMethod(mtSetter,x,y);
                        }
                        if(name.length>8&&name.startsWith("flibget_")){
                            var varn=name.substr(8);
                            if(properties.exists(varn))properties.get(varn).x=t;
                            else properties.set(varn,{
                                x:t,y:null
                            });
                            t.data=tdMethod(mtGetter,x,y);
                        }
                    }
                    case tdSlot(const,sid,_,_,_):var flibd=({
                        var n2=abc.cpool.names[t.name-1];
                        switch(n2){
                            case mQName(_,ns,name):var n3=abc.cpool.nspaces[ns-1];
                            abc.cpool.strings[n3.name-1];
                            default:"";
                        }
                    });
                    var name=({
                        var n2=abc.cpool.names[t.name-1];
                        switch(n2){
                            case mQName(_,_,name):abc.cpool.strings[name-1];
                            case mRTQName(_,name):abc.cpool.strings[name-1];
                            case mMultiname(_,name,_):abc.cpool.strings[name-1];
                            default:"";
                        }
                    });
                    if(flibd=="flibdel")flibrem.set(name,null);
                    if(flibd==""&&name.substr(0,8)=="flibdel_"&&name.length>8){
                        flibrem.set(name,null);
                        flibrem.set(name.substr(8),null);
                    }
                    default:
                }
            }
            var ntraits=[];
            for(t in i.traits){
                switch(t.data){
                    case tdMethod(type,_,id):if(Type.enumEq(type,mtMethod)){
                        var name=({
                            var n2=abc.cpool.names[t.name-1];
                            switch(n2){
                                case mQName(_,_,name):abc.cpool.strings[name-1];
                                case mRTQName(_,name):abc.cpool.strings[name-1];
                                case mMultiname(_,name,_):abc.cpool.strings[name-1];
                                default:"";
                            }
                        });
                        if(!flibrem.exists(name))ntraits.push(t);
                        else{
                            methodid.remove(id);
                        }
                    }
                    else ntraits.push(t);
                    case tdSlot(const,_,_,_,_):var name=({
                        var n2=abc.cpool.names[t.name-1];
                        switch(n2){
                            case mQName(_,_,name):abc.cpool.strings[name-1];
                            case mRTQName(_,name):abc.cpool.strings[name-1];
                            case mMultiname(_,name,_):abc.cpool.strings[name-1];
                            default:"";
                        }
                    });
                    if(flibrem.exists(name))continue;
                    if(!const){
                        if(properties.exists(name)){
                            var p=properties.get(name);
                            if(p.x!=null)p.x.name=t.name;
                            if(p.y!=null)p.y.name=t.name;
                            continue;
                        }
                    }
                    ntraits.push(t);
                    default:ntraits.push(t);
                }
            }
            i.traits=ntraits;
        }
        var methodset=new IntHash<Int>();
        var ind=0;
        for(i in methodid)methodset.set(i,ind++);
        var i=0;
        while(true){
            if(i>=abc.mbodies.length)break;
            var mbody=abc.mbodies[i];
            if(methodset.exists(mbody.method)){
                i++;
                continue;
            }
            abc.mbodies.splice(i,1);
            continue;
        }
        var out=new BytesOutput();
        var writer=new flib.abc.Writer(out);
        writer.writeABC(abc);
        return out.getBytes();
    }
}

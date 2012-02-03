package flib.abc;
import haxe.Int32;
import haxe.io.Bytes;
typedef ABC={
    var minor:Int;
    var major:Int;
    var cpool:CPool;
    var methods:Array<Method>;
    var metadata:Array<Metadata>;
    var instances:Array<Instance>;
    var classes:Array<XClass>;
    var scripts:Array<Script>;
    var mbodies:Array<MBody>;
}
typedef CPool={
    var ints:Array<Int32>;
    var uints:Array<Int32>;
    var doubles:Array<Float>;
    var strings:Array<String>;
    var nspaces:Array<Namespace>;
    var nssets:Array<NsSet>;
    var names:Array<Multiname>;
}
typedef Method={
    var return_type:Int;
    var name:Int;
    var need_arg_obj:Bool;
    var need_act:Bool;
    var need_rest:Bool;
    var set_dxns:Bool;
    var param_types:Array<Int>;
    var param_names:Array<Int>;
    var optionals:Array<Option>;
}
typedef Option={
    var value:Int;
    var kind:NSType;
}
typedef Metadata={
    var name:Int;
    var items:Array<Item>;
}
typedef Item={
    var key:Int;
    var value:Int;
}
typedef Instance={
    var name:Int;
    var superc:Int;
    var ns:Int;
    var iinit:Int;
    var flags:Int;
    var interfaces:Array<Int>;
    var traits:Array<Trait>;
}
typedef Trait={
    var name:Int;
    var metadata:Array<Int>;
    var final:Bool;
    var overriden:Bool;
    var data:TraitData;
}
enum TraitData{
    tdSlot(const:Bool,slotid:Int,typename:Int,vindex:Int,type:NSType);
    tdClass(slotid:Int,classi:Int);
    tdFunction(slotid:Int,method:Int);
    tdMethod(type:MethodType,slotid:Int,method:Int);
}
enum MethodType{
    mtMethod;
    mtGetter;
    mtSetter;
}
typedef XClass={
    var cinit:Int;
    var traits:Array<Trait>;
}
typedef Script={
    var init:Int;
    var traits:Array<Trait>;
}
typedef MBody={
    var method:Int;
    var max_st:Int;
    var l_cnt:Int;
    var init_sc:Int;
    var sc_depth:Int;
    var avm:Bytes;
    var exceptions:Array<Exception>;
    var traits:Array<Trait>;
}
typedef Exception={
    var from:Int;
    var to:Int;
    var target:Int;
    var exc_type:Int;
    var var_name:Int;
}
typedef Namespace={
    var type:NSType;
    var name:Int;
}
enum NSType{
    nsPrivateNs;
    nsNamespace;
    nsPackageNs;
    nsPackIntNs;
    nsProtectNs;
    nsExplicitNs;
    nsStatProtNs;
    nsOther(x:Int);
}
typedef NsSet=Array<Int>;
enum Multiname{
    mQName(a:Bool,ns:Int,name:Int);
    mRTQName(a:Bool,name:Int);
    mRTQNameL(a:Bool);
    mMultiname(a:Bool,name:Int,ns_set:Int);
    mMultinameL(a:Bool,ns_set:Int);
    mGenericName(type:Int,params:Array<Int>);
    mAnyName;
}

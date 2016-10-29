import ceylon.json {
    JsonObject,
    JsonArray,
    Value
}

//
//  Basic and primitives
//

class DummyGeneric<T>(T foo) {
    shared actual String string => classname(this) + "{foo=``tostr(foo)``}";
}
class DummyValue(Value val) {
    shared actual String string => classname(this) + "{val=``tostr(val)``}";
}
class DummyValueOptional(Value? val) {
    shared actual String string => classname(this) + "{val=``tostr(val)``}";
}
class DummyValueDefault(Value val = "DEFAULT-VALUE") {
    shared actual String string => classname(this) + "{val=``tostr(val)``}";
}
class DummyValueDefaultOptional(Value? val = "DEFAULT-VALUE") {
    shared actual String string => classname(this) + "{val=``tostr(val)``}";
}
class DummyPrimitives(String str, Integer int, Boolean bool, Float float) {
    shared actual String string => classname(this) + "{str=``str``, int=``int``, bool=``bool``, float=``float``}";
}
class DummyPrimitivesOptional(String? str, Integer? int, Boolean? bool, Float? float) {
    shared actual String string => classname(this) + "{str=``tostr(str)``, int=``tostr(int)``, bool=``tostr(bool)``, float=``tostr(float)``}";
}
class DummyString(String str) {
    shared actual String string => classname(this) + "{str=``str``}";
}
class DummyInteger(Integer int) {
    shared actual String string => classname(this) + "{int=``int``}";
}
class DummyFloat(Float float) {
    shared actual String string => classname(this) + "{float=``float``}";
}
class DummyBoolean(Boolean bool) {
    shared actual String string => classname(this) + "{bool=``bool``}";
}
class DummyJsonArray(JsonArray jsonArray) {
    shared actual String string => classname(this) + "{jsonArray=``jsonArray``}";
}
class DummyJsonObject(JsonObject jsonObject) {
    shared actual String string => classname(this) + "{jsonObject=``jsonObject``}";
}
class Dummy2Fields(Integer aaa, Integer bbb) {
    shared actual String string => classname(this) + "{aaa=``aaa``, bbb=``bbb``}";
}
class Dummy2Default(Integer aaa, Integer bbb = 12345) {
    shared actual String string => classname(this) + "{aaa=``aaa``, bbb=``bbb``}";
}
class DummyUnion(Integer|String aaa, Boolean|Float bbb) {
    shared actual String string => classname(this) + "{aaa=``aaa``, bbb=``bbb``}";
}
class DummyDefaultCtr {
    Integer aaa;
    shared new (Integer aaa) {
        this.aaa = aaa;
    }
    shared actual String string => classname(this) + "{aaa=``aaa``}";
}
class DummyWithoutDefaultCtr {
    Integer aaa;
    shared new ctr1(Integer aaa) {
        this.aaa = aaa;
    }
    shared actual String string => classname(this) + "{aaa=``aaa``}";
}

//
//  Objects
//

class DummyObject(DummyValue dummy) {
    shared actual String string => classname(this) + "{dummy=``dummy``}";
}
class DummyObjectObject(DummyObject obj) {
    shared actual String string => classname(this) + "{obj=``obj``}";
}
class DummyObjectOptional(DummyValue? dummy) {
    shared actual String string => classname(this) + "{dummy=``tostr(dummy)``}";
}
interface DummyInterface {}

//
//  Arrays
//

class DummyArraySequential<T>(T[] items) {
    shared actual String string => classname(this) + "{items=``items``}";
}
class DummyArraySequence<T>([T+] items) {
    shared actual String string => classname(this) + "{items=``items``}";
}
class DummyArrayStreamPossiblyEmpty<T>({T*} items) {
    shared actual String string => classname(this) + "{items=``items``}";
}
class DummyArrayStreamNonEmpty<T>({T+} items) {
    shared actual String string => classname(this) + "{items=``items``}";
}

// TODO FEATURE load JsonObject as Map<String,Target>(implement as issue/branch for release 0.2)
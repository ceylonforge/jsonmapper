import ceylon.test.engine {
    DefaultLoggingListener
}
import ceylon.test {
    createTestRunner,
    assertEquals,
    test,
    fail
}
import org.ceylonforge.jsonmapper {
    load,
    enum,
    wrap,
    Converter,
    JsonLoadException,
    buildJsonLoad,
    JsonLoadConfiguration
}
import ceylon.language.meta.model {
    Class
}
import ceylon.whole {
    Whole,
    wholeNumber,
    parseWhole
}
import ceylon.json {
    Value,
    JSONObject = Object,
    JSONArray = Array
}
import ceylon.language.meta {
    type
}

// String | Boolean | Integer | Float | JSONObject | JSONArray | Null

String tostr(Anything val) => val?.string else "<null>";
String classname(Anything obj) {
    return type(obj).declaration.name;
}



shared class LoadTest() {
    variable Converter[]? converters = null; // todo !!! remove this

    // todo !!! remove this
//    JsonLoadBuilder b = JsonLoadBuilder();

    test
    shared void testParse_DefaultParams() {
        checkLoad0(`Dummy`, """{"int":123, "str":"some value"}""",
            "Dummy{str:some value, int:123, bool:false, float:999.99}", "all default");

        checkLoad0(`Dummy`, """{"int":123, "str":"some value", "bool":true}""",
            "Dummy{str:some value, int:123, bool:true, float:999.99}", "one default");
    }

    test
    shared void testParse_ObjectField() {
        checkLoad0(`Dummy3`, """{"dummy2":{"int2":12345}, "str":"VALUE"}""",
            "Dummy3{str:VALUE, dummy2:Dummy2{int2:12345}}");
    }

    // todo !!! remove this test as duplicate
    test
    shared void testSkipExtraFields() {
        checkLoad0(`Dummy2`, """{"int2":12345, "foo":99999}""",
            "Dummy2{int2:12345}");
    }

    test
    shared void testEnumAsValueConstructors() {
        checkLoad0(`DummyEnumClient`, """{"enumValue":"value2"}""",
            "DummyEnumClient{enumValue:DummyEnum{value2}}");
        // todo !!! тест на error без enum
    }

    test // todo !!! test different primitive types
    shared void testWrappedValue() {
        checkLoad0(`DummyWrapperClient`, """{"wrapper":12345}""",
            "DummyWrapperClient{wrapper=DummyWrapper{12345}}");

        // todo !!! тест на error без нее)
    }

    // todo !!! move into lib src code
    Whole wholeFactory(String|Integer val) {
        switch (val)
        case (is String) {
            assert(exists w = parseWhole(val));
            return w;
        }
        case (is Integer) {
            return wholeNumber(val);
        }
    }

    test
    shared void testWhole() {
        converters = [wholeFactory];
        checkLoad0(`DummyWithWholes`, """{"strw":"123", "intw":456}""",
            "DummyWithWholes{strw=123, intw=456}");
    }

    test
    shared void testConverters_ReturnType() {
        DummyValue1(Integer|String) v1 = (Integer|String val) {
            return object satisfies DummyValue1 {
                shared actual String string => val.string;
            };
        };
        DummyValue2(String|Integer) v2 = (String|Integer val) {
            return object satisfies DummyValue2 {
                shared actual String string => val.string;
            };
        };
        converters = [v1, v2];
        checkLoad0(`DummyForConverters`, """{"value1":12345, "value2":"DUMMY"}""",
            "DummyForConverters{value1=12345, value2=DUMMY}");
    }

//  todo !!! check for error in commmand line run
//    todo !!! report error
//    todo !!! reproduce error for renaming alias in import and report about it (если еще нет тикета об этой ошибке)
// C:\dev\java\jdk1.8.0_66\bin\java -Dceylon.system.repo=C:\Users\olegn\.IntelliJIdea2016.2\config\plugins\CeylonIDEA\classes\embeddedDist\repo -Didea.launcher.port=7533 "-Didea.launcher.bin.path=C:\Program Files (x86)\JetBrains\IntelliJ IDEA 2016.2.4\bin" -Dfile.encoding=windows-1251 -classpath "C:\Users\olegn\.IntelliJIdea2016.2\config\plugins\CeylonIDEA\classes\embeddedDist\lib\ceylon-bootstrap.jar;C:\Program Files (x86)\JetBrains\IntelliJ IDEA 2016.2.4\lib\idea_rt.jar" com.intellij.rt.execution.application.AppMain com.redhat.ceylon.launcher.Bootstrap run --run test.org.ceylonforge.jsonmapper.runThisTests test.org.ceylonforge.jsonmapper/1.0.0
//    ceylon run: Failed to resolve test.org.ceylonforge.jsonmapper.
//    LoadTest$5$1anonymous_5_
//    com.redhat.ceylon.model.loader.ModelResolutionException: Failed to resolve test.org.ceylonforge.jsonmapper.LoadTest$5$1anonymous_5_
//    at com.redhat.ceylon.model.loader.AbstractModelLoader$5.call(AbstractModelLoader.java:1782)
//    at com.redhat.ceylon.model.loader.AbstractModelLoader$5.call(AbstractModelLoader.java:1690)
//    at com.redhat.ceylon.model.loader.AbstractModelLoader$1.call(AbstractModelLoader.java:345)
//    at com.redhat.ceylon.model.loader.AbstractModelLoader.embeddingSync(AbstractModelLoader.java:336)
//    at com.redhat.ceylon.model.loader.AbstractModelLoader.synchronizedCall(AbstractModelLoader.java:341)
//    at com.redhat.ceylon.model.loader.AbstractModelLoader.convertToDeclaration(AbstractModelLoader.java:1690)
//    at com.redhat.ceylon.model.loader.AbstractModelLoader.addLocalDeclarations(AbstractModelLoader.java:3248)
//    at com.redhat.ceylon.model.loader.AbstractModelLoader.complete(AbstractModelLoader.java:3041)
//    at com.redhat.ceylon.model.loader.AbstractModelLoader.access$1200(AbstractModelLoader.java:100)
//    at com.redhat.ceylon.model.loader.AbstractModelLoader$16.run(AbstractModelLoader.java:2369)
//    at com.redhat.ceylon.model.loader.AbstractModelLoader$2.call(AbstractModelLoader.java:360)
//    at com.redhat.ceylon.model.loader.AbstractModelLoader$1.call(AbstractModelLoader.java:345)
//    at com.redhat.ceylon.model.loader.AbstractModelLoader.embeddingSync(AbstractModelLoader.java:336)
//    at com.redhat.ceylon.model.loader.AbstractModelLoader.synchronizedCall(AbstractModelLoader.java:341)
//    at com.redhat.ceylon.model.loader.AbstractModelLoader.synchronizedRun(AbstractModelLoader.java:357)
//    at com.redhat.ceylon.model.loader.AbstractModelLoader.complete(AbstractModelLoader.java:2365)
//    at com.redhat.ceylon.model.loader.model.LazyClass$1.run(LazyClass.java:103)
//    at com.redhat.ceylon.model.loader.AbstractModelLoader$2.call(AbstractModelLoader.java:360)
//    at com.redhat.ceylon.model.loader.AbstractModelLoader$1.call(AbstractModelLoader.java:345)
//    at com.redhat.ceylon.model.loader.AbstractModelLoader.embeddingSync(AbstractModelLoader.java:336)
//    at com.redhat.ceylon.model.loader.AbstractModelLoader.synchronizedCall(AbstractModelLoader.java:341)
//    at com.redhat.ceylon.model.loader.AbstractModelLoader.synchronizedRun(AbstractModelLoader.java:357)
//    at com.redhat.ceylon.model.loader.model.LazyClass.load(LazyClass.java:97)
//    at com.redhat.ceylon.model.loader.model.LazyClass.hasConstructors(LazyClass.java:194)
//    at com.redhat.ceylon.compiler.java.runtime.metamodel.Metamodel.getOrCreateMetamodel(Metamodel.java:381)
//    at com.redhat.ceylon.compiler.java.runtime.metamodel.Metamodel.getOrCreateMetamodel(Metamodel.java:1301)
//    at test.org.ceylonforge.jsonmapper.runThisTests_.runThisTests(tests.ceylon:256)
//    at test.org.ceylonforge.jsonmapper.runThisTests_.main(tests.ceylon)
//    at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
//    at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
//    at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
//    at java.lang.reflect.Method.invoke(Method.java:497)
//    at ceylon.modules.api.runtime.SecurityActions.invokeRunInternal(SecurityActions.java:57)
//    at ceylon.modules.api.runtime.SecurityActions.invokeRun(SecurityActions.java:48)
//    at ceylon.modules.api.runtime.AbstractRuntime.invokeRun(AbstractRuntime.java:68)
//    at ceylon.modules.api.runtime.AbstractRuntime.execute(AbstractRuntime.java:105)
//    at ceylon.modules.api.runtime.AbstractRuntime.execute(AbstractRuntime.java:101)
//    at ceylon.modules.Main.execute(Main.java:69)
//    at ceylon.modules.Main.main(Main.java:42)
//    at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
//    at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
//    at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
//    at java.lang.reflect.Method.invoke(Method.java:497)
//    at org.jboss.modules.Module.run(Module.java:308)
//    at org.jboss.modules.Main.main(Main.java:487)
//    at ceylon.modules.bootstrap.CeylonRunTool.run(CeylonRunTool.java:307)
//    at com.redhat.ceylon.common.tools.CeylonTool.run(CeylonTool.java:524)
//    at com.redhat.ceylon.common.tools.CeylonTool.execute(CeylonTool.java:405)
//    at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
//    at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
//    at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
//    at java.lang.reflect.Method.invoke(Method.java:497)
//    at com.redhat.ceylon.launcher.Launcher.runInJava7Checked(Launcher.java:115)
//    at com.redhat.ceylon.launcher.Launcher.run(Launcher.java:41)
//    at com.redhat.ceylon.launcher.Launcher.run(Launcher.java:34)
//    at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
//    at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
//    at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
//    at java.lang.reflect.Method.invoke(Method.java:497)
//    at com.redhat.ceylon.launcher.Bootstrap.runInternal(Bootstrap.java:139)
//    at com.redhat.ceylon.launcher.Bootstrap.run(Bootstrap.java:93)
//    at com.redhat.ceylon.launcher.Bootstrap.main(Bootstrap.java:85)
//    at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
//    at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
//    at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
//    at java.lang.reflect.Method.invoke(Method.java:497)
//    at com.intellij.rt.execution.application.AppMain.main(AppMain.java:147)
//    test
//    shared void testConverters_EveryJsonValueType() {
//        DummyValue1(Value) v1 = (Value val) {
//            return object satisfies DummyValue1 { todo !!! this string expose runtime error
//                shared actual String string =>
//                    switch (val)
//                    case (is JsonObject) (val["dummy"]?.string else "[dummy] is NULL")
//                    case (is JsonArray) (val[0]?.string else "[0] is NULL")
//                    case (is Null) "NULL"
//                    else val.string;
//            };
//        };
//        converters = [v1];
//        checkLoad(`DummyForConverters2`, """{"vString":"FOO", "vBoolean":true, "vInteger":12345, "vFloat":67.89, "vJsonObject":{"dummy":"BAR"}, "vJsonArray":["BAZ"], "vNull":null}""",
//            "DummyForConverters2{vString=FOO, vBoolean=true, vInteger=12345, vFloat=67.89, vObject=BAR, vArray=BAZ, vNull=null}");
//    }

    test
    shared void testConverters_EveryJsonValueType() {
        DummyValue1(Value) converter = `DummyValue1Impl`; // classes also Callable
        converters = [converter];
        checkLoad0(`DummyForConverters2`, """{"vString":"FOO", "vBoolean":true, "vInteger":12345, "vFloat":67.89, "vObject":{"dummy":"BAR"}, "vArray":["BAZ"], "vNull":null}""",
            "DummyForConverters2{vString=FOO, vBoolean=true, vInteger=12345, vFloat=67.89, vObject=BAR, vArray=BAZ, vNull=NULL}");
    }

    // todo !!! todo test there is no converters or parameter for converter is wrong type

    // todo !!! test null and nullable (and other not tested jsonvalue types if any)

    // todo !!! implement json(name=...) annotation

//    test
//    shared void testDecimal() {
//        checkLoad(`DummyWithDecimals`, """{}""",
//            "");
//        // todo !!! implement
//    }

    void checkLoad0(Class<> cls, String json, String expected, String? msg = null) {
        value f = converters;
        value obj = if (exists f)
                    then load(cls, json, f)
                    else load(cls, json);
        assert(is Object obj);
        assertEquals(obj.string, expected, msg);
    }

    // todo !!! test object field generic type
    // todo !!! test different collections (которые нужны для DTO)
    // todo !!! test support member classes (для вложенных объектов)

    // todo !!! test support objects for json-enum-values - with value constructor
    // todo !!! test error: non-existent value constructor

    // todo !!! support Whole and Decimal (maybe generify such external wrappers/default wrappers)

    // todo !!! test error: not all required parameters provided
    // todo !!! test error: wrong parameter type - primitives
    // todo !!! test error: wrong parameter type - primitive and class and vice versa
}



class Dummy(String str, Integer int, Boolean bool = false, Float float = 999.99) {
    shared actual String string => "Dummy{str:``str``, int:``int``, bool:``bool``, float:``float``}";
}

class Dummy2(shared Integer int2) {
    shared actual String string => "Dummy2{int2:``int2``}";
}

class Dummy3(shared String str, shared Dummy2 dummy2) {
    shared actual String string => "Dummy3{str:``str``, dummy2:``dummy2``}";
}

enum
class DummyEnum {
    String name;
    shared new value1 {
        name = "value1";
    }
    shared new value2 {
        name = "value2";
    }
    shared actual String string => "DummyEnum{``name``}";
}

class DummyEnumClient(shared DummyEnum enumValue) {
    shared actual String string => "DummyEnumClient{enumValue:``enumValue``}";
}

// todo !!! видимо,  аннотацию wrap (это тоже, кстати существительное)/wrapper - а может здесь и без аннотации (чтобы можно было сторонние классы использовать - хотя их можно по-другому через фабрики какие-нибудь заводить)
wrap
class DummyWrapper(shared Integer wrapped) {
    shared actual String string => "DummyWrapper{``wrapped``}";
}

class DummyWrapperClient(shared DummyWrapper wrapper) {
    shared actual String string => "DummyWrapperClient{wrapper=``wrapper``}"; // todo !!! refactore to =
}

// todo !!! does we required shared for attributes? - shared is not required

class DummyWithWholes(Whole strw, Whole intw) {
    shared actual String string => "DummyWithWholes{strw=``strw``, intw=``intw``}";
}

class DummyForConverters(DummyValue1 value1, DummyValue2 value2) {
    shared actual String string => "DummyForConverters{value1=``value1``, value2=``value2``}";
}
interface DummyValue1 {}
interface DummyValue2 {}

class DummyValue1Impl(Value val) satisfies DummyValue1 {
    shared actual String string =>
            switch (val)
            case (is JSONObject) (val["dummy"]?.string else "[dummy] is NULL")
            case (is JSONArray) (val[0]?.string else "[0] is NULL")
            case (is Null) "NULL"
            else val.string;
}

//String | Boolean | Integer | Float | Object | Array | Null

class DummyForConverters2(DummyValue1 vString, DummyValue1 vBoolean, DummyValue1 vInteger,
                            DummyValue1 vFloat, DummyValue1 vObject, DummyValue1 vArray, DummyValue1 vNull) {
    shared actual String string =>
            "DummyForConverters2{vString=``vString``, vBoolean=``vBoolean``, vInteger=``vInteger``, vFloat=``vFloat``, vObject=``vObject``, vArray=``vArray``, vNull=``vNull``}";
}

// todo !!! implement native separate
//class DummyWithDecimals(Decimal strd, Whole intd) {
//}

shared void runThisTests() {
    value runner = createTestRunner([`class LoadTest`], [DefaultLoggingListener()]);
    value result = runner.run();
}

import org.ceylonforge.jsonmapper {
    JsonLoadConfiguration,
    JsonLoadException,
    buildJsonLoad
}
import ceylon.test {
    test,
    assertEquals,
    fail,
    createTestRunner
}
import ceylon.language.meta.model {
    Class
}
import ceylon.test.engine {
    DefaultLoggingListener
}
import ceylon.json {
    JsonArray,
    JsonObject
}

shared void runLoadBasicTests() {
    createTestRunner([`class LoadBasicTest`], [DefaultLoggingListener()]).run();
}

class LoadBasicTest() {

    variable JsonLoadConfiguration? cfg = null;

    test
    shared void testLoad_Fail_NotJsonObject() {
        checkLoadFail_NotJsonObject("");
        checkLoadFail_NotJsonObject("NON-VALID-JSON");

        checkLoadFail_NotJsonObject(""""STRING-VALUE"""");
        checkLoadFail_NotJsonObject("true");
        checkLoadFail_NotJsonObject("12345");
        checkLoadFail_NotJsonObject("67.89");
        checkLoadFail_NotJsonObject("null");
        checkLoadFail_NotJsonObject("""[{"aaa":123}]"""); // don't support array in top level (for now) - but todo !!! support this
    }

    void checkLoadFail_NotJsonObject(String json) {
        checkLoadFailed(`DummyPrimitives`, json);
    }

    //
    //  Basic tests
    //

    test
    shared void testPrimitives() {
        checkLoad(`DummyPrimitives`, """{"int":123, "str":"some value", "float":45.678, "bool":true}""", // use different order in json and initializer
            "DummyPrimitives{str=some value, int=123, bool=true, float=45.678}");
    }

    test
    shared void testPrimitives_Optional() {
        checkLoad(`DummyPrimitivesOptional`, """{"int":123, "str":"some value", "float":45.678, "bool":true}""",
            "DummyPrimitivesOptional{str=some value, int=123, bool=true, float=45.678}", "parameters provided");
        checkLoad(`DummyPrimitivesOptional`, """{"int":null, "str":null, "float":null, "bool":null}""",
            "DummyPrimitivesOptional{str=<null>, int=<null>, bool=<null>, float=<null>}", "parameters nulls");
    }

    test
    shared void testPrimitives_Failed() {
        checkLoadFailed(`DummyString`, """{"int":false}""");
        checkLoadFailed(`DummyInteger`, """{"int":123.45}""");
        checkLoadFailed(`DummyFloat`, """{"float":true}""");
        checkLoadFailed(`DummyBoolean`, """{"bool":123}""");

        checkLoadFailed(`DummyString`, """{"str":null}""");
        checkLoadFailed(`DummyInteger`, """{"int":null}""");
        checkLoadFailed(`DummyFloat`, """{"float":null}""");
        checkLoadFailed(`DummyBoolean`, """{"bool":null}""");
    }

    test
    shared void testDirectly_JsonObject() {
        checkLoad(`DummyJsonArray`, """{"jsonArray":[111, 222, 333]}""", "DummyJsonArray{jsonArray=[111,222,333]}");
    }

    test
    shared void testDirectly_JsonArray() {
        checkLoad(`DummyJsonObject`, """{"jsonObject":{"aaa":123, "bbb":456}}""", """DummyJsonObject{jsonObject={"aaa":123,"bbb":456}}""");
    }

    test
    shared void testSkipExtraFields() {
        checkLoad(`DummyString`, """{"str":"DUMMY-VALUE", "extraField":"DUMMY-BAR"}""", "DummyString{str=DUMMY-VALUE}");
        checkLoad(`Dummy2Default`, """{"aaa":111, "extraField":222}""", "Dummy2Default{aaa=111, bbb=12345}");

        cfg = JsonLoadConfiguration {
            skipExtraFields = false;
        };
        checkLoadFailed(`DummyString`, """{"str":"DUMMY-VALUE", "extraField":"DUMMY-BAR"}""");
        testPrimitives(); // check order here
    }

    test
    shared void testMissingFieldsFailed() {
        checkLoadFailed(`Dummy2Fields`, """{"aaa":123}""", "less fields in JSON");
        checkLoadFailed(`Dummy2Fields`, """{"aaa":123, "dummyUnknown":456}""", "same count fields in JSON");
        checkLoadFailed(`Dummy2Fields`, """{"bbb":456, "dummyUnknown1":111, "dummyUnknown":222}""", "more fields in JSON");
    }

    test
    shared void testAutoNulls() {
        cfg = JsonLoadConfiguration {
            autoNulls = true;
        };
        checkLoad(`DummyPrimitivesOptional`, """{"str":"DUMMY-VALUE", "bool":true}""",
            "DummyPrimitivesOptional{str=DUMMY-VALUE, int=<null>, bool=true, float=<null>}", "parameters nulls");
    }

    // todo DEFFERED test some collection/sequence as top object for top JsonArray

    //
    //  Auto-convert primitives tests
    //

    test
    shared void testAutoConvert_FromString() {
        cfg = JsonLoadConfiguration {
            autoConvertPrimitives = true;
        };
        checkLoad(`DummyInteger`, """{"int":"123"}""", "DummyInteger{int=123}");
        checkLoad(`DummyFloat`, """{"float":"45.67"}""", "DummyFloat{float=45.67}");
        checkLoad(`DummyBoolean`, """{"bool":"true"}""", "DummyBoolean{bool=true}");

        checkLoadFailed(`DummyInteger`, """{"int":"aaa"}""");
        checkLoadFailed(`DummyFloat`, """{"float":"bbb"}""");
        checkLoadFailed(`DummyBoolean`, """{"bool":"ccc"}""");
    }

    test
    shared void testPrimitives_AutoConvert_ToString() {
        cfg = JsonLoadConfiguration {
            autoConvertPrimitives = true;
        };
        checkLoad(`DummyString`, """{"str":123}""", "DummyString{str=123}");
        checkLoad(`DummyString`, """{"str":45.67}""", "DummyString{str=45.67}");
        checkLoad(`DummyString`, """{"str":true}""", "DummyString{str=true}");
        checkLoad(`DummyString`, """{"str":"DUMMY-STRING"}""", "DummyString{str=DUMMY-STRING}");
    }


    test
    shared void testAutoConvert_Nulls_Failed() {
        cfg = JsonLoadConfiguration {
            autoConvertPrimitives = true;
        };
        checkLoadFailed(`DummyInteger`, """{"int":null}""");
        checkLoadFailed(`DummyFloat`, """{"float":null}""");
        checkLoadFailed(`DummyBoolean`, """{"bool":null}""");
        checkLoadFailed(`DummyString`, """{"str":null}""");
    }

    test
    shared void testAutoConvert_Off_Failed() {
        cfg = JsonLoadConfiguration {
            autoConvertPrimitives = false;
        };

        checkLoadFailed(`DummyInteger`, """{"int":"123"}""");
        checkLoadFailed(`DummyFloat`, """{"float":"45.67"}""");
        checkLoadFailed(`DummyBoolean`, """{"bool":"true"}""");

        checkLoadFailed(`DummyString`, """{"str":123}""");
        checkLoadFailed(`DummyString`, """{"str":45.67}""");
        checkLoadFailed(`DummyString`, """{"str":true}""");
    }

    //
    //  Implementation details
    //

    void checkLoad(Class<> cls, String json, String expected, String? msg = null) {
        //        value load = buildJsonLoad<>();
        //        value obj = load(cls, json);
        // todo !!! file bug: inline refactoring upper is (bug is <><>):
        //        value obj = buildJsonLoad<><>()(cls, json);

        value cfg0 = cfg;
        value obj = if (exists cfg0)
        then buildJsonLoad<>(cfg0)(cls, json)
        else buildJsonLoad<>()(cls, json);
        assert(is Object obj);
        assertEquals(obj.string, expected, msg);
    }

    void checkLoadFailed(Class<> cls, String json, String? msg = null) {
        try {
            value cfg0 = cfg;
            if (exists cfg0) {
                buildJsonLoad<>(cfg0)(cls, json);
            } else {
                buildJsonLoad<>()(cls, json);
            }
        } catch (JsonLoadException e) {
            print("*** Info about exception:\n``e``");

            // todo !!! maybe move CauseStack into JsonLoad-function - and extract JsonExceptionInfo into separate class (and setup error verbosing in config)
            // todo DEFFERED and add info about jsonpath

            variable Throwable? ex = e.cause;
            variable String tabs = "";
            variable String prefix = "CausesStack{";
            while (exists cause = ex) {
                ex = cause.cause;
                tabs += "\t\t";
                print(tabs + prefix + cause.string + (if (ex exists) then  "" else "}"));
                prefix = "<- ";
            }
            return;
        }
        fail("There is no exception: " + (msg?.string else "JSON '``json``' to ``cls.string``"));
    }

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
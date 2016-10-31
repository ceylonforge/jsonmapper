import ceylon.json {
    JsonArray,
    JsonObject,
    Value
}
import ceylon.language.meta.model {
    Class
}
import ceylon.test {
    test,
    assertEquals,
    fail,
    createTestRunner
}
import ceylon.test.engine {
    DefaultLoggingListener
}

import org.ceylonforge.jsonmapper {
    JsonLoadException,
    buildJsonLoad
}

shared void runLoadBasicTests() {
    createTestRunner([`class LoadBasicTest`], [DefaultLoggingListener()]).run();
}

class LoadBasicTest() {

    test
    shared void testLoad_Fail_NotJsonObject() {
        checkLoadFail_NotJsonObject("");
        checkLoadFail_NotJsonObject("NON-VALID-JSON");

        checkLoadFail_NotJsonObject(""""STRING-VALUE"""");
        checkLoadFail_NotJsonObject("true");
        checkLoadFail_NotJsonObject("12345");
        checkLoadFail_NotJsonObject("67.89");
        checkLoadFail_NotJsonObject("null");
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
        checkLoadFailed(`DummyString`, """{"str":false}""");
        checkLoadFailed(`DummyInteger`, """{"int":123.45}""");
        checkLoadFailed(`DummyFloat`, """{"float":true}""");
        checkLoadFailed(`DummyBoolean`, """{"bool":123}""");

        checkLoadFailed(`DummyString`, """{"str":null}""");
        checkLoadFailed(`DummyInteger`, """{"int":null}""");
        checkLoadFailed(`DummyFloat`, """{"float":null}""");
        checkLoadFailed(`DummyBoolean`, """{"bool":null}""");

        checkLoadFailed(`DummyString`, """{"str":{}}""", "object to primitive");
        checkLoadFailed(`DummyString`, """{str":[]}""", "array to primitive");
    }

    test
    shared void testPrimitives_UnionTypeParameters() {
        checkLoad(`DummyUnion`, """{"aaa": 123, "bbb":true}""",
            "DummyUnion{aaa=123, bbb=true}");
        checkLoad(`DummyUnion`, """{"aaa": "DUMMY-VALUE", "bbb":123.45}""",
            "DummyUnion{aaa=DUMMY-VALUE, bbb=123.45}");
    }

    test
    shared void testGenerics() {
        checkLoad(`DummyGeneric<String>`, """{"foo":"DUMMY-VALUE"}""",
            "DummyGeneric{foo=DUMMY-VALUE}");
        checkLoad(`DummyGeneric<Integer>`, """{"foo":123}""",
            "DummyGeneric{foo=123}");
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

        // TODO uncomment/implement in some next release
        //        cfg = JsonLoadConfiguration {
        //            skipExtraFields = false;
        //        };
        //        checkLoadFailed(`DummyString`, """{"str":"DUMMY-VALUE", "extraField":"DUMMY-BAR"}""");
        //        testPrimitives(); // check order here
    }

    test
    shared void testMissingFieldsFailed() {
        checkLoadFailed(`Dummy2Fields`, """{"aaa":123}""", "less fields in JSON");
        checkLoadFailed(`Dummy2Fields`, """{"aaa":123, "dummyUnknown":456}""", "same count fields in JSON");
        checkLoadFailed(`Dummy2Fields`, """{"bbb":456, "dummyUnknown1":111, "dummyUnknown":222}""", "more fields in JSON");
    }

    test
    shared void testMissingFieldsFailed_ForOptionalProperty() {
        checkLoadFailed(`DummyValueOptional`, """{}""");
    }

    test
    shared void testDefaultProperty() {
        checkLoad(`Dummy2Default`, """{"aaa":111, "bbb":222}""",
            "Dummy2Default{aaa=111, bbb=222}");
        checkLoad(`Dummy2Default`, """{"aaa":111}""",
            "Dummy2Default{aaa=111, bbb=12345}");
        checkLoad(`DummyValueDefault`, """{}""",
            "DummyValueDefault{val=DEFAULT-VALUE}");
        checkLoad(`DummyValueDefaultOptional`, """{}""",
            "DummyValueDefaultOptional{val=DEFAULT-VALUE}");
    }

    test
    shared void testConstructors() {
        checkLoad(`DummyDefaultCtr`, """{"aaa":123}""", "DummyDefaultCtr{aaa=123}");
        checkLoadFailed(`DummyWithoutDefaultCtr`, """{"aaa":123}""");
    }

    test
    shared void testTopLevelArrayOfObjects() {
        checkLoad(`DummyValue`, """[]""", "{}");
        checkLoad(`DummyValue`, """[{"val":123}, {"val":"DUMMY-VALUE"}]""",
            "{ DummyValue{val=123}, DummyValue{val=DUMMY-VALUE} }");

        // silently skip non-objects by default
        checkLoad(`DummyValue`, """[{"val":123}, 777, {"val":"DUMMY-VALUE"}, ["NESTED-ARRAY"]]""",
            "{ DummyValue{val=123}, DummyValue{val=DUMMY-VALUE} }");
        checkLoad(`DummyValue`, """[123, true, "DUMMY-STRING"]""", "{}");
    }

    test
    shared void testPrimitiveToObjectConversionFailed() {
        checkLoadFailed(`DummyObjectOptional`, """{"dummy":123}""");
    }

    test
    shared void testNestedObject() {
        checkLoad(`DummyObject`, """{"dummy":{"val":123}}""",
            "DummyObject{dummy=DummyValue{val=123}}");
        checkLoad(`DummyObjectOptional`, """{"dummy":{"val":123}}""",
            "DummyObjectOptional{dummy=DummyValue{val=123}}");
        checkLoad(`DummyGeneric<DummyValue>`, """{"foo":{"val":123}}""",
            "DummyGeneric{foo=DummyValue{val=123}}");

        checkLoad(`DummyObjectOptional`, """{"dummy":null}""",
            "DummyObjectOptional{dummy=<null>}");

        checkLoad(`DummyObjectObject`, """{"obj":{"dummy":{"val":123}}}""",
            "DummyObjectObject{obj=DummyObject{dummy=DummyValue{val=123}}}", "nested nested object");

        checkLoad(`DummyGeneric<Value|DummyObject>`, """{"foo":{"dummy":{"val":123}}}""",
            """DummyGeneric{foo={"dummy":{"val":123}}}""", "Union type parameter with Value is supported and Value is used");
        checkLoad(`DummyGeneric<DummyObject|Value>`, """{"foo":{"dummy":{"val":123}}}""",
            """DummyGeneric{foo={"dummy":{"val":123}}}""", "Union type parameter with Value is supported and Value is used");
        checkLoad(`DummyGeneric<DummyObject|Integer>`, """{"foo":123}""",
            """DummyGeneric{foo=123}""", "Union type parameter with primitive is supported and primitive is used");
    }

    test
    shared void testNestedObject_ConversionFailed() {
        checkLoadFailed(`DummyGeneric<DummyObjectOptional|DummyObject>`, """{"foo":{"dummy":{"val":123}}}""", "Union objects paremeter is not supported");
        checkLoadFailed(`DummyGeneric<<DummyObjectOptional|DummyObject>?>`, """{"foo":{"dummy":{"val":123}}}""", "Union objects parameter is not supported (optional)");
        checkLoadFailed(`DummyGeneric<Null|DummyObjectOptional|DummyObject>`, """{"foo":{"dummy":{"val":123}}}""", "Union objects parameter is not supported (with Null)");

        checkLoadFailed(`DummyGeneric<DummyInterface>`, """{"foo":{}}""", "Interface parameter is not supported");

        checkLoadFailed(`DummyGeneric<DummyObject & DummyInterface>`, """{"foo":{"dummy":{"val":123}}}""", "Intersection type paremeter is not supported");
    }

}

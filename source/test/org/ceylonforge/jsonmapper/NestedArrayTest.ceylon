import ceylon.test {
    createTestRunner,
    test
}
import ceylon.test.engine {
    DefaultLoggingListener
}
import ceylon.json {
    JsonObject,
    JsonArray,
    Value
}
import ceylon.language.meta.model {
    Class
}
import test.org.ceylonforge.jsonmapper { checkLoadCommon = checkLoad}

shared void runNestedArrayTests() {
    createTestRunner([`class NestedArrayTest`], [DefaultLoggingListener()]).run();
}

shared void runOneTest() {
    createTestRunner([`function NestedArrayTest.testStream_JsonValues`], [DefaultLoggingListener()]).run();
    //    createTestRunner([`function LoadBasicTest.testNestedArray_Sequential_JsonValues`], [DefaultLoggingListener()]).run();
}

class NestedArrayTest() {

    variable [String,String] brackets = ["[", "]"];

    test
    shared void testSequential_JsonValues() {
        checkLoad(`DummyArraySequential<Integer>`, """{"items":[11,22,33,44,55]}""",
            "DummyArraySequential{items=[11, 22, 33, 44, 55]}");
        checkLoad(`DummyArraySequential<Float>`, """{"items":[1.1,2.2,3.3,4.4,5.5]}""",
            "DummyArraySequential{items=[1.1, 2.2, 3.3, 4.4, 5.5]}");
        checkLoad(`DummyArraySequential<String>`, """{"items":["one", "two", "three"]}""",
            """DummyArraySequential{items=[one, two, three]}""");
        checkLoad(`DummyArraySequential<Boolean>`, """{"items":[true, true, false]}""",
            """DummyArraySequential{items=[true, true, false]}""");

        checkLoad(`DummyArraySequential<JsonArray>`, """{"items":[[111], [22, 22], [33, 33, 33]]}""",
            """DummyArraySequential{items=[[111], [22,22], [33,33,33]]}""");
        checkLoad(`DummyArraySequential<JsonObject>`, """{"items":[{"foo":123}, {"bar":456}]}""",
            """DummyArraySequential{items=[{"foo":123}, {"bar":456}]}""");

        checkLoad(`DummyArraySequential<Value>`, """{"items":[111, 22.33, "DUMMY-VALUE", true, [456], {"foo":789}, null]}""",
            """DummyArraySequential{items=[111, 22.33, DUMMY-VALUE, true, [456], {"foo":789}, <null>]}""", "array of ceylon.json::Value");

        checkLoad(`DummyArraySequential<Integer>`, """{"items":[]}""",
            "DummyArraySequential{items=[]}", "empty array");
        checkLoad(`DummyArraySequential<Integer?>`, """{"items":[123, null]}""",
            "DummyArraySequential{items=[123, <null>]}", "array of optional values");
        checkLoad(`DummyArraySequential<Integer|String>`, """{"items":[123, "DUMMY"]}""",
            "DummyArraySequential{items=[123, DUMMY]}", "array of union");

        checkLoadFailed(`DummyArraySequential<String>`, """{"items":["DUMMY", 123]}""", "mixed array");
    }

    test
    shared void testSequential_Objects() {
        checkLoad(`DummyArraySequential<DummyInteger>`, """{"items":[]}""",
            "DummyArraySequential{items=[]}", "empty array");

        checkLoad(`DummyArraySequential<DummyInteger>`, """{"items":[{"int":111}, {"int":222}]}""",
            "DummyArraySequential{items=[DummyInteger{int=111}, DummyInteger{int=222}]}");

        checkLoad(`DummyArraySequential<DummyInteger?>`, """{"items":[{"int":111}, null, {"int":222}]}""",
            "DummyArraySequential{items=[DummyInteger{int=111}, <null>, DummyInteger{int=222}]}", "optional values");

        checkLoad(`DummyArraySequential<DummyArraySequential<DummyInteger>>`, """{"items":[{"items":[{"int":111}]}, {"items":[{"int":222}]}]}""",
            "DummyArraySequential{items=[DummyArraySequential{items=[DummyInteger{int=111}]}, DummyArraySequential{items=[DummyInteger{int=222}]}]}", "nested nested sequential");

        checkLoadFailed(`DummyArraySequential<DummyInteger|DummyString>`, """{"items":[{"int":123123}, {"str":"DUMMY"}]}""", "sequential of general union is not supported for now"); // TODO DEFFERED consider support union by signature (or with some custom provided resolver)
    }

    test
    shared void testSequence() {
        checkLoad(`DummyArraySequence<DummyInteger>`, """{"items":[{"int":111}, {"int":222}]}""",
            "DummyArraySequence{items=[DummyInteger{int=111}, DummyInteger{int=222}]}");

        checkLoadFailed(`DummyArraySequence<DummyInteger>`, """{"items":[]}""");
    }

    test
    shared void testStream_JsonValues() {
        checkLoad(`DummyArrayStreamPossiblyEmpty<Integer>`, """{"items":[11,22,33,44,55]}""",
            "DummyArrayStreamPossiblyEmpty{items={ 11, 22, 33, 44, 55 }}");

//        checkLoad(`DummyArrayStreamPossiblyEmpty<Float>`, """{"items":[1.1,2.2,3.3,4.4,5.5]}""",
//            "DummyArrayStreamPossiblyEmpty{items=[1.1, 2.2, 3.3, 4.4, 5.5]}");
//        checkLoad(`DummyArrayStreamPossiblyEmpty<String>`, """{"items":["one", "two", "three"]}""",
//            """DummyArrayStreamPossiblyEmpty{items=[one, two, three]}""");
//        checkLoad(`DummyArrayStreamPossiblyEmpty<Boolean>`, """{"items":[true, true, false]}""",
//            """DummyArrayStreamPossiblyEmpty{items=[true, true, false]}""");
//
//        checkLoad(`DummyArrayStreamPossiblyEmpty<JsonArray>`, """{"items":[[111], [22, 22], [33, 33, 33]]}""",
//            """DummyArrayStreamPossiblyEmpty{items=[[111], [22,22], [33,33,33]]}""");
//        checkLoad(`DummyArrayStreamPossiblyEmpty<JsonObject>`, """{"items":[{"foo":123}, {"bar":456}]}""",
//            """DummyArrayStreamPossiblyEmpty{items=[{"foo":123}, {"bar":456}]}""");
//
//        checkLoad(`DummyArrayStreamPossiblyEmpty<Value>`, """{"items":[111, 22.33, "DUMMY-VALUE", true, [456], {"foo":789}, null]}""",
//            """DummyArrayStreamPossiblyEmpty{items=[111, 22.33, DUMMY-VALUE, true, [456], {"foo":789}, <null>]}""", "array of ceylon.json::Value");
//
//        checkLoad(`DummyArrayStreamPossiblyEmpty<Integer>`, """{"items":[]}""",
//            "DummyArrayStreamPossiblyEmpty{items=[]}", "empty array");
//        checkLoad(`DummyArrayStreamPossiblyEmpty<Integer?>`, """{"items":[123, null]}""",
//            "DummyArrayStreamPossiblyEmpty{items=[123, <null>]}", "array of optional values");
//        checkLoad(`DummyArrayStreamPossiblyEmpty<Integer|String>`, """{"items":[123, "DUMMY"]}""",
//            "DummyArrayStreamPossiblyEmpty{items=[123, DUMMY]}", "array of union");
//
//        checkLoadFailed(`DummyArrayStreamPossiblyEmpty<String>`, """{"items":["DUMMY", 123]}""", "mixed array");
    }

    // todo !!! test other streams, ceylon Array and others collections (or may be collection schedule to extended)
    // todo !!! test tuples (or may delay it to next releases)
    // todo !!! support maps

    //
    //  Implementation details
    //

    // todo !!! comment here about this use case here: https://ceylon-lang.org/blog/2015/06/03/generic-function-refs/

    void checkJsonValues() {
        value clsDecl = `class DummyArraySequential`;

//        value checks = {
//            [`Integer`, """{"items":[11,22,33,44,55]}""", "DummyArraySequential{items=<(11, 22, 33, 44, 55)>"],
//            [`Float`, """{"items":[1.1,2.2,3.3,4.4,5.5]}""", "DummyArraySequential{items=<(1.1, 2.2, 3.3, 4.4, 5.5)>}"],
//
//        };
        // todo !!! continue from here

        checkLoad(`DummyArraySequential<Integer>`, """{"items":[11,22,33,44,55]}""",
            "DummyArraySequential{items=<(11, 22, 33, 44, 55)>");
        checkLoad(`DummyArraySequential<Float>`, """{"items":[1.1,2.2,3.3,4.4,5.5]}""",
            "DummyArraySequential{items=<(1.1, 2.2, 3.3, 4.4, 5.5)>}");
        checkLoad(`DummyArraySequential<String>`, """{"items":["one", "two", "three"]}""",
            """DummyArraySequential{items=<(one, two, three)>}""");
        checkLoad(`DummyArraySequential<Boolean>`, """{"items":[true, true, false]}""",
            """DummyArraySequential{items=<(true, true, false)>}""");

        checkLoad(`DummyArraySequential<JsonArray>`, """{"items":[[111], [22, 22], [33, 33, 33]]}""",
            """DummyArraySequential{items=<([111], [22,22], [33,33,33])>}""");
        checkLoad(`DummyArraySequential<JsonObject>`, """{"items":[{"foo":123}, {"bar":456}]}""",
            """DummyArraySequential{items=<({"foo":123}, {"bar":456})>}""");

        checkLoad(`DummyArraySequential<Value>`, """{"items":[111, 22.33, "DUMMY-VALUE", true, [456], {"foo":789}, null]}""",
            """DummyArraySequential{items=<(111, 22.33, DUMMY-VALUE, true, [456], {"foo":789}, <null>)>}""", "array of ceylon.json::Value");

        checkLoad(`DummyArraySequential<Integer>`, """{"items":[]}""",
            "DummyArraySequential{items=<()>}", "empty array");
        checkLoad(`DummyArraySequential<Integer?>`, """{"items":[123, null]}""",
            "DummyArraySequential{items=<(123, <null>)>}", "array of optional values");
        checkLoad(`DummyArraySequential<Integer|String>`, """{"items":[123, "DUMMY"]}""",
            "DummyArraySequential{items=<(123, DUMMY)>}", "array of union");

        checkLoadFailed(`DummyArraySequential<String>`, """{"items":["DUMMY", 123]}""", "mixed array");
    }

    void checkLoad(Class<> cls, String json, String expected, String? msg = null) {
        checkLoadCommon(cls, json,
            expected.replace("<(", brackets[0]).replace(")>", brackets[1]),
            msg);
    }

}
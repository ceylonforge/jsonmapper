import ceylon.json {
    JsonObject,
    JsonArray,
    Value
}
import ceylon.language.meta.declaration {
    ClassDeclaration
}
import ceylon.language.meta.model {
    Class,
    Type
}
import ceylon.test {
    createTestRunner,
    test,
    parameters
}
import ceylon.test.engine {
    DefaultLoggingListener
}

shared void runNestedArrayTests() {
    createTestRunner([`class NestedArrayTest`], [DefaultLoggingListener()]).run();
}

shared void runOneTest() {
    createTestRunner([`function NestedArrayTest.testEmpty`], [DefaultLoggingListener()]).run();
}

shared {[ClassDeclaration, [String, String]]*} testArrayParams => {
    [`class DummyArraySequential`, ["[", "]"]],
    [`class DummyArraySequence`, ["[", "]"]],
    [`class DummyArrayStreamPossiblyEmpty`, ["{ ", " }"]],
    [`class DummyArrayStreamNonEmpty`, ["{ ", " }"]]
};

alias CheckExpected => String|Failed;
alias CheckCase => [Type<>, String, CheckExpected|CheckExpected(Type<>)|CheckExpected(ClassDeclaration), String?];

class NestedArrayTest() {

    variable [String,String] brackets = ["UNDEFINED", "UNDEFINED"];
    variable String expectedClassName = "UNDEFINED";

    // todo !!! test other streams, ceylon Array and others collections (or may be collection schedule to extended)
    // todo !!! test tuples (or may delay it to next releases)
    // todo !!! support maps

    // todo !!! comment here about this use case here: https://ceylon-lang.org/blog/2015/06/03/generic-function-refs/

    test
    parameters(`value testArrayParams`)
    shared void testJsonValues(ClassDeclaration classDecl, [String, String] brackets) {
        {CheckCase+} checks = {
            [`Integer`, """{"items":[11,22,33,44,55]}""", "{items=<(11, 22, 33, 44, 55)>}", null],
            [`Float`, """{"items":[1.1,2.2,3.3,4.4,5.5]}""", "{items=<(1.1, 2.2, 3.3, 4.4, 5.5)>}", null],
            [`String`, """{"items":["one", "two", "three"]}""", """{items=<(one, two, three)>}""", null],

            [`Boolean`, """{"items":[true, true, false]}""", """{items=<(true, true, false)>}""", null],

            [`JsonArray`, """{"items":[[111], [22, 22], [33, 33, 33]]}""", """{items=<([111], [22,22], [33,33,33])>}""", null],
            [`JsonObject`, """{"items":[{"foo":123}, {"bar":456}]}""", """{items=<({"foo":123}, {"bar":456})>}""", null],

            [`Integer?`, """{"items":[123, null]}""", "{items=<(123, <null>)>}", "array of optional values"],
            [`Integer|String`, """{"items":[123, "DUMMY"]}""", "{items=<(123, DUMMY)>}", "array of union"],

            [`String`, """{"items":["DUMMY", 123]}""", failed, "mixed array"]
        };

        checkCases(classDecl, brackets, checks);
    }

    test
    parameters(`value testArrayParams`)
    shared void testObjects(ClassDeclaration classDecl, [String, String] brackets) {
        {CheckCase+} checks = {
            [`DummyInteger`, """{"items":[{"int":111}, {"int":222}]}""",
                    "{items=<(DummyInteger{int=111}, DummyInteger{int=222})>}", null],
            [`DummyInteger?`, """{"items":[{"int":111}, null, {"int":222}]}""",
                    "{items=<(DummyInteger{int=111}, <null>, DummyInteger{int=222})>}", "optional values"],
            [`DummyInteger|DummyString`, """{"items":[{"int":123123}, {"str":"DUMMY"}]}""", failed, "sequential of general union is not supported for now"]
        };

        checkCases(classDecl, brackets, checks);
    }

    test
    parameters(`value testArrayParams`)
    shared void testValue(ClassDeclaration classDecl, [String, String] brackets) {
        {CheckCase+} checks = {
            [`Value`, """{"items":[111, 22.33, "DUMMY-VALUE", true, [456], {"foo":789}, null]}""",
                (Type<> cls) => if (cls == `DummyArrayStreamPossiblyEmpty<Value>`)
                                then """{items=[111,22.33,"DUMMY-VALUE",true,[456],{"foo":789},null]}""" // JsonArray is used for DummyArrayStreamPossiblyEmpty
                                else """{items=<(111, 22.33, DUMMY-VALUE, true, [456], {"foo":789}, <null>)>}""",
                "array of ceylon.json::Value"]
        };

        checkCases(classDecl, brackets, checks);
    }

    test
    shared void testNestedNested() {
        checkLoad(`DummyArraySequential<DummyArraySequential<DummyInteger>>`, """{"items":[{"items":[{"int":111}]}, {"items":[{"int":222}]}]}""",
            "DummyArraySequential{items=[DummyArraySequential{items=[DummyInteger{int=111}]}, DummyArraySequential{items=[DummyInteger{int=222}]}]}");
        checkLoad(`DummyArraySequence<DummyArraySequence<DummyInteger>>`, """{"items":[{"items":[{"int":111}]}, {"items":[{"int":222}]}]}""",
            "DummyArraySequence{items=[DummyArraySequence{items=[DummyInteger{int=111}]}, DummyArraySequence{items=[DummyInteger{int=222}]}]}");
        checkLoad(`DummyArrayStreamPossiblyEmpty<DummyArrayStreamPossiblyEmpty<DummyInteger>>`, """{"items":[{"items":[{"int":111}]}, {"items":[{"int":222}]}]}""",
            "DummyArrayStreamPossiblyEmpty{items={ DummyArrayStreamPossiblyEmpty{items={ DummyInteger{int=111} }}, DummyArrayStreamPossiblyEmpty{items={ DummyInteger{int=222} }} }}");
        checkLoad(`DummyArrayStreamNonEmpty<DummyArrayStreamNonEmpty<DummyInteger>>`, """{"items":[{"items":[{"int":111}]}, {"items":[{"int":222}]}]}""",
            "DummyArrayStreamNonEmpty{items={ DummyArrayStreamNonEmpty{items={ DummyInteger{int=111} }}, DummyArrayStreamNonEmpty{items={ DummyInteger{int=222} }} }}");
    }

    test
    parameters(`value testArrayParams`)
    shared void testEmpty(ClassDeclaration classDecl, [String, String] brackets) {
        value expected = (ClassDeclaration clsDecl) => if (clsDecl == `class DummyArraySequential` || clsDecl == `class DummyArrayStreamPossiblyEmpty`)
                then "{items=[]}"
                else failed;

        {CheckCase+} checks = {
            [`Integer`, """{"items":[]}""", expected, "scalar"],
            [`DummyInteger`, """{"items":[]}""", expected, "object"]
        };

        checkCases(classDecl, brackets, checks);
    }

    //
    //  Implementation details
    //

    void checkCases(ClassDeclaration classDecl, [String, String] brackets, {CheckCase+} checks) {
        this.expectedClassName = classDecl.name;
        this.brackets = brackets;

        for ([itemType, json, expected, msg] in checks) {
            value cls = classDecl.classApply<>(itemType);
            switch (expected)
            case (is CheckExpected) {
                checkLoadCase(cls, json, expected, msg);
            }
            case (is CheckExpected(Type<>)) {
                checkLoadCase(cls, json, expected(cls), msg);
            }
            else {
                checkLoadCase(cls, json, expected(classDecl), msg);
            }
        }
    }

    void checkLoadCase(Class<> cls, String json, CheckExpected expected, String? msg = null) {
        switch (expected)
        case (is String) {
            checkLoad(cls, json,
                expectedClassName + expected.replace("<(", brackets[0]).replace(")>", brackets[1]),
                msg);
        }
        case (is Failed) {
            checkLoadFailed(cls, json, msg);
        }
    }
}

abstract class Failed() of failed {}
object failed extends Failed() {}
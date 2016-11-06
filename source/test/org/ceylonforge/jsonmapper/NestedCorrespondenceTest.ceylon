import ceylon.json {
    Value,
    JsonArray,
    JsonObject
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
    buildJsonLoad
}

shared void runNestedCorrespondenceTest() {
    createTestRunner([`class NestedCorrespondenceTest`], [DefaultLoggingListener()]).run();
}

class NestedCorrespondenceTest() {

    test
    shared void testCorrespondence() {
        checkCorr(`DummyObjectCorrespondence<Integer>`, """{"map":{ "one": 123, "two":789, "three":456 }}""",
            {
                "one" -> 123,
                "two" -> 789,
                "three" -> 456,
                "foo" -> absent
            });
        checkCorr(`DummyObjectCorrespondence<Integer?>`, """{"map":{ "one": 123, "two":null, "three":456 }}""",
            {
                "one" -> 123,
                "two" -> null,
                "three" -> 456,
                "foo" -> absent
            });
        checkCorr(`DummyObjectCorrespondence<Integer|String>`, """{"map":{ "one": 123, "two":"DUMMY", "three":456 }}""",
            {
                "one" -> 123,
                "two" -> "DUMMY",
                "three" -> 456,
                "foo" -> absent
            });
        checkCorr(`DummyObjectCorrespondence<Value>`, """{"map":{ "int": 123, "str":"DUMMY", "float":456.78, "bool":true,
                                                                 "array":[12,23,34], "object":{"aaa":987}, "nil":null }}""",
            {
                "int" -> 123,
                "str" -> "DUMMY",
                "float" -> 456.78,
                "bool" -> true,
                "array" -> JsonArray{ 12, 23, 34 },
                "object" -> JsonObject{ "aaa"->987 },
                "nil" -> null,
                "foo" -> absent
            });

        checkCorr(`DummyObjectCorrespondence<Integer>`, """{"map":{ }}""",
            {
                "one" -> absent,
                "foo" -> absent
            }, "empty");

        checkCorr(`DummyObjectCorrespondence<DummyInteger>`, """{"map":{ "one":{"int":123123} }}""",
            {
                "one" -> DummyInteger(123123),
                "foo" -> absent
            }, "DummyInteger");
    }

    test
    shared void testUnionFailed() {
        value obj = buildJsonLoad<>()(`DummyObjectCorrespondence<DummyString|DummyInteger>`, """{"map":{ "one":{"str":"DUMMY"}, "two":{"int":123} }}""");
        assert (is DummyObjectCorrespondence<DummyString|DummyInteger> obj);
        try {
            value one = obj.map["one"];
            fail("There is no exception for ONE");
        } catch (e) {
            print("*** Info about exception: ``e``");
        }
        try {
            value two = obj.map["two"];
        } catch (e) {
            print("*** Info about exception: ``e``");
        }
    }

    // todo !!! [k->v], [k->v+], {k->v*}, {k->v+}
    // todo !!! Collection<k->v>
    // todo !!! Map<k, v>

    void checkCorr(Class<> cls, String json, {<String->Anything>+} expected, String? msg = null) {
        value obj = buildJsonLoad<>()(cls, json);
        assert(is DummyObjectCorrespondence<Anything> obj);
        value actual = {
            for (k->v in expected)
                if (obj.map.defines(k))
                then k->obj.map[k]
                else k->absent
        };
        assertEquals(actual.string, expected.string);
    }

}

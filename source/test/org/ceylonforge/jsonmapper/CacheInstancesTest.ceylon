import ceylon.language.meta.model {
    Class
}
import ceylon.test {
    test,
    assertEquals,
    createTestRunner
}
import ceylon.test.engine {
    DefaultLoggingListener
}

import org.ceylonforge.jsonmapper {
    buildJsonLoad,
    JsonLoadResult
}

shared void runCacheInstancesTest() {
    createTestRunner([`class CacheInstancesTest`], [DefaultLoggingListener()]).run();
}

class CacheInstancesTest() {
    test
    shared void testTopLevelArrayOfObjects() {
        checkLoadCached(`DummyCached`, """[{"int":123}, {"int":456}]""");
    }

    test
    shared void testCorrespondence() {
        checkLoadCached(`DummyObjectCorrespondence<DummyCached>`, """{"map":{"one":{"int":123}, "two":{"int":456}}}""",
            (JsonLoadResult<DummyObjectCorrespondence<DummyCached>> obj) =>
                if (is DummyObjectCorrespondence<DummyCached> obj)
                then "{one=``tostr(obj.map["one"])``, two=``tostr(obj.map["two"])``}"
                else "TOSTR-NOT-IMPLEMENTED-HERE-FOR-ITERABLE"
        );
    }

    // todo !!! support caching objects in nested iterable and for top level iterable

}

void checkLoadCached<T>(Class<T> cls, String json, String(JsonLoadResult<T>) tostr = (JsonLoadResult<T> obj) => obj.string) given T satisfies Object {
    value obj = buildJsonLoad<T>()(cls, json);
    value string1st = tostr(obj);
    assertEquals(tostr(obj), string1st, "2nd string wrong");
}

variable Integer instanceCounter = 0;

class DummyCached(Integer int) {
    Integer count = instanceCounter++;
    shared actual String string => classname(this) + "{``count``@int=``int``}";
}
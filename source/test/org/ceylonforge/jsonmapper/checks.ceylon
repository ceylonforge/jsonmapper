import ceylon.language.meta {
    type
}
import ceylon.language.meta.model {
    Class
}
import ceylon.test {
    assertEquals,
    fail,
    createTestRunner
}
import org.ceylonforge.jsonmapper {
    JsonLoadException,
    buildJsonLoad
}
import ceylon.test.engine {
    DefaultLoggingListener
}

shared void runAllTests() {
    createTestRunner([`module test.org.ceylonforge.jsonmapper`], [DefaultLoggingListener()]).run();
}

String tostr(Anything val) => val?.string else "<null>";
String classname(Anything obj) {
    return type(obj).declaration.name;
}

void checkLoad(Class<> cls, String json, String expected, String? msg = null) {
    value obj = buildJsonLoad<>()(cls, json);
    assert(is Object obj);
    assertEquals(obj.string, expected, msg);
}

void checkLoadFailed(Class<> cls, String json, String? msg = null) {
    try {
        value loaded = buildJsonLoad<>()(cls, json);
        fail("\n***** THERE IS NO EXCEPTION``if (exists msg) then ": " + msg  else ""`` *****\n" +
        ("JSON '``json``'\n\t\t-> ``tostr(loaded)``" +
        "\n*********************************\n"));
    } catch (JsonLoadException e) {
        print("*** Info about exception:\n``e``");

        // todo maybe move CauseStack into JsonLoad-function - and extract JsonExceptionInfo into separate class (and setup error verbosing in config)
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
    }
}

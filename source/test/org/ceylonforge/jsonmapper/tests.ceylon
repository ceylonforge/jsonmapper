import ceylon.language.meta {
    type
}
String tostr(Anything val) => val?.string else "<null>";
String classname(Anything obj) {
    return type(obj).declaration.name;
}

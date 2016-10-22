import ceylon.json {
    JSONObject = Object,
    parse,
    Value,
    JSONArray = Array
}
import ceylon.language.meta.declaration {
    ClassDeclaration
}
import ceylon.language.meta.model {
    Class,
    Type,
    Gettable
}
import ceylon.language.meta {
    type
}

// todo !!! rename library to something like json-load/jsonloader (jsonloader - нормальный вариант)

// todo !!! remove this alias
//shared alias Factory<Produced> => Type<Produced> -> Produced(Value);

shared ResultType load<ResultType, Arguments>(
        Class<ResultType, Arguments> cls,
        String json,
        Converter[] converters = []) {
    assert(is JSONObject jsonObject = parse(json));
    return parseJSONObject(cls, jsonObject, converters);
}

// todo !!! remove
//shared ResultType load2<ResultType, Arguments>(
//    Class<ResultType, Arguments> cls,
//    String json,
//    Anything(Nothing)[] factories = []
//) {
//    assert(is JSONObject jsonObject = parse(json));
//    return parseJSONObject(cls, jsonObject);
//}

shared final sealed annotation class EnumAnnotation()
        satisfies OptionalAnnotation<EnumAnnotation, ClassDeclaration> {}
shared annotation EnumAnnotation enum() => EnumAnnotation();

shared final sealed annotation class WrapAnnotation()
        satisfies OptionalAnnotation<WrapAnnotation, ClassDeclaration> {}
shared annotation WrapAnnotation wrap() => WrapAnnotation();

shared alias Converter => Anything(String) | Anything(Boolean) | Anything(Integer) | Anything(Float) |
                            Anything(JSONObject) | Anything(JSONArray) | Anything(Null);

// todo !!! converter'ы нужно добавлять по одному типу ?

// todo !!! refactore to class with state (i.e. factories in state)
//ResultType parseJSONObject<ResultType, Arguments>(
ResultType parseJSONObject<ResultType>(
        Class<ResultType> cls,
        JSONObject jsonObject,
        Converter[] converters) {
    assert(exists ctr = cls.defaultConstructor);
    value names = { for (p in ctr.declaration.parameterDeclarations) if (p.name in jsonObject.keys) p.name };

    // todo !!! может вообще на api десериализации перейти
    // todo !!! или пойти через атрибуты класса (а не через инициализатор) - но есть ли там значения по умолчанию?
    //       может вообще абстрагироваться от поьььлучения списка именованных параметров

    // или все-таки оставить инициализацию через параметры инициализатора (то есть таким образом отличать атрибуты, которые берем из JSON'a и прочие атрибуты, которые могут быть у класса)
    // поэтому называем не mapper, а loader
    //      с другой стороны, будет обратный процесс выгрузки в json - и здесь надо решить, что выгружать

    print("*** JSON keys: " + jsonObject.keys.string); // todo !!! remove

    try {

//        value a = zipPairs(names, ctr.parameterTypes).map((p) );

        value params = {
            for (p in zipPairs(names, ctr.parameterTypes))
                let (name = p[0])
                name -> convertJsonValue(jsonObject[name], p[1], converters)
        };

        print("*** PARAMS: " + params.string); // todo !!! remove
        return ctr.namedApply(params);
    } catch (e) {
        throw JsonLoadException("Error loading JSON into object of class " + cls.string, e);
    }
}

//shared ResultType load<ResultType, Arguments>(
//Class<ResultType, Arguments> cls,
//String json,

shared alias JsonUloadToString<in Unloadable = Nothing> => String(Unloadable);

shared ResultType load333<ResultType>(
Class<ResultType> cls,
String json) {
    assert(is JSONObject jsonObject = parse(json));
    return parseJSONObject(cls, jsonObject, []);
}

shared class JsonMappingBuilder() {

    shared JsonLoad<ResultType> buildLoad<ResultType = Anything>() {
        return (Class<ResultType> cls, String json) {
            assert(is JSONObject jsonObject = parse(json));
            return parseJSONObject<ResultType>(cls, jsonObject, []);

        };
//        JsonLoad<ResultType> load = (Class<ResultType> cls, String json) {
//
//        };

//        return load;
    }

    shared JsonUloadToString<Unloadable> buildUnloadToString<in Unloadable = Nothing>() {
        return (Unloadable obj) {
            return "TODO"; // todo !!! implement
        };
    }
}

// todo !!! remove
//JsonUloadToString<> dummy = (Null obj) {
//    return "";
//}


// todo !!! instead of nothing - use intersection
Anything convertJsonValue(Value jsonValue, Type<> paramType, Converter[] converters) {
//    let (jsonValue = jsonObject[name], paramType = p[1])
//    if (is JSONObject jsonValue, is Class<> paramType)
//    then parseJSONObject(paramType, jsonValue)
//    else jsonValue

    // todo !!! generify jsonValue processing pipeline (and prepare with builder) - and spread in tests - separate pipeline with features
    // todo !!! or use filter pattern (то есть с явной передачей управления дальше?

    if (paramType.subtypeOf(`String | Boolean | Integer | Float`)) {
        return jsonValue; // todo ??? !!! test converters for this 'primitive classes' ?
    }

    if (is Class<> paramType) {
        if (is JSONObject jsonValue) {
            return parseJSONObject(paramType, jsonValue, converters);
        }
        if (is String jsonValue) {
//            todo !!! test enum
//            ,exists enumAnnotation = optionalAnnotation(`EnumAnnotation`, paramType.declaration)) {

//            print("*** jsonValue = " + jsonValue); // todo !!! remove
//            value aaa = paramType.getConstructor(jsonValue);
//            print("*** VCTR: " + (aaa?.string else "NULL")); // todo !!! remove

            if (is Gettable<> valueCtr = paramType.getConstructor(jsonValue)) {
                return valueCtr.get();
            }
            // todo !!! test error else

            // todo DEFFERED test inherited enum
        }

        // todo !!! check for wrap annotation (need test)
        // todo !!! implement autowrap - возможность явно указать типы (классы), которые без wrap будут использоваться
        // todo !!! implement wrap annotation constraint - возможность применять только к классам с инициализатором Value-совместимым
        // ??? generalize to converter ?
        if (exists ctr = paramType.defaultConstructor) {
            print("*** CTR APPLY: " + ctr.string);

            // todo !!! ??? test for this assert (что удоабвлетворяет Converter)
//            assert (); на value

            return ctr.apply(jsonValue); // wrapper
        }
    }

    // todo !!! addConverter in build would create ConvertersResolver lazy
    Anything converted;

    switch (jsonValue)
    case (is String) {
        converted = tryConverters(jsonValue, paramType, converters);
    }
    case (is Boolean) {
        converted = tryConverters(jsonValue, paramType, converters);
    }
    case (is Integer) {
        converted = tryConverters(jsonValue, paramType, converters);
    }
    case (is Float) {
        converted = tryConverters(jsonValue, paramType, converters);
    }
    case (is JSONObject) {
        converted = tryConverters(jsonValue, paramType, converters);
    }
    case (is JSONArray) {
        converted = tryConverters(jsonValue, paramType, converters);
    }
    case (is Null) {
        converted = tryConverters(jsonValue, paramType, converters);
    }

    // todo !!! check for absent value
    return converted;

//    for (converter in converters) {
//        if (exists returnType = type(converter).typeArgumentList[0], returnType.subtypeOf(paramType)) {
//            switch (jsonValue) // todo !!! (??? получится ли ?) extract this switch out of cycle (generefy cycle with jsonValue type)
//            case (is String) {
//                assert (is Anything(String) converter);
//                return converter(jsonValue);
//            }
//            case (is Boolean) {
//                assert (is Anything(Boolean) converter);
//                return converter(jsonValue);
//            }
//            case (is Integer) {
//                assert (is Anything(Integer) converter);
//                return converter(jsonValue);
//            }
//            case (is Float) {
//                assert (is Anything(Float) converter);
//                return converter(jsonValue);
//            }
//            case (is JSONObject) {
//                assert (is Anything(JSONObject) converter);
//                return converter(jsonValue);
//            }
//            case (is JSONArray) {
//                assert (is Anything(JSONArray) converter);
//                return converter(jsonValue);
//            }
//            case (is Null) {
//                assert (is Anything(Null) converter);
//                return converter(jsonValue);
//            }
//        }
//    }

//    for (converter in converters) {
//        value aaa = type(converter);
//
//
//        value ccc = { for (c in converters) if (paramType.exactly(`Callable<Anything, Nothing>`)) aaa.satisfiedTypes[0] };
////        print("*** AAA: " + aaa.string);
////        if (type(f).)
//    }

//    return jsonValue; // todo !!! ??? throw error here ?
}

// todo !!! todo file feature (into github) request for use Aliases in of for generics
Anything tryConverters<JsonValue>(JsonValue jsonValue, Type<> paramType, Converter[] converters) given JsonValue of String | Boolean | Integer | Float | JSONObject | JSONArray | Null {
    for (converter in converters) {
        if (exists returnType = type(converter).typeArgumentList[0], returnType.subtypeOf(paramType),
                is Anything(JsonValue) converter) {
            return converter(jsonValue);
        }
    }

    return null; // todo !!! return special object for absent
}

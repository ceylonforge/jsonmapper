import ceylon.json {
    JsonObject,
    JsonArray,
    Value,
    parse
}
import ceylon.language.meta {
    classDeclaration,
    type
}
import ceylon.language.meta.declaration {
    FunctionOrValueDeclaration
}
import ceylon.language.meta.model {
    Class,
    Type,
    CallableConstructor,
    UnionType,
    ClassOrInterface
}

//
//  Public API
//

"Build function to load JSON into objects"
shared JsonLoad<ResultType> buildJsonLoad<ResultType = Anything>() {
    return JsonLoader<ResultType>().load;
}

shared alias JsonSource => String;
shared alias JsonLoadResult<ResultType> => ResultType|{ResultType*};
shared alias JsonLoad<ResultType = Anything> => JsonLoadResult<ResultType>(Class<ResultType>, JsonSource);

shared class JsonLoadException(String description, Throwable? cause = null) extends Exception(description, cause) {}

//
//  Implementation details
//

alias ParameterZip => [FunctionOrValueDeclaration, Type<Anything>];

class JsonLoader<ResultType = Anything>() {

    shared JsonLoadResult<ResultType> load(Class<ResultType> cls, JsonSource json) {
        Value parsed;
        try {
            parsed = parse(json);
        } catch (Exception e) {
            throw JsonLoadException("Error parsing JSON: " + jsonInfo(json), e);
        }
        if (is JsonObject parsed) {
            return loadJsonObject<ResultType>(cls, parsed);
        }
        if (is JsonArray parsed) {
            return loadJsonArray<ResultType>(cls, parsed);
        }
        throw JsonLoadException("JSON is not object: " + jsonInfo(json));
    }

    {ResultType*} loadJsonArray<ResultType>(Class<ResultType> cls, JsonArray jsonArray) {
        return { for (value v in jsonArray) if (is JsonObject v) loadJsonObject(cls, v)};
    }

    ResultType loadJsonObject<ResultType>(Class<ResultType> cls, JsonObject jsonObject) {
        try {
            if (exists ctr = cls.defaultConstructor) {
                value parameters = zipParameters(ctr, jsonObject.keys);
                value params = [
                    for ([pdecl, ptype] in parameters)
                    let (name = pdecl.name)
                    name -> resolveValue(jsonObject[name], ptype)
                ]; // use sequential here for single evaluation
                try {
                    return ctr.namedApply(params);
                } catch (e) {
                    value b = StringBuilder().append("Constructor\n\t\t``ctr````ctr.parameterTypes``\nfailed with parameters:");
                    for (entry in params) {
                        b.append("\n\t\t``entry`` (``type(entry.item)``)");
                    }
                    throw JsonLoadException(b.string, e);
                }
            } else {
                throw JsonLoadException("Class ``cls`` has no default constructor");
            }
        } catch (e) {
            // todo DEFFERED reconsider this message for generics (because there are no type parameters in declaration.name)
            throw JsonLoadException("Load (JSON -> ``cls.declaration.name``) failed:\n\tClass: ``cls.declaration.qualifiedName``\n\tReason: ``e.message``\n\tException:``classDeclaration(e).qualifiedName``", e);
        }
    }

    {ParameterZip*} zipParameters(CallableConstructor<Anything> ctr, Collection<String> keys) {
        value parametersZip = zipPairs(ctr.declaration.parameterDeclarations, ctr.parameterTypes);
        return {
            for ([pdecl, ptype] in parametersZip) if (pdecl.name in keys) [pdecl, ptype]
        };
    }

    Target resolveValueTyped<Target>(Value jsonValue, Type<Target> targetType) {
        assert (is Target target = resolveValue(jsonValue, targetType));
        return target;
    }

    // todo ??? remove Target from this method as it An
    Anything resolveValue<Target>(Value jsonValue, Type<Target> targetType) {
        if (targetType.typeOf(jsonValue)) {
            return jsonValue;
        }
        if (is JsonObject jsonValue) {
            if (is Class<> targetType) {
                return loadJsonObject(targetType, jsonValue);
            }
            if (is UnionType<Target> targetType, exists targetClass = getClassIfOptional(targetType)) {
                return loadJsonObject(targetClass, jsonValue);
            }
        }
        if (is JsonArray jsonValue) {
            if (jsonValue.empty) {
                return [];
            }
            if (is ClassOrInterface<Iterable<>> targetType) {
                value iterable = resolveIterable(jsonValue, targetType);

                return if (targetType is ClassOrInterface<Sequential<>>)
                            then iterable.sequence()
                            else iterable;
            }
        }
        throw JsonLoadException("Can not resolve value '``tostr(jsonValue)``' into type '``targetType``'");
    }

    {Anything*} resolveIterable(JsonArray jsonValue, ClassOrInterface<Iterable<>> targetType) {
        value itemType = getIterableItemType(targetType);
        value streamType = `class JsonArrayIterable`.memberClassApply<JsonLoader<ResultType>>(`JsonLoader<ResultType>`, itemType);
        assert (exists streamConstructor = streamType.defaultConstructor);
        assert (is Iterable<> stream = streamConstructor.bind(this).apply(jsonValue, itemType));
        return stream;
    }

    class JsonArrayIterable<Element>(JsonArray jsonValue, Type<Element> itemType) satisfies Iterable<Element, Nothing> {
        shared actual Iterator<Element> iterator() => object satisfies Iterator<Element> {
            Iterator<Value> jsonIterator = jsonValue.iterator();
            shared actual Element|Finished next() {
                switch (next = jsonIterator.next())
                case (is Value) {
                    return resolveValueTyped<Element>(next, itemType);
                }
                case (is Finished) {
                    return next;
                }
            }
        };
    }

    Type<> getIterableItemType(ClassOrInterface<Iterable<>> targetType) {
        if (exists itemType = targetType.typeArgumentList.first) {
            return itemType;
        }
        throw JsonLoadException("Could not obtain sequential item type for ``targetType``");
    }

    "Return Target class if targetType is 'Target?'. Else return null."
    Class<Target>? getClassIfOptional<out Target>(UnionType<Target> targetType) {
        variable Class<Target>? targetClass = null;
        for (value caseType in targetType.caseTypes) {
            if (caseType.exactly(`Null`)) {
                // simply skip if Null
            } else if (is Class<Target> caseType) {
                if (targetClass exists) {
                    return null;
                }
                targetClass = caseType;
            }
        }
        return targetClass;
    }

    String jsonInfo(String json) {
        if (json.size == 0) {
            return "<EMTY>";
        } else if (json.size > 32) {
            return "'" + json.substring(0, 32) + "...'";
        } else {
            return "'" + json + "'";
        }
    }
}

Boolean isOptional(Type<> ptype) => ptype.supertypeOf(`Null`);
String tostr(Anything val) => val?.string else "<null>";




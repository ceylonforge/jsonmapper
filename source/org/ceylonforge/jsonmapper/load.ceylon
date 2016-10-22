import ceylon.json {
    JsonObject,
    JsonArray,
    Value,
    parse
}
import ceylon.language.meta {
    classDeclaration
}
import ceylon.language.meta.declaration {
    FunctionOrValueDeclaration
}
import ceylon.language.meta.model {
    Class,
    Type,
    CallableConstructor
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
                value names = { for (pz in parameters) pz[0].name };
                value params = {
                    for (p in zipPairs(names, ctr.parameterTypes))
                    let (name = p[0])
                    name -> resolveValue(jsonObject[name], p[1])
                };
                try {
                    return ctr.namedApply(params);
                } catch (e) {
                    throw JsonLoadException("Constructor '``ctr````ctr.parameterTypes``' failed with parameters '``params``'", e);
                }
            } else {
                throw JsonLoadException("Class ``cls`` has no default constructor");
            }
        } catch (e) {
            throw JsonLoadException("Load (JSON -> ``cls.declaration.name``) failed:\n\tClass: ``cls.declaration.qualifiedName``\n\tReason: ``e.message``\n\tException:``classDeclaration(e).qualifiedName``", e);
        }
    }

    {ParameterZip*} zipParameters(CallableConstructor<Anything> ctr, Collection<String> keys) {
        value parametersZip = zipPairs(ctr.declaration.parameterDeclarations, ctr.parameterTypes);
        return {
            for ([pdecl, ptype] in parametersZip) if (pdecl.name in keys) [pdecl, ptype]
        };
    }

    Anything resolveValue<Target>(Value jsonValue, Type<Target> targetType) {
        if (targetType.typeOf(jsonValue)) {
            return jsonValue;
        }
        return null;
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

Boolean isOptional(Type<> ptype) {
    return ptype.supertypeOf(`Null`);
}




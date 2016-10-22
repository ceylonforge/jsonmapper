import ceylon.language.meta.model {
    Class,
    Type,
    CallableConstructor
}
import ceylon.json {
    JSONObject=Object,
    Value,
    JSONArray=Array,
    parse
}
import ceylon.language.meta {
    type,
    typeLiteral,
    classDeclaration
}
import ceylon.language.meta.declaration {
    FunctionOrValueDeclaration
}

shared class JsonLoadException(String description, Throwable? cause = null) extends Exception(description, cause) {}

shared alias JsonSource => String;
shared alias JsonLoad<ResultType = Anything> => ResultType(Class<ResultType>, JsonSource);

shared class ResolveTarget<Target>(shared Type<Target> targetType) {
}

shared alias ValueResolver<Output = Anything, in Input = Value>
    given Input of String | Boolean | Integer | Float | JSONObject | JSONArray | Null
        => Output(Input, ResolveTarget<Output>);

shared alias PrimitiveValue => String | Boolean | Integer | Float | Null;

shared alias PrimitiveConverter<Output = Anything, in Input = PrimitiveValue>
    given Input of String | Boolean | Integer | Float | Null
        => Output(Input);

shared object notResolved {}

shared class JsonLoadConfiguration(
    "Auto convert Integer, Float, Boolean to and from String"
    shared Boolean autoConvertPrimitives = false,
    "Silently skip extra fields in JSON"
    shared Boolean skipExtraFields = true,
    "If true use null for missing nullable properties"
    shared Boolean autoNulls = false
) {}

// todo !!! if ResultType is not default - build effective "precompiled" version of JsonLoad-function
shared JsonLoad<ResultType> buildJsonLoad<ResultType = Anything>(JsonLoadConfiguration cfg = JsonLoadConfiguration()) {
    return JsonLoader<ResultType>(cfg).load; // todo !!! refactore - нужно учитывать конфигурацию здесь при сборке/построении функции, а не при выполнении функции (то есть pipe-line с контекстом сделать)
}

alias ParameterZip => [FunctionOrValueDeclaration, Type<Anything>];

class JsonLoader<ResultType = Anything>(JsonLoadConfiguration cfg) {

    // todo DEFFERED implement pretty/informic/usefull error messages (то есть чтобы было понятно, на чем и где упал мэппинг) - использовать для анализа этих мест вывод (print) тестов

    // todo !!! maybe refactore this class to use ValueResolvers

    ResultType loadJsonObject<ResultType>(Class<ResultType> cls, JSONObject jsonObject) {
        assert(exists ctr = cls.defaultConstructor);
        value keys = jsonObject.keys;
        //        value names = { for (p in ctr.declaration.parameterDeclarations) if (p.name in keys) p.name };
        {ParameterZip*} parameters = zipParameters(ctr, keys);

        // todo DEFFERED maybe implement fail fast missing fields (maybe as cfg parameter/strategy)

        // todo !!! remove
//        print("*** PARAMETERS: " + parameters.string); // todo !!! extract to DebugMonitor

        value names = { for (pz in parameters) pz[0].name };

        // todo !!! remove
//        print("*** NAMES: " + names.string);

        if (!cfg.skipExtraFields && !names.containsEvery(keys)) {
            //            throw JsonLoadException("JSON has some extra fields: " + keys.filter((String key) => !names.contains(key)).string);
            throw JsonLoadException("JSON has some extra fields: " + { for (k in keys) if (!k in names) k }.string);
        }

        try {
            value params = {
                for (p in zipPairs(names, ctr.parameterTypes))
                let (name = p[0])
                name -> resolveValue(jsonObject[name], p[1]) // use valueResolvers here
            //            name -> valueResolvers[0]
            };
//            print("*** PARAMS: " + params.string); // todo !!! remove

            // todo !!! remove
//            print("*** PTYPES: " + ctr.parameterTypes.string);

            try {
                return ctr.namedApply(params);
            } catch (e) {
                throw JsonLoadException("Initializer '``ctr````ctr.parameterTypes``' failed with parameters '``params``'", e);
            }
        } catch (e) {
            //            throw JsonLoadException("Error loading JSON into object of class ``cls.string`` (``e.message``)", e);
            // todo !!! use in every JsonLoad exception
            throw JsonLoadException("Load (JSON -> ``cls.declaration.name``) failed:\n\tClass: ``cls.declaration.qualifiedName``\n\tReason: ``e.message``\n\tException:``classDeclaration(e).qualifiedName``", e);
        }
    }

    shared ResultType load(Class<ResultType> cls, JsonSource json) {
        Value parsed;
        try {
            parsed = parse(json);
        } catch (Exception e) {
            throw JsonLoadException("Error parsing JSON: " + jsonInfo(json), e);
        }
        if (is JSONObject parsed) {
            // todo !!! test catch error and throw JsonLoadException
            return loadJsonObject<ResultType>(cls, parsed);
        }
        throw JsonLoadException("JSON is not object: " + jsonInfo(json));
    }

    {ParameterZip*} zipParameters(CallableConstructor<Anything> ctr, Collection<String> keys) {
        value parametersZip = zipPairs(ctr.declaration.parameterDeclarations, ctr.parameterTypes);
        if (cfg.autoNulls) {

            // todo !!! remove this debug
//            for ([pdecl, ptype] in zipPairs(ctr.declaration.parameterDeclarations, ctr.parameterTypes)) {
//                print("*** NAME: " + pdecl.name + ", PTYPE: " + ptype.string + ", is Null: " + isOptional(ptype).string);
//            }

            return {
                for ([pdecl, ptype] in zipPairs(ctr.declaration.parameterDeclarations, ctr.parameterTypes))
                    if (pdecl.name in keys || isOptional(ptype))
                        [pdecl, ptype]
            };
        } else {
            return {
                for ([pdecl, ptype] in parametersZip) if (pdecl.name in keys) [pdecl, ptype]
            };
        }
    }

    // todo !!! здесь по идее должно возвращаться Target - но пока не понятно, как на уровне компиляции это сделать (чтобы компилировалось)
    // todo !!! maybe remove Target because Anything here in real
//    Target resolveValue<Target>(Value jsonValue, Type<Target> targetType) {
    Anything resolveValue<Target>(Value jsonValue, Type<Target> targetType) {
        if (targetType.typeOf(jsonValue)) {
            return jsonValue;
        }
        if (cfg.autoConvertPrimitives) {
            if (is String jsonValue) {
                if (targetType.subtypeOf(`Integer`)) {
                    return parseInteger(jsonValue);
                }
                if (targetType.subtypeOf(`Boolean`)) {
                    return parseBoolean(jsonValue);
                }
                if (targetType.subtypeOf(`Float`)) {
                    return parseFloat(jsonValue);
                }
            }
            if (targetType.subtypeOf(`String`)) {
                return jsonValue?.string;
            }
        }

        return null; // todo !!! implement
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




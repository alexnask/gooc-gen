use gi
import structs/ArrayList
import gi/[CallbackInfo, CallableInfo, RegisteredTypeInfo, TypeInfo, ConstantInfo, Repository]
import OocWriter, Visitor, Utils

Callback: class {
    info: CallbackInfo

    init: func(=info)

    oocClosure?: func -> Bool {
        // If the last argument is a pointer, then we can turn this to an ooc closure , as context will be passed to the last argument
        if(info getNArgs() > 0) {
            arg := info getArg(info getNArgs() - 1)
            type := arg getType() toString()
            arg unref()
            return (type == "Pointer")
        }
        false
    }

    toOocString: func(namespace: String, parent: RegisteredTypeInfo = null, byValue?: Bool = false) -> String {
        // This assumes oocClosure? is true
        types := ""
        first := true
        for(i in 0..info getNArgs() - 1) {
            if(first) first = false
            else types += ", "

            arg := info getArg(i)
            types += arg oocType(namespace, parent, byValue?)
            arg unref()
        }

        returnType := info getReturnType()
        iface := returnType getInterface() as RegisteredTypeInfo
        if(iface) return "Func(%s) -> %s" format(types, iface oocType(namespace, parent, byValue?))
        else if(returnType toString() != "Void") return "Func(%s) -> %s" format(types, returnType toString(namespace))

        "Func(%s)" format(types)
    }
}

CallbackVisitor: class extends Visitor {
    callbacks := static ArrayList<Callback> new()
    callback: static func(name: String) -> Callback {
        ret: Callback = null
        This callbacks each(|cb|
            if(cb info getName() toString() == name) ret = cb
        )
        ret
    }

    info: CallbackInfo

    init: func(=info)

    write: func(writer: OocWriter) {
        // We don't actually write anything, but we create a Callback and store it
        This callbacks add(Callback new(info ref()))
    }
}

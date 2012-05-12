use gi
import gi/[BaseInfo, FunctionInfo, RegisteredTypeInfo, ArgInfo]
import OocWriter, Visitor, Utils

// Handle arguments of callback types (make them pointer, generate a second function that takes a closure and passes the context as a userData pointer if the function has one and the callback type has a last argument of pointer type)

FunctionVisitor: class extends Visitor {
    info: FunctionInfo
    // Parent type (declaration)
    parent: RegisteredTypeInfo
    byValue? := false

    init: func(=info)
    init: func~withParent(=info, =parent)
    init: func~withByValue(=info, =parent, =byValue?)

    write: func(writer: OocWriter) {
        namespace := info getNamespace() toString()
        name := info getName()
        inValueStruct? := (parent != null && byValue?)
        isStatic? := false
        isConstructor? := info getFlags() & FunctionInfoFlags isConstructor?
        suffix: String = null

        // This is pretty naive but at the moment only constructors are detected as static, I have found no other way to do it D:
        if(parent && isConstructor?) {
            isStatic? = true
            suffix = name toString()
            name = "new" toCString() // c"new"
        }

        // If the function is a structure members, this should be passed by reference
        writer w("%s: %sextern(%s) %s " format(name toString() toCamelCase(), (isStatic?) ? "static " : "", info getSymbol(), (inValueStruct?) ? "func@" : "func"))
        if(suffix) writer uw("~" + suffix)

        // Write arguments
        first := true
        // The previous type we wrote
        prevType := ""
        for(i in 0 .. info getNArgs()) {
            last? := i == info getNArgs() - 1
            arg := info getArg(i)
            type := arg oocType(namespace, parent, inValueStruct?)

            if(first) {
                prevType = type
                writer uw("(")
            }
            // If the type of the arguments hasn't changed and we arent on the last argument we can jus write the name of the argument, else we write its name and type
            argName := arg getName()
            if(first) {
                first = false
                if(last?) writer uw("%s : %s" format(argName, type))
                else writer uw(argName toString())
            } else if(type != prevType) {
                if(last?) writer uw(" : %s, %s : %s" format(prevType, argName, type))
                else writer uw(" : %s, %s" format(prevType, argName))
            } else if(last?) {
                writer uw(", %s : %s" format(argName, type))
            } else {
                writer uw(", %s" format(argName toString()))
            }
            prevType = type
            arg unref()
        }
        // If the function can throw an error, we need to add an Error* argument :)
        if(info getFlags() & FunctionInfoFlags throws?) {
            writer uw(", error : Error*")
        }

        if(!first) writer uw(") ")
        returnType := info getReturnType()
        iface := returnType getInterface() as RegisteredTypeInfo
        if(iface) writer uw("-> %s" format(iface oocType(namespace, parent, inValueStruct?)))
        else if(returnType toString() != "Void") writer uw("-> %s" format(returnType toString()))
        writer uw("\n")
    }
}

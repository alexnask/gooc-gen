use gi
import gi/[BaseInfo, FunctionInfo, RegisteredTypeInfo, ArgInfo]
import OocWriter, Visitor, Utils

FunctionVisitor: class extends Visitor {
    info: FunctionInfo
    // Parent type (declaration)
    parent: RegisteredTypeInfo
    byValue? := false

    init: func(=info)
    init: func~withParent(=info, =parent)
    init: func~withByValue(=info, =parent, =byValue?)

    write: func(writer: OocWriter) {
        name := info getName()
        inValueStruct? := (parent && byValue?)
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
            type := arg getType() toString()

            if(parent && type == parent getName() toString() escapeOocTypes()) {
                type = (inValueStruct?) ? "This*" : "This"
            }

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
        if(isConstructor? && parent && !inValueStruct?) {
            writer uw("-> This")
        } else if(isConstructor? && inValueStruct?) {
            writer uw("-> This*")
        } else if(returnType && (str := returnType toString()) != "Void") {
            if(parent && str == parent getName() toString() escapeOocTypes()) str = (inValueStruct?) ? "This*" : "This"
            writer uw("-> %s" format(str))
        }
        writer uw("\n")
    }
}

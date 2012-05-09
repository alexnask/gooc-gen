use gi
import gi/[BaseInfo, FunctionInfo, RegisteredTypeInfo, ArgInfo]
import OocWriter, Visitor, Utils

FunctionVisitor: class extends Visitor {
    info: FunctionInfo
    // Parent type (declaration)
    parent: RegisteredTypeInfo

    init: func(=info)
    init: func~tihParent(=info, =parent)

    write: func(writer: OocWriter) {
        name := info getName()
        inStruct? := (parent && parent isStructInfo?())
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
        writer w("%s: %sextern(%s) %s " format(name toString() toCamelCase(), (isStatic?) ? "static " : "", info getSymbol(), (inStruct?) ? "func@" : "func"))
        if(suffix) writer uw("~" + suffix)

        // Write arguments
        first := true
        // The previous type we wrote
        prevType := ""
        for(i in 0 .. info getNArgs()) {
            arg := info getArg(i)
            type := arg getType() toString()

            if(first) {
                first = false
                prevType = type
                writer uw("(")
            }
            else writer uw(", ")

            if(parent && type == parent getName() toString() escapeOocTypes()) {
                type = (inStruct?) ? "This*" : "This"
            }

            // If the type of the arguments hasn't changed and we arent on the last argument we can jus write the name of the argument, else we write its name and type
            argName := arg getName()
            if(type != prevType || !argName || i == info getNArgs() - 1) {
                prevType = type
                if(argName) {
                    writer uw("%s : %s" format(argName, type))
                } else {
                    writer uw(type)
                }
            } else {
                writer uw(argName toString())
            }

            arg unref()
        }
        // If the function can throw an error, we need to add an Error* argument :)
        if(info getFlags() & FunctionInfoFlags throws?) {
            writer uw(", error : Error*")
        }

        if(!first) writer uw(")")
        returnType := info getReturnType()
        if(isConstructor? && parent && !inStruct?) {
            writer uw(" -> This")
        } else if(isConstructor? && inStruct?) {
            writer uw(" -> This*")
        } else if(returnType && (str := returnType toString()) != "Void") {
            writer uw(" -> %s" format(str))
        }
        writer uw("\n")
    }
}

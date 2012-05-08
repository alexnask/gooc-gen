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
        isStatic? := false
        isConstructor? := info getFlags() & FunctionInfoFlags isConstructor?
        suffix: String = null

        // This is pretty naive but at the moment only constructors are detected as static, I have found no other way to do it D:
        if(parent && isConstructor?) {
            isStatic? = true
            suffix = name toString()
            name = "new" toCString() // c"new"
        }
        writer w("%s: %sextern(%s) func" format(name toString() toCamelCase(), (isStatic?) ? "static " : "", info getSymbol()))
        if(suffix) writer uw(" ~" + suffix)

        // Write arguments
        first := true
        for(i in 0 .. info getNArgs()) {
            if(first) {
                first = false
                writer uw("(")
            }
            else writer uw(", ")

            arg := info getArg(i)
            type := arg getType() toString()
            argName := arg getName()
            if(argName) {
                writer uw(argName toString() + " : " + type)
            } else {
                writer uw(type)
            }
            arg unref()
        }
        // If the function can throw an error, we need to add an Error* argument :)
        if(info getFlags() & FunctionInfoFlags throws?) {
            writer uw(", error : Error*")
        }

        if(!first) writer uw(")")
        returnType := info getReturnType()
        if(isConstructor? && parent) {
            writer uw(" -> This")
        } else if(returnType && (str := returnType toString()) != "Void") {
            writer uw(" -> %s" format(str))
        }
        writer uw("\n")
    }
}

use gi
import gi/[BaseInfo, FunctionInfo, RegisteredTypeInfo]
import OocWriter, Visitor

FunctionVisitor: class extends Visitor {
    info: FunctionInfo
    // Parent type (declaration)
    parent: RegisteredTypeInfo

    init: func(=info)
    init: func~tihParent(=info, =parent)

    write: func(writer: OocWriter) {
        name := info getName()
        isStatic? := false
        suffix: String = null

        // This is pretty naive but at the moment only constructors are detected as static, I have found no other way to do it D:
        if(parent && info getFlags() & FunctionInfoFlags isConstructor?) {
            isStatic? = true
            suffix = name toString()
            name = "new" toCString() // c"new"
        }
        writer w("%s: %sextern(%s) func %s(" format(name, (isStatic?) ? "static " : "", info getSymbol(), suffix ? "~" + suffix + " " : ""))

        for(i in 0 .. info getNArgs()) {
            arg :=  info getArg(i)
        }

        writer uw(")\n\n")
    }
}

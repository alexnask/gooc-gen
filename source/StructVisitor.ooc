use gi
import gi/[StructInfo, FunctionInfo, Repository]
import OocWriter, Visitor, FunctionVisitor, Utils

StructVisitor: class extends Visitor {
    info: StructInfo
    init: func(=info)

    write: func(writer: OocWriter) {
        name := info getName() toString() escapeOocTypes()
        // For some reason the ctype of the StructInfo is never populated and we cannot access it directly through an attribute, so we just find the prefix of the namespace and prepend it to sthe structure name
        writer w("%s: cover from %s%s {\n\n" format(name, Repository getCPrefix(null, info getNamespace()), info getName())) . indent()

        // Write methods
        for(i in 0 .. info getNMethods()) {
            method := info getMethod(i)
            FunctionVisitor new(method, info) write(writer)
            method unref()
        }

        writer dedent() . uw("\n\n}\n\n")
    }
}

use gi
import gi/[StructInfo, FunctionInfo, FieldInfo, Repository]
import OocWriter, Visitor, FunctionVisitor, Utils

StructVisitor: class extends Visitor {
    info: StructInfo
    init: func(=info)

    write: func(writer: OocWriter) {
        name := info getName() toString() escapeOocTypes()
        byValue? := (info getNFields() != 0)

        // If the structure only has dummy fields, it must be covered by reference
        dummies := true
        if(byValue?) {
            for(i in 0 .. info getNFields()) {
                field := info getField(i)
                if(!field getName() toString() startsWith?("dummy")) dummies = false
                field unref()
            }
            byValue? = !dummies
        }
        // For some reason the ctype of the StructInfo is never populated and we cannot access it directly through an attribute, so we just find the prefix of the namespace and prepend it to sthe structure name
        writer w("%s: cover from %s%s {\n\n" format(name, info cType(), (byValue?) ? "" : "*")) . indent()

        // Write methods
        for(i in 0 .. info getNMethods()) {
            method := info getMethod(i)
            FunctionVisitor new(method, info, byValue?) write(writer)
            method unref()
        }
        writer dedent() . uw("\n\n}\n\n")
    }
}

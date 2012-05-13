use gi
import gi/[StructInfo, FunctionInfo, FieldInfo, Repository]
import OocWriter, Visitor, FunctionVisitor, FieldVisitor, Utils

StructVisitor: class extends Visitor {
    info: StructInfo
    init: func(=info)

    write: func(writer: OocWriter) {
        namespace := info getNamespace() toString()
        name := info oocType(namespace)
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

        // Write fields
        if(byValue?) {
            for(i in 0 .. info getNFields()) {
                field := info getField(i)
                FieldVisitor new(field, info, byValue?) write(writer) . free()
                field unref()
            }
            writer uw('\n')
        }

        // Write methods
        for(i in 0 .. info getNMethods()) {
            method := info getMethod(i)
            FunctionVisitor new(method, info, byValue?) write(writer) . free()
            method unref()
        }
        writer dedent() . uw("\n\n}\n\n")
    }
}

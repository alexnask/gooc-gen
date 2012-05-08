use gi
import gi/[FunctionInfo, EnumInfo, Repository]
import OocWriter, Visitor, FunctionVisitor, Utils
import structs/ArrayList

// In the generated GLib binding, the typename of enums are null. WHY?! (Only happens in GLib)
EnumVisitor: class extends Visitor {
    info: EnumInfo
    init: func(=info)

    write: func(writer: OocWriter) {
        name := info getName() toString() escapeOocTypes()
        // For some reason, the ctype of the enum is never populated and we cant directly get it as an attribute, so we fetch the prefix of the current namespace and prepend it to the name of the enum :D
        writer w("%s: extern(%s%s) enum {\n\n" format(name, Repository getCPrefix(null, info getNamespace()), info getName())) . indent()

        // Write our values
        first := true
        for(i in 0 .. info getNValues()) {
            if(first) first = false
            else writer uw(",\n")

            value := info getValue(i)
            writer w("%s: extern(%s)" format(value getName() toString() toCamelCase() escapeOocTypes(), value getAttribute("c:identifier")))
            value unref()
        }
        writer uw('\n')
        // Write our methods
        for(i in 0 .. info getNMethods()) {
            method := info getMethod(i)
            FunctionVisitor new(method, info) write(writer)
            method unref()
        }

        writer uw('\n') . dedent() . w("}\n\n")
    }
}

use gi
import gi/[FunctionInfo, EnumInfo]
import OocWriter, Visitor, FunctionVisitor, Utils
import structs/ArrayList

// Must make new version of libgirepository, wich requires newer version of Glib :/
EnumVisitor: class extends Visitor {
    info: EnumInfo
    init: func(=info)

    write: func(writer: OocWriter) {
        name := info getName() toString() escapeOocTypes()
        writer w("%s: extern(%s) enum {\n\n" format(name, info getTypeName())) . indent()

        // Write our values
        first := true
        for(i in 0 .. info getNValues()) {
            if(first) first = false
            else writer uw(",\n")

            value := info getValue(i)
            writer w("%s = %d" format(value getName() toString() toCamelCase(), value getValue()))
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

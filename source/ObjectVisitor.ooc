use gi
import gi/[FunctionInfo, ObjectInfo, ArgInfo, InterfaceInfo, PropertyInfo, ConstantInfo]
import OocWriter, Visitor, FunctionVisitor, PropertyVisitor, ConstantVisitor, Utils
import structs/ArrayList

ObjectVisitor: class extends Visitor {
    info: ObjectInfo
    init: func(=info)

    write: func(writer: OocWriter) {
        name := info getName() toString() escapeOocTypes()
        writer w("%s: cover from %s*" format(name, info getTypeName()))
        parent := info getParent()
        if(parent) {
            parentName := parent getName() toString() escapeOocTypes()
            writer uw(" extends %s" format(parentName))
        }
        parent unref()

        nInter := info getNInterfaces()
        if(nInter > 0) {
            writer uw(" implements ")
            first := true
            for(i in 0 .. nInter) {
                if(first) first = false
                else writer uw(", ")
                inter := info getInterface(i)
                writer uw(inter getName() toString())
                inter unref()
            }
        }

        writer uw(" {\n\n") . indent()

        // Write our methods
        for(i in 0 .. info getNMethods()) {
            method := info getMethod(i)
            FunctionVisitor new(method, info) write(writer)
            method unref()
        }
        // Write our constants
        for(i in 0 .. info getNConstants()) {
            constant := info getConstant(i)
            ConstantVisitor new(constant, info) write(writer)
            constant unref()
        }

        writer uw('\n') . dedent() . w("}\n\n")
    }
}

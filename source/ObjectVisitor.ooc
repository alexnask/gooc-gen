use gi
import gi/[FunctionInfo, ObjectInfo, ArgInfo, InterfaceInfo]
import OocWriter, Visitor, FunctionVisitor

ObjectVisitor: class extends Visitor {
    info: ObjectInfo
    init: func(=info)

    write: func(writer: OocWriter) {
        name := (info getName() toString() == "Object") ? "_Object" : info getName() toString()
        writer w("%s: cover from %s*" format(name, info getTypeName()))
        parent := info getParent()
        if(parent) {
            parentName := (parent getName() toString() == "Object") ? "_Object" : parent getName() toString()
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

        for(i in 0 .. info getNMethods()) {
            method := info getMethod(i)
            FunctionVisitor new(method, info) write(writer)
            method unref()
        }

        writer dedent() . w("}\n\n")
    }
}

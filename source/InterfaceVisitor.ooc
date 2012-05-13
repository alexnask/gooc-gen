use gi
import gi/InterfaceInfo
import OocWriter, FunctionVisitor, ConstantVisitor, Visitor, Utils

InterfaceVisitor: class extends Visitor {
    info: InterfaceInfo
    init: func(=info)

    write: func(writer: OocWriter) {
        namespace := info getNamespace() toString()
        name := info oocType(namespace)

        writer w("%s: extern(%s) interface " format(name, info cType()))

        nInter := info getNPrerequisites()
        if(nInter > 0) {
            writer uw(" implements ")
            first := true
            for(i in 0 .. nInter) {
                if(first) first = false
                else writer uw(", ")
                inter := info getPrerequisite(i)
                writer uw(inter as InterfaceInfo oocType(namespace))
                inter unref()
            }
        }

        writer uw(" {\n\n") . indent()

        // Write our methods
        for(i in 0 .. info getNMethods()) {
            method := info getMethod(i)
            FunctionVisitor new(method, info) write(writer) . free()
            method unref()
        }
        // Write our constants
        for(i in 0 .. info getNConstants()) {
            constant := info getConstant(i)
            ConstantVisitor new(constant, info) write(writer) . free()
            constant unref()
        }

        writer uw('\n') . dedent() . w("}\n\n")
    }
}

use gi
import gi/[FunctionInfo, ObjectInfo, ArgInfo, InterfaceInfo, PropertyInfo, ConstantInfo]
import OocWriter, Visitor, FunctionVisitor, PropertyVisitor, ConstantVisitor, Utils
import structs/ArrayList

ObjectVisitor: class extends Visitor {
    info: ObjectInfo
    init: func(=info)

    write: func(writer: OocWriter) {
        namespace := info getNamespace() toString()
        name := info oocType(namespace)

        writer w("%s: cover from %s*" format(name, info cType()))
        parent := info getParent()
        if(parent) {
            writer uw(" extends %s" format(parent oocType(namespace)))
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
                writer uw(inter oocType(namespace))
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
        // We dont really care about object fields, they should not haev any and if they have all access should be done through members anywyay

        writer uw('\n') . dedent() . w("}\n\n")
    }
}

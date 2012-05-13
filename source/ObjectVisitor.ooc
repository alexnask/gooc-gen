use gi
import gi/[FunctionInfo, ObjectInfo, ArgInfo, InterfaceInfo, PropertyInfo, ConstantInfo]
import OocWriter, Visitor, FunctionVisitor, PropertyVisitor, ConstantVisitor, InterfaceVisitor, Utils
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

        // Write interfaces
        InterfaceVisitor written clear()
        nInter := info getNInterfaces()
        if(nInter > 0) {
            for(i in 0 .. nInter) {
                inter := info getInterface(i)
                if(inter isInterfaceInfo?()) InterfaceVisitor new(inter as InterfaceInfo, namespace) write(writer) . free()
                inter unref()
            }
        }

        writer uw('\n') . dedent() . w("}\n\n")
    }
}

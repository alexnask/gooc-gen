use gi
import structs/ArrayList
import gi/InterfaceInfo
import OocWriter, FunctionVisitor, ConstantVisitor, Visitor, Utils

InterfaceVisitor: class extends Visitor {
    written := static ArrayList<String> new() // Interfaces we have already written! The ObjectInfo should take care of clearing this list 

    namespace: String
    info: InterfaceInfo
    init: func(=info, =namespace)

    write: func(writer: OocWriter) {
        name := info oocType(namespace)

        This written add(name)
        writer w("// Namespace %s from C namespace %s\n" format(name, info cType()))

        nInter := info getNPrerequisites()
        if(nInter > 0) {
            for(i in 0..nInter) {
                inter := info getPrerequisite(i)
                name := inter as InterfaceInfo oocType(namespace)
                if(This written indexOf(name) < 0) {
                    if(inter isInterfaceInfo?()) This new(inter as InterfaceInfo, namespace) write(writer) . free()
                }
                inter unref()
            }
        }

        // Write our methods
        for(i in 0 .. info getNMethods()) {
            method := info getMethod(i)
            FunctionVisitor new(method, info, info getName() toString()) write(writer) . free()
            method unref()
        }
        // Write our constants
        for(i in 0 .. info getNConstants()) {
            constant := info getConstant(i)
            ConstantVisitor new(constant, info) write(writer) . free()
            constant unref()
        }
        writer w("// End of namespace %s\n\n" format(name))
    }
}


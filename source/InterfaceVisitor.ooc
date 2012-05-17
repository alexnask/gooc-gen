use gi
import structs/ArrayList
import gi/[RegisteredTypeInfo, InterfaceInfo]
import OocWriter, FunctionVisitor, ConstantVisitor, Visitor, Utils

// Writes interface declaration inside a class
InterfaceContentsVisitor: class extends Visitor {
    written := static ArrayList<String> new() // Interfaces we have already written! The ObjectInfo should take care of clearing this list 

    namespace: String
    info: InterfaceInfo
    init: func(=info, =namespace)

    write: func(writer: OocWriter) {
        name := info oocType(namespace)

        This written add(name)
        writer w("// Interface %s from C namespace %s\n" format(name, info cType()))

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
            FunctionVisitor new(method, info, info getName() toString(), namespace) write(writer) . free()
            method unref()
        }
        // Write our constants
        for(i in 0 .. info getNConstants()) {
            constant := info getConstant(i)
            ConstantVisitor new(constant, info) write(writer) . free()
            constant unref()
        }
        writer w("// End of interface %s\n\n" format(name))
    }
}

// Writes the actual interface
InterfaceVisitor: class extends Visitor {
    info: InterfaceInfo
    init: func(=info)

    write: func(writer: OocWriter) {
        namespace := info getNamespace() toString()
        name := info oocType(namespace)

        writer w("%s: interface" format(name))

        // Only write interface prerequisites :D
        nInter := info getNPrerequisites()
        if(nInter > 0) {
            //writer uw(" implements ")
            str := ""
            first := true
            for(i in 0 .. nInter) {
                inter := info getPrerequisite(i)
                if(inter isInterfaceInfo?() && !first) {
                    str += (", ")
                    str += inter as InterfaceInfo oocType(namespace)
                } else if(inter isInterfaceInfo?() && first) {
                    first = false
                    str += inter as InterfaceInfo oocType(namespace)
                }
                inter unref()
            }
            if(str != "") writer uw(" implements %s" format(str))
        }

        writer uw(" {\n\n") . indent()
        // Write our methods
        for(i in 0 .. info getNMethods()) {
            method := info getMethod(i)
            FunctionVisitor new(method, info, info getName() toString(), true) write(writer) . free()
            method unref()
        }
        // Write our constants
        for(i in 0 .. info getNConstants()) {
            constant := info getConstant(i)

            type := constant getType()
            typeStr := type toString(namespace)
            if(iface := type getInterface()) {
                typeStr = iface as RegisteredTypeInfo oocType(namespace, info)
                if(iface isCallableInfo?()) {
                    typeStr = "Pointer"
                }
            }
            writer w("%s : static const %s\n" format(constant getName(), typeStr))

            constant unref()
        }

        writer uw('\n') . dedent() . w("}\n\n")
    }
}


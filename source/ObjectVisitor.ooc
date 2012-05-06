use gi
import gi/[FunctionInfo, ObjectInfo, ArgInfo, InterfaceInfo, PropertyInfo]
import OocWriter, Visitor, FunctionVisitor, PropertyVisitor, Utils
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

        // Create an array of PropertyVisitors that will be filled when iterating through methods
        properties := ArrayList<PropertyVisitor> new(info getNProperties())
        // Write our methods
        for(i in 0 .. info getNMethods()) {
            method := info getMethod(i)

            if(method getFlags() & FunctionInfoFlags isGetter?) {
                // If this function is a getter, we try to find a property in our array that matches it else we add it
                prop := visitorFor(properties, method getProperty())
                if(prop) {
                    prop getter = info getMethod(i)
                } else {
                    prop := PropertyVisitor new(method getProperty())
                    prop getter = info getMethod(i)
                    properties add(prop)
                }
            } else if(method getFlags() & FunctionInfoFlags isSetter?) {
                // Same here
                prop := visitorFor(properties, method getProperty())
                if(prop) {
                    prop setter = info getMethod(i)
                } else {
                    prop := PropertyVisitor new(method getProperty())
                    prop setter = info getMethod(i)
                    properties add(prop)
                }
            }

            FunctionVisitor new(method, info) write(writer)
            method unref()
        }
        // Write our properties (they call methods under the hood)
        properties each(|visitor|
            visitor write(writer)
            visitor info unref()
            visitor getter unref()
            visitor setter unref()
            gc_free(visitor)
        )
        gc_free(properties)

        writer uw('\n') . dedent() . w("}\n\n")
    }
}

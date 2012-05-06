use gi
import gi/[RegisteredTypeInfo, TypeInfo, ConstantInfo]
import OocWriter, Visitor, Utils

ConstantVisitor: class extends Visitor {
    info: ConstantInfo
    parent: RegisteredTypeInfo = null
    init: func(=info)
    init: func~withParent(=info, =parent)

    write: func(writer: OocWriter) {
        // Straight-forward: If we have a parent, then we are a static member else we are just a global constant
        if(parent) writer w("%s : static const %s\n" format(info getName() toString() toCamelCase(), info getType() toString()))
        else writer w("%s : const %s\n" format(info getName() toString() toCamelCase(), info getType() toString()))
    }
}

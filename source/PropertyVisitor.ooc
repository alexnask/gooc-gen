use gi
import gi/[FunctionInfo, RegisteredTypeInfo, PropertyInfo]
import OocWriter, Visitor, Utils
import structs/ArrayList

visitorFor: func(this: ArrayList<PropertyVisitor>, prop: PropertyInfo) -> PropertyVisitor {
    ret: PropertyVisitor = null
    this each(|visitor|
        if(visitor info == prop) ret = visitor
    )
    ret
}

PropertyVisitor: class extends Visitor {
    setter, getter: FunctionInfo = null
    info: PropertyInfo

    init: func(=info)

    write: func(writer: OocWriter) {
        // Write the property declaration
        writer w("%s: %s {\n" format(info getName() toString() toCamelCase('-'), info getType() toString())) . indent()
        // Write the getter
        if(getter) writer w("get {\n") . indent() . w("%s()" format(getter getName() toString() toCamelCase())) . uw("\n") . dedent() . w("}\n")
        // Write the setter
        if(setter) writer w("set(s) {\n") . indent() . w("%s(s)" format(setter getName() toString() toCamelCase())) . uw("\n") . dedent() . w("}\n")
        // Close up the declaration
        writer dedent() . uw('\n') . w("}\n")
    }
}

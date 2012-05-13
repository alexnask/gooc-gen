use gi
import gi/[RegisteredTypeInfo, TypeInfo, FieldInfo, Repository]
import OocWriter, Visitor, Utils

FieldVisitor: class extends Visitor {
    info: FieldInfo
    parent: RegisteredTypeInfo
    byValue?: Bool
    init: func(=info, =parent, =byValue?)

    write: func(writer: OocWriter) {
        namespace := parent getNamespace() toString()
        cname := info getName()
        type := info getType()
        typeStr := type toString()
        if(iface := type getInterface()) typeStr = iface as RegisteredTypeInfo oocType(namespace, parent, byValue?)
        writer w("%s: extern(%s) %s\n" format(cname toString() toCamelCase(), cname, typeStr))
    }
}

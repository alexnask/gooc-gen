use gi
import gi/[RegisteredTypeInfo, TypeInfo, ConstantInfo, Repository]
import OocWriter, Visitor, Utils

// Gotta find true extern name :(
ConstantVisitor: class extends Visitor {
    info: ConstantInfo
    parent: RegisteredTypeInfo = null
    init: func(=info)
    init: func~withParent(=info, =parent)

    write: func(writer: OocWriter) {
        // Straight-forward: If we have a parent, then we are a static member else we are just a global constant
        // girepository doesnt give us any info on the c symbol of the constant, so we capitalize the prefix of its namespace and preprend it followed by an undersore before its name, it should do the trick :D
        cname := "%s_%s" format(Repository getCPrefix(null, info getNamespace()) toString() toUpper(), info getName())
        if(parent) writer w("%s : static extern(%s) const %s\n" format(info getName(), cname, info getType() toString()))
        else writer w("%s : extern(%s) const %s\n" format(info getName(), cname, info getType() toString()))
    }
}

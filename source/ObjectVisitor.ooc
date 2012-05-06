use gi
import gi/ObjectInfo
import OocWriter, Visitor

ObjectVisitor: class extends Visitor {
    info: ObjectInfo
    init: func(=info)

    write: func(writer: OocWriter) {
    }
}

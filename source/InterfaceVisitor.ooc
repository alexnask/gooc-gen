use gi
import gi/InterfaceInfo
import OocWriter, Visitor

InterfaceVisitor: class extends Visitor {
    info: InterfaceInfo
    init: func(=info)

    write: func(writer: OocWriter) {
    }
}

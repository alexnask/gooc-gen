use gi
import gi/ConstantInfo
import OocWriter, Visitor

ConstantVisitor: class extends Visitor {
    info: ConstantInfo
    init: func(=info)

    write: func(writer: OocWriter) {
    }
}

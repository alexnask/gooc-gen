use gi
import gi/FunctionInfo
import OocWriter, Visitor

FunctionVisitor: class extends Visitor {
    info: FunctionInfo
    init: func(=info)

    write: func(writer: OocWriter) {
    }
}

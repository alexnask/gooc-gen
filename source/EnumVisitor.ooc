use gi
import gi/EnumInfo
import OocWriter, Visitor

EnumVisitor: class extends Visitor {
    info: EnumInfo
    init: func(=info)

    write: func(writer: OocWriter) {
    }
}

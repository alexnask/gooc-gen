import OocWriter

Visitor: abstract class {
    write: abstract func(writer: OocWriter)

    free: func {
        gc_free(this)
    }
}

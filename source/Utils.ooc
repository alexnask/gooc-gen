use gi
import gi/[TypeInfo, RegisteredTypeInfo, BaseInfo]
import structs/ArrayList
import text/StringTokenizer

extend TypeTag {
    // Returns true if this type must be pointerized if its type info is marked as a pointer ;)
    needsPointerization?: func -> Bool {
        isBasic?() && (this != TypeTag gtype && this != TypeTag utf8 && this != TypeTag filename)
    }
}

extend TypeInfo {
    toString: func -> String {
        base := match(getTag()) {
            case TypeTag void       => "Void"
            case TypeTag boolean    => "Bool"
            case TypeTag int8       => "Int8"
            case TypeTag uint8      => "UInt8"
            case TypeTag int16      => "Int16"
            case TypeTag uint16     => "UInt16"
            case TypeTag int32      => "Int32"
            case TypeTag uint32     => "UInt32"
            case TypeTag int64      => "Int64"
            case TypeTag uint64     => "UInt64"
            case TypeTag float      => "Float"
            case TypeTag double     => "Double"
            case TypeTag gtype      => "Type"
            case TypeTag utf8       => "CString"
            case TypeTag filename   => "CString"
            case TypeTag glist      => "List"
            case TypeTag gslist     => "SList"
            case TypeTag ghash      => "Hash"
            case TypeTag error      => "Error"
            case TypeTag unichar    => "UInt"
            case TypeTag _interface => getInterface() as RegisteredTypeInfo getName() toString() escapeOocTypes()
            case TypeTag array      =>
                match(getArrayType()) {
                    case ArrayType array     => "Array"
                    case ArrayType ptrArray  => "PtrArray"
                    case ArrayType byteArray => "ByteArray"
                    case ArrayType c         =>  "%s*" format(getParamType(0) toString())
                }
        }
        (this isPointer?() && getTag() needsPointerization?()) ? "%s*" format(base) : base
    }
}

extend String {
    escapeOocTypes: func -> This {
        match(this) {
            case "Object"  => "_Object"
            case "Closure" => "_Closure"
            case "match"   => "_match"
            case "case"    => "_case"
            case "if"      => "_if"
            case "while"   => "_while"
            case "for"     => "_for"
            case           => this
        }
    }

    toCamelCase: func(delim := '_') -> This {
        ret := ""
        first := true
        this split(delim) each(|str|
            if(first) first = false
            else if(str size > 0) {
                str _buffer data[0] = str[0] toUpper()
            }
            ret += str
        )
        ret
    }
}

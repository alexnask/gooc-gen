use gi
import gi/[Repository, TypeInfo, RegisteredTypeInfo, BaseInfo, StructInfo, ArgInfo]
import structs/ArrayList
import text/StringTokenizer

extend RegisteredTypeInfo {
    cType: func -> String {
        "%s%s" format(Repository getCPrefix(null, getNamespace()), getName())
    }

    oocType: func(namespace: String, parent: This = null, byValue? := false, pointerize := false) -> String {
        name := getName() toString() escapeOoc()

        // Temporary fix while #390 is still relevant
        if(name endsWith?("Class")) name = name append("_")

        name = (getNamespace() toString() == namespace) ? name : "(%s %s%s)" format(getNamespace(), name, pointerize ? "*" : "")
        if(parent && parent getName() toString() escapeOoc() == name) {
            name = (byValue?) ? "This*" : "This"
        }
        name escapeOoc()
    }
}

extend ArgInfo {
    // Returns the ooc type based on the current namespace
    oocType: func(namespace: String, parent: RegisteredTypeInfo = null, byValue?: Bool = false) -> String {
        type := getType() toString(namespace)
        t := getType()
        iface := t getInterface() as RegisteredTypeInfo
        while(t && t isPointer?() && iface) {
            t = t getParamType(0)
            iface = (t != null) ? t getInterface() as RegisteredTypeInfo : null
        }
        if(iface && !iface isCallableInfo?()) type = iface oocType(namespace, parent, byValue?)
        else if(iface) type = "Pointer"
        type
    }
}

extend TypeInfo {
    // Returns true if this type must be pointerized if its type info is marked as a pointer ;)
    needsPointerization?: func -> Bool {
        tag := getTag()
        // Types that need pointerization are primitives and by value structures
        if(tag == TypeTag _interface && (_struct := getInterface()) isStructInfo?() && _struct as StructInfo getNFields() != 0) return true
        tag isBasic?() && (tag != TypeTag gtype && tag != TypeTag utf8 && tag != TypeTag filename)
    }

    toString: func(namespace: String = "GLib", pointerize := false) -> String {
        // TODO: Array types errors etc should be namespaced
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
            case TypeTag gtype      => "Int"
            case TypeTag utf8       => "CString"
            case TypeTag filename   => "CString"
            case TypeTag glist      => "List"
            case TypeTag gslist     => "SList"
            case TypeTag ghash      => "HashTable"
            case TypeTag error      => "Error"
            case TypeTag unichar    => "UInt"
            case TypeTag _interface => return getInterface() as RegisteredTypeInfo oocType(namespace, null, false, pointerize); null
            case TypeTag array      =>
                match(getArrayType()) {
                    case ArrayType array     => "Array"
                    case ArrayType ptrArray  => "PtrArray"
                    case ArrayType byteArray => "ByteArray"
                    case ArrayType c         =>  "%s" format(getParamType(0) toString(namespace, true))
                }
        }

        if(pointerize) base = "%s*" format(base)

        if(namespace != "GLib" && (base == "Array" || base == "PtrArray" || base == "ByteArray" || base == "SList" || base == "List" || base == "HashTable" || base == "Error")) base = "(%s %s)" format("GLib", base)
        base = (this isPointer?() && this needsPointerization?()) ? "%s*" format(base) : base
        (base == "Void*") ? "Pointer" : base
    }
}

extend String {
    escapeOoc: func -> This {
        match(this) {
            case "Object"    => "_Object"
            case "Closure"   => "_Closure"
            case "match"     => "_match"
            case "case"      => "_case"
            case "if"        => "_if"
            case "while"     => "_while"
            case "for"       => "_for"
            case "func"      => "_func"
            case "include"   => "_include"
            case "import"    => "_import"
            case "break"     => "_break"
            case "continue"  => "_continue"
            case "try"       => "_try"
            case "catch"     => "_catch"
            case "abstract"  => "_abstract"
            case "final"     => "_final"
            case "extern"    => "_extern"
            case "static"    => "_static"
            case "unmangled" => "_unmangled"
            case "const"     => "_const"
            case "enum"      => "_enum"
            case "class"     => "_class"
            case "cover"     => "_cover"
            case "inline"    => "_inline"
            case "null"      => "_null"
            case "true"      => "_true"
            case "false"     => "_false"
            case "interface" => "_interface"
            case             => (this[0] digit?()) ? this prepend('_') : this
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

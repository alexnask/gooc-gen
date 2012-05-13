use gi
import gi/[BaseInfo, FunctionInfo, RegisteredTypeInfo, ArgInfo]
import OocWriter, Visitor, Utils, CallbackVisitor

// Handle arguments of callback types (make them pointer, generate a second function that takes a closure and passes the context as a userData pointer if the function has one and the callback type has a last argument of pointer type)

FunctionVisitor: class extends Visitor {
    info: FunctionInfo
    // Parent type (declaration)
    parent: RegisteredTypeInfo
    byValue? := false
    forcedSuffix: String = null

    init: func(=info)
    init: func~withParent(=info, =parent)
    init: func~withByValue(=info, =parent, =byValue?)
    init: func~withSuffix(=info, =parent, =forcedSuffix)

    write: func(writer: OocWriter) {
        namespace := info getNamespace() toString()
        name := info getName()
        inValueStruct? := (parent != null && byValue?)
        isStatic? := false
        isConstructor? := info getFlags() & FunctionInfoFlags isConstructor?
        suffix: String = null
        rewriteClosureVersion? := false
        closureIndex := 0

        // This is pretty naive but at the moment only constructors are detected as static, I have found no other way to do it D:
        if(parent && isConstructor?) {
            isStatic? = true
            suffix = name toString()
            name = "new" toCString() // c"new"
        }

        // If the function is a structure members, this should be passed by reference
        writer w("%s: %sextern(%s) %s " format(name toString() toCamelCase() escapeOoc(), (isStatic?) ? "static " : "", info getSymbol(), (inValueStruct?) ? "func@" : "func"))
        if(suffix) writer uw("~" + suffix)
        else if(forcedSuffix) writer uw("~" + forcedSuffix)

        // Write arguments
        first := true
        // The previous type we wrote
        prevType := ""
        for(i in 0 .. info getNArgs()) {
            last? := i == info getNArgs() - 1
            arg := info getArg(i)

            type := arg oocType(namespace, parent, inValueStruct?)
            if(iface := arg getType() getInterface()) {
                if(callback := CallbackVisitor callback(iface getName() toString()))  {
                    // If we are accessing a function type we see if we can rewrite it as an ooc closure and we set the type of the argument to a Pointer
                    type = "Pointer"
                    nextArg := (!last?) ? info getArg(i + 1) : null
                    // We can rewrite an ooc version of the function with a closure if the function takes a Pointer last argument and the next argument of the function is a Pointer (usually user_data)
                    if(callback oocClosure?() && nextArg && nextArg getType() toString() == "Pointer") {
                        rewriteClosureVersion? = true
                        closureIndex = i
                    }
                    if(nextArg) nextArg unref()
                }
                iface unref()
            }

            if(first) {
                prevType = type
                writer uw("(")
            }
            // If the type of the arguments hasn't changed and we arent on the last argument we can jus write the name of the argument, else we write its name and type
            argName := arg getName() toString() escapeOoc()
            if(first) {
                first = false
                if(last?) writer uw("%s : %s" format(argName, type))
                else writer uw(argName)
            } else if(type != prevType) {
                if(last?) writer uw(" : %s, %s : %s" format(prevType, argName, type))
                else writer uw(" : %s, %s" format(prevType, argName))
            } else if(last?) {
                writer uw(", %s : %s" format(argName, type))
            } else {
                writer uw(", %s" format(argName))
            }
            prevType = type
            arg unref()
        }
        // If the function can throw an error, we need to add an Error* argument :)
        if(info getFlags() & FunctionInfoFlags throws?) {
            if(!first) writer uw(", error : Error*") // TODO: namespace error
            else writer uw("(error : Error*)")
        }

        if(!first) writer uw(") ")
        returnType := info getReturnType()
        iface := returnType getInterface() as RegisteredTypeInfo
        if(iface) writer uw("-> %s" format(iface oocType(namespace, parent, inValueStruct?)))
        else if(returnType toString() != "Void") writer uw("-> %s" format(returnType toString()))
        writer uw("\n")

        // TODO: Code from here on is terrible, far too much repetition
        if(rewriteClosureVersion?) {
            arg := info getArg(closureIndex)
            closureName := arg getName() toString() escapeOoc()
            arg unref()

            writer w("%s: %s %s ~%sclosure (" format(name toString() toCamelCase(), (isStatic?) ? "static " : "", (inValueStruct?) ? "func@" : "func", (forcedSuffix) ? forcedSuffix : ""))
            first := true
            for(i in 0 .. info getNArgs()) {
                last? := (i == info getNArgs() - 1) || ((closureIndex == info getNArgs() - 2) && (i == info getNArgs() - 2))
                arg := info getArg(i)
                argName := arg getName() toString() escapeOoc()

                type := arg oocType(namespace, parent, inValueStruct?)
                if(first) {
                    prevType = type
                }

                if(i == closureIndex) {
                    iface := arg getType() getInterface()
                    callback := CallbackVisitor callback(iface getName() toString())
                    iface unref()
                    closureStr := "%s : %s" format(closureName, callback toOocString(namespace, parent, byValue?))

                    if(first && last?) writer uw(closureStr)
                    else if(first) writer uw(argName)
                    else if(last?) writer uw(" : %s, %s" format(prevType, closureStr))
                    else writer uw(" : %s, %s" format(prevType, argName))

                    prevType = callback toOocString(namespace, parent, byValue?)
                    if(first) first = false
                } else if(i != closureIndex + 1) {
                    // If the type of the arguments hasn't changed and we arent on the last argument we can jus write the name of the argument, else we write its name and type
                    if(first) {
                        if(last?) writer uw("%s : %s" format(argName, type))
                        else writer uw(argName)
                    } else if(type != prevType) {
                        if(last?) writer uw(" : %s, %s : %s" format(prevType, argName, type))
                        else writer uw(" : %s, %s" format(prevType, argName))
                    } else if(last?) {
                        writer uw(", %s : %s" format(argName, type))
                    } else {
                        writer uw(", %s" format(argName))
                    }
                    prevType = type
                    if(first) first = false
                }
                arg unref()
            }
            // If the function can throw an error, we need to add an Error* argument :)
            if(info getFlags() & FunctionInfoFlags throws?) {
                if(!first) writer uw(", error : Error*") // TODO: should be namespaced if necessary
                else writer uw("(error : Error*")
            }
            writer uw(") {\n") . indent()
            writer w("%s(" format(name toString() toCamelCase()))
            first = true
            for(i in 0..info getNArgs()) {
                if(first) first = false
                else writer uw(", ")

                if(i == closureIndex) {
                    writer uw("%s as Closure thunk" format(closureName))
                } else if(i == closureIndex + 1) {
                    writer uw("%s as Closure context" format(closureName))
                } else {
                    arg := info getArg(i)
                    writer uw(arg getName() toString() escapeOoc())
                    arg unref()
                }
            }
            writer uw(")\n") . dedent() . w("}\n")
        }
    }
}

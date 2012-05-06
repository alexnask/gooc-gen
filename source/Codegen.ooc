use gtk, gi
import gi/[Repository, BaseInfo, FunctionInfo, EnumInfo, ObjectInfo, InterfaceInfo, ConstantInfo]
import gtk/Gtk
import structs/ArrayList
import text/StringTokenizer
import OocWriter, Visitor, FunctionVisitor, EnumVisitor, ObjectVisitor, InterfaceVisitor, ConstantVisitor

Codegen: class {
    repo := Repository getDefault()
    dest: String
    verbose? := false
    dep? := false
    namespaces: ArrayList<String>

    init: func(source: String, =dest) {
        repo prependSearchPath(source)
    }

    run: func {
        // First, we determine wich namespaces to generate bindings for
        // Note: this does not really work but anyway :p
        if(!namespaces) {
            if(verbose?) "No namespaces given, assuming loaded ones" println()
            // If the user has chosen what namespaces he wants, we use them, in the opposite case we get all that are loaded in the repository
            loaded := repo getLoadedNamespaces()
            if(loaded) {
                i := 0
                while(loaded[i]) {
                    ns := loaded[i] toString()
                    if(namespaces indexOf(ns) < 0) namespaces add(ns)
                    if(verbose?) "Loaded namespace %s added to namespace list" format(ns) println()
                    i += 1
                }
            }
            if(verbose?) "Namespace list populated" println()
        }
        // We load the namespaces in the repository
        loadNamespaces()
        // Generate the binding awesomeness
        generate()
    }

    loadNamespaces: func {
        error: Error* = null
        if(namespaces) {
            // Go through the namespaces
            namespaces each(|nameVer|
                if(verbose?) "Loading namespace %s" format(nameVer) println()
                // Find the name and version
                name := nameVer split('-')[0]
                ver := nameVer split('-')[1]
                // Require the repository to have them
                repo require(name, ver, RepositoryLoadFlags lazy, error&)
                if(error) {
                    if(error@ message) raise("Could not load namespace %s version %s. Reason: %s" format(name, ver, error@ message))
                    else raise("Could not load namespace %s version %s for an unknown reason" format(name, ver))
                    error@ free()
                }

                // If we have been passed the option to, we add the namespace's dependencies to the namespace list
                if(dep?) {
                    if(verbose?) "Loading dependencies..." println()

                    dependencies := repo getDependencies(name)
                    if(dependencies) {
                        i := 0
                        while(dependencies[i]) {
                            dep := dependencies[i] toString()
                            if(namespaces indexOf(dep) < 0) namespaces add(dep)
                            if(verbose?) "Dependency loaded: %s" format(dep) println()
                            i += 1
                        }
                    }
                }
                if(verbose?) "Namespace loaded" println()
            )
        }
    }

    generate: func {
        // Open up our destination file
        writer := OocWriter new(dest)
        if(verbose?) "Opened destination file" println()

        // And then go through our namespace symbols and generate them
        namespaces each(|nameVer|
            ns := nameVer split('-')[0]
            writer w("/** NAMESPACE %s **/\n\n" format(ns)) . indent()
            if(verbose?) "Writing symbols for namespace %s" format(ns) println()
            for(index in 0 .. repo getNInfos(ns)) {
                info := repo getInfo(ns, index)
                name := info getName() toString()
                if(verbose?) "Writing symbol %s of type %s" format(name, info getType() toString()) println()
                // Make a visitor depending on the type of the symbol
                // Signals, callbacks, values, vfuncs, properties, fields, unions (?)
                visitor := match(info getType()) {
                    case InfoType function => FunctionVisitor new(info as FunctionInfo) as Visitor
                    case InfoType _enum => EnumVisitor new(info as EnumInfo) as Visitor
                    case InfoType flags => EnumVisitor new(info as EnumInfo) as Visitor
                    case InfoType object => ObjectVisitor new(info as ObjectInfo) as Visitor
                    case InfoType _interface => InterfaceVisitor new(info as InterfaceInfo) as Visitor
                    case InfoType constant => ConstantVisitor new(info as ConstantInfo) as Visitor
                    case => null as Visitor // We want to ignore generating symbols for some types of info, so we yield no error here
                }
                if(visitor) visitor write(writer)
                info unref()
            }
            writer dedent()
        )
        // Close up the destination file
        writer close()
    }
}

use gtk, gi
import gi/Repository
import gtk/Gtk
import structs/ArrayList
import text/StringTokenizer

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
        // Here is where we do everything
        error: Error*
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
                    raise("Could not load namespace %s version %s. Reason: %s" format(name, ver, error@ message))
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
}

import structs/ArrayList
import text/[Opts, StringTokenizer]
import io/File
import Codegen

main: func(args: ArrayList<String>) {
    opts := Opts new(args)
    if(opts set?("help")) {
        "Usage: %s <options> <dest> where:\n\
        options:\n\
            -source=<src> sets the directory gooc-gen will seek the GIR files in (default is the current directory)\n\
            -namespaces=<ns> a comma speratated list of namespaces gooc-gen will generate bindings for. A namespace is symbolized as name-version. If unspecified, all namespaces will be generated\n\
            -with-dependencies will cause gooc-gen to load the dependencies of the selected namespaces and generate binding code for them too\n\
            -v enables verbose mode (warning: lots of data will be displayed)\n\
        dest is the directory gooc-gen will generate files in\n" format(opts get("self")) println()
    } else if(opts args getSize() != 1) {
        "Please give gooc-gen exactly one destination directory to write to." println()
    } else {
        // Determine te source path
        selfFile := File new(opts get("self"))
        source := opts set?("source") ? opts get("source") : ((selfFile file?()) ? selfFile getAbsoluteFile() parent() path : null)
        if(!source || !File new(source) dir?()) raise("Could not determine source directory.")
        if(!File new(opts args[0]) dir?()) raise("Destination provided is not a valid directory.")
        // Determine the namespaces to generate bindings for
        ns: ArrayList<String>
        if(opts set?("namespaces")) ns = opts get("namespaces") split(',')
        // Set up the code generator
        codegen := Codegen new(source, opts args[0])
        codegen verbose? = opts set?("v")
        codegen dep? = opts set?("with-dependencies")
        codegen namespaces = ns
        try {
            // Run the code generator
            codegen run()
        } catch(e: Exception) {
            e formatMessage() println()
        }
    }
}

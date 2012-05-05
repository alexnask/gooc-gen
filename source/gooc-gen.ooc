import structs/ArrayList
import text/Opts
import io/File

main: func(args: ArrayList<String>) {
    opts := Opts new(args)
    if(opts set?("help")) {
        "Usage: %s <options> <dest> where:\n\
        options:\n\
            -source=<src> sets the directory gooc-gen will seek the GIR files in (default is the current directory)\n\
            -v enables verbose mode (warning: lots of data will be displayed)\n\
        dest is the binding file gooc-gen will generate\n" format(opts get("self")) println()
    } else if(opts args getSize() != 1) {
        "Please give gooc-gen exactly one destination file to write to." println()
    } else {
        // Determine te source path
        selfFile := File new(opts get("self"))
        source := opts set?("source") ? opts get("source") : ((selfFile file?()) ? selfFile getAbsoluteFile() parent() path : null)
        if(!source) raise("Could not determine source directory.")
    }
}

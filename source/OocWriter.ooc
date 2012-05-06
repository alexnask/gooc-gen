import io/FileWriter

OocWriter: class extends FileWriter {
    tabLevel := 0
    indent: func {
        tabLevel += 1
    }

    dedent: func {
        tabLevel -= 1
        if(tabLevel < 0) raise("lolwut too much untabbing newb")
    }

    init: func~fName(fileName: String) {
        super~withName(fileName, false)
    }

    w: func(s: String) {
        this write("    " times(tabLevel)) .write(s)
    }

    w: func~char(c: Char) {
        this write("    " times(tabLevel)) .write(c)
    }
}

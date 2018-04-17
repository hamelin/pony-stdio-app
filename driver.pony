interface Driver

    be at_start(app: App val) => None
    be at_end(app: App val, exitcode: I32 val) => None
    be bytes(app: App val, data: String val)

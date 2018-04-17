use "stdapp"


actor Main is Driver
    var _len: USize val

    new create(env: Env) =>
        _len = 0
        Launch(env, this)

    be at_start(app: App val) =>
        app.out.print("Will exit with code equal to standard input length.")

    be bytes(app: App val, data: String val) =>
        _len = _len + data.size()
        if _len > 20 then
            app.out.print("Reached 20 input bytes; exiting with code 127.")
            app.exit(127)
        end

    be at_end(app: App val, exitcode: I32 val) =>
        app.out.print("At end; outstanding exit code is " + exitcode.string() + ".")
        app.exit(I32.from[USize](_len))

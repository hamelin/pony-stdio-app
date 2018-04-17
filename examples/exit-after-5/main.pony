use "stdapp"


actor Main is Driver
    var _num_ch: USize

    new create(env: Env) =>
        _num_ch = 0
        Launch(env, this)

    be at_start(app: App val) =>
        app.out.print("Type characters, I will exit at the 5th.")

    be bytes(app: App val, data: String val) =>
        _num_ch = _num_ch + data.size()
        if _num_ch >= 5 then
            app.exit(I32.from[USize](_num_ch) - 5)
        end

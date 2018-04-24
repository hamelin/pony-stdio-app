use "stdapp"


actor Main is DriverBuffered

    new create(env: Env) =>
        Launch(env, DriverLines(this))

    be apply(app: App val, line: String val) =>
        app.out.print(line.upper())

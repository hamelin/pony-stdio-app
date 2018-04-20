use "stdapp"
use "term"


actor Main is DriverBuffered

    be apply(app: App val, chunk: String val) =>
        let copy = chunk.clone()
        copy.replace("\n", ANSI.bright_blue() + "\\n" + ANSI.reset())
        app.out.write("{" + consume copy + "}")

    new create(env: Env) =>
        Launch(env, DriverFixed(this, 4))

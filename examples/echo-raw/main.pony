use "term"

use "stdapp"


actor Main is Driver

    new create(env: Env) =>
        Launch(env, this)

    be bytes(app: App val, data: String val) =>
        app.err.write(ANSI.bright_red() + data + ANSI.reset())

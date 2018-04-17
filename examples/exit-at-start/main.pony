use "stdapp"


actor Main is Driver

    new create(env: Env) =>
        Launch(env, this)

    be at_start(app: App val) =>
        app.exit(
            try
                app.args(1)?.read_int[I32]()?._1
            else
                app.err.print(
                    (try
                        "Usage: " + app.args(0)? + " code"
                    else
                        "How the hell is args organized?"
                    end) + "\nDefault to 0."
                )
                0
            end
        )

    be apply(app: App val, data: String val) =>
        app.err.print("Not supposed to get here! Received data: " + data)

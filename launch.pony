use "files"


primitive Launch

    fun apply(env: Env, driver: Driver tag) =>
        try
            let exit_code: _ExitCode tag = _ExitCode
            let app: App val = App(env, exit_code)?
            let is_term: Bool val = isatty(env)
            driver.at_start(app)
            env.input(
                recover
                    object
                        var _last_was_newline: Bool val = false
                        fun ref apply(data: Array[U8] iso): None =>
                            let s: String val = String.from_iso_array(consume data)
                            try
                                let char_last = s(s.size() - 1)?
                                if _last_was_newline and (char_last == 4) then
                                    env.input.dispose()
                                else
                                    _last_was_newline = (char_last == 10)
                                    if is_term then
                                        env.out.write(s)
                                    end
                                    driver.bytes(app, s)
                                end
                            else
                                env.err.print("FATAL -- Empty data given to read from.")
                                app.exit(-1)
                            end
                        fun ref dispose() =>
                            exit_code.get({(code: I32 val) => driver.at_end(app, code) })
                    end
                end,
                4096
            )
        else
            env.err.print("FATAL -- Cannot set up basic data structure, abort.")
        end

    fun isatty(env: Env): Bool val =>
        try
            let info = FileInfo(FilePath(env.root as AmbientAuth, "/dev/fd/0")?)?
            not (info.file or info.pipe)
        else
            env.err.print("Unable to determine whether stdin is a TTY; default to yes.")
            true
        end

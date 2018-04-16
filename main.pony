use "cli"
use "collections"
use "files"
use "promises"
use "term"


interface iso _ExitCodeProcessor
    fun apply(code: I32 val): None

actor _ExitCode
    var _code: I32 val
    new create() =>
        _code = 0
    be set(code: I32 val) =>
        _code = code
    be get(proc: _ExitCodeProcessor iso) =>
        (consume proc)(_code)


class val App
    let _env: Env val
    let root: AmbientAuth val
    let out: OutStream tag
    let err: OutStream tag
    let args: Array[String val] val
    let _exit_code: _ExitCode tag

    new val create(env: Env, exit_code: _ExitCode tag)? =>
        _env = env
        root = env.root as AmbientAuth
        out = env.out
        err = env.err
        args = env.args
        _exit_code = exit_code

    fun val env_vars(prefix: String val = "", squash: Bool val = false): Map[String val, String val] val =>
        EnvVars(_env.vars())

    fun val exit(code: I32 val = 0) =>
        _exit_code.set(code)
        _env.exitcode(code)
        _env.input.dispose()


interface Driver

    be at_start(app: App val)
    be at_end(app: App val, exitcode: I32 val)
    be apply(app: App val, data: String val)


primitive Launch

    fun ref apply(env: Env, driver: Driver tag) =>
        try
            let exit_code: _ExitCode tag = _ExitCode
            let app: App val = App(env, exit_code)?
            let is_term: Bool val = isatty(env)
            driver.at_start(app)
            env.input(
                recover
                    object
                        fun apply(data: Array[U8] iso): None =>
                            let s: String val = String.from_iso_array(consume data)
                            if is_term then
                                env.out.write(s)
                            end
                            driver(app, s)
                        fun dispose() =>
                            exit_code.get({(code: I32 val) => driver.at_end(app, code) })
                    end
                end
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

use "cli"
use "collections"


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
        EnvVars(_env.vars, prefix, squash)

    fun val exit(code: I32 val = 0) =>
        _exit_code.set(code)
        _env.exitcode(code)
        _env.input.dispose()

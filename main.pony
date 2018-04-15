use "cli"
use "collections"
use "files"
use "promises"
use "term"


class val Ok
    let prompt: String val

    new val create() =>
        prompt = ANSI.erase()

    new val with_prompt(prompt': String val) =>
        prompt = prompt'


class val Exit
    let code: I32 val

    new val create(code': I32 val) =>
        code = code'

    new val success() =>
        code = 0

type ProcessResult is (Ok val | Exit val)


/* class Shell */
/*     let _env: Env */

/*     new create(env: Env) => */
/*         _env = env */

/*     fun box root(): (AmbientAuth val | None val) => _env.root */
/*     fun box out(): OutStream => _env.out */
/*     fun box err(): OutStream => _env.err */
/*     fun box args(): Array[String val] val => _env.args */
/*     fun box env_vars(prefix: String val = "", squash: Bool val = false): Map[String val, String val] val => */
/*         EnvVars(_env.vars()) */
/*     fun ref _attach(notify: StdinNotify iso): None => _env.input(consume notify) */
/*     fun ref _close(): None => _env.input.dispose() */
/*     fun ref _terminating(exit: Exit val): None => _env.exitcode(exit.code) */
/*     /1* fun ref _readline(notify: ReadlineNotify iso^): Readline => Readline(notify, _env.input) *1/ */


interface Driver

    fun ref at_start(env: Env): ProcessResult val =>
        Ok

    fun ref at_end(env: Env, exit: Exit val): Exit val =>
        exit

    fun ref complete(prefix: String val, env: Env): Seq[String val] box =>
        []

    fun ref apply(data: String val, env: Env): ProcessResult


primitive _Shutdown

    fun initiate(env_or_promise: (Env | Promise[String] tag)): None =>
        match env_or_promise
        | let env: Env                  => env.input.dispose()
        | let prom: Promise[String] tag => prom.reject()
        end

    fun finish(env: Env, driver: Driver, result: ProcessResult val): None =>
        let exit: Exit val = match result
        | let x: Exit val =>
            x
        else
            env.err.print("Exit code not set prior to shutting down. Using default.")
            Exit(-1)
        end
        env.exitcode(driver.at_end(env, exit).code)


/* interface _Engine */
/*     fun iso attach(env: Env, prompt: String val): None */
/*     fun ref exit(exit': Exit val): None */
/*     fun ref dispose(): None */

    /* fun iso start(env: Env, driver: Driver): None => */
    /*     match driver.at_start(shell) */
    /*     | let ok: Ok => */
    /*         attach(shell, ok.prompt) */
    /*     | let x: Exit => */
    /*         _Shutdown.initiate(shell) */
    /*         _Shutdown.finish(shell, driver, x) */
    /*     end */


/* class _EngineStdin is (_Engine & StdinNotify) */
/*     let _env: Env */
/*     let _driver: Driver */
/*     var _exit: Exit */

/*     new create(env: Env, driver: Driver) => */
/*         _shell = shell */
/*         _driver = driver */
/*         _exit = Exit.success() */
/*         match _driver.at_start(shell) */
/*         | let ok: Ok val => */
/*             attach(shell, ok.prompt) */
/*         | let x: Exit val => */
/*             _Shutdown.initiate(shell) */
/*             _Shutdown.finish(shell, driver, x) */
/*         end */

/*     fun ref attach(env: Env, prompt: String val): None => */
/*         _shell._attach(this) */

/*     fun ref apply(data: Array[U8] iso) => */
/*         match _driver(String.from_array(consume data), _shell) */
/*         | let x: Exit => */
/*             _exit = x */
/*             _Shutdown.initiate(_shell) */
/*         end */

/*     fun ref dispose() => */
/*         _Shutdown.finish(_shell, _driver, _exit) */

/*     fun ref exit(exit': Exit val) => */
/*         _exit = exit' */


/* class _EngineTerm is (_Engine & ReadlineNotify) */
/*     let _env: Env */
/*     var _term: (ANSITerm tag | None) */
/*     let _driver: Driver tag */
/*     var _exit: Exit val */

/*     new create(env: Env, driver: Driver tag) => */
/*         _shell = shell */
/*         _driver = driver */
/*         _term = None */
/*         _exit = Exit.success() */

/*     fun ref attach(env: Env, prompt: String val) => */
/*         let term: ANSITerm = ANSITerm(shell._readline(this), shell.out()) */
/*         _term = term */
/*         _shell.attach( */
/*             let self = this */
/*             recover */
/*                 object */
/*                     fun ref apply(data: Array[U8] iso) => term(consume data) */
/*                     fun ref dispose() => self.dispose() */
/*                 end */
/*             end */
/*         ) */

/*     fun ref dispose() => */
/*         try */
/*             (_term as ANSITerm).dispose() */
/*         end */
/*         _Shutdown.finish(_shell, _driver, _exit) */

/*     fun ref exit(exit': Exit val) => */
/*         _exit = exit' */

/*     fun ref apply(data: String val, prompt: Promise[String] tag) => */
/*         match _driver(data, _shell) */
/*         | let ok: Ok => */
/*             prompt(ok.prompt) */
/*         | let x: Exit => */
/*             _exit = x */
/*             _Shutdown.initiate(_shell) */
/*         end */

/*     fun ref tab(prefix: String val): Seq[String val] box => */
/*         _driver.complete(prefix) */


class _AdapterStdin is StdinNotify
    let _env: Env
    let _driver: Driver ref
    var _result: ProcessResult val

    new create(env: Env, driver: Driver) =>
        _env = env
        _driver = driver
        _result = Ok

    fun ref apply(data: Array[U8 val] iso): None =>
        _result = _driver(String.from_array(consume data), _env)
        match _result
        | let _: Exit val =>
            _Shutdown.initiate(_env)
        end

    fun ref dispose(): None =>
        _Shutdown.finish(_env, _driver, _result)


class _ReadlineNotify is ReadlineNotify
    let _env: Env
    let _driver: Driver ref
    var _result: ProcessResult val

    new create(env: Env, driver: Driver) =>
        _env = env
        _driver = driver
        _result = Ok

    fun ref apply(data: String val, prompt: Promise[String] tag): None =>
        _result = _driver(data, _env)
        match _result
        | let ok: Ok val => prompt(ok.prompt)
        else
            _Shutdown.initiate(prompt)
        end

    fun ref tab(prefix: String val): Seq[String val] box =>
        _driver.complete(prefix, _env)

    fun ref get_attribs(): (Env, Driver, ProcessResult) =>
        (_env, _driver, _result)


class _Readline is ANSINotify
    let _readline: Readline
    let _notify: _ReadlineNotify iso

    new create(env: Env, driver: Driver iso^) =>
        _notify = recover _ReadlineNotify(env, driver) end
        _readline = Readline(_notify, env.out)

    fun ref apply(term: ANSITerm ref, input: U8 val) => _readline(term, input)
    fun ref prompt(term: ANSITerm ref, value: String val) => _readline.prompt(term, value)
    fun ref up(ctrl: Bool val, alt: Bool val, shift: Bool val) => _readline.up(ctrl, alt, shift)
    fun ref down(ctrl: Bool val, alt: Bool val, shift: Bool val) => _readline.down(ctrl, alt, shift)
    fun ref left(ctrl: Bool val, alt: Bool val, shift: Bool val) => _readline.left(ctrl, alt, shift)
    fun ref right(ctrl: Bool val, alt: Bool val, shift: Bool val) => _readline.right(ctrl, alt, shift)
    fun ref home(ctrl: Bool val, alt: Bool val, shift: Bool val) => _readline.home(ctrl, alt, shift)
    fun ref end_key(ctrl: Bool val, alt: Bool val, shift: Bool val) => _readline.end_key(ctrl, alt, shift)
    fun ref delete(ctrl: Bool val, alt: Bool val, shift: Bool val) => _readline.delete(ctrl, alt, shift)
    fun ref insert(ctrl: Bool val, alt: Bool val, shift: Bool val) => _readline.insert(ctrl, alt, shift)
    fun ref page_up(ctrl: Bool val, alt: Bool val, shift: Bool val) => _readline.page_up(ctrl, alt, shift)
    fun ref page_down(ctrl: Bool val, alt: Bool val, shift: Bool val) => _readline.page_down(ctrl, alt, shift)
    fun ref fn_key(i: U8 val, ctrl: Bool val, alt: Bool val, shift: Bool val) => _readline.fn_key(i, ctrl, alt, shift)
    fun ref size(rows: U16 val, cols: U16 val) => _readline.size(rows, cols)

    fun ref closed() =>
        (let env, let driver, let result) = _notify.get_attribs()
        _Shutdown.finish(env, driver, result)
        _readline.closed()


class _AdapterTerm is StdinNotify
    let _term: ANSITerm tag

    new create(env: Env, driver: Driver iso^) =>
        _term = ANSITerm(_Readline(env, driver), env.input)

    fun ref apply(data: Array[U8] val): None => _term(data)
    fun ref dispose(): None => _term.dispose()


primitive App

    fun launch(env: Env, driver: Driver iso^) =>
        match driver.at_start(env)
        | let ok: Ok val =>
            env.input(
                recover
                    if isatty(env) then
                        _AdapterTerm(env, driver)
                    else
                        _AdapterStdin(env, driver)
                    end
                end
            )
        | let x: Exit val =>
            _Shutdown.initiate(env)
            _Shutdown.finish(env, driver, x)
        end

        /* (recover */
        /*     /1* if isatty(env) then *1/ */
        /*     /1*     _EngineTerm(shell, driver) *1/ */
        /*     /1* else *1/ */
        /*     /1*     _EngineStdin(shell, driver) *1/ */
        /*     /1* end *1/ */
        /*     _EngineStdin(shell, driver) */
        /* end)//.start(shell, driver) */

    fun isatty(env: Env): Bool val =>
        try
            let info = FileInfo(FilePath(env.root as AmbientAuth, "/dev/fd/0")?)?
            not (info.file or info.pipe)
        else
            env.err.print("Unable to determine whether stdin is a TTY; default to yes.")
            true
        end

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

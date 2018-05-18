use "regex"


interface FindSeparator
    fun apply(cache: String box): (ISize val, USize val)?


class iso _FindSplitSeparator is FindSplit
    let _find_separator: FindSeparator val

    new iso create(find_separator: FindSeparator val) =>
        _find_separator = consume find_separator

    fun apply(cache: String box): (ISize val, USize val) =>
        try
            _find_separator(cache)?
        else
            NoChunk()
        end


primitive DriverSeparator
    fun apply(delegate: DriverBuffered tag, find_separator: FindSeparator val): DriverBytes tag =>
        Buffer(delegate, _FindSplitSeparator(find_separator), false)


class SeparateString is FindSeparator
    let _separator: String val

    new val create(separator: String val) =>
        _separator = separator

    fun apply(cache: String box): (ISize val, USize val)? =>
        let pos = cache.find(_separator)?
        (pos, USize.from[ISize](pos) + _separator.size())


primitive DriverSplitBy
    fun apply(delegate: DriverBuffered tag, separator: String val): DriverBytes tag =>
        DriverSeparator(delegate, SeparateString(separator))


class SeparateRegex is FindSeparator
    let _separator: Regex val

    new val create(separator: Regex val) =>
        _separator = separator

    fun apply(cache: String box): (ISize val, USize val)? =>
        // Unhappy about having to clone the full buffer, but that's the only way to get a val.
        let m = _separator(cache.clone())?
        (ISize.from[USize](m.start_pos()), m.end_pos() + 1)


primitive DriverSplitRegex
    fun apply(delegate: DriverBuffered tag, separator: Regex val): DriverBytes tag =>
        DriverSeparator(delegate, SeparateRegex(separator))

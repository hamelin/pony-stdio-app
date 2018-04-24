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


primitive DriverSplitBy
    fun apply(delegate: DriverBuffered tag, separator: String val): DriverBytes tag =>
        DriverSeparator(
            delegate,
            {(cache: String box): (ISize, USize)? =>
                let pos = cache.find(separator)?
                (pos, USize.from[ISize](pos) + separator.size())
            }
        )


primitive DriverSplitRegex
    fun apply(delegate: DriverBuffered tag, separator: Regex val): DriverBytes tag =>
        DriverSeparator(
            delegate,
            {
                (cache: String box): (ISize, USize)? =>
                    // Unhappy about having to clone the full buffer, but that's the only way to get a val.
                    let m = separator(cache.clone())?
                    (ISize.from[USize](m.start_pos()), m.end_pos() + 1)
            }
        )

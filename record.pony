use "regex"


interface DriverRecord is Driver
    be apply(app: App val, fields: Array[String val] val)


actor _DriverBufferedRecords is DriverBuffered
    let _delegate: DriverRecord tag
    let _sep_fields: FindSeparator val

    new create(delegate: DriverRecord tag, sep_fields: FindSeparator val) =>
        _delegate = delegate
        _sep_fields = sep_fields

    be at_start(app: App val) =>
        _delegate.at_start(app)

    be at_end(app: App val, exitcode: I32 val) =>
        _delegate.at_end(app, exitcode)

    be apply(app: App val, record_raw: String val) =>
        let record: Array[String val] iso = recover Array[String val](10) end
        var raw: String val = record_raw
        while true do
            try
                (let sep_start, let sep_end) = _sep_fields(raw)?
                if sep_start > 0 then
                    record.push(raw.trim(0, USize.from[ISize](sep_start)))
                end
                raw = raw.trim(sep_end)
            else
                break
            end
        end
        if raw.size() > 0 then
            record.push(raw)
        end
        _delegate(app, consume record)


primitive DriverRecords
    fun apply(
        delegate: DriverRecord tag,
        sep_fields: FindSeparator val,
        sep_records: FindSeparator val
    ): DriverBytes tag =>
        DriverSeparator(_DriverBufferedRecords(delegate, sep_fields), sep_records)


primitive DriverRecordsSplitBy
    fun apply(
        delegate: DriverRecord tag,
        sep_fields: String val = ",",
        sep_records: String val = "\n"
    ): DriverBytes tag =>
        DriverRecords(delegate, SeparateString(sep_records), SeparateString(sep_fields))


primitive DriverRecordsRegex
    fun apply(
        delegate: DriverRecord tag,
        sep_fields: Regex val,
        sep_records: Regex val
    ): DriverBytes tag =>
        DriverRecords(delegate, SeparateRegex(sep_fields), SeparateRegex(sep_records))


primitive DriverRecordsAwk
    fun apply(
        delegate: DriverRecord tag,
        sep_fields_regex: String val = "[[:blank:]]+",
        sep_records: String val = "\n"
    ): DriverBytes tag? =>
        let sep_fields: Regex iso = recover Regex(sep_fields_regex)? end
        DriverRecords(delegate, SeparateRegex(consume sep_fields), SeparateString(sep_records))

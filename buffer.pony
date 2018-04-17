interface FindSplit
    fun apply(cache: String box): (ISize val, USize val)

primitive NoChunk
    fun value(): ISize val => -1
    fun apply(): (ISize val, USize val) => (value(), 0)


interface DriverBuffered is Driver
    be apply(app: App val, chunk: String val)


actor Buffer is DriverBytes
    let _delegate: DriverBuffered tag
    let _find_split: FindSplit val
    var _reject_last_incomplete: Bool val
    var _cache: String trn

    new create(delegate: DriverBuffered tag, find_split: FindSplit val, reject_last_incomplete: Bool val = false) =>
        _delegate = delegate
        _find_split = consume find_split
        _reject_last_incomplete = reject_last_incomplete
        _cache = recover trn String end

    be at_start(app: App val) =>
        _delegate.at_start(app)

    be at_end(app: App val, exit_code: I32 val) =>
        if not _reject_last_incomplete then
            _delegate(app, _cache = recover trn String end)
        end
        _delegate.at_end(app, exit_code)

    be apply(app: App val, data: String val) =>
        _cache.insert_in_place(-1, data)
        (let split_start, let split_end) = _find_split(_cache)
        if not (split_start is NoChunk.value()) then
            _delegate(app, _cache.substring(0, split_start))
            _cache.trim_in_place(split_end)
            apply(app, "")
        end


primitive DriverFixed
    fun apply(delegate: DriverBuffered tag, size_chunk: USize val) =>
        Buffer(
            delegate,
            {
                (cache: String box): (ISize val, USize val) =>
                    if cache.size() >= size_chunk then
                        (0, size_chunk)
                    else
                        NoChunk()
                    end
            }
        )

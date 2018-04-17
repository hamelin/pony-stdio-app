type SplitResult is (String iso^, String iso^)


interface SplitChunk
    fun apply(data: String iso): SplitResult


interface DriverBuffered is Driver

    be apply(app: App val, chunk: String val)


actor Buffer is DriverBytes
    let _delegate: DriverBuffered tag
    let _split_chunk: SplitChunk iso
    var _cache: String iso

    new create(delegate: DriverBuffered tag, split_chunk: SplitChunk iso) =>
        _delegate = delegate
        _split_chunk = consume split_chunk
        _cache = recover String end

    be at_start(app: App val) =>
        _delegate.at_start(app)

    be at_end(app: App val, exit_code: I32 val) =>
        _delegate.at_end(app, exit_code)

    be apply(app: App val, data: String val) =>
        _cache.insert_in_place(-1, data)
        let cache_iso: String iso = _cache = recover String end
        (let chunk: String iso, _cache) = recover _split_chunk(consume cache_iso) end
        if chunk.size() > 0 then
            _delegate(app, consume chunk)
            apply(app, "")  // In case there would be more chunks yet.
        end

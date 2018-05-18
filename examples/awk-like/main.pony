use "json"
use "stdapp"


actor Main is DriverRecord

    new create(env: Env) =>
        try
            Launch(env, DriverRecordsAwk(this)?)
        else
            env.err.print("Not supposed to have problems with an invalid regular expression -- wtf?")
            env.exitcode(1)
        end

    be apply(app: App val, record: Array[String val] val) =>
        if record.size() > 0 then
            let copy: Array[JsonType] ref = Array[JsonType](record.size())
            for field in record.values() do
                copy.push(field)
            end
            app.out.print(JsonArray.from_array(copy).string())
        end

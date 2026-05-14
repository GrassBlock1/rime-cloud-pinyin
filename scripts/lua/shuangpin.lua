local M = {}

local INITIAL_MAP = {
    u = "sh", i = "ch", v = "zh",
}

local SCHEMAS = {}

SCHEMAS.flypy = {
    initial = INITIAL_MAP,
    final = {
        q = "iu", w = "ei", e = "e", r = "uan", t = "ve",
        y = "un", o = "uo", p = "ie", a = "a", s = "ong",
        d = "ai", f = "en", g = "eng", h = "ang", j = "an",
        k = "ing", l = "uang", z = "ou", x = "ia", c = "ao",
        v = "ui", b = "in", n = "iao", m = "ian",
    },
    disambig = {
        k = {
            default = "ing",
            after = { g = "uai", k = "uai", h = "uai", v = "uai", u = "uai", i = "uai", r = "uai", z = "uai", c = "uai", s = "uai" },
        },
        l = {
            default = "uang",
            after = { j = "iang", q = "iang", x = "iang", n = "iang", l = "iang" },
        },
        x = {
            default = "ia",
            after = { g = "ua", k = "ua", h = "ua", v = "ua", u = "ua", i = "ua", r = "ua", z = "ua", c = "ua", s = "ua" },
        },
        s = {
            default = "ong",
            after = { j = "iong", q = "iong", x = "iong" },
        },
        r = {
            default = "uan",
            after = { j = "van", q = "van", x = "van", y = "van" },
        },
        y = {
            default = "un",
            after = { j = "vn", q = "vn", x = "vn", y = "vn" },
        },
        v = {
            default = "ui",
            after = { n = "v", l = "v", j = "u", q = "u", x = "u", y = "u" },
        },
        o = {
            default = "uo",
            after = { a = "o", o = "o", e = "e" },
        },
        t = {
            default = "ve",
            after = {},
        },
    },
    zero_initial = "auto",
}

SCHEMAS.zrm = {
    initial = INITIAL_MAP,
    final = {
        q = "iu", w = "ia", e = "e", r = "uan", t = "ve",
        y = "ing", o = "uo", p = "un", a = "a", s = "ong",
        d = "uang", f = "en", g = "eng", h = "ang", j = "an",
        k = "ao", l = "ai", z = "ei", x = "ie", c = "iao",
        v = "ui", b = "ou", n = "in", m = "ian",
    },
    disambig = {
        w = {
            default = "ia",
            after = { g = "ua", k = "ua", h = "ua", v = "ua", u = "ua", i = "ua", r = "ua", z = "ua", c = "ua", s = "ua" },
        },
        y = {
            default = "ing",
            after = { g = "uai", k = "uai", h = "uai", v = "uai", u = "uai", i = "uai", r = "uai", z = "uai", c = "uai", s = "uai" },
        },
        d = {
            default = "uang",
            after = { j = "iang", q = "iang", x = "iang", n = "iang", l = "iang" },
        },
        s = {
            default = "ong",
            after = { j = "iong", q = "iong", x = "iong" },
        },
        r = {
            default = "uan",
            after = { j = "van", q = "van", x = "van", y = "van" },
        },
        p = {
            default = "un",
            after = { j = "vn", q = "vn", x = "vn", y = "vn" },
        },
        v = {
            default = "ui",
            after = { n = "v", l = "v", j = "u", q = "u", x = "u", y = "u" },
        },
        o = {
            default = "uo",
            after = { a = "o", o = "o", e = "e" },
        },
    },
    zero_initial = "o",
}

SCHEMAS.mspy = {
    initial = INITIAL_MAP,
    final = {
        q = "iu", w = "ia", e = "e", r = "uan", t = "ve",
        y = "v", o = "uo", p = "un", a = "a", s = "ong",
        d = "uang", f = "en", g = "eng", h = "ang", j = "an",
        k = "ao", l = "ai", z = "ei", x = "ie", c = "iao",
        v = "ui", b = "ou", n = "in", m = "ian",
    },
    disambig = {
        w = {
            default = "ia",
            after = { g = "ua", k = "ua", h = "ua", v = "ua", u = "ua", i = "ua", r = "ua", z = "ua", c = "ua", s = "ua" },
        },
        y = {
            default = "v",
            after = { g = "uai", k = "uai", h = "uai", v = "uai", u = "uai", i = "uai", r = "uai", z = "uai", c = "uai", s = "uai" },
        },
        d = {
            default = "uang",
            after = { j = "iang", q = "iang", x = "iang", n = "iang", l = "iang" },
        },
        s = {
            default = "ong",
            after = { j = "iong", q = "iong", x = "iong" },
        },
        r = {
            default = "uan",
            after = { j = "van", q = "van", x = "van", y = "van" },
        },
        p = {
            default = "un",
            after = { j = "vn", q = "vn", x = "vn", y = "vn" },
        },
        v = {
            default = "ui",
            after = { d = "ve", t = "ve", n = "v", l = "v", j = "u", q = "u", x = "u", y = "u" },
        },
        o = {
            default = "uo",
            after = { a = "o", o = "o", e = "e" },
        },
    },
    zero_initial = "o",
}

SCHEMAS.sogou = {
    initial = INITIAL_MAP,
    final = {
        q = "iu", w = "ia", e = "e", r = "uan", t = "ve",
        y = "ing", o = "uo", p = "un", a = "a", s = "ong",
        d = "uang", f = "en", g = "eng", h = "ang", j = "an",
        k = "ao", l = "ai", z = "ei", x = "ie", c = "iao",
        v = "ui", b = "ou", n = "in", m = "ian",
    },
    disambig = {
        w = {
            default = "ia",
            after = { g = "ua", k = "ua", h = "ua", v = "ua", u = "ua", i = "ua", r = "ua", z = "ua", c = "ua", s = "ua" },
        },
        y = {
            default = "ing",
            after = { g = "uai", k = "uai", h = "uai", v = "uai", u = "uai", i = "uai", r = "uai", z = "uai", c = "uai", s = "uai" },
        },
        d = {
            default = "uang",
            after = { j = "iang", q = "iang", x = "iang", n = "iang", l = "iang" },
        },
        s = {
            default = "ong",
            after = { j = "iong", q = "iong", x = "iong" },
        },
        r = {
            default = "uan",
            after = { j = "van", q = "van", x = "van", y = "van" },
        },
        p = {
            default = "un",
            after = { j = "vn", q = "vn", x = "vn", y = "vn" },
        },
        v = {
            default = "ui",
            after = { n = "v", l = "v", j = "u", q = "u", x = "u", y = "u" },
        },
        o = {
            default = "uo",
            after = { a = "o", o = "o", e = "e" },
        },
    },
    zero_initial = "o",
}

local function resolve_initial(ch, schema)
    return schema.initial[ch] or ch
end

local function resolve_final(ch, initial_ch, schema)
    local base = schema.final[ch]
    if not base then return nil end

    local dis = schema.disambig[ch]
    if dis and dis.after then
        local override = dis.after[initial_ch]
        if override then return override end
    end
    return base
end

local function decode_pair(first, second, schema)
    local initial_ch = first
    local final_ch = second

    local initial = resolve_initial(initial_ch, schema)

    local final = resolve_final(final_ch, initial_ch, schema)
    if not final then
        final = final_ch
    end

    if initial == final then
        return initial
    end

    if final == "v" then
        return initial .. "v"
    end

    return initial .. final
end

function M.to_quanpin(input, schema_name)
    local schema = SCHEMAS[schema_name]
    if not schema then return input end

    local result = {}
    local i = 1
    local len = #input

    while i <= len do
        local ch = input:sub(i, i)
        if ch == "'" or ch == " " then
            i = i + 1
        else
            if i + 1 <= len then
                local first = input:sub(i, i)
                local second = input:sub(i + 1, i + 1)
                if second == "'" or second == " " then
                    table.insert(result, resolve_initial(first, schema))
                    i = i + 1
                else
                    table.insert(result, decode_pair(first, second, schema))
                    i = i + 2
                end
            else
                table.insert(result, resolve_initial(ch, schema))
                i = i + 1
            end
        end
    end

    return table.concat(result, "'")
end

function M.is_shuangpin(schema_name)
    return schema_name ~= nil and schema_name ~= "" and SCHEMAS[schema_name] ~= nil
end

return M

local M = {}

M.data = {}
M.loaded = false
M.dirty = false
M.file_path = nil
M.pending = {}

local function default_path()
    local home = os.getenv("HOME") or os.getenv("USERPROFILE") or "."
    local xdg = os.getenv("XDG_DATA_HOME")
    if xdg then
        return xdg .. "/rime/cloud_pinyin_user_dict.lua"
    end
    return home .. "/.local/share/rime/cloud_pinyin_user_dict.lua"
end

local function ensure_dir(path)
    local dir = path:match("^(.*)/[^/]*$")
    if dir and dir ~= "" then
        os.execute('mkdir -p "' .. dir .. '" 2>/dev/null')
    end
end

function M.load(path)
    M.file_path = path or default_path()
    M.data = {}

    local f = io.open(M.file_path, "r")
    if not f then
        M.loaded = true
        return
    end

    for line in f:lines() do
        local py, word, count = line:match("^([^\t]+)\t([^\t]+)\t(%d+)")
        if py and word and count then
            M.data[py] = M.data[py] or {}
            M.data[py][word] = tonumber(count) or 1
        end
    end

    f:close()
    M.loaded = true
    M.dirty = false
end

function M.save()
    if not M.dirty then return end
    if not M.file_path then M.file_path = default_path() end

    ensure_dir(M.file_path)

    local f = io.open(M.file_path, "w")
    if not f then return end

    for py, words in pairs(M.data) do
        for word, count in pairs(words) do
            f:write(py .. "\t" .. word .. "\t" .. tostring(count) .. "\n")
        end
    end

    f:close()
    M.dirty = false
end

function M.record(pinyin, word)
    if not pinyin or not word or pinyin == "" or word == "" then return end

    M.data[pinyin] = M.data[pinyin] or {}
    M.data[pinyin][word] = (M.data[pinyin][word] or 0) + 1
    M.dirty = true
end

function M.lookup(pinyin)
    if not pinyin then return {} end
    return M.data[pinyin] or {}
end

function M.boost_quality(pinyin, word, base_quality)
    local words = M.lookup(pinyin)
    local count = words[word] or 0
    if count > 0 then
        return base_quality + math.min(count, 10) * 0.5
    end
    return base_quality
end

function M.track(pinyin, word)
    M.pending[word] = pinyin
end

function M.on_commit(text)
    local pinyin = M.pending[text]
    if pinyin then
        M.record(pinyin, text)
        M.pending[text] = nil
        M.save()
        return true
    end
    return false
end

function M.clear_pending()
    M.pending = {}
end

return M

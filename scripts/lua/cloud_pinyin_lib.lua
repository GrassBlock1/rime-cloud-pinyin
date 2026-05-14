local M = {}

local shuangpin = require("shuangpin")
local user_dict = require("user_dict")

local ok, lib = pcall(require, "cloud_pinyin")
if not ok then
    log.error("[cloud_pinyin] 无法加载动态库: " .. tostring(lib))
    lib = nil
elseif type(lib.fetch) ~= "function" then
    log.error("[cloud_pinyin] 动态库缺少 fetch 函数")
    lib = nil
end

M.config = {
    engine = "sougou",
    shuangpin_schema = "",
    max_candidates = 5,
    quality = 2,
    comment = "云拼音",
    user_dict = true,
    api_url = "",
}

local function ensure_user_dict()
    if M.config.user_dict and not user_dict.loaded then
        user_dict.load()
    end
end

local function translate_input(input)
    if shuangpin.is_shuangpin(M.config.shuangpin_schema) then
        return shuangpin.to_quanpin(input, M.config.shuangpin_schema)
    end
    return input
end

local function fetch_words(query)
    if not lib then
        return nil
    end

    local api_url = nil
    if M.config.engine == "custom" then
        if M.config.api_url == "" then
            return {}
        end
        api_url = M.config.api_url
    end

    local ok, result = pcall(lib.fetch, M.config.engine, query, api_url)
    if not ok then
        log.error("[cloud_pinyin] 动态库调用失败: " .. tostring(result))
        return nil
    end

    return result or {}
end

local function yield_cloud_candidate(word, input, seg)
    local c = Candidate("cloud_pinyin", seg.start, seg._end, word.text, "(" .. M.config.comment .. ")")
    c.quality = M.config.quality

    if M.config.user_dict then
        c.quality = user_dict.boost_quality(input, word.text, c.quality)
    end

    if word.preedit and word.preedit ~= "" then
        c.preedit = word.preedit
    elseif shuangpin.is_shuangpin(M.config.shuangpin_schema) then
        c.preedit = shuangpin.to_quanpin(input, M.config.shuangpin_schema)
    end

    if M.config.user_dict then
        user_dict.track(input, word.text)
    end

    yield(c)
end

function M.translator(input, seg, env)
    if #input < 2 then
        return
    end

    ensure_user_dict()

    local query = translate_input(input)

    local result = fetch_words(query)
    if not result then
        return M.fallback_translator(input, seg, env)
    end

    if not result or #result == 0 then
        return
    end

    for i, word in ipairs(result) do
        if i > M.config.max_candidates then
            break
        end
        yield_cloud_candidate(word, input, seg)
    end
end

function M.fallback_translator(input, seg, env)
    local query = translate_input(input)

    local cmd
    if M.config.engine == "custom" then
        local api_url = M.config.api_url
        if api_url == "" then
            return
        end
        cmd = string.format('cloud_pinyin --engine custom --api-url "%s" --format tsv "%s" 2>/dev/null',
            api_url, query)
    else
        cmd = string.format('cloud_pinyin --engine %s --format tsv "%s" 2>/dev/null',
            M.config.engine, query)
    end

    local handle = io.popen(cmd, "r")
    if not handle then
        return
    end

    local count = 0
    for line in handle:lines() do
        if count >= M.config.max_candidates then
            break
        end

        local parts = {}
        for part in line:gmatch("[^\t]+") do
            table.insert(parts, part)
        end

        if #parts >= 1 then
            local word = {
                text = parts[1],
                preedit = parts[3] or "",
            }
            yield_cloud_candidate(word, input, seg)
            count = count + 1
        end
    end

    handle:close()
end

function M.processor(key, env)
    local kNoop = 2

    if not M.config.user_dict then
        return kNoop
    end

    local context = env.engine.context
    if not context:is_composing() then
        return kNoop
    end

    local repr = key:repr()
    if repr == "Return" or repr == "space" or
       (repr:match("^%d$") and repr ~= "0") then
        local commit = context:get_commit_text()
        if commit and commit ~= "" then
            user_dict.on_commit(commit)
        end
    end

    return kNoop
end

function M.notifier(env)
    if not M.config.user_dict then return end

    local context = env.engine.context
    local commit = context.commit_text
    if commit and commit ~= "" then
        user_dict.on_commit(commit)
    end
end

function M.make_processor(trigger_key)
    local flag = false

    local function processor(key, env)
        local kAccepted = 1
        local kNoop = 2
        local context = env.engine.context

        if key:repr() == trigger_key then
            if context:is_composing() then
                flag = true
                context:refresh_non_confirmed_composition()
                return kAccepted
            end
        end

        return kNoop
    end

    local function triggered_translator(input, seg, env)
        if flag then
            flag = false
            M.translator(input, seg, env)
        end
    end

    return {
        processor = processor,
        translator = triggered_translator,
    }
end

return M

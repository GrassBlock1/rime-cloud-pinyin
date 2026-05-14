-- rime.lua 配置示例
-- 将此文件内容复制到你的 rime.lua 中

-- ========== 方案 A: CLI 调用 (推荐) ==========

-- 方式 1: 直接翻译器（自动触发）
local cloud_pinyin_cli = require("cloud_pinyin_cli")
cloud_pinyin_cli.config.engine = "sougou"             -- 云拼音引擎: sougou, baidu, google, custom
cloud_pinyin_cli.config.shuangpin_schema = "flypy"     -- 双拼方案: flypy, zrm, mspy, sogou, 留空则不转换
cloud_pinyin_cli.config.user_dict = true               -- 选中云拼音候选时记录用户词库
cloud_pinyin_translator = cloud_pinyin_cli.translator
cloud_pinyin_processor = cloud_pinyin_cli.processor    -- 用于监听选词提交，记录用户词库

-- 方式 2: 带触发键（按 Control+t 触发）
-- local cloud_pinyin = cloud_pinyin_cli.make_processor("Control+t")
-- cloud_pinyin_processor = cloud_pinyin.processor
-- cloud_pinyin_translator = cloud_pinyin.translator

-- 方式 3: 自定义 API
-- cloud_pinyin_cli.config.engine = "custom"
-- cloud_pinyin_cli.config.api_url = "https://your-api.com/pinyin?input={input}"
-- 响应格式: {"candidates": [{"text": "你好", "preedit": "ni hao"}]}
-- cloud_pinyin_translator = cloud_pinyin_cli.translator
-- cloud_pinyin_processor = cloud_pinyin_cli.processor


-- ========== 方案 B: 动态库 (性能更好，需编译 so/dll) ==========
-- 如果放在 ~/.local/share/fcitx5/rime/lua 的库文件无法工作，请尝试取消注释下面一行
-- package.cpath = os.getenv("HOME") .. "/.local/share/fcitx5/rime/lua/?.so;" .. package.cpath
--
-- local cloud_pinyin_lib = require("libcloud_pinyin")
-- cloud_pinyin_lib.config.engine = "sougou"
-- cloud_pinyin_lib.config.shuangpin_schema = "flypy"  -- 双拼方案: flypy, zrm, mspy, sogou, 留空则不转换
-- cloud_pinyin_lib.config.user_dict = true
-- cloud_pinyin_lib.config.loading_animation = true
-- cloud_pinyin_translator = cloud_pinyin_lib.translator
-- cloud_pinyin_processor = cloud_pinyin_lib.processor

-- 使用示例配置：
-- 在 schema.yaml 中添加：
-- engine:
--   translators:
--     - lua_translator@cloud_pinyin_translator
--   processors:
--     - lua_processor@cloud_pinyin_processor  -- 记录用户词库
--
-- 支持的双拼方案 (shuangpin_schema):
--   flypy  - 小鹤双拼
--   zrm    - 自然码
--   mspy   - 微软双拼
--   sogou  - 搜狗双拼
--   留空   - 不使用双拼转换（默认）

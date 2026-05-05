# Rime 云拼音

可自定义的 Rime 输入引擎云端拼音增强工具。通过调用主流输入法的云端 API，实时获取最新的候选词推荐。

文档也提供其他语言版本：[简体中文](README-zh.md) | [英文](README.md)

## 能做什么

- 多引擎支持：内置搜狗、百度、Google 三大输入法的云端 API，可自由切换
- 双拼友好：原生支持小鹤、自然码、微软、搜狗双拼，自动转全拼查询
- 智能记忆：选中云拼音候选时自动记录到用户词库，下次优先显示
- 自定义 API：支持接入自建的拼音服务，满足个性化需求
- 轻量高效：Rust 编写，性能优异，不拖慢输入节奏

## 快速开始

### 第一步：编译安装

确保你的系统已安装 Rust 工具链：

```bash
cargo build --release
```

编译完成后，将 `target/release/cloud_pinyin` 放到系统 PATH 中（如 `/usr/local/bin`）。

### 第二步：配置 Rime

1. 将 `scripts/` 目录下的所有 `.lua` 文件复制到 Rime 用户目录的 `lua/` 文件夹中

2. 在你的输入法方案（如 `luna_pinyin.schema.yaml`）中添加：

```yaml
engine:
  translators:
    - lua_translator@cloud_pinyin_translator
  processors:
    - lua_processor@cloud_pinyin_processor
```

3. 重新部署 Rime 引擎

## 进阶用法

### 按需触发模式

如果你不想每次输入都触发云查询，可以设置触发键：

```lua
-- 按 Control + t 时才触发云拼音
local cloud_pinyin = cloud_pinyin_cli.make_processor("Control+t")
cloud_pinyin_processor = cloud_pinyin.processor
cloud_pinyin_translator = cloud_pinyin.translator
```

### 自定义 API

如果你有自建的拼音服务，可以这样接入：

```lua
cloud_pinyin_cli.config.engine = "custom"
cloud_pinyin_cli.config.api_url = "https://your-api.com/pinyin?input={input}"
```

你的 API 需要返回 JSON 格式：

```json
{
  "candidates": [{ "text": "你好", "preedit": "ni hao" }, { "text": "你号" }]
}
```

详细的 API 规范请参考 [自定义 API 文档](docs/custom_api.md)。

### 命令行测试

你也可以直接在终端测试云拼音功能：

```bash
# 使用搜狗引擎查询
cloud_pinyin --engine sougou "nihao"

# 查看详细信息（词长、拼音）
cloud_pinyin --engine baidu --format tsv "zhongguo"
```

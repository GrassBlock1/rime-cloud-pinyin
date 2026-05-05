# Rime Cloud Pinyin

A customizable cloud pinyin enhancement tool for the Rime input engine. It fetches real-time candidate word recommendations by calling the cloud APIs of mainstream input methods.

Docs also available in other languages: [简体中文](README-zh.md) | [English](README.md)

## Features

- Multiple engine support: Built-in cloud APIs for Sogou, Baidu, and Google input methods, freely switchable
- Shuangpin friendly: Natively supports Xiaohe, Ziranmao, Microsoft, and Sogou Shuangpin, with automatic conversion to full pinyin for querying
- Smart memorization: When a cloud pinyin candidate is selected, it is automatically recorded in the user dictionary and prioritized next time
- Custom API: Supports integrating self-hosted pinyin services to meet personalized needs
- Lightweight and efficient: Written in Rust, excellent performance, does not slow down typing

## Quick Start

### Step 1: Build and Install

Make sure the Rust toolchain is installed on your system:

```bash
cargo build --release
```

After building, place `target/release/cloud_pinyin` into a directory in your system PATH (e.g., `/usr/local/bin`).

### Step 2: Configure Rime

1. Copy all `.lua` files from the `scripts/` directory to the `lua/` folder in your Rime user directory

2. In your input method schema (e.g., `luna_pinyin.schema.yaml`), add:

```yaml
engine:
  translators:
    - lua_translator@cloud_pinyin_translator
  processors:
    - lua_processor@cloud_pinyin_processor
```

3. Redeploy the Rime engine

## Advanced Usage

### On-Demand Trigger Mode

If you don't want to trigger a cloud query on every keystroke, you can set a trigger key:

```lua
-- Trigger cloud pinyin only on Control + t
local cloud_pinyin = cloud_pinyin_cli.make_processor("Control+t")
cloud_pinyin_processor = cloud_pinyin.processor
cloud_pinyin_translator = cloud_pinyin.translator
```

### Custom API

If you have a self-hosted pinyin service, you can integrate it like this:

```lua
cloud_pinyin_cli.config.engine = "custom"
cloud_pinyin_cli.config.api_url = "https://your-api.com/pinyin?input={input}"
```

Your API needs to return JSON in the following format:

```json
{
  "candidates": [{ "text": "你好", "preedit": "ni hao" }, { "text": "你号" }]
}
```

For detailed API specifications, please refer to the [Custom API Documentation](docs/custom_api.md).

### Command Line Testing

You can also test the cloud pinyin functionality directly in the terminal:

```bash
# Query using the Sogou engine
cloud_pinyin --engine sougou "nihao"

# View detailed information (word length, pinyin)
cloud_pinyin --engine baidu --format tsv "zhongguo"
```

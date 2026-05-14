#[derive(Debug)]
pub struct Word {
    pub text: String,
    pub length: usize,
    pub preedit: String,
}

pub fn fetch(
    engine: &str,
    input: &str,
    api_url: Option<&str>,
) -> Result<Vec<Word>, Box<dyn std::error::Error>> {
    match engine {
        "baidu" => fetch_baidu(input),
        "google" => fetch_google(input),
        "sougou" => fetch_sougou(input),
        "custom" => {
            let url = api_url.ok_or("自定义引擎需要指定 api_url")?;
            fetch_custom(url, input)
        }
        _ => Err(format!("未知的引擎: {engine}").into()),
    }
}

fn fetch_baidu(input: &str) -> Result<Vec<Word>, Box<dyn std::error::Error>> {
    let url = format!(
        "https://olime.baidu.com/py?input={}&inputtype=py&bg=0&ed=5&result=hanzi&resultcoding=utf-8&ch_en=0&clientinfo=web&version=1",
        urlencoding::encode(input)
    );

    let client = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(5))
        .build()?;

    let resp = client.get(&url).send()?;
    let text = resp.text()?;

    if std::env::var("DEBUG").is_ok() {
        eprintln!("[baidu] 响应: {}", text);
    }

    let json: serde_json::Value = serde_json::from_str(&text)?;
    let mut words = Vec::new();

    if json["status"] == "T" {
        if let Some(result) = json["result"].as_array() {
            if let Some(first) = result.first().and_then(|r| r.as_array()) {
                for item in first.iter().take(5) {
                    if let Some(item_arr) = item.as_array() {
                        if item_arr.len() >= 3 {
                            let text = item_arr[0].as_str().unwrap_or("").to_string();
                            let length = item_arr[1].as_u64().unwrap_or(0) as usize;
                            let pinyin_info = &item_arr[2];
                            let pinyin = pinyin_info["pinyin"].as_str().unwrap_or("").to_string();
                            let preedit = pinyin.replace("'", " ");

                            words.push(Word {
                                text,
                                length,
                                preedit,
                            });
                        }
                    }
                }
            }
        }
    }

    Ok(words)
}

fn fetch_google(input: &str) -> Result<Vec<Word>, Box<dyn std::error::Error>> {
    let url = format!(
        "https://inputtools.google.com/request?text={}&itc=zh-t-i0-pinyin&num=5&cp=0&cs=1&ie=utf-8&oe=utf-8",
        urlencoding::encode(input)
    );

    let client = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_millis(1500))
        .build()?;

    let resp = client.get(&url).send()?;
    let text = resp.text()?;

    let json: serde_json::Value = serde_json::from_str(&text)?;
    let mut words = Vec::new();

    if json[0] == "SUCCESS" {
        if let Some(results) = json[1].as_array() {
            if let Some(first) = results.first().and_then(|r| r.as_array()) {
                let input_text = first[0].as_str().unwrap_or("");
                let candidates = first[1].as_array();
                let meta = first.get(3);

                if let Some(candidates) = candidates {
                    for (i, candidate) in candidates.iter().take(5).enumerate() {
                        let text = candidate.as_str().unwrap_or("").to_string();

                        let length = meta
                            .and_then(|m| m["matched_length"].as_array())
                            .and_then(|arr| arr.get(i))
                            .and_then(|v| v.as_u64())
                            .unwrap_or(input_text.len() as u64)
                            as usize;

                        let preedit = meta
                            .and_then(|m| m["annotation"].as_array())
                            .and_then(|arr| arr.get(i))
                            .and_then(|v| v.as_str())
                            .unwrap_or("")
                            .to_string();

                        words.push(Word {
                            text,
                            length,
                            preedit,
                        });
                    }
                }
            }
        }
    }

    Ok(words)
}

fn fetch_sougou(input: &str) -> Result<Vec<Word>, Box<dyn std::error::Error>> {
    let data = serial_keys(input);

    let url = "http://shouji.sogou.com/web_ime/mobile.php?durtot=0&h=000000000000000&r=store_mf_wandoujia&v=3.7";

    let client = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_millis(1000))
        .build()?;

    let resp = client
        .post(url)
        .header("Content-Type", "application/octet-stream")
        .body(data)
        .send()?;

    let bytes = resp.bytes()?;
    let words = parse_sougou_result(&bytes)?;

    Ok(words)
}

fn serial_keys(keys: &str) -> Vec<u8> {
    let token = vec![0u8, 5, 0, 0, 0, 0, 1];
    let total_len = token.len() + keys.len() + 3;

    let mut data = Vec::new();
    data.push(total_len as u8);
    data.extend_from_slice(&token);
    data.push(keys.len() as u8);
    data.extend_from_slice(keys.as_bytes());

    let mut start: u8 = 0;
    for &b in &data {
        start ^= b;
    }
    data.push(start);

    data
}

fn parse_sougou_result(result: &[u8]) -> Result<Vec<Word>, Box<dyn std::error::Error>> {
    let mut words = Vec::new();

    if result.len() < 2 {
        return Ok(words);
    }

    let expected_len = (result[0] as usize) + 2;
    if expected_len != result.len() {
        eprintln!(
            "[sougou] 警告: 数据包长度不匹配, 期望 {}, 实际 {}",
            expected_len,
            result.len()
        );
    }

    if result.len() < 0x14 + 2 {
        return Ok(words);
    }

    let num_words = u16::from_le_bytes([result[0x12], result[0x13]]) as usize;
    if num_words == 0 || num_words > 32 {
        eprintln!("[sougou] 警告: 词数量异常 {}", num_words);
        return Ok(words);
    }

    let mut pos: usize = 0x14;

    for _ in 0..num_words {
        if pos + 2 > result.len() {
            break;
        }

        let str_len = u16::from_le_bytes([result[pos], result[pos + 1]]) as usize;
        pos += 2;

        if str_len == 0 || str_len > 0xFF {
            eprintln!("[sougou] 错误: 无效的字符串长度 {}", str_len);
            continue;
        }

        if pos + str_len > result.len() {
            break;
        }

        let utf16_bytes = &result[pos..pos + str_len];
        pos += str_len;

        let utf16_vec: Vec<u16> = utf16_bytes
            .chunks_exact(2)
            .map(|chunk| u16::from_le_bytes([chunk[0], chunk[1]]))
            .collect();

        let text = String::from_utf16(&utf16_vec).unwrap_or_default();

        if pos + 2 > result.len() {
            break;
        }
        let skip1 = u16::from_le_bytes([result[pos], result[pos + 1]]) as usize;
        pos += skip1 + 2;

        if pos + 2 > result.len() {
            break;
        }
        let skip2 = u16::from_le_bytes([result[pos], result[pos + 1]]) as usize;
        pos += skip2 + 2 + 1;

        words.push(Word {
            text,
            length: 0,
            preedit: String::new(),
        });

        if words.len() >= 5 {
            break;
        }
    }

    Ok(words)
}

fn fetch_custom(api_url: &str, input: &str) -> Result<Vec<Word>, Box<dyn std::error::Error>> {
    let url = api_url.replace("{input}", &urlencoding::encode(input));

    let client = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(5))
        .build()?;

    let resp = client.get(&url).send()?;
    let text = resp.text()?;

    if std::env::var("DEBUG").is_ok() {
        eprintln!("[custom] 响应: {}", text);
    }

    let json: serde_json::Value = serde_json::from_str(&text)?;
    let mut words = Vec::new();

    if let Some(candidates) = json["candidates"].as_array() {
        for item in candidates.iter().take(5) {
            let word_text = item["text"].as_str().unwrap_or("").to_string();
            if word_text.is_empty() {
                continue;
            }
            let preedit = item["preedit"].as_str().unwrap_or("").to_string();
            words.push(Word {
                text: word_text,
                length: input.len(),
                preedit,
            });
        }
    }

    Ok(words)
}

#[cfg(feature = "lua")]
#[mlua::lua_module]
fn cloud_pinyin(lua: &mlua::Lua) -> mlua::Result<mlua::Table> {
    let exports = lua.create_table()?;

    let fetch_fn = lua.create_function(
        |lua, (engine, input, api_url): (String, String, Option<String>)| {
            let words =
                fetch(&engine, &input, api_url.as_deref()).map_err(mlua::Error::external)?;
            let result = lua.create_table()?;

            for (index, word) in words.into_iter().enumerate() {
                let item = lua.create_table()?;
                item.set("text", word.text)?;
                item.set("length", word.length)?;
                item.set("preedit", word.preedit)?;
                result.set(index + 1, item)?;
            }

            Ok(result)
        },
    )?;

    exports.set("fetch", fetch_fn)?;
    Ok(exports)
}

use clap::Parser;

#[derive(Parser, Debug)]
#[command(author, version, about = "云拼音命令行工具", long_about = None)]
struct Args {
    #[arg(
        short,
        long,
        default_value = "sougou",
        help = "云拼音引擎: baidu, google, sougou, custom"
    )]
    engine: String,

    #[arg(
        short,
        long,
        help = "输出格式: simple (仅词汇), tsv (词\\长度\\拼音)",
        default_value = "simple"
    )]
    format: String,

    #[arg(
        long,
        help = "自定义 API URL 模板, 用 {input} 作为拼音占位符 (需 -e custom)"
    )]
    api_url: Option<String>,

    #[arg(help = "输入的拼音")]
    input: String,
}

fn main() {
    let args = Args::parse();

    let result = cloud_pinyin::fetch(&args.engine, &args.input, args.api_url.as_deref());

    match result {
        Ok(words) => {
            for word in words {
                match args.format.as_str() {
                    "tsv" => println!("{}\t{}\t{}", word.text, word.length, word.preedit),
                    _ => println!("{}", word.text),
                }
            }
        }
        Err(e) => {
            eprintln!("请求失败: {}", e);
            std::process::exit(1);
        }
    }
}

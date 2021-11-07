# hatenablog-all-feed-generator

はてなブログのRSS出力件数が30件までなのでRSS自体に30件以上載せたい場合の方法を見つけられなかったため書き捨てでスクリプトを書いた

## 使いかた
### 環境変数

はてなブログのAPIを使うため各種環境変数が必要

下記参照のこと

[Consumer key を取得して OAuth 開発をはじめよう - Hatena Developer Center](http://developer.hatena.ne.jp/ja/documents/auth/apis/oauth/consumer)

| 名前 | 概要 |
|:-|:-|
|HATENABLOG_CONSUMER_KEY ||
|HATENABLOG_CONSUMER_SECRET| |
|HATENABLOG_ACCESS_TOKEN| |
|HATENABLOG_ACCESS_TOKEN_SECRET| |

- bin/entries.rb

ファイル内でも修正が必要(49 - 51)

RSS内で使用するため適切な説明などを入れる

```
SITE_TITLE = '' # サイトタイトル
SITE_DESCRIPTION = '' # サイト説明
SITE_URL = '' # e.g.) https://swfz.hatenablog.com/
```

### Execution

はてなブログのユーザー名、ドメインが引数で必要なのでそれぞれ渡す

```shell
bundle install
ruby bin/entries.rb ${HATENABLOG_USERNAME} ${HATENABLOG_DOMAIN}
```

`rss.xml`というファイルが生成されるので適当な場所にホストしてRSSとして参照してもらう

仕組み上すべてのエントリーをとってくるようになってるので記事数が多い場合、APIリクエスト数が結構行く可能性があるので注意が必要です

## 気が向いたらやるかも
- リファクタリング
- RSSファイルの定期出力
- XMLファイルのデプロイ
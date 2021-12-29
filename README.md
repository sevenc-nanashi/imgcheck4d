# 拾い画チェッカー for Discord

[拾い画チェッカーAPI](https://imgcheck.irucabot.com/) を使って、拾い画かどうか判定するBotです。

## 使い方

### 返信する

拾い画かどうか判定したいメッセージにBotのメンションで送信してください。

### 右クリックメニューを使う

拾い画かどうか判定したいメッセージに右クリックして `拾い画チェック` を選択してください。

## セルフホストの仕方

1. リポジトリをクローンします。
2. `bundle install` を実行します。
3. Discord Developer Portal で Bot を作成します。
4. `.env.sample` を `.env` にコピーし、トークンを入力します。
5. `bundle exec discorb run` を実行します。

## ライセンス

MITライセンスで公開しています。
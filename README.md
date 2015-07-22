# README

### About

Rails上でDynamoDBのAPIを検証するためのサンプルアプリケーションです。
デフォルトではDynamoDB Localを利用しますが、DynamoDBに切り替えることも可能です。

### Install

```
bundle install --path=vendor/bundle
./dynamodb_local/start
bundle exec rails s
```

`http://localhost:3000/`を開くと、DynamoDB APIを確認することができます (`http://localhost:8000/shell`でJS Shellを起動できます)。
APIのリファレンスは[Module: Aws::DynamoDB API](http://docs.aws.amazon.com/sdkforruby/api/Aws/DynamoDB.html)を参照下さい。

### Tips

DynamoDBを利用する場合、`app/controllers/application_controller.rb`のエンドポイントをコメントアウトします。

```
@dynamo_db = Aws::DynamoDB::Client.new(
  region: 'ap-northeast-1',
  # endpoint: 'http://localhost:8000'
)
```

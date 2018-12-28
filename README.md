# Authentication Proxy Server of Amazon Product Advertising API.
### (Amazon Product Advertising APIの認証を代替するPROXYサーバ)

amazon-auth-proxyの実行環境には以下の3種類があります。この
ドキュメントではそれぞれについて順に説明します。

* CGI, FastCGI
* Sinatra
* Docker

### amazon-auth-proxy.cgi, amazon-auth-proxy.fcgi

amazon-auth-proxy.cgiは、RubyのCGIとして書かれています。従来の
Amazon ECS APIとして動作し、指定した言語のAmazon PAAPIに対して
有効な認証済みリクエストを作成して呼び出し元に返します。または
実際にAPIをコールしたのち、結果をそのまま返します。

amazon-auth-proxy.fcgiはFastCGI対応版です。内部的に.cgiを呼び出
しているので、.cgiも必要です。

amazon-auth-proxy.cgiは、同じディレクトリにあるamazon-auth-proxy.yaml
というファイルを読み、そこに記述されている各種APIキーとAPIのエ
ントリポイント、アソシエイトIDなどを使ってAPI呼び出しを構築しま
す(amazon-auth-proxy.sample.yamlを参照)。amazon-auth-proxy.yaml
には公開してはいけない情報が含まれるので、.htaccessなどによって
アクセスを禁止しなくてはいけません(dot.htaccess参照)。

amazon-auth-proxy.yamlで指定するentry_pointには、以下のような各
国向けAmazonのAPIエントリポイントURLを指定します:

```
http://webservices.amazon.com/onca/xml
http://webservices.amazon.co.jp/onca/xml
http://webservices.amazon.fr/onca/xml
http://webservices.amazon.co.uk/onca/xml
http://webservices.amazon.de/onca/xml
http://webservices.amazon.ca/onca/xml
```

また、Styleパラメタを使用したクエリのため、xslt_entry_pointとし
て以下のURLも指定してください:

```
http://xml-us.amznxslt.com/onca/xml
http://xml-jp.amznxslt.com/onca/xml
http://xml-fr.amznxslt.com/onca/xml
http://xml-uk.amznxslt.com/onca/xml
http://xml-de.amznxslt.com/onca/xml
http://xml-ca.amznxslt.com/onca/xml
```

use_redirectは、通常trueにして運用してください。これは構築した
AmazonへのリクエストURLを、302リダイレクトとして呼び出し元に返
すという意味です。これにより、proxyサーバの負荷を低減します。

### amazon-auth-proxy.rb
amazon-auth-proxy.cgiのSinatra版です。内部で.cgiを読み込んでい
るため、.cgiも必要です。

Sinatra版は、一つのインスタンスで各国サイトに対応します。このた
め、.cgiとは設定ファイルの形式が異なります。amazon-auth-proxy.sinatra.yaml
をamazon-auth-proxy.yamlに変えて利用して下さい。

HerokuのようなPaaSでの利用を考慮して、access_keyとsecret_keyは
それぞれ以下の環境変数を優先して使うようになっています:

```
AMAZON_ACCESS_KEY
AMAZON_SECRET_KEY
```

お使いのPaaSに応じて上記の環境変数を設定して下さい。また、Amazon
側の仕様変更により、AssociateTag(aid)が指定されていない国のAmazon
は利用できなくなっています。自分が管理しているAssociateTagをaid
に指定して下さい。例:

```
aid:
  jp: cshs-22
  us: tdiarnet-20
```

Sinatora版では、リバースプロキシサービス向けのrpaproxy.yamlも自動
生成します。aidで指定した国のみのrpaproxy.yamlを生成します。名前
としてamazon-auth-proxy.yamlのnameを利用するので忘れずに書き換えて
下さい。

### Dockerを使った実行
Sinatra版のDockerイメージを提供しています。下記のようにして実行して
ください。

access_keyとsecret_keyをamazon-auth-proxy.yamlに記述した場合:

```bash
% docker run --name amazon-auth-proxy \
  -v $(pwd)/amazon-auth-proxy.yaml:/app/amazon-auth-proxy:ro \
  -p 80:80 tdtds/amazon-auth-proxy:latest
```

access_keyとsecret_keyを環境変数で与える場合:

```bash
% docker run --name amazon-auth-proxy \
  -v $(pwd)/amazon-auth-proxy.yaml:/app/amazon-auth-proxy:ro \
  -e AMAZON_ACCESS_KEY=【YOUR_ACCESS_KEY】 \
  -e AMAZON_SECRET_KEY=【YOUR_SECRET_KEY】 \
  -p 80:80 tdtds/amazon-auth-proxy:latest
```

### 権利関係
```
Copyright (C) 2011 TADA Tadashi <t@tdtds.jp>
You can redistribute it and/or modify it under GPL2.
```

なお、module HMACは、えろぺおさんのコードを流用しています。
<http://elpeo.jp/diary/20090512.html#p01>

# Dockerを使ったJavaScript開発環境汎用リポジトリ
このリポジトリは**ローカルにNode.jsのインストールを行わず**で、Docker上で**ReactやVueなどのJavaScriptフレームワークを使ったプロジェクトを立ち上げる**ための汎用的な基盤を提供します。　　
ここでは、特に`Vite & React`環境の構築を行います。

This repository provides a versatile foundation for setting up projects using JavaScript frameworks like React and Vue on Docker, eliminating the need for local Node.js installation. This guide specifically focuses on setting up a Vite & React environment.
[Here is for English Speaker](README-EN.md)

## Node.js環境の準備とコンテナの起動
ベースとなるNode.js環境（node:22-alpine）のコンテナを起動します。
初期設定では、プロジェクトを立ち上げるための対話モードを有効にしています。

- Dockerfile
  - FROM node:22-alpine
  - image名はnode-22-installです
  - CMD ["sh"]で永続的にコンテナが起動します。終了させることを忘れないでください
- docker-compose.yml
  - volumes: - .:/app でローカルとコンテナのディレクトリを同期。
  - tty: trueとstdin_open: trueで対話モードを有効化。

### プロジェクトの立ち上げ
- Node-jsをインストールして、コンテナをバックグラウンドで起動します。
```bash
docker compose up -d
```
- 起動しているコンテナの`ID`もしくは`NAMES`を確認して、コンテナシェルに入ってください。
```bash
docker ps
```
```bash
docker exec -it [コンテナIDもしくはNAMES] /bin/sh
```
- コンテナのシェルに入ったら、Viteの対話式コマンドでプロジェクトを立ち上げます。 `create-react-app`は非推奨のため、Viteを使用します。
```bash
/app # npm create vite
```
> 
> **対話式の入力例:** 
> - Viteの指示に従って、プロジェクト名やフレームワークを選択します。
>  - プロジェクト名は任意です。例えば、vite-projectとすると、ルートフォルダ直下にそのフォルダが作成されます。
>  - フレームワークは立ち上げたいプロジェクトで選択してください。このリポジトリでは`React`,`Typescript`をベースにしています。
>  - Install with npm and start now? に Yes と答えると、依存関係のインストールも自動で行われます。
>

<img src="npm vite command.png">

- プロジェクトの作成が完了したら、`ctrl`+`c`で対話モードを終了し、シェルを抜けてください。
```bash
/app # exit
```
### コンテナとイメージの停止・破棄
プロジェクトの立ち上げに必要な作業はこれで完了です。初期設定用のコンテナとイメージを停止・破棄します。
このままDockerfileとdockerc-compose.ymlを破棄をおこなわない場合、立ち上げたプロジェクト環境に応じて、書き換えをしてください。
```bash
docker compose down
docker image rm node-22-install
```

## 開発環境用ファイルへの入れ替えと設定
新しく作成されたプロジェクト（例: vite-project）を、開発・実行用の環境設定に切り替えます。`asset`ディレクトリ内にある以下のファイルを、作成した新しいプロジェクトのルートに移動またはコピーしてください。これらは`Vite & React`をベースとした開発に最適化されています。

|ファイル名|説明|
|-|-|
|asset/Dockerfile|アプリケーションの実行環境を定義。依存関係のインストールやホットリロード用ポートの設定が含まれます。|
|asset/docker-compose.yml|開発時の設定を定義。ホットリロードの安定化やポートマッピング、node_modulesの分離設定が含まれます。|
|.dockerignore|不要なファイルをイメージビルドから除外。|

### 開発環境ファイルの設定内容
- **Dockerfile（asset/Dockerfile）:** ビルドのキャッシュを最適化し、npm installとソースコードのコピーを実行します。
```Dockerfile
FROM node:22-alpine 

WORKDIR /app
# キャッシュ最適化
COPY package*.json ./ 
RUN npm install
# プロジェクトのソースコードをコピー
COPY . .
# ポート:VITEのデフォルトポート
EXPOSE 5173
# 実行:開発サーバーを起動
CMD ["npm", "run", "dev"]
```
- **docker-compose.yml（asset/docker-compose.yml）:** ホスト（ローカル）環境とコンテナ環境でのファイルを同期し、Viteのホットリロードを安定させます。
```yml
version: '3.1.0'
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    # ローカルのnode_modulesがコンテナを上書きすることを防ぐため、node_modulesを分離してください。依存関係はpackage.jsonが管理し、コンテナを最新に保ってくれます。また、バイナリエラーを回避します。
    # node_modulesは.dockerignoreでコピー対象外にしてください。
    volumes:
      - .:/app
      - /app/node_modules 
    # ポートマッピング:ローカルにマッピングしたい方は3000:5173等としてください。
    ports:
      - "5173:5173"
    # ホットリロードの安定化
    environment:
      - CHOKIDAR_USEPOLLING=true
```
- **.dockerignore（asset/.dockerignore）:** node_modulesやdistなどの自動生成されるイメージに含める必要のないローカルファイルを除外します。

#### コード修正(VITE環境の場合)
作成したプロジェクトのpackage.jsonを修正し、devコマンドでホスト側からアクセスできるようにします。
##### package.jsonの修正
```json
  "scripts": {
    "dev": "vite --host 0.0.0.0", // vite --host 0.0.0.0"にすることで、Dockerコンテナ外（ホストマシン）のブラウザからlocalhost:5173などでアクセス可能になります
    "build": "tsc -b && vite build",
    "lint": "eslint .",
    "preview": "vite preview"
  },
```
##### vite.config.tsの修正（任意:相対パスを利用する場合）
Viteはデフォルトで絶対参照です。create-react-appのような相対参照をしたい場合やレンタルサーバー等にデプロイする場合、プロジェクトルートのvite.`config.ts`（または`vite.config.js`）に以下の設定を追加してください。  
>※package.jsonへのhomepageプロパティはViteでは無効です。
```typescript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  base: './',　// これを追加
  plugins: [react()],
})
```

## 次のステップ
これで、Dockerコンテナ内でVite + Reactの開発を開始できます。このリポジトリ（汎用環境を構築したリポジトリ）の役割はこれで完了です。

新しく作成したプロジェクトフォルダ（例: vite-project）をルートにして、新しいリポジトリとして開発を進めてください。

### 開発を始めるために
1. 新しいプロジェクトフォルダ（例: vite-project）に移動します。
2. docker compose up コマンドで開発サーバーを起動します。
3. ブラウザで http://localhost:5173 にアクセスし、開発を開始してください。

|コマンド|実行|
|-|-|
|docker compose up -d|コンテナをバックグラウンドで起動。シェルでビルドコマンド`npm run build`を実行するときなど。|
|docker compose up --build|イメージを強制的にビルドし、コンテナを起動|
|docker compose up|コンテナをフォアグラウンドで起動|
|`ctrl`+`c`|フォアグラウンドで起動中のコンテナを停止（正常終了）|
|docker compose stop|実行中のコンテナを停止。コンテナの状態（設定やデータ）は保持されます。|
|docker compose down|コンテナとネットワークを停止・破棄|
|docker compose run [SERVICE] [COMMAND] |一時的なコンテナでコマンドを実行。コマンド実行後、コンテナは自動的に終了します。|


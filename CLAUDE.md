# CLAUDE.md

## コンテキスト参照先

- Terraform 操作規約（plan/apply・ファイル管理・Secret Manager） → `.claude/rules/terraform.md`

## このリポジトリの役割

rails-sandbox-backend / rails-sandbox-frontend を GCP（Cloud Run + Cloud SQL）にデプロイするための Terraform とデプロイスクリプトを管理する。

## 重要な知識

### イメージタグ管理

`terraform.tfvars` の `rails_image` / `front_image` には git SHA ベースのタグを使う（`:latest` は Terraform が差分を検知できないため使用しない）。

```
rails_image = "asia-northeast1-docker.pkg.dev/.../rails-api:abc1234"
front_image = "asia-northeast1-docker.pkg.dev/.../front:def5678"
```

`deploy.sh` が自動更新するため、手動編集は不要。

### NEXT_PUBLIC_ 変数の扱い

Next.js の `NEXT_PUBLIC_` 変数はビルド時に静的埋め込みされる。Cloud Run の実行時環境変数では効かない。フロントのビルドは必ず `--build-arg NEXT_PUBLIC_GRAPHQL_ENDPOINT=<URL>` を渡すこと。`deploy.sh` はこれを自動で行う。

### DATABASE_URL のフォーマット

Cloud Run から Cloud SQL への接続は Unix socket 経由。Ruby の URI ライブラリの制約により、以下のフォーマットが必要：

```
postgresql://USER:PASS@localhost/DB_NAME?host=/cloudsql/PROJECT:REGION:INSTANCE
```

`@/` ではなく `@localhost` を使うこと（`@/` だと URI::InvalidURIError になる）。

### Cloud SQL の接続方式

Cloud Run v2 の `volumes` ブロックで Cloud SQL Auth Proxy を自動起動する。`/cloudsql/PROJECT:REGION:INSTANCE` に Unix socket が作られ、DATABASE_URL の `?host=` で参照する。

### Artifact Registry

`rails-sandbox` リポジトリは Terraform 外で作成済み（state に含まれない）。プロジェクト削除時は別途削除が必要。

## deploy.sh の注意

- `terraform apply -auto-approve` を使用するため、差分は事前に `terraform plan` で確認すること
- 各リポジトリの HEAD コミットが未プッシュでも動作するが、デプロイ前に push しておくことを推奨
- 実行場所は `rails-sandbox-infra/` ディレクトリ。`rails-sandbox-backend/` と `rails-sandbox-frontend/` が同じ階層にある前提

## ファイル構成の注意

- `terraform.tfvars` はコミット対象外（`.gitignore` 済み）。`deploy.sh` がローカルで SHA を自動書き換えする
- `terraform.tfstate` はコミット対象外（`.gitignore` 済み）。現状はローカル state
- Secret Manager の秘匿値は Terraform state に含まれるため、state ファイルの取り扱いに注意

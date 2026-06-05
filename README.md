# rails-sandbox-infra

rails-sandbox / rails-sandbox-front を GCP にデプロイするための Terraform インフラ管理リポジトリ。

## 構成

```
rails-sandbox-infra/
├── deploy.sh          # ビルド〜デプロイを一括実行するスクリプト
└── terraform/
    ├── main.tf        # プロバイダー設定
    ├── variables.tf   # 変数定義
    ├── terraform.tfvars        # プロジェクト ID・リージョン・イメージタグ
    ├── terraform.tfvars.example
    ├── croud_run.tf   # Cloud Run サービス定義
    ├── cloudsql.tf    # Cloud SQL インスタンス・DB・ユーザー
    ├── secrets.tf     # Secret Manager シークレット定義
    ├── iam.tf         # サービスアカウント・IAM バインディング
    └── outputs.tf     # rails_api_url / front_url
```

## GCP リソース

| リソース | 内容 |
|---|---|
| Cloud Run | `rails-sandbox-api`（Rails）/ `rails-sandbox-front`（Next.js） |
| Cloud SQL | PostgreSQL 16 (`db-f1-micro`)、Unix socket で Cloud Run と接続 |
| Secret Manager | `rails-master-key` / `database-url` / `allowed-origins` |
| Artifact Registry | `rails-sandbox` リポジトリ（Terraform 外で作成） |
| Service Account | `rails-runner`（Cloud Run 実行用） |

## 前提条件

```bash
# ツール
brew install terraform google-cloud-sdk

# 認証
gcloud auth login
gcloud auth application-default login
gcloud config set project <PROJECT_ID>
```

## 初回セットアップ

```bash
cd terraform
terraform init

# Secret Manager に初期値を登録（既存シークレットは import する）
gcloud secrets versions add rails-master-key --data-file=<path/to/master.key>

terraform apply
```

## 通常デプロイ

リポジトリルートの `deploy.sh` がすべてを担う。`GCP_PROJECT` は必須、`GCP_REGION` は未指定時 `asia-northeast1`。

```bash
export GCP_PROJECT=your-project-id
# export GCP_REGION=asia-northeast1  # 必要なら変更
./deploy.sh
```

内部で以下を順番に実行する：

1. `rails-sandbox` の git SHA でバックエンドイメージをビルド・push
2. `terraform output` で API URL を取得
3. `rails-sandbox-front` の git SHA + API URL でフロントイメージをビルド・push
4. `terraform.tfvars` のイメージタグを更新
5. `terraform apply` でデプロイ

## URL 確認

```bash
cd terraform
terraform output rails_api_url
terraform output front_url
```

## 削除

```bash
# リソースのみ削除
cd terraform && terraform destroy

# プロジェクトごと削除（最も確実）
gcloud projects delete <PROJECT_ID>
```

## Terraform 操作規約

### plan → apply の必須フロー

`terraform apply` を単体で実行してはならない。必ず事前に `terraform plan` で差分を確認する。

```bash
cd terraform
terraform plan   # 差分を確認
terraform apply  # 問題なければ適用
```

`deploy.sh` は `-auto-approve` で apply するため、deploy.sh 経由でデプロイする前に
手動で `terraform plan` を実行して差分を把握しておくこと。

### イメージタグ管理

`terraform.tfvars` の `rails_image` / `front_image` には git SHA ベースのタグを使う。
`:latest` タグは Terraform が差分を検知できないため使用禁止。

```hcl
rails_image = "asia-northeast1-docker.pkg.dev/.../rails-api:abc1234"
front_image = "asia-northeast1-docker.pkg.dev/.../front:def5678"
```

`deploy.sh` が各リポジトリの HEAD コミットの SHA で自動更新する。手動編集は不要。

### ファイル管理

| ファイル | git 管理 | 備考 |
|---|---|---|
| `terraform.tfvars` | **管理外**（.gitignore 済み） | deploy.sh がローカルで SHA を自動書き換えするため |
| `terraform.tfvars.example` | 管理対象 | 初期セットアップの雛形 |
| `terraform.tfstate` | **管理外**（.gitignore 済み） | ローカル state はコミット不可 |
| `.terraform.lock.hcl` | 管理外（.gitignore 済み） | — |
| `*.tf` | 管理対象 | インフラ定義本体 |

### Secret Manager の取り扱い

`terraform.tfstate` には Secret Manager の秘匿値が平文で含まれる場合がある。
state ファイルは絶対にコミット・共有しないこと。

### Artifact Registry の注意

`rails-sandbox` Artifact Registry リポジトリは Terraform 外で作成済みのため state に含まれない。
`terraform destroy` を実行しても Artifact Registry は削除されない。別途手動削除が必要。
#!/bin/bash
# 前提: rails-sandbox/, rails-sandbox-front/, rails-sandbox-infra/ が同じ階層にあること
set -euo pipefail

INFRA_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_DIR="$(dirname "$INFRA_DIR")"
TERRAFORM_DIR="$INFRA_DIR/terraform"

PROJECT="${GCP_PROJECT:?GCP_PROJECT を設定してください (例: export GCP_PROJECT=your-project-id)}"
REGION="${GCP_REGION:-asia-northeast1}"
REGISTRY="$REGION-docker.pkg.dev/$PROJECT/rails-sandbox"

RAILS_SHA=$(git -C "$WORKSPACE_DIR/rails-sandbox" rev-parse --short HEAD)
FRONT_SHA=$(git -C "$WORKSPACE_DIR/rails-sandbox-front" rev-parse --short HEAD)

echo "==> rails-api:$RAILS_SHA をビルド中..."
gcloud builds submit \
  --config="$WORKSPACE_DIR/rails-sandbox/cloudbuild.yaml" \
  --project="$PROJECT" \
  --substitutions="_SHA=$RAILS_SHA" \
  "$WORKSPACE_DIR/rails-sandbox"

# rails_image を更新
sed -i '' "s|rails_image = .*|rails_image = \"$REGISTRY/rails-api:$RAILS_SHA\"|" "$TERRAFORM_DIR/terraform.tfvars"

# Cloud Run の URL は一度作成されると変わらないため、現在の値を使用
API_URL=$(cd "$TERRAFORM_DIR" && terraform output -raw rails_api_url)
echo "==> API URL: $API_URL"

echo "==> front:$FRONT_SHA をビルド中..."
gcloud builds submit \
  --config="$WORKSPACE_DIR/rails-sandbox-front/cloudbuild.yaml" \
  --project="$PROJECT" \
  --substitutions="_SHA=$FRONT_SHA,_GRAPHQL_ENDPOINT=$API_URL/graphql" \
  "$WORKSPACE_DIR/rails-sandbox-front"

# front_image を更新
sed -i '' "s|front_image = .*|front_image = \"$REGISTRY/front:$FRONT_SHA\"|" "$TERRAFORM_DIR/terraform.tfvars"

echo "==> terraform apply..."
cd "$TERRAFORM_DIR"
terraform apply -auto-approve

echo ""
echo "===== デプロイ完了 ====="
echo "Front URL: $(terraform output -raw front_url)"
echo "API URL:   $API_URL"

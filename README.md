# GCP Free Tier × Terraform × Docker デプロイメントプロジェクト

[![CI/CD Pipeline](https://github.com/YOUR_USERNAME/gcp-deploy-lab/actions/workflows/deploy.yml/badge.svg)](https://github.com/YOUR_USERNAME/gcp-deploy-lab/actions/workflows/deploy.yml)

## 📋 概要

GCP（Google Cloud Platform）の無料枠（Free Tier）を最大限活用し、Infrastructure as Code (Terraform) とコンテナ技術 (Docker) を用いて、本番レベルのデプロイメントパイプラインを構築したプロジェクトです。

## ✨ 特徴

- **💰 完全無料枠**: `e2-micro` インスタンスと `us-central1` リージョンを選定
- **🏗️ IaC (Infrastructure as Code)**: Terraform により VPC/Subnet/Firewall/VM を一括構築
- **🐳 Immutable Infrastructure**: Container-Optimized OS (COS) を採用し、コンテナを自動実行
- **🔒 セキュリティ**: 非特権ユーザー、非ルートコンテナ、環境変数管理
- **🔄 冪等性**: Terraform による宣言的な状態管理
- **🚀 CI/CD**: GitHub Actions による自動ビルド・デプロイ

## 🏗️ アーキテクチャ

```
┌─────────────────┐      ┌──────────────┐      ┌─────────────────┐
│  Local Machine  │──▶───│ Docker Hub   │──▶───│  GCP (GCE)      │
│  (開発環境)      │ push │  (Registry)  │ pull │  e2-micro + COS │
└─────────────────┘      └──────────────┘      └─────────────────┘
        │                                                │
        │                                                │
        └────────────▶ GitHub Actions ────────────▶─────┘
                       (CI/CD Pipeline)
```

### リソース構成
- **VPC**: カスタムネットワーク
- **Subnet**: 10.0.1.0/24
- **Firewall**: HTTP (80), SSH (オプション)
- **Compute Engine**: e2-micro + COS + 30GB Standard disk

## 🛠️ 使用技術

| カテゴリ | 技術 |
|---------|------|
| **Language** | Python 3.11 |
| **Framework** | Flask 3.0.0 |
| **Container** | Docker (Multi-stage build) |
| **IaC** | Terraform >= 1.0 |
| **Cloud** | Google Cloud Platform |
| **CI/CD** | GitHub Actions |

## 🚀 セットアップ手順

### 前提条件

- GCP アカウント (無料枠有効)
- Docker Hub アカウント
- GitHub リポジトリ
- ローカルに以下がインストール済み:
  - Docker
  - Terraform >= 1.0
  - Google Cloud SDK

### 1. リポジトリをクローン

```bash
git clone https://github.com/YOUR_USERNAME/gcp-deploy-lab.git
cd gcp-deploy-lab
```

### 2. GCP サービスアカウントの作成

```bash
# プロジェクトIDを設定
export PROJECT_ID="your-gcp-project-id"

# サービスアカウント作成
gcloud iam service-accounts create terraform-sa \
  --display-name="Terraform Service Account"

# 必要な権限を付与
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:terraform-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/compute.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:terraform-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

# キーをダウンロード
gcloud iam service-accounts keys create ~/gcp-key.json \
  --iam-account=terraform-sa@${PROJECT_ID}.iam.gserviceaccount.com
```

### 3. GCS バケットの作成（Terraform state 用）

TerraformのstateをGCSで管理し、ローカルとCI/CDで共有します。

```bash
# GCSバケットを作成（ユニークな名前が必要）
export BUCKET_NAME="terraform-state-${PROJECT_ID}"

gsutil mb -p ${PROJECT_ID} -c STANDARD -l us-central1 gs://${BUCKET_NAME}

# バージョニングを有効化（推奨）
gsutil versioning set on gs://${BUCKET_NAME}
```

> **無料枠**: GCSは毎月5GBまで無料。terraform.tfstateは数百KBなので実質タダです。

**backend.tf の作成:**

```bash
cd terraform

# テンプレートファイルをコピー
cp backend.tf.example backend.tf

# backend.tf を編集（your-project-id を実際のプロジェクトIDに変更）
```

**backend.tf の内容:**

```hcl
terraform {
  backend "gcs" {
    bucket = "terraform-state-your-project-id"  # 作成したバケット名に変更
    prefix = "terraform/state"
  }
}
```

> ⚠️ **重要**: `backend.tf` は個人のプロジェクト情報が含まれるため、`.gitignore` に追加されています。
> リポジトリには `backend.tf.example` がテンプレートとして提供されています。

### 4. Terraform 変数ファイルの設定

Terraform で使用する変数を設定します。

```bash
cd terraform

# テンプレートをコピー
cp terraform.tfvars.example terraform.tfvars

# terraform.tfvars を編集
```

**必須パラメーター:**

| パラメーター | 説明 | 例 |
|------------|------|-----|
| `project_id` | GCP プロジェクト ID | `"your-gcp-project-id"` |
| `docker_image` | Docker Hub イメージパス | `"docker.io/your-username/gcp-free-app:latest"` |

**オプションパラメーター:**

| パラメーター | デフォルト値 | 説明 |
|------------|------------|------|
| `environment` | `"dev"` | 環境名 (dev/staging/prod) |
| `region` | `"us-central1"` | GCP リージョン |
| `zone` | `"us-central1-a"` | GCP ゾーン |
| `machine_type` | `"e2-micro"` | マシンタイプ |
| `ssh_source_ranges` | `[]` | SSH接続を許可するIP範囲 |

**設定例:**

```hcl
project_id = "my-gcp-project-12345"
docker_image = "docker.io/myusername/gcp-free-app:latest"
environment = "dev"
```

> **注意**: `terraform.tfvars` は `.gitignore` に含まれているため、Git にコミットされません。

### 5. GitHub Secrets の設定

GitHub リポジトリの Settings > Secrets and variables > Actions で以下を設定:

| Secret 名 | 説明 |
|-----------|------|
| `GCP_PROJECT_ID` | GCP プロジェクト ID |
| `GCP_SA_KEY` | サービスアカウントキー (JSON 全体) |
| `DOCKER_HUB_USERNAME` | Docker Hub ユーザー名 |
| `DOCKER_HUB_TOKEN` | Docker Hub アクセストークン |

### 6. ローカルデプロイ (任意)

```bash
# Docker イメージをビルド
docker build -t gcp-free-app:latest .

# ローカルで実行
docker run -p 8080:8080 gcp-free-app:latest

# ブラウザで確認
open http://localhost:8080
```

### 7. Terraform でインフラをデプロイ

```bash
cd terraform

# GCP 認証（初回のみ）
gcloud auth application-default login

# Terraform 実行（GCS backendを使用）
terraform init
terraform plan
terraform apply

# 不要になったら削除
terraform destroy
```

> **重要**: apply/destroy は**ローカルで手動実行**を推奨します。事故や課金を防ぐため、CI/CDでは plan までの実行にしています。

**認証について:**
- 一度 `gcloud auth application-default login` を実行すれば、認証情報は `~/.config/gcloud/application_default_credentials.json` に保存されます
- 次回以降のterraform実行では再ログイン不要です
- 認証エラーが出た場合のみ、再度ログインしてください（トークン有効期限: 約1時間）

### 8. GitHub Actions で自動チェック

```bash
git add .
git commit -m "Initial commit"
git push origin main
```

mainブランチへのプッシュで自動的に以下が実行されます：
1. Dockerイメージのビルド & プッシュ
2. Terraformの検証（init, validate, plan）

> **注意**: `terraform apply` はCIで実行されません。インフラのデプロイ/削除はローカルで手動実行してください。

## 📁 ディレクトリ構造

```
.
├── .github/
│   └── workflows/
│       └── deploy.yml          # CI/CDパイプライン定義
├── app/
│   ├── main.py                 # Flaskアプリケーション
│   └── requirements.txt        # Python依存関係
├── terraform/
│   ├── main.tf                 # Terraformメイン設定
│   ├── variables.tf            # 変数定義
│   └── terraform.tfvars.example # 変数テンプレート
├── Dockerfile                  # マルチステージビルド設定
├── .gitignore                  # Git除外設定
└── README.md                   # このファイル
```

## 🔐 セキュリティのベストプラクティス

### 実装済み

- ✅ 非rootユーザーでコンテナを実行
- ✅ 非特権ポート (8080) を使用
- ✅ 秘密情報を `.gitignore` で除外
- ✅ Docker マルチステージビルド
- ✅ ヘルスチェックの実装
- ✅ 最小限の権限を持つサービスアカウント
- ✅ ファイアウォールによるアクセス制御

### 推奨される追加対策

- 🔲 Terraform state を GCS バックエンドに保存
- 🔲 本番環境では SSH アクセスを制限
- 🔲 Cloud Logging/Monitoring の有効化
- 🔲 Secrets Manager の活用

## 🔄 冪等性の保証

### Terraform
- **宣言的な状態管理**: 同じ構成を何度実行しても同じ結果
- **State ファイル**: リソースの現在の状態を追跡
- **環境変数による分離**: dev/staging/prod 環境を分離可能

### Docker
- **イミュータブルなイメージ**: タグ付けによるバージョン管理
- **レイヤーキャッシュ**: ビルドの高速化

### GitHub Actions
- **条件付き実行**: main ブランチのみデプロイ
- **ジョブ分離**: ビルドとデプロイを分離

## 🧪 テスト

```bash
# アプリケーションのヘルスチェック
curl http://<EXTERNAL_IP>/health

# レスポンス例
{
  "status": "healthy",
  "environment": "prod",
  "port": 8080
}
```

## 💰 コスト管理

### 無料枠の内訳
- **Compute Engine**: e2-micro 1台/月 (us-central1)
- **永続ディスク**: 30GB Standard
- **ネットワーク**: 1GB/月の外部通信

### コスト最適化のポイント
1. リージョンは必ず `us-central1`, `us-east1`, `us-west1` のいずれかを使用
2. マシンタイプは `e2-micro` を維持
3. 不要な時はインスタンスを停止: `gcloud compute instances stop <INSTANCE_NAME>`

## 🐛 トラブルシューティング

### Terraform エラー

```bash
# State をリフレッシュ
terraform refresh

# 強制的に再作成
terraform taint google_compute_instance.app_server
terraform apply
```

### コンテナが起動しない

```bash
# GCE にSSH接続
gcloud compute ssh <INSTANCE_NAME> --zone=us-central1-a

# コンテナログを確認
sudo docker logs <CONTAINER_ID>
```

### GitHub Actions が失敗する

1. Secrets が正しく設定されているか確認
2. GCP サービスアカウントの権限を確認
3. Terraform の状態ファイルが競合していないか確認

## 📚 参考資料

- [GCP Always Free](https://cloud.google.com/free/docs/gcp-free-tier)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Container-Optimized OS](https://cloud.google.com/container-optimized-os/docs)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

## 🤝 コントリビューション

1. Fork this repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 ライセンス

MIT License

## 👤 作成者

[Sohey-K](https://github.com/Sohey-k)

---

**⚠️ 注意**: このプロジェクトは学習・実験目的です。本番環境で使用する場合は、セキュリティとコストを十分に検討してください。

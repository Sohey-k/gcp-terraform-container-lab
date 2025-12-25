# GCP Free Tier x Terraform x Docker Deployment Lab

## 概要
GCP（Google Cloud Platform）の無料枠（Free Tier）を最大限活用し、Terraformを用いてインフラをコード化（IaC）、Dockerコンテナをデプロイする一連のパイプラインを構築したプロジェクトです。

## 特徴
- **完全無料枠**: `e2-micro` インスタンスと `us-central1` リージョンを選定。
- **IaC (Infrastructure as Code)**: Terraformにより、VPC/Subnet/Firewall/VMを一括構築。
- **Immutable Infrastructure**: Container-Optimized OS (COS) を採用し、コンテナを自動実行。

## 構成図
[Local Machine (WSL2)] --(push)--> [Docker Hub]
      |                                  |
[Terraform (IaC)] --(deploy)--> [Google Cloud (GCE)] --(pull)--> [App Container]

## 使用技術
- **Language**: Python (Flask)
- **Container**: Docker
- **IaC**: Terraform
- **Cloud**: Google Cloud (Compute Engine, VPC)

## 使い方
1. `docker build` & `push` でイメージをDocker Hubへ。
2. `gcloud auth application-default login` で認証。
3. `terraform init` / `plan` / `apply` でデプロイ。

## 工夫した点
- 32GBメモリのローカル環境を活かした高速なビルドサイクルの実現。
- メタデータ（gce-container-declaration）を活用した、VM起動時のコンテナ自動デプロイ設定。
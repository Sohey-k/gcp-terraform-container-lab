# マルチステージビルドを使用してイメージサイズを最小化
FROM python:3.11-slim as base

# セキュリティアップデートを適用
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 非特権ユーザーを作成
RUN groupadd -r appuser && useradd -r -g appuser appuser

# 作業ディレクトリを設定
WORKDIR /app

# 依存関係を先にコピーしてキャッシュを活用
COPY app/requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# アプリケーションコードをコピー
COPY app/main.py .

# 非特権ユーザーに切り替え
RUN chown -R appuser:appuser /app
USER appuser

# ヘルスチェック用のポート (非特権ポート)
EXPOSE 8080

# 環境変数を設定
ENV PYTHONUNBUFFERED=1 \
    FLASK_APP=main.py

# ヘルスチェックを追加
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080')"

# コンテナ起動時にFlaskを実行
CMD ["python", "main.py"]


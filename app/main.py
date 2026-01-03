import os
from flask import Flask, jsonify

app = Flask(__name__)

# 環境変数から設定を取得
ENVIRONMENT = os.environ.get('ENVIRONMENT', 'development')
PORT = int(os.environ.get('PORT', 8080))

@app.route('/')
def hello():
    return f"""
    <html>
    <head>
        <title>GCP Deployment Success</title>
        <style>
            body {{
                font-family: Arial, sans-serif;
                display: flex;
                justify-content: center;
                align-items: center;
                height: 100vh;
                margin: 0;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            }}
            .container {{
                text-align: center;
                background: white;
                padding: 40px;
                border-radius: 10px;
                box-shadow: 0 10px 25px rgba(0,0,0,0.2);
            }}
            h1 {{ color: #667eea; margin-bottom: 20px; }}
            .status {{ color: #28a745; font-weight: bold; }}
            .info {{ color: #6c757d; margin-top: 10px; }}
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🎉 GCP Free Tier x Terraform x Docker</h1>
            <p class="status">✅ デプロイ成功！</p>
            <div class="info">
                <p>Environment: <strong>{ENVIRONMENT}</strong></p>
                <p>Machine Type: <strong>e2-micro</strong></p>
                <p>Port: <strong>{PORT}</strong></p>
            </div>
        </div>
    </body>
    </html>
    """

@app.route('/health')
def health():
    """ヘルスチェック用エンドポイント"""
    return jsonify({
        'status': 'healthy',
        'environment': ENVIRONMENT,
        'port': PORT
    }), 200

if __name__ == '__main__':
    # 本番環境では Gunicorn などの WSGI サーバーを使用することを推奨
    app.run(host='0.0.0.0', port=PORT, debug=(ENVIRONMENT == 'development'))


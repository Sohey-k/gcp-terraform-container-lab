from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    # 成功したことが一目でわかるメッセージ
    return "<h1>GCP Free Tier x Terraform x Docker 成功！</h1><p>Status: Running on e2-micro</p>"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)

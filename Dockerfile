FROM python:3.9-slim
WORKDIR /app
RUN pip install flask
COPY app/main.py .
EXPOSE 80
# コンテナ起動時にPythonを実行
CMD ["python", "main.py"]

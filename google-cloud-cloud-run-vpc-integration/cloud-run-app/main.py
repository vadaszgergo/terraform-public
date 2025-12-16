import requests

from flask import Flask, Response

app = Flask(__name__)
TARGET_URL = "http://192.168.1.110:80"

@app.route("/", defaults={"path": ""})
@app.route("/<path:path>")
def proxy(path):
    try:
        resp = requests.get(f"{TARGET_URL}/{path}", timeout=5)
        return Response(
            resp.content,
            status=resp.status_code,
            content_type=resp.headers.get("Content-Type")
        )
    except Exception as e:
        return str(e), 502

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)


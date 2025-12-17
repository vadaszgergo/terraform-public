from http.server import BaseHTTPRequestHandler, HTTPServer
import socket


def get_private_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # Does not actually send traffic
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
    except Exception:
        ip = "unknown"
    finally:
        s.close()
    return ip


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        # Source IP of the HTTP request (Cloud Run)
        source_ip = self.client_address[0]

        # Destination IP of this server
        destination_ip = get_private_ip()

        port = self.server.server_port

        html = f"""
        <html>
          <head>
            <title>On-Prem Destination Server</title>
            <style>
              body {{ font-family: Arial, sans-serif; margin: 40px; }}
              h1 {{ color: #2c3e50; }}
              p {{ font-size: 16px; }}
              code {{ background: #f4f4f4; padding: 4px 6px; }}
            </style>
          </head>
          <body>
            <h1>Hello, this is the on-prem destination server!</h1>

            <p>
             <code>Cloud Run --> Egress VPC --> VPN Gateway --> VPN tunnel -->
              On-prem VPN Gateway --> Destination Server</code>
            </p>

            <hr>

            <p><strong>Cloud Run source IP:</strong> <code>{source_ip}</code></p>
            <p><strong>Destination server IP:</strong> <code>{destination_ip}</code></p>
            <p><strong>Port number:</strong> <code>{port}</code></p>
          </body>
        </html>
        """

        self.send_response(200)
        self.send_header("Content-Type", "text/html")
        self.end_headers()
        self.wfile.write(html.encode("utf-8"))


if __name__ == "__main__":
    HTTPServer(("0.0.0.0", 80), Handler).serve_forever()

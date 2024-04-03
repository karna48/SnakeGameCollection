from http.server import SimpleHTTPRequestHandler, HTTPServer


if __name__ == "__main__":
    hostName = "localhost"
    serverPort = 8080
    webServer = HTTPServer((hostName, serverPort), SimpleHTTPRequestHandler)
    print("Server started http://%s:%s" % (hostName, serverPort))

    try:
        webServer.serve_forever()
    except KeyboardInterrupt:
        pass

    webServer.server_close()
    print("Server stopped.")

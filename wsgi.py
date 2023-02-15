from wsgiref.simple_server import make_server

def app(environ, start_response):
    status = '200 OK'
    headers = [('Content-type', 'text/html')]
    start_response(status, headers)
    return [b"Hello, world!"]

httpd = make_server('', 8000, app)
print("Serving on port 8000...")
httpd.serve_forever()

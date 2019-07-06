from flask import Flask, request, jsonify
import functools
import os

app = Flask(__name__)

def validate_request(func):
    def warapper_validate_request(*args, **kwargs):
        message = request.json
        if message is None:
            return jsonify({"error": "request payload not in json format"})
        return func(*args, **kwargs)
        
    return warapper_validate_request


@app.route('/')
@app.route('/info')
def info():
    response = {
        "message": "Congratulations! You reached application via Kong API Gateway",
        "version": "1.0"
    }
    return jsonify(response)

@app.route('/health')
def health():
    response = {
        "status": "UP",
        "version": "1.0"
    }
    return jsonify(response)


@app.route('/api', methods=['POST'])
@validate_request
def handlejson():
    print(f"header=${request.headers} and data=${request.json}")
    
    response = {"received": request.json}
    return jsonify(response)

if __name__ == "__main__":
    server_port = os.getenv('SERVER_PORT', '8080')
    app.run(host='0.0.0.0', port=server_port)

from flask import Flask, request, jsonify
import functools
import os

app = Flask(__name__)

def validate_request(func, valid_user=list(["abhi", "shar", "atharv"])):
    def warapper_validate_request(*args, **kwargs):
        message = request.json
        if message is None:
            return jsonify({"error": "request payload not in json format"})
        return func(*args, **kwargs)
        
    return warapper_validate_request


@app.route('/')
def hello():
    return "hello from flask"


@app.route('/api/json', methods=['POST'])
@validate_request
def handlejson():
    print(f"header=${request.headers} and data=${request.json}")
    user = request.json["username"]
    response = {"text": f"hello {user}"}
    return jsonify(response)

if __name__ == "__main__":
    server_port = os.getenv('SERVER_PORT', '8080')
    app.run(host='0.0.0.0', port=server_port)

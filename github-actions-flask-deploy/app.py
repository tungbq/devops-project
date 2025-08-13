from flask import Flask

app = Flask(__name__)

@app.route('/')
def index():
    return "Hello From Github Actions CI/CD Pipeline!"



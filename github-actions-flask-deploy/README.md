# GitHub Actions CI/CD Example – Flask App

This example shows how to automate testing and deployment of a simple Flask application using GitHub Actions.

## 📁 Structure

- `app.py`: Basic Flask web app
- `requirements.txt`: Dependencies
- `.github/workflows/flask-deploy.yml`: CI/CD pipeline

## 🚀 GitHub Actions Workflow

Triggered on every push to `main`:

1. Checkout code
2. Set up Python
3. Install dependencies
4. (Placeholder) Run tests
5. (Placeholder) Deploy app

## 🔧 Deployment

This example includes a placeholder deploy step. You can customize it to:

- Deploy to EC2 via SSH
- Push to Heroku
- Use Docker + AWS ECS

## ✅ Getting Started Locally

```bash
pip install -r requirements.txt
python app.py


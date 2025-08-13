# Project 13 — Azure Static Web Apps (Simple)

This mini‑project shows how to host a static website on **Azure Static Web Apps (SWA)** and deploy it automatically from GitHub using **GitHub Actions**.

> ✅ Based on Azure’s official guidance for SWA quickstarts and build configuration. :contentReference[oaicite:1]{index=1}

---

## What you’ll build
- A tiny static site (`index.html`, CSS, JS).
- A GitHub Actions workflow that deploys only when files in this project change.

---

## Prereqs
- Azure subscription (Free tier is fine).
- **Static Web App** created in the Azure Portal:
  - Plan: *Free* is OK.
  - During creation, choose **GitHub** as the source.
  - Select your fork and branch.
  - Set app location to: `projects/azure-static-web-apps-simple/src`
  - Leave API/Output location empty for this simple site.
- If you don’t connect GitHub in the portal, you can also deploy using an **API token** secret `AZURE_STATIC_WEB_APPS_API_TOKEN` (see CI/CD section). :contentReference[oaicite:2]{index=2}

---

## Folder structure 

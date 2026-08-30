import os
import socket
from datetime import datetime, timezone

from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI(title="notification-service")

POD_NAME = os.environ.get("POD_NAME", socket.gethostname())

# Log of "sent" notifications, in-memory — a demo sink, not a real notifier.
SENT: list[dict] = []


class NotifyRequest(BaseModel):
    to: str
    message: str


@app.get("/healthz")
def healthz():
    return {"status": "ok"}


@app.get("/readyz")
def readyz():
    return {"status": "ready"}


@app.post("/notify")
def notify(req: NotifyRequest):
    entry = {
        "pod": POD_NAME,
        "to": req.to,
        "message": req.message,
        "sentAt": datetime.now(timezone.utc).isoformat(),
    }
    SENT.append(entry)
    return entry


@app.get("/sent")
def sent():
    return {"pod": POD_NAME, "count": len(SENT), "notifications": SENT}

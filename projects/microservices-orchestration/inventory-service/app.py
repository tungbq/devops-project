import os
import socket

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI(title="inventory-service")

POD_NAME = os.environ.get("POD_NAME", socket.gethostname())

# In-memory stock — a demo service, not a real inventory system. Reset on
# every pod restart on purpose, so scaling replicas visibly shows each pod
# starting from the same seed stock (see the repo's HPA/scaling walkthrough).
STOCK = {"widget": 10, "gadget": 5, "gizmo": 0}


class ReserveRequest(BaseModel):
    item: str
    quantity: int = 1


@app.get("/healthz")
def healthz():
    return {"status": "ok"}


@app.get("/readyz")
def readyz():
    return {"status": "ready"}


@app.get("/stock")
def stock():
    return {"pod": POD_NAME, "stock": STOCK}


@app.post("/reserve")
def reserve(req: ReserveRequest):
    available = STOCK.get(req.item)
    if available is None:
        raise HTTPException(status_code=404, detail=f"unknown item '{req.item}'")
    if available < req.quantity:
        raise HTTPException(status_code=409, detail=f"insufficient stock for '{req.item}'")
    STOCK[req.item] -= req.quantity
    return {"pod": POD_NAME, "item": req.item, "reserved": req.quantity, "remaining": STOCK[req.item]}

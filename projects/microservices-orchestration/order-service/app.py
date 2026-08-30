import os
import socket
import uuid

import httpx
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI(title="order-service")

POD_NAME = os.environ.get("POD_NAME", socket.gethostname())

# Injected via a ConfigMap (see ../k8s/configmap.yaml) — short K8s DNS names,
# resolvable because all three services share one namespace. This is the
# actual "orchestration" being demonstrated: order-service never hardcodes
# an IP, Kubernetes' internal DNS does the discovery.
INVENTORY_URL = os.environ.get("INVENTORY_URL", "http://localhost:8001")
NOTIFICATION_URL = os.environ.get("NOTIFICATION_URL", "http://localhost:8002")

HTTP_TIMEOUT = 5.0


class OrderRequest(BaseModel):
    customer: str
    item: str
    quantity: int = 1


@app.get("/healthz")
def healthz():
    return {"status": "ok"}


@app.get("/readyz")
def readyz():
    return {"status": "ready"}


@app.post("/orders")
def create_order(req: OrderRequest):
    order_id = str(uuid.uuid4())

    try:
        reserve_res = httpx.post(
            f"{INVENTORY_URL}/reserve",
            json={"item": req.item, "quantity": req.quantity},
            timeout=HTTP_TIMEOUT,
        )
    except httpx.RequestError as exc:
        raise HTTPException(status_code=502, detail=f"inventory-service unreachable: {exc}") from exc
    if reserve_res.status_code != 200:
        raise HTTPException(status_code=reserve_res.status_code, detail=reserve_res.json().get("detail"))

    try:
        notify_res = httpx.post(
            f"{NOTIFICATION_URL}/notify",
            json={"to": req.customer, "message": f"Order {order_id} for {req.quantity}x {req.item} confirmed"},
            timeout=HTTP_TIMEOUT,
        )
        notify_res.raise_for_status()
    except httpx.HTTPError as exc:
        # Stock is already reserved — a failed notification shouldn't roll
        # the order back (a real system would use an outbox/retry queue
        # here; that's a separate lesson from "orchestration basics").
        return {
            "pod": POD_NAME,
            "orderId": order_id,
            "status": "confirmed_notification_failed",
            "reservation": reserve_res.json(),
            "notificationError": str(exc),
        }

    return {
        "pod": POD_NAME,
        "orderId": order_id,
        "status": "confirmed",
        "reservation": reserve_res.json(),
        "notification": notify_res.json(),
    }

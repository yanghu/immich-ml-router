import os

from fastapi import FastAPI, Request
from fastapi.responses import PlainTextResponse

BACKEND_NAME = os.environ.get("BACKEND_NAME", "unknown")

app = FastAPI()


@app.get("/")
async def root():
    return {"message": "Immich ML"}


@app.get("/ping")
async def ping():
    return PlainTextResponse("pong")


@app.post("/predict")
async def predict(request: Request):
    return {"backend": BACKEND_NAME}

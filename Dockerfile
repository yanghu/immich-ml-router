FROM python:3.12-slim
WORKDIR /app
RUN pip install --no-cache-dir fastapi httpx uvicorn
COPY router.py .
CMD ["uvicorn", "router:app", "--host", "0.0.0.0", "--port", "3003"]

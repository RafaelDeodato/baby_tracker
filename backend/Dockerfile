# Imagem de produção do backend Flask — roda via gunicorn, não via
# `python run.py` (esse é só pro dev local, ver docker-compose.yml e
# CLAUDE.md). Alvo é o Cloud Run: expõe a porta via variável de ambiente
# PORT (padrão 8080 se não vier definida).

FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV PORT=8080
EXPOSE 8080

CMD ["sh", "-c", "gunicorn --bind 0.0.0.0:${PORT:-8080} --workers 2 run:app"]

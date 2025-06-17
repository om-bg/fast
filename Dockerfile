# Étape 1 : Image Python légère avec gestion du cache pip
FROM python:3.10-slim as base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Étape 2 : Installer les dépendances système minimales pour OpenCV et Ultralytics
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Étape 3 : Installer les dépendances Python (avec root-user-action pour éviter le warning)
COPY requirements.txt .
RUN pip install --no-cache-dir --root-user-action=ignore -r requirements.txt

# Étape 4 : Copier le code source
COPY . .


RUN chmod +x start.sh

# Lancer le script start.sh
CMD ["./start.sh"]

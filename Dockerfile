# Utiliser une image de base Python alpine plus légère
# Alpine Linux est connue pour ses images Docker très petites
FROM python:3.10-slim-buster as builder

# Définir l'encodage pour éviter les problèmes de locale
ENV LANG C.UTF-8

# Installer les dépendances système nécessaires pour OpenCV (versions slim/headless)
# Ces dépendances sont minimales mais essentielles pour Pillow, NumPy, et OpenCV
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        git \
        libgtk2.0-dev \
        pkg-config \
        libavcodec-dev \
        libavformat-dev \
        libswscale-dev \
        libatlas-base-dev \
        libjpeg-dev \
        libpng-dev \
        libtiff-dev \
        zlib1g-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Définir le répertoire de travail
WORKDIR /app

# Copier le fichier requirements.txt en premier pour optimiser le cache Docker
COPY requirements.txt .

# Installer les dépendances Python
# Utiliser opencv-python-headless pour réduire la taille (pas d'interface graphique)
# Mettre à jour pip pour s'assurer d'avoir la dernière version
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copier les fichiers de l'application
COPY . .

# Si vous téléchargez le modèle en ligne au démarrage, vous n'avez pas besoin de le COPIER
# Si vous le COPIEZ, assurez-vous que `yolov8n.pt` est dans le même dossier que le Dockerfile
# COPY yolov8n.pt .

# Utiliser une image plus légère pour l'exécution finale (multi-stage build)
FROM python:3.10-slim-buster

ENV LANG C.UTF-8

WORKDIR /app

# Copier seulement ce qui est nécessaire depuis l'image 'builder'
COPY --from=builder /usr/local/lib/python3.10/site-packages /usr/local/lib/python3.10/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /app /app

# Assurez-vous que le modèle est disponible. Si vous ne le téléchargez pas au runtime, il doit être ici.
# Si vous l'avez copié dans l'étape `builder`, il sera disponible via `/app/yolov8n.pt`


RUN chmod +x start.sh

# Lancer le script start.sh
CMD ["./start.sh"]

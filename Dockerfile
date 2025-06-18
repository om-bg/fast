# --- Étape 1: Builder pour compiler les dépendances (multi-stage build) ---
FROM python:3.9-slim-buster as builder

# Définir l'encodage
ENV LANG C.UTF-8
ENV PYTHONUNBUFFERED 1

# Installer les dépendances système minimales pour la compilation
# (build-essential, cmake, etc. pour opencv et d'autres libs C)
# libgl1-mesa-glx est souvent nécessaire pour des raisons obscures même avec headless
# libgomp1 pour OpenMP (souvent utilisé par NumPy, OpenCV)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        git \
        pkg-config \
        libatlas-base-dev \
        libjpeg-dev \
        libpng-dev \
        libtiff-dev \
        zlib1g-dev \
        libavcodec-dev \
        libavformat-dev \
        libswscale-dev \
        libgl1-mesa-glx \
        libgomp1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copier requirements.txt
COPY requirements.txt .

# Installer les dépendances Python
# Utiliser une version spécifique d'opencv-python-headless
# `--no-cache-dir` est crucial pour ne pas stocker les packages de pip
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# --- Étape 2: Image Finale pour l'exécution ---
FROM python:3.9-slim-buster

# Définir l'encodage et les variables d'environnement pour l'exécution
ENV LANG C.UTF-8
ENV PYTHONUNBUFFERED 1

WORKDIR /app

# Copier seulement les packages installés et les fichiers de l'application
# Cela évite de copier les outils de build.
COPY --from=builder /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /app/requirements.txt /app/requirements.txt # Copier pour info si besoin, pas vraiment utile
COPY . .

# IMPORTANT: Supprimer le fichier de modèle de l'image finale si vous le téléchargez au runtime
# Si vous avez un `COPY yolov8n.pt .` dans votre Dockerfile précédent, retirez-le.
# La ligne suivante n'est pertinente que si `yolov8n.pt` est accidentellement copié ailleurs.
# RUN rm -f yolov8n.pt # Décommentez si vous rencontrez des problèmes de taille à cause du modèle


RUN chmod +x start.sh

# Lancer le script start.sh
CMD ["./start.sh"]

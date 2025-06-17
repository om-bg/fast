# Étape 1 : Utiliser une image Python légère
FROM python:3.10-slim

# Étape 2 : Répertoires
WORKDIR /app

# Étape 3 : Copier les fichiers requis
COPY requirements.txt .
COPY . .

# Étape 4 : Installer les dépendances système minimales
RUN apt-get update && apt-get install -y \
    gcc libglib2.0-0 libsm6 libxext6 libxrender-dev wget && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Étape 5 : Installer les packages Python nécessaires
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

RUN chmod +x start.sh

# Lancer le script start.sh
CMD ["./start.sh"]

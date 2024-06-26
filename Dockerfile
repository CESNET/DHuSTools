# Základní obraz založený na Debianu 11
FROM debian:12

# Instalace potřebných balíčků pro synchronizační skripty
RUN apt-get update && apt-get install -y \
    curl \
    iputils-ping \
    python3 \
    xmlstarlet \
    python3-pip \
    python3-venv \
    git \
 && rm -rf /var/lib/apt/lists/*

# Klonování repozitáře
RUN git clone https://github.com/CESNET/DHuSTools.git /app

# Vytvoření virtuálních prostředí pro různé stactools
RUN python3 -m venv /opt/s1 && /opt/s1/bin/pip install stactools-sentinel1 requests
RUN python3 -m venv /opt/s2 && /opt/s2/bin/pip install stactools-sentinel2 requests
RUN python3 -m venv /opt/s3 && /opt/s3/bin/pip install stactools-sentinel3==0.3.0 requests
RUN python3 -m venv /opt/s5p && /opt/s5p/bin/pip install stactools-sentinel5p netCDF4

# Přidání skriptů do kontejneru
COPY register-stac.sh check-new-register-stac.sh gen_new_list.sh /app/

#COPY requirements.txt register-stac.sh check-new-register-stac.sh gen_new_list.sh /app/
# Nastavení pracovního adresáře
WORKDIR /app

# Instalace závislostí z requirements.txt ve výchozím virtuálním prostředí
#RUN python3 -m venv /opt/venv && /opt/venv/bin/pip install -r /app/requirements.txt

# Nastavení oprávnění pro spouštění skriptů
RUN chmod +x /app/*

ENV PYTHONWARNINGS="ignore"

# Aktivace výchozího virtuálního prostředí
ENV PATH="/opt/venv/bin:$PATH"

# Spuštění synchronizačního skriptu při startu kontejneru
CMD ["./check-new-register-stac.sh"]


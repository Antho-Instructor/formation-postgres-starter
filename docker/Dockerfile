FROM postgres:18

# PL/Python, utilisé dans le dernier atelier. L'image officielle contient déjà
# le dépôt PGDG : le paquet s'installe directement.
RUN apt-get update \
 && apt-get install -y --no-install-recommends postgresql-plpython3-18 \
 && rm -rf /var/lib/apt/lists/*

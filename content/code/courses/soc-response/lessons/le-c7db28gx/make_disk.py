# make_disk.py: the files a small office keeps on its file server, written into ./data
import csv
import os
import random

random.seed(16)
CLIENTS = ["acme-logistica", "bento-advogados", "casa-verde", "delta-engenharia", "estrela-saude"]
NAMES = ["Alice Moreira", "Caio Prado", "Denise Rocha", "Enzo Lima", "Fabiana Reis", "Gustavo Alves"]

for client in CLIENTS:
    folder = os.path.join("data", "clients", client)
    os.makedirs(folder, exist_ok=True)
    with open(os.path.join(folder, "contracts.csv"), "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["contract", "signed", "value_brl"])
        for n in range(1, random.randint(3, 6)):
            w.writerow([f"{client}-{n:03}", f"2026-0{random.randint(1, 8)}-1{n}", random.randint(5, 90) * 1000])

os.makedirs(os.path.join("data", "exports"), exist_ok=True)
with open(os.path.join("data", "exports", "contacts-2026-08.csv"), "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["client", "contact", "email"])
    for client in CLIENTS:
        name = random.choice(NAMES)
        w.writerow([client, name, name.split()[0].lower() + "@" + client + ".example"])
print("written:", sum(len(files) for _, _, files in os.walk("data")), "files")

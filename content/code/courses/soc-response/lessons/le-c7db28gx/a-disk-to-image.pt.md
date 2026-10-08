---
title: Um disco para gerar a imagem
version: 1
---

O laboratório precisa de um disco com alguma coisa dentro. Discos reais são grandes e lentos de copiar; um
**arquivo de imagem de disco** de 32 MB se comporta exatamente como um disco para tudo nesta aula, e o Linux
consegue apresentá-lo como um dispositivo de bloco, o mesmo tipo de coisa que `/dev/sda`.

O conteúdo vem de um programa curto. Crie uma pasta para o caso, `mkdir /root/case`, e escreva isto nela como
`make_disk.py`:

```schooling-example
{"language": "python", "file": "make_disk.py", "parts": [{"code": "# make_disk.py: the files a small office keeps on its file server, written into ./data\nimport csv\nimport os\nimport random\n"}, {"code": "random.seed(16)\nCLIENTS = [\"acme-logistica\", \"bento-advogados\", \"casa-verde\", \"delta-engenharia\", \"estrela-saude\"]\nNAMES = [\"Alice Moreira\", \"Caio Prado\", \"Denise Rocha\", \"Enzo Lima\", \"Fabiana Reis\", \"Gustavo Alves\"]\n", "note": "Uma semente fixa, então toda execução escreve o mesmo conteúdo: cinco clientes e seis pessoas, todos inventados."}, {"code": "for client in CLIENTS:\n    folder = os.path.join(\"data\", \"clients\", client)\n    os.makedirs(folder, exist_ok=True)\n    with open(os.path.join(folder, \"contracts.csv\"), \"w\", newline=\"\") as f:\n        w = csv.writer(f)\n        w.writerow([\"contract\", \"signed\", \"value_brl\"])\n        for n in range(1, random.randint(3, 6)):\n            w.writerow([f\"{client}-{n:03}\", f\"2026-0{random.randint(1, 8)}-1{n}\", random.randint(5, 90) * 1000])\n", "note": "Uma pasta por cliente, cada uma com alguns contratos. São os dados comuns de negócio que um servidor de arquivos guarda."}, {"code": "os.makedirs(os.path.join(\"data\", \"exports\"), exist_ok=True)\nwith open(os.path.join(\"data\", \"exports\", \"contacts-2026-08.csv\"), \"w\", newline=\"\") as f:\n    w = csv.writer(f)\n    w.writerow([\"client\", \"contact\", \"email\"])\n    for client in CLIENTS:\n        name = random.choice(NAMES)\n        w.writerow([client, name, name.split()[0].lower() + \"@\" + client + \".example\"])\nprint(\"written:\", sum(len(files) for _, _, files in os.walk(\"data\")), \"files\")", "note": "Uma exportação de contatos, com nomes e e-mails: dados pessoais. A aula a apaga, e a aula 17 a traz de volta."}]}
```

Depois, três comandos. O programa escreve os arquivos. O `mke2fs` cria um sistema de arquivos ext4 de 32 MB num
arquivo chamado `disk.img` e o preenche com a pasta `data` (`-d`), sem precisar montar nada. E o `debugfs`, a
ferramenta de reparo dos próprios sistemas de arquivos ext, apaga a exportação **dentro** da imagem, do jeito que
alguém da equipe arrumando as coisas a teria apagado do servidor:

```
root@soc:~/case# python3 make_disk.py
written: 6 files
root@soc:~/case# mke2fs -q -t ext4 -L files-data -d data disk.img 32M
Creating regular file disk.img
root@soc:~/case# debugfs -w -R 'rm exports/contacts-2026-08.csv' disk.img
debugfs 1.47.0 (5-Feb-2023)

root@soc:~/case# ls -l disk.img
-rw-r--r-- 1 root root 33554432 Oct  7 20:59 disk.img
```

O disco agora guarda cinco arquivos de contratos, e a exportação sumiu da pasta. Sumir da pasta não é sumir do
disco: apagar um arquivo no ext4 remove o nome e marca o espaço como livre, e os bytes ficam até algo
sobrescrevê-los. A aula 17 os encontra. Por enquanto, o disco é a evidência, e o trabalho desta aula é copiá-lo
sem mudá-lo.

Esta aula precisa de um pacote que a aula 1 não instalou, o `ewf-tools`, usado na quinta seção. Instale agora,
`sudo apt install ewf-tools`, para o laboratório ficar pronto.

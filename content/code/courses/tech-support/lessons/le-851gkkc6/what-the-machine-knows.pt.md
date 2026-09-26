---
title: O que um computador sabe sobre si
version: 1
---

O firmware de todo PC carrega uma pequena tabela descrevendo a máquina, e o `dmidecode` a lê:

```
ana@pc1:~$ sudo dmidecode -t system | grep -E "Manufacturer|Product Name|Serial Number|UUID"
        Manufacturer: QEMU
        Product Name: Ubuntu 24.04 PC (Q35 + ICH9, 2009)
        Serial Number: Not Specified
        UUID: eb9d0818-b197-423d-b984-f7fe52a6797f
ana@pc1:~$ bash /tmp/inventory.sh
"pc1","QEMU","Ubuntu 24.04 PC (Q35 + ICH9, 2009)","Not Specified","QEMU Virtual CPU version 2.5+","961 MiB","6.8G","52:54:00:8c:26:a7","24.04"
```

Um notebook de loja diria o nome do fabricante, o modelo e um número de série impresso na etiqueta dele.
Este diz **`QEMU`** e **`Not Specified`**: é uma máquina virtual, e ninguém deu um número de série a ela.
Vale saber isso como fato, e não como detalhe do laboratório, porque **máquinas virtuais também são bens**,
no papel, e não têm etiqueta para ler. A organização dá a elas um identificador próprio.

O script por trás da última linha coleta o resto:

```schooling-example
{"language": "bash", "parts": [{"code": "#!/usr/bin/env bash\n# inventory.sh: one CSV line describing this computer, for the asset register.", "note": "Rodado em cada computador; cada execução imprime uma linha, e as linhas juntas são a metade do registro que vem da máquina."}, {"code": "maker=$(sudo dmidecode -s system-manufacturer)\nmodel=$(sudo dmidecode -s system-product-name)\nserial=$(sudo dmidecode -s system-serial-number)", "note": "**O `dmidecode` lê o que o firmware diz sobre a máquina**: quem fez, o modelo, o número de série. Precisa de `sudo`, porque as tabelas que ele lê não ficam abertas a todo usuário."}, {"code": "cpu=$(lscpu | awk -F': +' '/^Model name/ {print $2}')\nmem=$(free -m | awk '/^Mem:/ {print $2 \" MiB\"}')", "note": "O nome do processador, e a memória que o sistema vê, em MiB: um pouco menos que a instalada, porque o kernel guarda uma parte para si."}, {"code": "root=$(df -h --output=size / | tail -n 1 | tr -d ' ')\nmac=$(ip -br link | awk '$1 != \"lo\" {print $3; exit}')", "note": "O tamanho do sistema de arquivos do sistema, e o MAC da primeira placa de rede, que muitas vezes é como o computador é reconhecido na rede."}, {"code": ". /etc/os-release\nprintf '\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\"\\n' \\\n  \"$(hostname)\" \"$maker\" \"$model\" \"$serial\" \"$cpu\" \"$mem\" \"$root\" \"$mac\" \"$VERSION_ID\"", "note": "**Todo campo entre aspas**, porque um nome de modelo pode ter vírgula, e este tem: `Ubuntu 24.04 PC (Q35 + ICH9, 2009)`. Sem as aspas, uma planilha o dividiria em duas colunas e deslocaria todas as colunas seguintes."}]}
```

Tudo nele vem da máquina, e esse é justamente o limite dele: **nenhum comando diz quem usa este computador,
onde ele está, quando foi comprado ou até quando vai a garantia**. Isso vem das pessoas e da papelada, e é
a outra metade do registro.

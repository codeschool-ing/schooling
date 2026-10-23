---
title: O que está instalado, contra o que está corrigido
version: 1
---

**Um aviso diz que versão de um pacote corrige uma falha. Uma máquina diz que versão ela tem.**
Avaliar é pôr as duas lado a lado. Todo o resto que um scanner faz, os painéis, as categorias, o
histórico, se apoia nessa comparação, e fazê-la à mão uma vez mostra o que as ferramentas estão
fazendo e onde erram.

Comece pelo que o `web` tem:

```
ana@web:~$ dpkg-query -W -f='${Package} ${Version}\n' openssh-server nginx sudo curl
curl 8.5.0-2ubuntu10.16
nginx 1.24.0-2ubuntu7.18
openssh-server 1:9.6p1-3ubuntu13.20
sudo 1.9.15p5-3ubuntu5.24.04.4
```

São textos de versão Debian, e cada um tem até três partes. O `1:` na frente da versão do OpenSSH é a
**época**, que passa por cima de tudo o que vem depois. `9.6p1` é a versão de origem, a que os
próprios desenvolvedores do OpenSSH lançaram. `-3ubuntu13.20` é a revisão de empacotamento: a
vigésima atualização do Ubuntu para esse pacote nesta versão, e **toda correção de segurança que o
Ubuntu distribui entra nesse último número**, porque o Ubuntu leva as correções para a versão que
lançou em vez de passar para uma versão de origem mais nova.

## Um feed de avisos

Avisos de verdade vêm da distribuição (os USNs do Ubuntu, com os dados OVAL), dos fornecedores e da
lista de CVEs. O feed abaixo não é nenhum deles: **ele foi escrito para esta aula**, com
identificadores inventados, para que os números dele possam ficar ao lado dos pacotes do seu
laboratório sem afirmar nada sobre falhas reais. O formato é o de um de verdade: um pacote, a versão
que o corrige, um vetor de gravidade, uma probabilidade de exploração e se ele é sabidamente
explorado. Escreva-o no `admin` como `feed.json`:

```json
[
  {"id": "JTB-2026-01", "package": "openssh-server", "fixed": "1:9.6p1-3ubuntu13.21",
   "cvss": "AV:N/AC:H/PR:N/UI:N/S:U/C:H/I:H/A:H", "epss": 0.02, "kev": false},
  {"id": "JTB-2026-02", "package": "nginx", "fixed": "1.24.0-2ubuntu7.19",
   "cvss": "AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H", "epss": 0.41, "kev": true},
  {"id": "JTB-2026-03", "package": "sudo", "fixed": "1.9.15p5-3ubuntu5.24.04.2",
   "cvss": "AV:L/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:H", "epss": 0.06, "kev": false},
  {"id": "JTB-2026-04", "package": "curl", "fixed": "8.5.0-2ubuntu10.17",
   "cvss": "AV:N/AC:L/PR:N/UI:R/S:U/C:L/I:N/A:N", "epss": 0.003, "kev": false},
  {"id": "JTB-2026-05", "package": "vsftpd", "fixed": "3.0.5-0ubuntu3.2",
   "cvss": "AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:N/A:N", "epss": 0.05, "kev": false},
  {"id": "JTB-2026-06", "package": "python3.12", "fixed": "3.12.3-1ubuntu0.15",
   "cvss": "AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H", "epss": 0.11, "kev": false},
  {"id": "JTB-2026-07", "package": "libssl3t64", "fixed": "3.0.13-0ubuntu3.17",
   "cvss": "AV:N/AC:H/PR:N/UI:N/S:U/C:H/I:N/A:N", "epss": 0.01, "kev": false}
]
```

Depois o script que os compara. Ele roda no `admin` e lê o `web` por SSH, com a chave em que o
laboratório já confia. O botão de copiar entrega o programa sem as notas:

```schooling-example
{"language": "python", "file": "vulncheck.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"vulncheck.py FEED HOST: which advisories in FEED apply to the packages installed on HOST.\"\"\"\nimport json, subprocess, sys", "note": "O feed é uma lista de avisos; o segundo argumento é a máquina a conferir. Nada é instalado nessa máquina: o script roda no `admin` e pergunta por SSH, e é isso que o torna uma verificação **autenticada**, que lê o banco de dados de pacotes em vez de adivinhar por fora."}, {"code": "\nfeed = json.load(open(sys.argv[1]))\nout = subprocess.run([\"ssh\", sys.argv[2], \"dpkg-query -W -f='${Package} ${Version}\\\\n'\"],\n                     capture_output=True, text=True, check=True).stdout\ninstalled = dict(line.split(\" \", 1) for line in out.splitlines())", "note": "Um único comando SSH lista cada pacote instalado com a versão exata, e a resposta vira um dicionário de nome para versão."}, {"code": "\nfor adv in feed:\n    have = installed.get(adv[\"package\"])\n    if have is None:\n        state = \"not installed\"\n    elif subprocess.run([\"dpkg\", \"--compare-versions\", have, \"lt\", adv[\"fixed\"]]).returncode == 0:\n        state = \"VULNERABLE\"\n    else:\n        state = \"fixed\"\n    print(f'{adv[\"id\"]}  {adv[\"package\"]:15} {have or \"-\":28} fixed in {adv[\"fixed\"]:26} {state}')", "note": "A comparação é o `dpkg --compare-versions`, nunca uma comparação de textos. Versões Debian trazem uma época (`1:`), a versão de origem e uma revisão de empacotamento, e `3ubuntu13.9` é mais antiga que `3ubuntu13.20` embora venha depois dela em ordem alfabética. O código de saída diz se a versão instalada é menor que a que corrige a falha."}]}
```

Rode-o contra o `web`:

```
ana@admin:~$ ls
cvss.py
feed.json
prioritise.py
vulncheck.py
ana@admin:~$ python3 vulncheck.py feed.json web
JTB-2026-01  openssh-server  1:9.6p1-3ubuntu13.20         fixed in 1:9.6p1-3ubuntu13.21       VULNERABLE
JTB-2026-02  nginx           1.24.0-2ubuntu7.18           fixed in 1.24.0-2ubuntu7.19         VULNERABLE
JTB-2026-03  sudo            1.9.15p5-3ubuntu5.24.04.4    fixed in 1.9.15p5-3ubuntu5.24.04.2  fixed
JTB-2026-04  curl            8.5.0-2ubuntu10.16           fixed in 8.5.0-2ubuntu10.17         VULNERABLE
JTB-2026-05  vsftpd          3.0.5-0ubuntu3.1             fixed in 3.0.5-0ubuntu3.2           VULNERABLE
JTB-2026-06  python3.12      3.12.3-1ubuntu0.17           fixed in 3.12.3-1ubuntu0.15         fixed
JTB-2026-07  libssl3t64      3.0.13-0ubuntu3.16           fixed in 3.0.13-0ubuntu3.17         VULNERABLE
```

Cinco dos sete se aplicam. Dois estão `fixed`: o `web` já tem um `sudo` e um `python3.12` mais novos
que as versões que corrigiram essas falhas, então não há nada a fazer, e um relatório que os listasse
mesmo assim seria ruído que ensina as pessoas a ler por cima. Os outros cinco estão `VULNERABLE`: a
versão instalada é menor que a corrigida.

**Este é o núcleo de todo scanner autenticado**, que entra na máquina, lê o banco de dados de pacotes
e o compara com avisos. A próxima seção trata de scanners que não entram, e de por que as respostas
deles valem menos.

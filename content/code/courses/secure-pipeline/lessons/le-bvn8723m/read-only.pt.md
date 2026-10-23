---
title: Um sistema de arquivos somente leitura, e os dois lugares onde o linkbox escreve
version: 1
---

`--read-only` monta todo o sistema de arquivos da imagem como somente leitura, então nada no contêiner
consegue mudar um arquivo que veio com a imagem, seja qual for o processo. O método que a aula 21 de
`docker` usou no Postgres funciona em qualquer imagem: **inicie somente leitura, leia o que ela não
conseguiu escrever, e dê a ela exatamente esses lugares.** O linkbox falha duas vezes, e cada falha
nomeia o seu lugar.

### Primeira falha: o gunicorn não sobe

```
ana@vm:~/linkbox$ docker run -d --name linkbox --read-only -p 127.0.0.1:8000:8000 -e LINKBOX_TOKEN=local-only linkbox:dev
4a79c78038ef2424d25a8f3defd7c0bf490c63315479c033d8faa1cc6cf8e7fd
ana@vm:~/linkbox$ docker ps -a --filter name=linkbox --format "{{.Status}}"
Exited (255) 2 seconds ago
ana@vm:~/linkbox$ docker logs linkbox 2>&1 | tail -n 3
                            "No usable temporary directory found in %s" %
                            dirlist)
FileNotFoundError: [Errno 2] No usable temporary directory found in ['/tmp', '/var/tmp', '/usr/tmp', '/app']
ana@vm:~/linkbox$ docker rm -f linkbox
linkbox
```

**O contêiner já tinha saído quando perguntamos**, e a última linha do log nomeia o problema:
`No usable temporary directory found in ['/tmp', '/var/tmp', '/usr/tmp', '/app']`. É o módulo
`tempfile` do Python, que tentou os lugares de sempre e o diretório de trabalho, e não achou nada
gravável. O gunicorn precisa de um antes de atender a primeira requisição: cada worker mantém um
pequeno arquivo temporário que toca como heartbeat, para o master distinguir um worker travado de um
ocupado. O código do próprio linkbox nunca pediu arquivo temporário, e por isso nenhum teste
percebeu.

Um diretório temporário é espaço de rascunho, que some quando o contêiner para, e é exatamente isso
que um `tmpfs` é: um sistema de arquivos em memória, montado num caminho.

### Segunda falha: a primeira escrita

```
ana@vm:~/linkbox$ docker run -d --name linkbox --read-only --tmpfs /tmp -p 127.0.0.1:8000:8000 -e LINKBOX_TOKEN=local-only linkbox:dev
5751d0672951c4c6a91ca93ec239c77d0dd13178d20b71da0d8c2c38753dbfa7
ana@vm:~/linkbox$ curl -s -o /dev/null -w "%{http_code}\n" -X POST -H "X-Token: local-only" -d url=https://example.org/handbook http://127.0.0.1:8000/links
500
ana@vm:~/linkbox$ docker logs linkbox 2>&1 | grep Error
sqlite3.OperationalError: unable to open database file
ana@vm:~/linkbox$ docker rm -f linkbox
linkbox
```

O gunicorn sobe, e **a primeira requisição que toca o banco responde 500**. O log diz
`unable to open database file`: o SQLite não conseguiu criar `/data/linkbox.db`, porque `/data` faz
parte da imagem e a imagem agora é somente leitura. Esta falha é pior que a primeira, porque o
contêiner fica de pé e com cara de saudável até alguém usá-lo; uma execução de staging que só
conferisse se o contêiner subiu teria deixado passar.

Onde o linkbox guarda os dados é uma decisão sobre os dados, não sobre o sistema de arquivos. Em
staging os dados são jogados fora depois do scan, então um `tmpfs` serve. Em produção eles precisam
sobreviver ao contêiner, e o lugar deles é um volume, que a aula 10 dá como volume do Kubernetes. De
um jeito ou de outro, é uma montagem própria, e o resto continua somente leitura:

```
ana@vm:~/linkbox$ docker run -d --name linkbox --read-only --tmpfs /tmp --tmpfs /data:uid=65532,gid=65532 -p 127.0.0.1:8000:8000 -e LINKBOX_TOKEN=local-only linkbox:dev
f0ef124b2d1d1c55e03b3ee5ec6d8440843f33754842581d5a0ff5e7ddd9445d
ana@vm:~/linkbox$ curl -s -X POST -H "X-Token: local-only" -d url=https://example.org/handbook http://127.0.0.1:8000/links
{"code":"rMPeDg"}
ana@vm:~/linkbox$ docker exec linkbox python3 -c "print(open('/proc/mounts').read(), end='')" | grep -E ' (/|/tmp|/data) '
overlay / overlay ro,relatime,lowerdir=1080/fs:910/fs:909/fs:908/fs:907/fs:253/fs:252/fs:251/fs:250/fs:249/fs:248/fs:247/fs:246/fs:245/fs:244/fs:243/fs:242/fs:241/fs:240/fs:239/fs:238/fs:237/fs:236/fs:235/fs:234/fs:233/fs:232/fs:231/fs:230/fs:229/fs:228/fs:227/fs:226/fs:225/fs:224/fs:223/fs:222/fs:221/fs:220/fs:219/fs:218/fs:217/fs:216/fs:215/fs:214/fs:213/fs:212/fs:211/fs:210/fs:209/fs:208/fs:207/fs:206/fs,upperdir=/var/lib/docker/containerd/daemon/io.containerd.snapshotter.v1.overlayfs/snapshots/1081/fs,workdir=/var/lib/docker/containerd/daemon/io.containerd.snapshotter.v1.overlayfs/snapshots/1081/work 0 0
tmpfs /data tmpfs rw,nosuid,nodev,noexec,relatime,mode=755,uid=65532,gid=65532 0 0
tmpfs /tmp tmpfs rw,nosuid,nodev,noexec,relatime 0 0
ana@vm:~/linkbox$ docker rm -f linkbox
linkbox
ana@vm:~/linkbox$ docker run --rm --read-only --user 0 --entrypoint python3 linkbox:dev -c "open('/app/app.py', 'a')"
Traceback (most recent call last):
  File "<string>", line 1, in <module>
    open('/app/app.py', 'a')
    ~~~~^^^^^^^^^^^^^^^^^^^^
OSError: [Errno 30] Read-only file system: '/app/app.py'
```

**201 e um código: o serviço funciona com exatamente dois lugares graváveis.** A tabela de montagens
mostra os três que importam. A raiz é `overlay` montado `ro`. `/tmp` e `/data` são `tmpfs`, e o Docker
os monta `nosuid`, `nodev` e `noexec`: um arquivo escrito ali não pode ser rodado como programa, não
pode carregar bit setuid e não pode ser um dispositivo. `uid=65532,gid=65532` faz `/data` pertencer
ao usuário com que a aplicação roda, do jeito que a imagem da aula 8 arrumou. Um `tmpfs` sem dono é
gravável por todos no contêiner, o que funciona e diz menos sobre para quem é o diretório.

O último comando é o ponto de todo o exercício. **O mesmo `--user 0` que reescreveu o `app.py` na
seção anterior agora recebe `Read-only file system`.** A proteção não depende mais de quem é o
processo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"sp-l09-mounts\" aria-label=\"O sistema de arquivos do linkbox quando roda somente leitura. A raiz, vinda da imagem, é um overlay montado ro e contém /app e /packages. Dois tmpfs são graváveis, nosuid, nodev e noexec: /tmp, onde cada worker do gunicorn guarda o arquivo de heartbeat, e /data, do usuário 65532, onde o SQLite guarda o linkbox.db. Os dois ficam em memória e somem quando o contêiner para.\"><defs></defs><rect x=\"15\" y=\"15\" width=\"690\" height=\"220\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"30\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">/</text><text x=\"46\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a imagem: overlay, ro</text><rect x=\"35\" y=\"60\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">/app</text><text x=\"110.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o código</text><rect x=\"35\" y=\"130\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">/packages</text><text x=\"110.0\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">os pacotes</text><rect x=\"260\" y=\"60\" width=\"420\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">/tmp  tmpfs  rw,noexec</text><text x=\"470.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">arquivos de heartbeat do gunicorn</text><rect x=\"260\" y=\"130\" width=\"420\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">/data  tmpfs  rw,noexec</text><text x=\"470.0\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">SQLite: linkbox.db, dono 65532</text><text x=\"470\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">em memória, somem quando o contêiner para</text></svg>", "caption": "Um sistema de arquivos somente leitura e dois pequenos graváveis, cada um ali porque a aplicação falhou sem ele."}
```

### O que o `noexec` não impede

O `noexec` impede o kernel de executar um arquivo em `/tmp` como programa. Ele não impede o `python3`
de ler um arquivo `.py` dali e rodar o conteúdo, porque o programa é o interpretador e o arquivo é só
a entrada dele. Uma raiz somente leitura e um diretório de rascunho `noexec` tiram os jeitos fáceis
de plantar uma ferramenta e mantê-la; não tornam impossível executar código num contêiner que tem um
interpretador dentro. Por isso esta aula não para no sistema de arquivos.

### Achando os lugares de qualquer imagem

O linkbox precisou de dois lugares e achou os dois em duas tentativas. Uma aplicação maior pode
precisar de mais, e a ordem do trabalho é a mesma: rode somente leitura em staging, exercite a
aplicação (suba, mande uma requisição a cada rota que escreve, rode uma tarefa se ela tiver), leia
os erros, acrescente uma montagem para cada um, e **escreva a lista no lugar que inicia o
contêiner**, para ela ser revisada como código. Para o linkbox esse lugar é o script de staging da
última seção, e a partir da aula 10 o manifesto.

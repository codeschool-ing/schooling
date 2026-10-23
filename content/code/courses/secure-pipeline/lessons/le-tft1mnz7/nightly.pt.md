---
title: A lista noturna, e um build do zero
version: 1
---

Algumas checagens valem a pena e são lentas demais para esperar. Elas vão para uma segunda lista, que
roda uma vez por dia, na `main`, quando ninguém está esperando. **Mover uma checagem para lá não é
baixar a régua: ela continua rodando todo dia, no código que está de fato na `main`**, e o resultado
continua chegando a alguém. O que muda é que o push de ninguém espera por ela.

### A lista

A lista noturna tem o mesmo formato de `ci/stages`: um estágio por linha, comentários permitidos.
Salve como `ci/nightly`:

```
# The checks too slow to wait for on every push. They run once a day on
# main, after everything in ci/stages has passed.
rebuild
```

O único estágio dela constrói a imagem sem cache. Salve como `ci/rebuild.sh`:

```sh
# The image built from nothing. Every push reuses the layers already built,
# so a change that arrives without a commit, in the base image or in a
# package, never reaches it; this build has no cache to reuse.
set -euo pipefail
docker build -q --no-cache -t "linkbox:nightly" .
```

### Por que um build do zero

O Docker reaproveita uma camada sempre que a instrução que a criou e os arquivos que ela leu não
mudaram. No `Dockerfile` do linkbox, isso quer dizer que a linha do `pip install` roda uma vez, na
primeira, e todo push seguinte reaproveita o resultado enquanto o `requirements.txt` for o mesmo
arquivo. É isso que deixa o estágio de build rápido. É também um ponto cego: **a camada em cache é um
registro do que a internet respondeu no dia em que foi construída.** Um pacote que o requirements.txt
não fixa, puxado por um que ele fixa, fica com a versão que tinha naquele dia. Um build que hoje
falharia, porque uma versão foi retirada do índice, continua dando certo a partir do cache até o dia
em que alguém precisa de um build limpo.

O rebuild roda todos os passos de novo. Duas coisas ele não faz sozinho, e o curso volta às duas. Ele
usa a imagem base que já está na máquina: pegar uma `python:3.13` mais nova exige um `docker pull`
antes, ou `--pull` no build, e a aula 15 fixa a base por digest para que mudá-la seja uma decisão e
não um acidente. E ele não varre o que construiu: quem lê o resultado é a varredura de imagem da
aula 8.

Rode a lista noturna no laptop antes do commit. Diferente do estágio de teste, o rebuild não tropeça
no `.venv` do laptop, porque o `.dockerignore` o deixa fora do build:

```
ana@vm:~/linkbox$ ci/pipeline.sh ci/nightly
rebuild: passed in 11s
pipeline passed
ana@vm:~/linkbox$ docker images linkbox:nightly
IMAGE             ID             DISK USAGE   CONTENT SIZE   EXTRA
linkbox:nightly   1669ea85472b       1.64GB          422MB        
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"sp-l02-builds\" aria-label=\"Cinco tempos de uma mesma gravação, numa escala de 0 a 11 segundos: criar o ambiente virtual, 0,028 segundo; instalar os pacotes a partir do cache do uv, 0,073; pytest, 1,062; o build da imagem com o cache do Docker, 0,495; o rebuild noturno sem cache, 11 segundos.\"><defs></defs><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">uv venv</text><text x=\"20\" y=\"45\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">ambiente</text><rect x=\"230\" y=\"24\" width=\"1.5\" height=\"22\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"0.5\"></rect><text x=\"239.5\" y=\"35\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.028 s</text><text x=\"20\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">uv pip install</text><text x=\"20\" y=\"85\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">do cache do uv</text><rect x=\"230\" y=\"64\" width=\"2.92\" height=\"22\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"0.5\"></rect><text x=\"240.92\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.073 s</text><text x=\"20\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pytest</text><text x=\"20\" y=\"125\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">três testes</text><rect x=\"230\" y=\"104\" width=\"42.480000000000004\" height=\"22\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"0.5\"></rect><text x=\"280.48\" y=\"115\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1.062 s</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">docker build</text><text x=\"20\" y=\"165\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">com o cache</text><rect x=\"230\" y=\"144\" width=\"19.8\" height=\"22\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"0.5\"></rect><text x=\"257.8\" y=\"155\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.495 s</text><text x=\"20\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">rebuild</text><text x=\"20\" y=\"205\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sem cache, noturno</text><rect x=\"230\" y=\"184\" width=\"440\" height=\"22\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"0.5\"></rect><text x=\"678\" y=\"195\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">11 s</text><line x1=\"230\" y1=\"14\" x2=\"230\" y2=\"220\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"230\" y1=\"220\" x2=\"230\" y2=\"225\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"230\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><line x1=\"430\" y1=\"220\" x2=\"430\" y2=\"225\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"430\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><line x1=\"630\" y1=\"220\" x2=\"630\" y2=\"225\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"630\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><text x=\"450\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">segundos de espera, uma escala só</text></svg>", "caption": "Tudo o que o push espera cabe em menos de três segundos. Só o build do zero leva onze."}
```

O mesmo `Dockerfile`, os mesmos arquivos, a mesma máquina: **o build do zero levou 11 segundos, e o
com cache, menos de um.** O mesmo rebuild no servidor, mais abaixo, levou 10, que é o segundo de
variação de que a seção de medição avisou. Onze segundos não são nada para esperar hoje, porque o
linkbox instala oito pacotes pequenos. Uma imagem que compila uma dependência ou instala um pacote do
sistema leva minutos, e a diferença cresce a cada linha do `Dockerfile`. Essa diferença é o motivo de
o rebuild não estar em cada push.

### Commit, e push

```
ana@vm:~/linkbox$ git add ci
ana@vm:~/linkbox$ git status --short
A  ci/nightly
M  ci/pipeline.sh
A  ci/rebuild.sh
ana@vm:~/linkbox$ git commit -q -m "the pipeline takes a list: every push, and the nightly run"
ana@vm:~/linkbox$ git push ci main
remote: run 1: main at 023b325        
remote: test: passed in 1s        
remote: build: passed in 0s        
remote: pipeline passed        
remote: run 1: passed        
To /home/ana/ci/linkbox.git
   3f932db..023b325  main -> main
```

O hook roda `ci/stages`, como antes, e nada no push espera pelo rebuild.

### Quem dispara a execução noturna

Um push dispara a execução do servidor; um agendamento dispara a noturna. Neste servidor, o
agendamento seria uma linha no crontab do usuário com que a CI roda. Ela clona a `main` do
repositório do servidor e roda as duas listas em ordem, então as checagens noturnas só rodam numa
`main` cujas checagens de push passaram. Aqui está a mesma coisa feita à mão, do jeito que o
agendador faria:

```
ana@vm:~/linkbox$ rm -rf /tmp/nightly && git clone -q ~/ci/linkbox.git /tmp/nightly && /tmp/nightly/ci/pipeline.sh && /tmp/nightly/ci/pipeline.sh ci/nightly
test: passed in 1s
build: passed in 1s
pipeline passed
rebuild: passed in 10s
pipeline passed
ana@vm:~/linkbox$ rm -rf /tmp/nightly
```

Num servidor de verdade, o crontab do usuário com que a CI roda teria duas linhas como estas, a
segunda às 03:10 toda noite. A primeira importa tanto quanto: o cron inicia os comandos com um `PATH`
mínimo, que não inclui `~/.local/bin`, onde fica o `uv`, e o estágio de teste falharia na primeira
noite.

```
PATH=/home/ana/.local/bin:/usr/local/bin:/usr/bin:/bin
10 3 * * * (rm -rf /tmp/nightly && git clone -q ~/ci/linkbox.git /tmp/nightly && /tmp/nightly/ci/pipeline.sh && /tmp/nightly/ci/pipeline.sh ci/nightly) >>~/ci/nightly.log 2>&1
```

Elas não foram instaladas na máquina da gravação, para o laboratório ficar quieto entre as aulas, e
nenhuma execução delas aparece aqui. Acrescente com `crontab -e`, com o diretório do seu próprio
usuário no `PATH`, se quiser a coisa de verdade.

A CI hospedada tem a mesma ideia com outro nome. O GitHub Actions roda um workflow agendado com
`on: schedule:` e uma expressão cron, sobre o commit mais recente da branch padrão, e a documentação
avisa que uma execução agendada pode atrasar quando os runners estão ocupados. O GitLab chama isso de
pipeline schedules. Nenhum dos dois foi executado para este curso.

### O resultado precisa chegar a alguém

Às 03:10 ninguém está olhando. **Uma execução noturna que falha num log que ninguém abre é o scanner
ignorado da aula 1 de novo**, só que mais silencioso. O que quer que rode o agendamento precisa mandar
a falha para um lugar onde uma pessoa a veja de manhã: um e-mail para o time, uma mensagem no canal
dele, uma issue atribuída a quem cuida do serviço. A aula 7 decide quais achados noturnos quebram e
quais só alertam; esta aula só precisa garantir que eles sejam lidos.

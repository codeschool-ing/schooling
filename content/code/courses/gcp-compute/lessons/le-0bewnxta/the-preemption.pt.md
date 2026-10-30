---
title: Os trinta segundos
version: 1
---

Quando o Google precisa de uma máquina Spot de volta, ele não puxa o cabo. **Ele manda à máquina o
sinal que um botão de energia manda, espera cerca de trinta segundos para ela desligar sozinha, e
então a para de qualquer jeito.** O que o seu software faz com esses trinta segundos decide se uma
preempção custa alguns segundos de trabalho ou tudo desde o último salvamento.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Uma linha do tempo de uma preempção. No início, o Compute Engine envia um desligamento suave ACPI e põe instance/preempted em TRUE. Nos trinta segundos seguintes, mais ou menos, os serviços recebem SIGTERM, o script de desligamento roda e o sistema operacional desliga. No fim dos trinta segundos a máquina é parada de qualquer jeito, e o que não foi salvo se perde.\"><defs><marker id=\"l6p-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><path d=\"M60 120 L660 120\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M60 120 L60 70\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l6p-ah)\"></path><path d=\"M660 120 L660 70\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l6p-ah)\"></path><rect x=\"20\" y=\"22\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">desligamento suave</text><text x=\"120.0\" y=\"53.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ACPI, o aviso</text><rect x=\"560\" y=\"22\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">parada forçada</text><text x=\"635.0\" y=\"53.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sem mais aviso</text><text x=\"360\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">cerca de 30 segundos</text><rect x=\"90\" y=\"140\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">SIGTERM</text><text x=\"170\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">para cada serviço</text><rect x=\"270\" y=\"140\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">script de desligamento</text><text x=\"350\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a lição 7 o define</text><rect x=\"450\" y=\"140\" width=\"190\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"545.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">instance/preempted</text><text x=\"545\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">passa a valer TRUE</text></svg>", "caption": "Tudo que salva trabalho precisa caber nos trinta segundos entre o aviso e a parada forçada."}
```

## O que a máquina vê

Dentro da máquina, a preempção chega como um **desligamento suave ACPI**, o mesmo evento de alguém
apertando o botão de energia. O sistema operacional começa um desligamento ordenado: o systemd para
os serviços em ordem, e cada serviço recebe `SIGTERM` e um momento para sair. O Compute Engine também
roda o **script de desligamento** da máquina, se os metadados tiverem um, um script que a lição 7
configura do mesmo jeito que um script de inicialização. E o valor `instance/preempted` do servidor
de metadados passa a `TRUE`, então um programa que o consulta consegue diferenciar uma preempção de um
desligamento comum.

Os trinta segundos são um esforço, não uma promessa, e cobrem tudo: os serviços, o script de
desligamento e o desligamento do próprio sistema. **Um script de desligamento que precisa de um
minuto não ganha um minuto.** É o lugar para esvaziar um buffer ou marcar um job como interrompido,
não para enviar um gigabyte.

## Trinta segundos no laptop

Nada disso pode ser produzido aqui: não há máquina Spot para ser retomada. O que dá para mostrar é a
parte que é sua, um programa que ouve `SIGTERM` e usa bem o tempo, porque o `docker stop` manda
exatamente esse sinal e depois espera um número de segundos antes de matar o processo. Salve isto como
`~/gcp/worker.py`:

```python
# worker.py
import signal
import time

done = 0
stopping = False


def stop(signum, frame):
    global stopping
    stopping = True


signal.signal(signal.SIGTERM, stop)
print('started', flush=True)
while not stopping:
    time.sleep(1)  # one unit of work
    done += 1
print(f'SIGTERM after {done} units: saving progress', flush=True)
time.sleep(2)  # writing a checkpoint
print('checkpoint written, exiting', flush=True)
```

O tratador não faz nada além de marcar uma flag, e o laço verifica a flag entre uma unidade de
trabalho e outra, então uma unidade nunca é cortada ao meio. Ponha o programa numa imagem, com o
segundo programa desta seção ao lado, usando um `Dockerfile` na mesma pasta:

```dockerfile
# Dockerfile
FROM python:3.12.13-slim
COPY worker.py plain.py /
```

Depois construa a imagem, inicie o worker, deixe-o trabalhar alguns segundos e pare-o com trinta
segundos de tolerância, como o Compute Engine faria:

```
ana@laptop:~/gcp$ docker build -q -t spot-demo .
sha256:d3192edb3c6df57b69316fbf0d99faa87e839770c63957ab41aea9bc3c315cc8
ana@laptop:~/gcp$ docker run -d --name spot-worker spot-demo python3 /worker.py
2e865059cac39f03105bd1e2f93aa073b4a63250172bfc0715c80d406cd2e678
ana@laptop:~/gcp$ time docker stop -t 30 spot-worker
spot-worker

real	0m2.194s
user	0m0.014s
sys	0m0.015s
ana@laptop:~/gcp$ docker logs spot-worker
started
SIGTERM after 5 units: saving progress
checkpoint written, exiting
```

**A parada levou cerca de dois segundos**, o tempo de que o checkpoint precisava, e o log mostra o
trabalho salvo. Agora o mesmo trabalho sem tratador nenhum, que é o que a maioria dos programas é.
Este é o segundo programa, `~/gcp/plain.py`, que a imagem já guarda:

```python
# plain.py
import time

done = 0
print('started', flush=True)
while True:
    time.sleep(1)  # one unit of work
    done += 1
```

```
ana@laptop:~/gcp$ docker run -d --init --name plain-worker spot-demo python3 /plain.py
34fcd9fdb94426b946930ba2428fa8ee6a0eee35e7068b7db28c9fa893278f7f
ana@laptop:~/gcp$ time docker stop -t 30 plain-worker
plain-worker

real	0m0.141s
user	0m0.015s
sys	0m0.015s
ana@laptop:~/gcp$ docker logs plain-worker
started
ana@laptop:~/gcp$ docker inspect -f '{{.State.ExitCode}}' plain-worker
143
```

**O código de saída 143 é 128 mais 15, o número do `SIGTERM`**: o programa foi morto pelo sinal no
instante em que ele chegou, no meio do que estivesse fazendo, e nada foi salvo. O `--init` está ali
porque um processo rodando como o primeiro de um contêiner ignora o `SIGTERM` se não o tratar, o que
teria escondido a diferença; numa máquina virtual o seu serviço nunca é o primeiro processo, então
esta execução é o retrato honesto de um serviço despreparado numa máquina Spot retomada.

Isto é uma imitação do sinal, não de uma preempção. Mostra o que o seu programa faz com o aviso;
com que frequência os avisos vêm, e quanto tempo de aviso há de fato, é o lado do Google e não pode
ser testado de um laptop.

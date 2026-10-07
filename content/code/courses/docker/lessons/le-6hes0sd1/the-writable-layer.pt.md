---
title: O que sobrevive a um stop, e o que não sobrevive
version: 1
---

**A camada de escrita de um container vive exatamente o tempo que o container vive, e não o tempo
que o processo dele vive.** Parar um container encerra o processo e mantém a camada; remover o
container apaga a camada e tudo o que foi escrito nela. As pessoas dizem "containers são efêmeros"
pensando na segunda metade, e depois se surpreendem com a primeira.

A Ana inicia um container, escreve um arquivo nele e pergunta ao Docker o que mudou em relação à
imagem:

```
ana@vm:~$ docker run -d --name notes alpine:3.22 sleep 3600
f5fb65e5afd4a63ffe25cb5e39df039c8d0b0215f57f555038d3359c0b4a5e6b
ana@vm:~$ docker exec notes sh -c "echo first note > /notes.txt"
ana@vm:~$ docker diff notes
A /notes.txt
```

O `docker diff` lista os caminhos na camada do próprio container: `A` para acrescentado, `C` para
alterado e `D` para apagado. Uma linha, o arquivo que ela escreveu. É o diretório superior da aula 4,
lido pelo Docker em vez de pelas montagens do host.

## Parar mantém a camada

```
ana@vm:~$ docker stop notes
notes
ana@vm:~$ docker ps -a --format "{{.Names}}: {{.Status}}"
notes: Exited (137) Less than a second ago
ana@vm:~$ docker start notes
notes
ana@vm:~$ docker exec notes cat /notes.txt
first note
```

O container parou: o `docker ps -a`, que também lista containers parados, o mostra como `Exited`.
Iniciado de novo, ele tem o arquivo. **Um container parado não sumiu**; ele é uma camada de escrita e
uma configuração esperando o processo iniciar de novo, e continua ocupando disco até ser removido. O
`137` no status dele é o número da aula 4 de novo, `SIGKILL`: o `sleep` ignorou o sinal educado que o
`docker stop` mandou primeiro, então o Docker o matou depois da espera padrão de dez segundos. A aula
11 trata de por que isso acontece e de como um programa o evita.

## Remover apaga a camada

```
ana@vm:~$ docker rm -f notes
notes
ana@vm:~$ docker run -d --name notes alpine:3.22 sleep 3600
39068d3197c9c5698fe2817700f7b6e999762aa71efc4ef50945cc90254705bc
ana@vm:~$ docker exec notes cat /notes.txt
cat: can't open '/notes.txt': No such file or directory
```

Mesmo nome, mesma imagem, um container novo, e nenhum arquivo. **O nome não é o container.** Depois
que o `docker rm` rodou, o container antigo e a camada dele se foram, e o `docker run` criou um
totalmente novo que por acaso também se chama `notes`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Os estados de um container da esquerda para a direita. O docker create ou o docker run o cria: created. Iniciado, ele fica running. O docker stop o leva a exited, e o docker start o traz de volta a running. O docker rm leva um container exited a removido. Uma faixa embaixo diz que a camada de escrita existe de created até exited, e é apagada na remoção.\"><defs><marker id=\"l7life-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l7life-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"50\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"85\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">created</text><rect x=\"200\" y=\"50\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"265\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">running</text><rect x=\"380\" y=\"50\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"445\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">exited</text><rect x=\"570\" y=\"50\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"635\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">removido</text><path d=\"M152 75 L196 75\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l7life-ah-wire)\"></path><text x=\"174\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">start</text><path d=\"M332 66 L376 66\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l7life-ah-wire)\"></path><text x=\"354\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">stop</text><path d=\"M376 86 L332 86\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l7life-ah-wire)\"></path><text x=\"354\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">start</text><path d=\"M512 75 L566 75\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l7life-ah-amber)\"></path><text x=\"539\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">rm</text><rect x=\"20\" y=\"150\" width=\"490\" height=\"34\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"265\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a camada de escrita existe, com tudo o que foi escrito nela</text><rect x=\"570\" y=\"150\" width=\"130\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"635\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">apagada</text><text x=\"20\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">docker run = create + start</text></svg>", "caption": "Parar e iniciar movem um container entre running e exited, e a camada de escrita fica. Só a remoção apaga a camada."}
```

A diferença importa num hábito que todo mundo pega rápido: para "reiniciar" um container com um
ajuste novo, as pessoas o removem e o rodam de novo, porque a maior parte da configuração de um
container não pode ser mudada depois que ele é criado. Cada vez que fazem isso, a camada de escrita
antiga vai junto. **Nada que valha a pena guardar pode ficar só na camada de um container.** A próxima
etapa mostra quanto isso custa quando a coisa que vale a pena guardar é um banco de dados.

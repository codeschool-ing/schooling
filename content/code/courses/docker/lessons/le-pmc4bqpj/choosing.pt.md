---
title: Qual deles, quando
version: 1
---

**A pergunta que decide é de quem são os arquivos.** Se a aplicação é dona deles e ninguém os edita à
mão, um volume nomeado. Se uma pessoa no host é dona deles e o container deve enxergar as edições
dela, um bind mount. Se ninguém precisa deles depois que o container termina, `tmpfs`, que os guarda
na memória.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Três montagens num container. À esquerda, o host: um volume nomeado pgdata, guardado pelo Docker em /var/lib/docker/volumes; um diretório /home/ana/site montado por bind, que a Ana edita; e memória, para um tmpfs. À direita, o container os enxerga em /var/lib/postgresql/data, /srv e /scratch. O volume e o diretório sobrevivem ao container; o tmpfs não.\"><defs><marker id=\"l8three-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l8three-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l8three-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"330\" height=\"260\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"26\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">o host</text><rect x=\"400\" y=\"10\" width=\"310\" height=\"260\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"416\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">o container</text><rect x=\"26\" y=\"44\" width=\"298\" height=\"58\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"38\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">volume nomeado</text><text x=\"38\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/var/lib/docker/volumes/pgdata</text><text x=\"38\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">do Docker · sobrevive</text><rect x=\"420\" y=\"60\" width=\"270\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"434\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/var/lib/postgresql/data</text><path d=\"M326 74 L416 75\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l8three-ah-phosphor)\"></path><rect x=\"26\" y=\"119\" width=\"298\" height=\"58\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"38\" y=\"135\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">bind mount</text><text x=\"38\" y=\"153\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/home/ana/site</text><text x=\"38\" y=\"169\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">da Ana · sobrevive</text><rect x=\"420\" y=\"135\" width=\"270\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"434\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/srv</text><path d=\"M326 149 L416 150\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l8three-ah-amber)\"></path><rect x=\"26\" y=\"194\" width=\"298\" height=\"58\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"38\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">tmpfs</text><text x=\"38\" y=\"228\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">memória</text><text x=\"38\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">some quando o container termina</text><rect x=\"420\" y=\"210\" width=\"270\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"434\" y=\"225\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/scratch</text><path d=\"M326 224 L416 225\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l8three-ah-wire)\"></path></svg>", "caption": "As três diferem em quem é dono dos arquivos à esquerda. O Docker é dono do volume, a Ana é dona do diretório, e ninguém guarda a memória depois que o container termina.", "same": ["bind mount", "tmpfs"]}
```

| | volume nomeado | bind mount | tmpfs |
| --- | --- | --- | --- |
| onde ficam os dados | um diretório que o Docker gerencia, em `/var/lib/docker/volumes` | qualquer diretório do host que você indicar | memória |
| quem cria | o Docker, no primeiro uso ou com `docker volume create` | você, antes de o container iniciar | o Docker, quando o container inicia |
| sobrevive ao container | sim | sim, é o seu diretório | não |
| uso típico | bancos, arquivos enviados, tudo o que a aplicação possui | código-fonte durante o desenvolvimento, arquivos de configuração | espaço de rascunho, segredos que não podem tocar o disco |
| depende da organização do host | não | sim, o caminho precisa existir em cada máquina | não |

A última linha importa mais do que parece. Um comando com bind mount só funciona numa máquina que tenha
aquele caminho, então ele não viaja; um comando com volume nomeado funciona em qualquer lugar onde o
Docker rode. É por isso que configurações de produção se apoiam em volumes e as de desenvolvimento,
em bind mounts.

## Dois jeitos de escrever, e uma diferença

O `-v` e o `--mount` pedem as mesmas montagens, em duas sintaxes. O `--mount` é mais longo e diz tudo
pelo nome; o `-v` é mais curto e adivinha. A adivinhação aparece quando o caminho do host não existe:

```
ana@vm:~$ docker run --rm --mount type=bind,source="$PWD/missing",target=/srv alpine:3.22 true
docker: Error response from daemon: invalid mount config for type "bind": bind source path does not exist: /home/ana/missing

Run 'docker run --help' for more information
ana@vm:~$ docker run --rm -v "$PWD/missing":/srv alpine:3.22 true; ls -ld missing
drwxr-xr-x 2 root root 4096 Oct  6 13:42 missing
```

**O `--mount` recusa uma origem que não existe; o `-v` a cria**, como um diretório vazio pertencente ao
root, e o container inicia sem nada dentro. Um erro de digitação num caminho vira então um container
rodando feliz contra um diretório vazio, e um diretório perdido do root no host. Prefira o `--mount` em
scripts e onde quer que um erro deva interromper a execução, e deixe o `-v` para digitar no prompt.

## tmpfs, para o que nunca deve chegar ao disco

```
ana@vm:~$ docker run --rm --tmpfs /scratch:size=16m alpine:3.22 sh -c "df -h /scratch; dd if=/dev/zero of=/scratch/big bs=1M count=32"
Filesystem                Size      Used Available Use% Mounted on
tmpfs                    16.0M         0     16.0M   0% /scratch
dd: error writing '/scratch/big': No space left on device
17+0 records in
16+0 records out
16777216 bytes (16.0MB) copied, 0.006519 seconds, 2.4GB/s
```

Uma montagem `tmpfs` vive na memória e desaparece com o container. O `size=16m` é um limite rígido: o
`dd` tentou escrever 32 MB e parou nos 16 com "No space left on device". Sem tamanho, a montagem recebe
metade da memória do host:

```
ana@vm:~$ docker run --rm --tmpfs /scratch alpine:3.22 df -h /scratch
Filesystem                Size      Used Available Use% Mounted on
tmpfs                     7.9G         0      7.9G   0% /scratch
```

7.9G numa máquina com 16 GB. O que um container escreve ali conta contra o próprio limite de memória
dele, da aula 4, então defina um tamanho. Ele serve para arquivos numerosos e de vida curta, e serve
para arquivos que não podem ficar para trás no disco, e é por isso que a aula 21 monta um para os
arquivos temporários de um container somente leitura.

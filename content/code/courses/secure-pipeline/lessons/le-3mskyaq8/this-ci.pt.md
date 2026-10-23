---
title: O que um job nesta máquina consegue fazer
version: 1
---

O hook em `~/ci/linkbox.git/hooks/post-receive` roda todo estágio como o usuário dono do repositório,
que nesta máquina é a Ana. Um estágio é o script que o commit enviado contiver. Então a pergunta
honesta sobre a CI deste curso não é o que os estágios fazem, e sim **o que qualquer script rodando
como Ana conseguiria fazer**. A resposta depende de uma linha de saída.

```
ana@vm:~/linkbox$ id
uid=30033(ana) gid=30033(ana) groups=30033(ana),996(docker)
ana@vm:~/linkbox$ ls -l /var/run/docker.sock
srw-rw---- 1 root docker 0 Oct 23 09:17 /var/run/docker.sock
ana@vm:~/linkbox$ ps -C dockerd -o user=,pid=,comm=
root      9084 dockerd
```

### O grupo docker é root

A Ana está no grupo `docker` (gid 996 aqui), porque a aula 1 a colocou lá para que o pipeline pudesse
construir imagens sem `sudo`. O socket do daemon pertence ao root e tem escrita para esse grupo, e o
próprio daemon roda como root. Quem consegue escrever no socket consegue pedir ao daemon, que é root,
para iniciar um contêiner com qualquer opção que ele aceite, inclusive um contêiner que monta o
sistema de arquivos do host.

A própria documentação do Docker diz isso sem rodeios. Os passos de pós-instalação para Linux, os que
acrescentam um usuário ao grupo, trazem o aviso: **"The docker group grants root-level privileges to
the user."**, ou seja, o grupo docker dá ao usuário privilégios de nível root. A página sobre a
superfície de ataque do daemon acrescenta que só usuários de confiança deveriam poder controlar o
daemon. **Neste laptop, fazer parte do grupo `docker` equivale a ser root**, e o mesmo vale para todo
script que a CI roda, porque ele roda como membro.

Esta aula não demonstra o passo do grupo até o root, e você não precisa vê-lo para agir. As duas
linhas acima, o `id` e as permissões do socket, são o achado inteiro.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 130\" role=\"img\" data-fig=\"sp-l16-socket\" aria-label=\"Por que o grupo docker é root nesta máquina. Os scripts da CI rodam como ana, que está no grupo docker. O socket /var/run/docker.sock pertence ao root, grupo docker, com escrita para o grupo. O daemon por trás dele roda como root e inicia contêineres com as opções que lhe pedirem, então quem consegue escrever no socket consegue agir como root no host.\"><defs><marker id=\"sp-l16-socket-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"10\" y=\"30\" width=\"150\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"49.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">todo estágio da CI</text><text x=\"85.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">como ana, no grupo docker</text><rect x=\"190\" y=\"30\" width=\"180\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"280.0\" y=\"49.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">/var/run/docker.sock</text><text x=\"280.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">escrita para o grupo</text><rect x=\"400\" y=\"30\" width=\"150\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"475.0\" y=\"49.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o daemon do Docker</text><text x=\"475.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">roda como root</text><rect x=\"580\" y=\"30\" width=\"130\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"645.0\" y=\"49.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o host</text><text x=\"645.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">o que lhe pedirem</text><path d=\"M160 57 L188 57\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l16-socket-ah-amber)\"></path><path d=\"M370 57 L398 57\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l16-socket-ah-amber)\"></path><path d=\"M550 57 L578 57\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l16-socket-ah-amber)\"></path></svg>", "caption": "Cada passo é comum sozinho; juntos fazem da escrita num socket o mesmo que root."}
```

### O que decorre para o pipeline

Junte as peças deste curso. O `ci/sign.sh` vem do commit; a chave de assinatura fica em `~/ci/keys`,
legível pela Ana; a CI roda como Ana; a Ana consegue virar root. **Quem consegue enviar uma branch para
esta CI consegue, em princípio, fazer qualquer coisa nesta máquina**, inclusive assinar com a chave da
CI e ler `~/ci/keys`. Num laboratório com um usuário só, é a mesma pessoa, e está tudo bem. Para um
time, os remédios são os que esta aula vem nomeando:

- **O build roda onde não alcança a chave.** A assinatura sai do job, para um serviço que assina a
  pedido, que é a exigência do L3 da aula 14.
- **O build roda numa máquina nova**, para que nada que um job faça sobreviva a ele.
- **O build não tem acesso equivalente a root no host.** Isso quer dizer não dar ao usuário da CI o
  grupo `docker` numa máquina compartilhada, ou fazer esse grupo valer menos.

### Docker rootless, pela documentação

O Docker pode rodar o daemon em modo **rootless**: o daemon e os contêineres rodam como um usuário
comum, dentro de um user namespace, então o root dentro de um contêiner corresponde a esse usuário sem
privilégios do lado de fora. A documentação do Docker o instala com `dockerd-rootless-setuptool.sh
install`, depois do que o socket fica no diretório de execução do usuário, `$XDG_RUNTIME_DIR/docker.sock`,
e o `DOCKER_HOST` aponta para lá. O acesso a esse socket passa a valer o que o usuário vale, e não o que
o root vale.

A documentação também lista os limites: portas abaixo de 1024 precisam de configuração extra, alguns
drivers de armazenamento e alguns recursos, como AppArmor e certos modos de rede, não são suportados, e
limites de recursos precisam do cgroup v2 com delegação. **Ele não foi configurado para este curso**: o
Docker da máquina de gravação é o daemon root comum que a aula 1 instalou, e toda captura do curso
depende dele. O Podman, que roda rootless por padrão, é a outra resposta comum.

A CI local fica como está, com esta seção como o modelo de ameaças escrito dela: um laboratório de um
usuário só, cuja CI é tão poderosa quanto a dona, e não merece mais confiança do que isso.

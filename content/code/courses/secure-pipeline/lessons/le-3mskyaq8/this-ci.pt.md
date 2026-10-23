---
title: O que um job nesta máquina consegue fazer
version: 1
---

O hook em `~/ci/linkbox.git/hooks/post-receive` roda todo estágio como o usuário dono do repositório,
que nesta máquina é a Ana. Um estágio é o script que o commit enviado contiver. Então a pergunta
honesta sobre a CI deste curso não é o que os estágios fazem, e sim **o que qualquer script rodando
como Ana conseguiria fazer**. A resposta depende de uma linha de saída.

@@FENCE 1@@

### O grupo docker é root

A Ana está no grupo `docker` (gid 990 aqui), porque a aula 1 a colocou lá para que o pipeline pudesse
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

@@FIGURE socket@@

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

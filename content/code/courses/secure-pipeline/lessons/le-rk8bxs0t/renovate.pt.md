---
title: O Renovate, rodando na sua própria máquina
version: 1
---

**O Renovate faz o mesmo trabalho que o Dependabot, e roda em qualquer lugar.** É um programa de
código aberto, publicado no npm, que um serviço hospedado roda para GitHub, GitLab, Bitbucket e
outros, e que você também pode rodar por conta própria. Uma das plataformas dele é `local`: ele lê o
repositório do diretório atual, pergunta aos índices de pacotes o que há de mais novo e **relata o
que proporia sem escrever nada**. Isso faz dele o único bot de dependências que você consegue ver
trabalhando na sua própria máquina, e esta seção faz isso.

### Node.js, para um programa

O Renovate é um programa Node.js, e a versão usada aqui pede o Node 24. O Node publica as versões com
um arquivo de checksums, o mesmo padrão que a aula 1 usou para o uv. Baixe-o no seu diretório home e
ponha-o primeiro no path deste terminal:

@@FENCE 1@@

O `npx` vem com o Node. Ele baixa um pacote e o roda, então `npx --yes renovate@44.164.10` roda
exatamente essa versão sem instalar nada globalmente. A versão é fixada pelo mesmo motivo que a
aula 15 fixou todo o resto: o Renovate publica várias versões por dia, e uma aula que rodasse
`renovate@latest` rodaria um programa diferente a cada leitura.

### A configuração

O Renovate lê o `renovate.json` na raiz do repositório. O do linkbox diz as mesmas coisas que o
arquivo do Dependabot, com as palavras do Renovate. Salve-o como `renovate.json`:

@@FENCE 2@@

`config:recommended` é o preset de padrões sensatos do Renovate. **`minimumReleaseAge`** é o nome que
o Renovate dá à espera: uma versão com menos de catorze dias é encontrada e segurada. `schedule` e
`prConcurrentLimit` correspondem à agenda e ao limite do Dependabot, e a regra de pacotes agrupa as
atualizações minor e patch do Python num pull request só. O zizmor não tem auditoria para este
arquivo, então o estágio `workflows` do pipeline não o lê; a linha `$schema` deixa um editor conferi-lo
enquanto você digita. Faça o commit:

@@FENCE 3@@

### O que ele encontra em main

Rode-o contra `main`, com um relatório gravado num arquivo:

@@FENCE 4@@

O log diz que ele achou dois arquivos de requisitos com 13 dependências entre eles, e o relatório diz
que nenhuma está desatualizada. É o que a aula 15 deveria deixar: o lock foi compilado com
`--exclude-newer 2026-10-16`, e nada mais novo que essa data tinha sido publicado quando isto foi
gravado. A sua execução vai ser diferente, porque os índices mudam todo dia; esse é justamente o
motivo de rodar um bot toda semana.

### Um lock compilado um mês antes

Para ver o Renovate propor alguma coisa, o repositório precisa de um lock atrasado. Uma branch
consegue um honestamente: compilar os mesmos arquivos `.in` com uma data anterior, como alguém teria
feito em 20 de setembro.

@@FENCE 5@@

Quatro pacotes resolvem para versões mais antigas nessa data, e todos os outros pins continuam iguais.
Agora rode o Renovate na branch e peça ao relatório toda dependência que tem atualização:

@@FENCE 6@@

Cada linha é um pull request que o Renovate abriria numa plataforma de verdade, com a versão para a
qual moveria. **`waiting: true` é a espera funcionando**: o pluggy 1.7.0 foi publicado em 15 de
outubro, oito dias antes desta gravação, e o `minimumReleaseAge` o segura até ter catorze dias. Os
outros estão públicos há mais tempo e seriam propostos agora. O último comando importa tanto quanto o
relatório: `git status` não imprime nada, porque a plataforma `local` não muda arquivo nenhum e não
abre nada.

O que o Renovate faz numa plataforma hospedada com o mesmo relatório está na documentação dele e não
foi executado aqui. Ele abre uma branch e um pull request por atualização ou por grupo, e mantém uma
issue de "dependency dashboard" listando o que achou e o que está segurando. Faz rebase das branches
dele quando a base muda, e faz merge dos próprios pull requests quando uma regra permite, o assunto
da seção depois da próxima. Repare numa coisa do relatório que importa antes de tudo isso: o
Renovate relatou como arquivos lidos o `requirements.txt` e o `requirements-dev.txt`. Ele propõe
mudanças no lock, não no `requirements.in`. A próxima seção mostra por que uma mudança num lock com
hashes só está correta se quem a faz compila o lock de novo.

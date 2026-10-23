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

```
ana@vm:~/linkbox$ curl -fsSLO https://nodejs.org/dist/v24.21.0/node-v24.21.0-linux-x64.tar.xz
ana@vm:~/linkbox$ curl -fsSL https://nodejs.org/dist/v24.21.0/SHASUMS256.txt | grep " node-v24.21.0-linux-x64.tar.xz$" | sha256sum --check
node-v24.21.0-linux-x64.tar.xz: OK
ana@vm:~/linkbox$ tar -xJf node-v24.21.0-linux-x64.tar.xz -C ~/.local && rm node-v24.21.0-linux-x64.tar.xz
ana@vm:~/linkbox$ export PATH=~/.local/node-v24.21.0-linux-x64/bin:$PATH
ana@vm:~/linkbox$ node --version
v24.21.0
```

O `npx` vem com o Node. Ele baixa um pacote e o roda, então `npx --yes renovate@44.164.10` roda
exatamente essa versão sem instalar nada globalmente. A versão é fixada pelo mesmo motivo que a
aula 15 fixou todo o resto: o Renovate publica várias versões por dia, e uma aula que rodasse
`renovate@latest` rodaria um programa diferente a cada leitura.

### A configuração

O Renovate lê o `renovate.json` na raiz do repositório. O do linkbox diz as mesmas coisas que o
arquivo do Dependabot, com as palavras do Renovate. Salve-o como `renovate.json`:

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:recommended"],
  "timezone": "America/Sao_Paulo",
  "schedule": ["before 6am on monday"],
  "minimumReleaseAge": "14 days",
  "prConcurrentLimit": 3,
  "packageRules": [
    {
      "matchManagers": ["pip_requirements"],
      "matchUpdateTypes": ["minor", "patch"],
      "groupName": "python minor and patch"
    }
  ]
}
```

`config:recommended` é o preset de padrões sensatos do Renovate. **`minimumReleaseAge`** é o nome que
o Renovate dá à espera: uma versão com menos de catorze dias é encontrada e segurada. `schedule` e
`prConcurrentLimit` correspondem à agenda e ao limite do Dependabot, e a regra de pacotes agrupa as
atualizações minor e patch do Python num pull request só. O zizmor não tem auditoria para este
arquivo, então o estágio `workflows` do pipeline não o lê; a linha `$schema` deixa um editor conferi-lo
enquanto você digita. Faça o commit:

```
ana@vm:~/linkbox$ git add renovate.json
ana@vm:~/linkbox$ git commit -q -m "renovate: the same rules, for running it anywhere"
10:15AM INF 0 commits scanned.
10:15AM INF scanned ~413 bytes (413 bytes) in 220ms
10:15AM INF no leaks found
```

### O que ele encontra em main

Rode-o contra `main`, com um relatório gravado num arquivo:

```
ana@vm:~/linkbox$ npx --yes renovate@44.164.10 --platform=local --report-type=file --report-path=/tmp/report.json 2>&1 | grep -v "^npm "
 INFO: Renovate started
       "renovateVersion": "44.164.10"
 INFO: Repository started (repository=local)
       "renovateVersion": "44.164.10"
 INFO: Dependency extraction complete (repository=local, baseBranch=)
       "stats": {
         "managers": {
           "dockerfile": {"fileCount": 1, "depCount": 2},
           "github-actions": {"fileCount": 1, "depCount": 3},
           "pip_requirements": {"fileCount": 2, "depCount": 13}
         },
         "total": {"fileCount": 4, "depCount": 18}
       }
 WARN: GitHub token is required for some dependencies (repository=local)
       "githubDeps": ["actions/checkout", "astral-sh/setup-uv"]
(node:1115) MetadataLookupWarning: received unexpected error = All promises were rejected code = 403, ENOTFOUND
(Use `node --trace-warnings ...` to show where the warning was created)
 INFO: Repository finished (repository=local)
       "cloned": undefined,
       "durationMs": 9571,
       "result": undefined,
       "status": undefined,
       "enabled": undefined,
       "onboarded": undefined,
       "exitCode": undefined
 INFO: Renovate was run at log level "info". Set LOG_LEVEL=debug in environment variables to see extended debug logs.
ana@vm:~/linkbox$ jq -c .repositories.local.libYearsWithStatus.dependencyStatus /tmp/report.json
{"outdated":2,"total":18}
ana@vm:~/linkbox$ jq -c '.repositories.local.packageFiles[][] | .packageFile as $file | .deps[] | select(.updates | length > 0) | {$file, dep: .depName, to: (.updates[0].newVersion // .updates[0].newDigest), waiting: (.updates[0].pendingChecks // false)}' /tmp/report.json
{"file":"Dockerfile","dep":"python","to":"3.15","waiting":true}
{"file":".github/workflows/ci.yml","dep":"ubuntu","to":"26.04","waiting":true}
```

O Renovate achou mais que o lock Python: quatro arquivos e 18 dependências, os 13 pins dos dois
arquivos de requisitos, as duas imagens base do `Dockerfile` e três entradas do workflow da aula 16.
**Nenhum dos 13 pins Python está desatualizado**, que é o que a aula 15 deveria deixar: o lock foi
compilado com `--exclude-newer 2026-10-16`. As duas que ele atualizaria estão em outro lugar: a
imagem base `python`, de 3.13 para 3.15, e o runner `ubuntu` que o workflow nomeia, para 26.04. As
duas dizem `waiting: true`, então o `minimumReleaseAge` as está segurando, e as duas são o tipo de
mudança que nenhuma regra deveria aceitar sozinha: um Python novo debaixo de cada linha do linkbox, e
um sistema operacional novo debaixo de cada job.

Duas linhas do log tratam do que ele não conseguiu fazer. O `WARN` diz que duas actions não puderam
ser consultadas sem um token do GitHub; numa plataforma hospedada o Renovate tem um, e na sua
máquina você só lhe daria um para isso. O `MetadataLookupWarning` vem de uma biblioteca dentro do
Renovate que procura o serviço de metadados de um provedor de nuvem, não acha nenhum num laptop e não
muda nada. A sua execução vai ter números diferentes desta, porque os índices mudam todo dia; esse é
justamente o motivo de rodar um bot toda semana.

### Um lock compilado um mês antes

Para ver o Renovate propor alguma coisa, o repositório precisa de um lock atrasado. Uma branch
consegue um honestamente: compilar os mesmos arquivos `.in` com uma data anterior, como alguém teria
feito em 20 de setembro.

```
ana@vm:~/linkbox$ git switch -c stale-lock
Switched to a new branch 'stale-lock'
ana@vm:~/linkbox$ uv pip compile -q requirements.in --generate-hashes --exclude-newer 2026-09-20 -o requirements.txt
ana@vm:~/linkbox$ uv pip compile -q requirements-dev.in --generate-hashes --exclude-newer 2026-09-20 -o requirements-dev.txt
ana@vm:~/linkbox$ git diff --stat
 requirements-dev.txt |  14 +--
 requirements.txt     | 250 +++++++++++++++++++--------------------------------
 2 files changed, 101 insertions(+), 163 deletions(-)
ana@vm:~/linkbox$ git commit -q -am "the lock as it was compiled on 20 September"
10:17AM INF 0 commits scanned.
10:17AM INF scanned ~8350 bytes (8.35 KB) in 191ms
10:17AM INF no leaks found
```

Quatro pacotes resolvem para versões mais antigas nessa data, e todos os outros pins continuam iguais.
Agora rode o Renovate na branch e peça ao relatório toda dependência que tem atualização:

```
ana@vm:~/linkbox$ npx --yes renovate@44.164.10 --platform=local --report-type=file --report-path=/tmp/report.json >/tmp/renovate.log 2>&1
ana@vm:~/linkbox$ jq -c '.repositories.local.packageFiles[][] | .packageFile as $file | .deps[] | select(.updates | length > 0) | {$file, dep: .depName, to: (.updates[0].newVersion // .updates[0].newDigest), waiting: (.updates[0].pendingChecks // false)}' /tmp/report.json
{"file":"Dockerfile","dep":"python","to":"3.15","waiting":true}
{"file":".github/workflows/ci.yml","dep":"ubuntu","to":"26.04","waiting":true}
{"file":"requirements-dev.txt","dep":"iniconfig","to":"2.3.1","waiting":false}
{"file":"requirements-dev.txt","dep":"pluggy","to":"1.7.0","waiting":true}
{"file":"requirements.txt","dep":"markupsafe","to":"3.0.4","waiting":false}
{"file":"requirements.txt","dep":"werkzeug","to":"3.1.9","waiting":false}
ana@vm:~/linkbox$ git status --short
```

Cada linha é um pull request que o Renovate abriria numa plataforma de verdade, com a versão para a
qual moveria. As duas primeiras são as que `main` já tinha; as outras quatro são o lock de um mês
atrás. **`waiting: true` é a espera funcionando**: o pluggy 1.7.0 foi publicado em 15 de
outubro, oito dias antes desta gravação, e o `minimumReleaseAge` o segura até ter catorze dias. Os
outros três do lock estão públicos há mais tempo e seriam propostos agora. O último comando importa tanto quanto o
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

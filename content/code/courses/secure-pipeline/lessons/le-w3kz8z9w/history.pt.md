---
title: Reescrever o histórico, e registrar um segredo morto
version: 1
---

O Git consegue reescrever o histórico: trocar um valor em todo commit que o guarda, como se ele nunca
tivesse entrado num commit. Parece a correção, e é o passo feito com mais frequência primeiro e com
pressa. **Uma reescrita muda a sua cópia do histórico e nenhuma outra**, e o problema são as cópias.

### O que uma reescrita faz

`git filter-repo` é a ferramenta que a própria documentação do Git recomenda para isso, no lugar do
antigo `git filter-branch`. Ela se recusa a rodar em qualquer lugar que não seja um clone recém-feito,
para que um erro custe um clone e não o seu trabalho. Experimente num clone descartável, com uma
regra que troca o token onde quer que ele apareça. O `uvx` roda a ferramenta a partir do PyPI sem
instalá-la:

```
ana@vm:~/linkbox$ git clone -q ~/linkbox ~/rewritten && cd ~/rewritten
ana@vm:~/rewritten$ echo "regex:lbx_[A-Za-z0-9]+==>REMOVED" > ~/replace.txt
ana@vm:~/rewritten$ uvx --from git-filter-repo==2.47.0 git-filter-repo --replace-text ~/replace.txt
NOTICE: Removing 'origin' remote; see 'Why is my origin removed?'
        in the manual if you want to push back there.
        (was /home/ana/linkbox)

Parsed 6 commitsHEAD is now at deab516 the token out of the code, and a token of their own for the tests

New history written in 0.08 seconds; now repacking/cleaning...
Repacking your repo and cleaning out old unneeded objects
Completely finished after 0.18 seconds.
ana@vm:~/rewritten$ git log --oneline
deab516 the token out of the code, and a token of their own for the tests
166654d dependencies moved past their advisories, and composition analysis in the pipeline
f4a5d0c the security headers the baseline scan asked for, and the scan in the nightly run
23ffe39 static analysis in the pipeline, and the two findings it made fixed
4ef17f7 the pipeline takes a list: every push, and the nightly run
b6e2333 linkbox as it was handed over
ana@vm:~/rewritten$ git -C ~/linkbox log --oneline
cb77d44 the token out of the code, and a token of their own for the tests
19d0738 dependencies moved past their advisories, and composition analysis in the pipeline
d1186df the security headers the baseline scan asked for, and the scan in the nightly run
3afa289 static analysis in the pipeline, and the two findings it made fixed
ed9bbb4 the pipeline takes a list: every push, and the nightly run
3f932db linkbox as it was handed over
ana@vm:~/rewritten$ git show $(git rev-list --max-parents=0 HEAD):settings.py
import os

DATABASE = os.environ.get("LINKBOX_DB", "linkbox.db")
ADMIN_TOKEN = "REMOVED"
ana@vm:~/rewritten$ git -C ~/ci/linkbox.git grep -c lbx_7Rq2 main -- settings.py
main:settings.py:1
ana@vm:~/rewritten$ cd ~/linkbox && rm -rf ~/rewritten ~/replace.txt
```

Três coisas nessa saída são o argumento inteiro.

**Todo commit tem um hash novo.** `b6e2333` onde o seu repositório tem `3f932db`, e assim por diante
até o mais recente. O hash de um commit cobre o conteúdo e o pai dele, então mudar o primeiro commit
muda todos os que vêm depois. Todo clone, todo fork, todo branch aberto e toda execução de CI que
cita um commit agora cita um que o histórico reescrito não tem. Cada uma dessas pessoas tem de jogar
o clone fora e clonar de novo, e um branch que alguém esqueceu de rebasear traz os commits antigos,
com token e tudo, de volta no próximo push.

**O clone reescrito não sabe mais de onde veio.** O filter-repo removeu o remote `origin` de
propósito: enviar um histórico reescrito exige um push forçado, que é uma decisão a ser tomada por
uma pessoa, depois de avisar todo mundo que tem um clone.

**O servidor ainda tem o token**, porque a reescrita aconteceu num clone e o servidor é outro. Um
push forçado substituiria os branches lá, e ainda deixaria os forks, os backups e todos os laptops.
Numa plataforma hospedada há mais: a documentação do GitHub sobre remover dados sensíveis diz que
visualizações em cache e as referências de pull requests podem manter os commits antigos alcançáveis
até que o suporte deles os remova, e que forks não são afetados de jeito nenhum. Nada disso foi
executado neste curso.

### Então ela vem por último, e muitas vezes nem vem

Depois que o valor foi revogado, as cópias guardam algo que não abre nada. **Reescrever então rende
pouco**: um scanner para de apontá-lo, ao preço de todos os clones. Reescrever vale esse preço quando
o que entrou no commit não pode ser revogado: dados pessoais, o arquivo de um cliente, a chave
privada de um certificado em que outra pessoa já confia. Aí a reescrita faz parte de limitar o
estrago, feita junto com todo mundo que guarda uma cópia, e mesmo assim não é motivo para pular a
revogação.

O token do linkbox foi revogado na seção anterior. O histórico fica como está.

### Registrando o achado morto

A varredura do histórico ainda aponta o token, e vai apontar em toda execução enquanto o repositório
existir. **Um achado que foi tratado tem de ficar registrado como tratado**, ou o pipeline quebra por
causa dele para sempre e alguém, um dia, desliga o estágio. O gitleaks lê um arquivo chamado
`.gitleaksignore` na raiz do repositório: um fingerprint por linha, e os achados que ele nomeia
ficam fora do relatório.

O fingerprint é a última linha do achado na varredura do histórico, duas seções atrás. **Pegue o da
sua própria saída**, não o desta página: ele começa pelo hash do seu primeiro commit, que não é
`3f932db`. Depois escreva, acima dele, por que o achado está morto e desde quando, com a data em que
você fez a rotação do seu. Salve como `.gitleaksignore`:

```
# Findings that are dead: each one is a secret that was rotated, so the value
# in the history opens nothing any more. One fingerprint per line.
#
# The administration token committed with the first version of settings.py,
# revoked and replaced on 2026-10-12.
3f932db1ab33201959dc1dd9270d46dc0485e297:settings.py:generic-api-key:4
```

```
ana@vm:~/linkbox$ gitleaks git --no-banner --no-color .
2:00AM INF Unknown SCM platform. Use --platform to include links in findings. host=
2:00AM INF 6 commits scanned.
2:00AM INF scanned ~9214 bytes (9.21 KB) in 285ms
2:00AM INF no leaks found
ana@vm:~/linkbox$ git add .gitleaksignore
ana@vm:~/linkbox$ git commit -q -m "the rotated token, recorded as a dead finding"
```

**O fingerprint nomeia um achado, não uma regra nem um arquivo.** Um segredo novo acrescentado a
`settings.py` amanhã tem outro commit no fingerprint e é apontado como qualquer outro. Essa é a
diferença entre este arquivo e desligar `generic-api-key`, e é por isso que o comentário diz o que foi
feito em vez de "falso positivo": o achado era verdadeiro, e o valor está morto porque alguém o
matou.

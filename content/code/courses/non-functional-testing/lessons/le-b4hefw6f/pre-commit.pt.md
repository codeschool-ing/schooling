---
title: Um hook que recusa o commit
version: 1
---

Tudo até aqui achou a chave depois do commit. **O lugar mais barato para barrar um segredo é um
passo antes, quando o commit ainda não existe**, porque um commit que nunca foi feito não precisa de
troca de chave nem de histórico reescrito. O git consegue rodar um programa escolhido por você nesse
momento, um **hook de pre-commit**, e recusar o commit quando o programa falha.

## O hook

Um hook é um arquivo executável em `.git/hooks/`, com o nome do momento em que roda. Em `~/leaky`,
abra `nano .git/hooks/pre-commit`, cole isto e torne-o executável com o `chmod` abaixo:

```sh
#!/bin/sh
# leaky/.git/hooks/pre-commit
# Refuses the commit when what is staged looks like a secret. Prints no secret.
exec gitleaks git --pre-commit --staged --redact --verbose --no-banner --no-color
```

`--pre-commit --staged` diz ao gitleaks para ler **só o que está prestes a entrar no commit**, as
mudanças no stage, e não o histórico; é isso que deixa o hook tão rápido quanto um commit deve ser.
O `--redact` mantém o valor fora do terminal, e o `--verbose` diz que arquivo e que linha corrigir.
O `exec` devolve o código de saída do gitleaks direto ao git, e um código diferente de 0 é uma
recusa.

Agora repita o erro daquela tarde: copie a chave para o arquivo de configuração para experimentar o
provedor, e faça o commit.

```
ana@nft:~/leaky$ chmod +x .git/hooks/pre-commit
ana@nft:~/leaky$ grep KEY payment.env >> settings.ini
ana@nft:~/leaky$ git commit -am "try the payment provider"
Finding:     PAYMENT_API_KEY=REDACTED
Secret:      REDACTED
RuleID:      generic-api-key
Entropy:     4.875000
File:        settings.ini
Line:        7
Fingerprint: settings.ini:generic-api-key:7

4:53PM INF 0 commits scanned.
4:53PM INF scanned ~49 bytes (49 bytes) in 57ms
4:53PM WRN leaks found: 1
ana@nft:~/leaky$ git status --short
 M settings.ini
ana@nft:~/leaky$ git restore settings.ini
```

**O commit foi recusado.** O git não imprimiu nada seu; o achado é a saída do hook, com o valor
ocultado, o arquivo e a linha. O `git status` mostra o `settings.ini` ainda modificado e fora de
commit, e o `git restore` o devolve como o último commit o deixou. Nada chegou ao histórico, então
não há nada para trocar.

## Um hook é uma comodidade, não um controle

Dois fatos impedem o hook de ser a resposta inteira. **Ele mora em `.git/`, que não faz parte do
repositório**, então um clone novo não tem hook até alguém instalar um; e **qualquer um pode
pulá-lo** com `--no-verify`, que existe por bons motivos e é usado por maus. Veja o que isso deixa
para trás, e o que pega:

```
ana@nft:~/leaky$ grep KEY payment.env >> settings.ini
ana@nft:~/leaky$ git commit -q --no-verify -am "try the payment provider"
ana@nft:~/leaky$ gitleaks git --no-banner --no-color --redact
4:53PM INF 4 commits scanned.
4:53PM INF scanned ~310 bytes (310 bytes) in 50.5ms
4:53PM WRN leaks found: 2
ana@nft:~/leaky$ git reset -q --hard HEAD~1
ana@nft:~/leaky$ git log --oneline
7734329 keep env files out of the repository
d35bad3 take the key out of the settings
ad0a6bc payment settings
```

O commit entrou. A varredura do histórico, a que deve rodar no pipeline a cada push, **agora aponta
dois vazamentos**: o antigo, em `ad0a6bc`, e o novo. Essa é a camada que não depende da máquina de
ninguém nem da disciplina de ninguém. É por isso que uma equipe roda as duas: o hook para que a
maior parte dos erros nunca vire commit, o pipeline para que os que viram nunca cheguem ao branch
compartilhado sem ninguém notar.

Os dois últimos comandos tiram o commit ruim. **Isso só é seguro porque ele nunca foi enviado**: o
`git reset` reescreve o histórico só nesta máquina, e ninguém mais tem uma cópia. Se tivesse sido
enviado, esta seria a situação de "Como uma chave vai parar num repositório", e o primeiro passo
seria trocar a chave.

Equipes que querem o hook em toda máquina usam o framework pre-commit, de pre-commit.com, que instala
hooks a partir de um arquivo versionado no repositório; o gitleaks publica um hook para ele. Ele
baixa os hooks do GitHub, então não foi executado aqui, e não muda nada do que está acima: o hook
continua rodando numa máquina que alguém controla, e o pipeline continua sendo a verificação que
vale.

## Um achado que já foi tratado

Resta um achado, e ele vai ser apontado a cada push enquanto o histórico existir: `ad0a6bc`, a
chave que entrou e foi apagada no começo desta aula. Suponha que ela fosse real e tivesse sido
trocada hoje de manhã. O histórico ainda a guarda, a varredura ainda tem razão em dizer isso, e um
pipeline que falha a cada push ensina todo mundo a ignorá-lo.

A resposta é registrar que esse achado em particular foi tratado, pela impressão digital dele, num
arquivo `.gitleaksignore` versionado ao lado do código, com uma linha dizendo o que foi feito e por
quem:

```
ana@nft:~/leaky$ printf '%s\n' '# The payment key of ad0a6bc was revoked and replaced on 2026-10-01 (ana).' 'ad0a6bc9d70d4677797a3da73054ec968696f1b0:settings.ini:generic-api-key:7' > .gitleaksignore
ana@nft:~/leaky$ cat .gitleaksignore
# The payment key of ad0a6bc was revoked and replaced on 2026-10-01 (ana).
ad0a6bc9d70d4677797a3da73054ec968696f1b0:settings.ini:generic-api-key:7
ana@nft:~/leaky$ git add .gitleaksignore && git commit -q -m "record the revoked payment key"
4:53PM INF 0 commits scanned.
4:53PM INF scanned ~147 bytes (147 bytes) in 49.2ms
4:53PM INF no leaks found
ana@nft:~/leaky$ gitleaks git --no-banner --no-color; echo "exit $?"
4:53PM INF 4 commits scanned.
4:53PM INF scanned ~408 bytes (408 bytes) in 46.9ms
4:53PM INF no leaks found
exit 0
```

O commit do `.gitleaksignore` passou pelo hook, que o varreu e não achou nada. A varredura do
histórico agora não aponta **nenhum vazamento e sai com 0**, e todo achado novo continua a
reprová-la, porque a impressão digital nomeia um commit, um arquivo, uma regra e uma linha. Essa é a
diferença entre aceitar um achado conhecido e desligar a regra. O mesmo arquivo é onde vai um falso
positivo revisado, um valor que casou com uma regra e não é segredo, sempre com o motivo ao lado.

**Cada linha de um `.gitleaksignore` é uma decisão que alguém tomou, e o arquivo é revisado como
código.** Uma impressão digital acrescentada sem motivo, ou para uma chave que nunca foi trocada, é
o buraco que o pipeline foi construído para fechar.

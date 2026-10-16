---
title: Varrendo os arquivos e o histórico
version: 1
---

O **gitleaks** é um scanner de segredos: um único programa que lê texto e aponta o que parece uma
chave, um token ou uma senha, segundo uma lista de regras. Algumas regras conhecem o formato exato
das chaves de um provedor; uma delas, `generic-api-key`, procura um nome como `api_key` ou `secret`
seguido de um valor aleatório o bastante para ser uma. Ele lê três tipos de entrada, e cada um é um
subcomando:

| | lê | use para |
|---|---|---|
| `gitleaks dir` | os arquivos no disco, como estão agora | um diretório, a saída de um build, uma cópia da configuração de um servidor |
| `gitleaks git` | todo commit do histórico de um repositório | o repositório, a cada push, e uma vez sobre tudo o que ele já guardou |
| `gitleaks stdin` | o que chegar por um pipe | um log, um arquivo só, a conferência rápida de uma linha |

## Instalando

O gitleaks é um programa só, publicado para cada sistema na página de releases do GitHub. Na VM:

```sh
curl -fsSLO https://github.com/gitleaks/gitleaks/releases/download/v8.30.1/gitleaks_8.30.1_linux_x64.tar.gz
tar -xzf gitleaks_8.30.1_linux_x64.tar.gz gitleaks
sudo install gitleaks /usr/local/bin/
```

Num Mac com Apple silicon, o arquivo é `gitleaks_8.30.1_linux_arm64.tar.gz`. **Essas três linhas
não foram executadas para este curso**, porque o computador em que ele foi gravado não alcança o
GitHub; o gitleaks das transcrições foi compilado a partir do mesmo código-fonte da v8.30.1. Confira
que o seu responde:

```
ana@nft:~$ gitleaks version
v8.30.1
```

## Um repositório com um erro dentro

Crie um repositório descartável chamado `leaky`, na sua pasta pessoal e não dentro de
`~/boxoffice`. As duas linhas de `export` fixam o autor e a data de todo commit que você fizer neste
terminal, para que os seus hashes de commit saiam iguais aos impressos aqui. Um repositório de
verdade nunca faz isso; está aqui para que as transcrições e a sua tela possam ser comparadas linha
a linha.

```
ana@nft:~$ mkdir -p ~/leaky && cd ~/leaky
ana@nft:~/leaky$ git init -q -b main
ana@nft:~/leaky$ export GIT_AUTHOR_NAME=ana GIT_AUTHOR_EMAIL=ana@nft.test GIT_COMMITTER_NAME=ana GIT_COMMITTER_EMAIL=ana@nft.test
ana@nft:~/leaky$ export GIT_AUTHOR_DATE=2026-10-01T10:00:00-03:00 GIT_COMMITTER_DATE=2026-10-01T10:00:00-03:00
```

Crie o arquivo de configuração com `nano settings.ini` e cole isto. A chave são letras e dígitos
aleatórios, inventados para esta aula, e nenhum provedor jamais a emitiu:

```ini
# leaky/settings.ini
# The box office's payment settings. The key below was made up for lesson 18
# and was never issued by anybody.
[payment]
url = https://payments.example.test/v1
timeout_seconds = 5
payment_api_key = "nft7Zq2vRmX9kLp4Tn8Wc3Yb6Hd1Jf5G"
```

Depois faça o commit:

```
ana@nft:~/leaky$ git add settings.ini && git commit -q -m "payment settings"
ana@nft:~/leaky$ git log --oneline
ad0a6bc payment settings
```

Esse é o erro, no histórico. Agora o conserto de sempre: alguém percebe, apaga a linha e faz outro
commit. O `sed` abaixo apaga a linha; fazer isso à mão no `nano` dá no mesmo.

```
ana@nft:~/leaky$ sed -i '/payment_api_key/d' settings.ini
ana@nft:~/leaky$ git commit -q -am "take the key out of the settings"
ana@nft:~/leaky$ git log --oneline
d35bad3 take the key out of the settings
ad0a6bc payment settings
```

## Duas varreduras, duas respostas

Pergunte primeiro ao gitleaks sobre o diretório, que é o que uma varredura dos arquivos no disco
enxerga:

```
ana@nft:~/leaky$ gitleaks dir --no-banner --no-color; echo "exit $?"
4:53PM INF scanned ~202 bytes (202 bytes) in 3.4ms
4:53PM INF no leaks found
exit 0
```

**Nenhum vazamento, e código de saída 0.** O arquivo de configuração não tem mais a chave, e o
diretório `.git`, onde mora o histórico, não está entre os arquivos que o `dir` lê. Agora pergunte
sobre o histórico:

```
ana@nft:~/leaky$ gitleaks git --no-banner --no-color --verbose; echo "exit $?"
Finding:     payment_api_key = "nft7Zq2vRmX9kLp4Tn8Wc3Yb6Hd1Jf5G"
Secret:      nft7Zq2vRmX9kLp4Tn8Wc3Yb6Hd1Jf5G
RuleID:      generic-api-key
Entropy:     4.875000
File:        settings.ini
Line:        7
Commit:      ad0a6bc9d70d4677797a3da73054ec968696f1b0
Author:      ana
Email:       ana@nft.test
Date:        2026-10-01T13:00:00Z
Fingerprint: ad0a6bc9d70d4677797a3da73054ec968696f1b0:settings.ini:generic-api-key:7

4:53PM INF 2 commits scanned.
4:53PM INF scanned ~255 bytes (255 bytes) in 44.2ms
4:53PM WRN leaks found: 1
exit 1
ana@nft:~/leaky$ git show HEAD~1:settings.ini | grep key
# The box office's payment settings. The key below was made up for lesson 18
payment_api_key = "nft7Zq2vRmX9kLp4Tn8Wc3Yb6Hd1Jf5G"
```

O mesmo repositório, e desta vez **um vazamento, no commit `ad0a6bc`**, o primeiro, na linha 7 do
`settings.ini`. O código de saída é 1, e é isso que permite a um pipeline falhar sem ler uma
palavra. O `git show` prova o que o scanner está dizendo: o segundo commit tirou a linha do arquivo,
e o primeiro commit ainda a tem, para quem pedir.

Cada achado traz as mesmas informações, e são os campos de que um relatório de vazamento precisa:

- **`RuleID`** diz que regra casou, aqui a genérica. Uma regra com o nome de um provedor, como a das
  chaves de acesso de uma plataforma de nuvem, é uma evidência mais forte que um casamento genérico.
- **`Entropy`** mede quão aleatório é o valor. 4.875 é alto, a nota de algo gerado e não digitado,
  e é por isso que uma regra genérica confia nele.
- **`Commit`, `Author`, `Date`** dizem quando a chave chegou e a quem perguntar.
- **`Fingerprint`** é a identidade do achado: commit, arquivo, regra e linha. É o que você anota
  quando um achado já foi tratado, que é o que "Um hook que recusa o commit" faz.

## Por que a chave falsa parece verdadeira

Um scanner que apontasse cada `api_key = "changeme"` de cada tutorial seria desligado em uma semana.
Por isso o gitleaks pula valores que contêm palavras como `fake` ou `example`, e um valor de teste
precisa parecer verdadeiro para ser achado:

```
ana@nft:~/leaky$ echo 'payment_api_key = "fake-7Zq2vRmX9kLp4Tn8Wc3Yb6Hd1Jf5G"' | gitleaks stdin --no-banner --no-color
4:53PM INF scanned ~55 bytes (55 bytes) in 38ms
4:53PM INF no leaks found
ana@nft:~/leaky$ echo 'payment_api_key = "lesson18-7Zq2vRmX9kLp4Tn8Wc3Yb6Hd"' | gitleaks stdin --no-banner --no-color
4:53PM INF scanned ~54 bytes (54 bytes) in 37.7ms
4:53PM WRN leaks found: 1
```

**A primeira linha não é apontada e a segunda é**, e a única diferença é uma palavra no valor. Isso
é uma comodidade para repositórios reais, cheios de valores de exemplo, e uma armadilha para um
teste: uma verificação escrita com um valor obviamente falso só prova que o gitleaks o ignora. É
também por isso que a chave no `settings.ini` são caracteres aleatórios, e a palavra dizendo que ela
é inventada está no comentário acima, onde a regra não olha.

## Quando ele acha uma de verdade

O que fazer é a ordem de "Como uma chave vai parar num repositório", e nada nela é um comando do git
até o fim. **Troque a chave primeiro**: revogue-a no provedor e implante uma nova, porque é esse o
passo que torna inofensiva toda cópia do histórico. Depois leia o log do provedor sobre o uso da
chave antiga. Só então decida se vai reescrever o histórico com `git filter-repo` ou com o BFG
Repo-Cleaner, sabendo que isso muda todo hash daquele commit em diante e não recolhe nenhum clone.
Nesta aula a chave nunca foi real, então não há nada para trocar, e o `leaky` fica com o histórico
como está.

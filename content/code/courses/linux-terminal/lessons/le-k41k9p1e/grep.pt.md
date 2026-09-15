---
title: O `grep`, e as seis opções que cobrem quase tudo
version: 1
---

O `grep` imprime as linhas que casam. É só isso que ele faz, e é o comando que você vai digitar mais
do que qualquer outro desta aula.

```
ana@vm:~/work$ grep -c " 500 " logs/access.log
21
ana@vm:~/work$ grep -n "/admin" logs/access.log | head -3
165:10.0.1.33 - - [14/Sep/2026:07:59:27 +0000] "GET /admin HTTP/1.1" 403 16628 "kube-probe/1.29" 115
433:10.0.1.24 - - [14/Sep/2026:11:20:59 +0000] "GET /admin HTTP/1.1" 403 21827 "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)" 98
449:203.0.113.5 - - [14/Sep/2026:11:31:01 +0000] "GET /admin HTTP/1.1" 403 20646 "python-requests/2.32.3" 46
```

## As seis

| | |
|---|---|
| `-i` | ignorar maiúsculas e minúsculas |
| `-v` | **inverter**: imprimir as linhas que *não* casam |
| `-c` | contar **linhas** que casam |
| `-n` | prefixar cada uma com o número da linha |
| `-r` | descer em diretórios |
| `-l` | imprimir só os **nomes** dos arquivos que casaram |

```
ana@vm:~/work$ grep -c -v " 200 " logs/access.log
167
ana@vm:~/work$ grep -i "GOOGLEBOT" logs/access.log | wc -l
159
ana@vm:~/work$ grep -l "admin" logs/*.log
logs/access.log
ana@vm:~/work$ grep -r "app started" logs/ | head -3
logs/app.log:app started
logs/app.log:app started
logs/app.log:app started
```

**O `-v` é o que faz mais trabalho na prática.** A maioria das investigações é "tudo menos o
barulho", e o `grep -v` encadeado duas ou três vezes é como isso se escreve.

**O `-l` é para achar qual arquivo**, não o que tem nele. O `grep -rl TODO src/` te dá uma lista de
nomes que você pode passar para outra coisa — que é o `xargs` da seção 134.

E repare que o `grep -r logs/` imprimiu `logs/app.log:` na frente de cada linha. **O `grep` prefixa o
nome do arquivo sempre que está buscando em mais de um**, o que ajuda na tela e atrapalha num
pipeline. O `-h` desliga; o `-H` liga à força mesmo para um arquivo só.

## O `-c` conta linhas, não ocorrências

```
ana@vm:~/work$ grep -c o <<< "hello world"
1
```

Uma linha, dois `o`, e a resposta é 1. **O `grep -c` é uma contagem de linhas**, sempre.

Para contar ocorrências você precisa do `-o`, que imprime cada correspondência numa linha própria:

```
ana@vm:~/work$ grep -o "GET\|POST\|PUT\|DELETE" logs/access.log | sort | uniq -c
     28 DELETE
    975 GET
    167 POST
     30 PUT
```

**O `-o` é como o `grep` vira um extrator** em vez de um filtro. Combinado com `sort | uniq -c` ele
responde "com que frequência cada um destes aparece", que é uma pergunta para a qual as pessoas
escrevem um script.

## Contexto

```
ana@vm:~/work$ grep -A1 -B1 " 500 " logs/access.log | head -6
10.0.1.33 - - [14/Sep/2026:06:08:07 +0000] "GET /health HTTP/1.1" 200 3411 "kube-probe/1.29" 42
10.0.1.21 - - [14/Sep/2026:06:09:02 +0000] "POST /api/reports HTTP/1.1" 500 18487 "curl/8.5.0" 5833
10.0.1.36 - - [14/Sep/2026:06:09:03 +0000] "GET / HTTP/1.1" 200 20657 "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/131.0 Safari/537.36" 79
--
198.51.100.9 - - [14/Sep/2026:06:45:22 +0000] "GET / HTTP/1.1" 200 7628 "kube-probe/1.29" 52
198.51.100.17 - - [14/Sep/2026:06:45:55 +0000] "GET /favicon.ico HTTP/1.1" 500 5887 "kube-probe/1.29" 129
```

O `-A` depois, o `-B` antes, o `-C` os dois. O `--` é o `grep` separando grupos não adjacentes.

**Esta é a opção para ler um stack trace.** A linha com `Exception` raramente é a útil; o
`grep -A20 Exception app.log` é.

## O código de saída é o ponto

```
ana@vm:~/work$ grep -q " 500 " logs/access.log; echo "found 500s: $?"
found 500s: 0
ana@vm:~/work$ grep -q " 418 " logs/access.log; echo "found 418s: $?"
found 418s: 1
```

O `-q` não imprime nada e sai com 0 ou 1. **Isso faz do `grep` uma pergunta em vez de uma fonte de
texto**, e é como um script pergunta "isto está no arquivo":

```
if grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config; then ...
```

O aviso da seção 99 se aplica aqui: sob `set -e`, um `grep` que não acha nada para o script, porque
"sem correspondência" é um código diferente de zero. Num `if`, ou com `|| true`, está tudo bem.

## Qual grep você está rodando

Há três linguagens de padrão e a opção escolhe uma:

| | |
|---|---|
| `grep` | expressões regulares básicas — `+`, `?`, `\|`, `()` precisam de contrabarra |
| `grep -E` | **estendidas** — aqueles caracteres funcionam como eles mesmos. Igual ao `egrep` |
| `grep -F` | **strings fixas** — sem linguagem de padrão nenhuma. Igual ao `fgrep` |

```
ana@vm:~/work$ grep -E "^10\.0\.1\.[0-9]+ " logs/access.log | wc -l
651
ana@vm:~/work$ grep -F "." logs/access.log | wc -l
1200
```

A segunda é a demonstração: **o `-F` fez do ponto um ponto comum**, então ele casou com toda linha
que contém um ponto final, que são todas. Sem o `-F`, o `.` é "qualquer caractere" e também teria
casado com todas — a mesma resposta por outro motivo, que é exatamente por que isso merece ser
deliberado.

**Use o `-E` por padrão.** A sintaxe básica é um acidente histórico, e escrever `\(` e `\|` é um
imposto sem benefício. **Use o `-F` quando o padrão é entrada de usuário ou contém pontos, colchetes
ou barras** — buscar um endereço IP, um número de versão ou um caminho é o caso comum, e o `-F` é ao
mesmo tempo correto e mais rápido.

A seção 125 é a própria linguagem de padrões.

## Mais dois que valem

**O `grep -w`** casa palavras inteiras, então o `grep -w cat` não casa com `category`. É a opção que
as pessoas reinventam com `\b` e é mais curta.

**O `grep --include`** estreita uma busca recursiva por nome de arquivo: o
`grep -r --include='*.py' TODO .` busca só em arquivos python. Numa árvore grande é a diferença
entre uma busca e um cafezinho.

E o `ripgrep` — `rg` — é o substituto moderno: mesma ideia, muito mais rápido, respeita o
`.gitignore`, e busca recursivamente por padrão. Ele não está instalado em todo lugar, que é por que
esta seção é sobre o `grep`. Onde você o tiver, use.

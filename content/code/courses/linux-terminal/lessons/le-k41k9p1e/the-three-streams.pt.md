---
title: Três fluxos, e por que dois deles parecem o mesmo
version: 2
---

## Antes, os arquivos que esta aula lê

Todo comando desta aula lê o `~/work` da aula 3, e dois arquivos nele são novos: um dia do log de um
servidor web, `logs/access.log`, com mil e duzentas linhas, e um ano de vendas, `data/sales.csv`.
Um log de verdade carrega endereços de pessoas de verdade, então estes são feitos por um programa
curto. Copie o bloco inteiro para o terminal; ele escreve o programa em `make-data.py` e o roda:

```sh
cd ~/work
cat > make-data.py <<'END'
#!/usr/bin/env python3
"""Write the two files lesson 8 reads: a day of a web server's log, and a year of sales.

The same seed gives the same files on every machine, so your numbers match the page's."""
import random

r = random.Random(8)

# (method, path, how often), and who asks for it
pages = [("GET", "/health", 24), ("GET", "/", 22), ("POST", "/api/orders", 12),
         ("GET", "/static/app.js", 9), ("GET", "/static/app.css", 9), ("GET", "/index.html", 6),
         ("GET", "/favicon.ico", 4), ("GET", "/api/users", 4), ("PUT", "/api/users", 3),
         ("DELETE", "/api/orders", 2), ("POST", "/api/orders/new", 2), ("GET", "/admin", 1),
         ("POST", "/api/reports", 2)]
agents = ["Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/131.0 Safari/537.36",
          "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 Safari/18.1",
          "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)",
          "curl/8.5.0", "python-requests/2.32.3"]
codes = [200] * 86 + [201] * 5 + [404] * 3 + [302] * 2 + [304] * 2 + [500] * 2

t = 6 * 3600 + 60  # 06:01:00
with open("logs/access.log", "w") as log:
    for _ in range(1200):
        t += r.randint(1, 59)
        when = f"14/Sep/2026:{t // 3600:02}:{t // 60 % 60:02}:{t % 60:02} +0000"
        method, path, _ = r.choices(pages, weights=[p[2] for p in pages])[0]
        ip = r.choice(["10.0.1."] * 6 + ["198.51.100."] * 3 + ["203.0.113."]) + str(r.randint(2, 40))
        code = r.choice([401, 403]) if path == "/admin" else r.choice(codes)
        size = r.randint(300, 999) if path.startswith("/static") else r.randint(200, 24000)
        ms = r.randint(3001, 6000) if path == "/api/reports" else r.randint(5, 300)
        agent = "kube-probe/1.29" if path == "/health" else r.choice(agents)
        log.write(f'{ip} - - [{when}] "{method} {path} HTTP/1.1" {code} {size} "{agent}" {ms}\n')

with open("data/sales.csv", "w") as sales:
    sales.write("region,rep,quarter,units,revenue\n")
    for quarter in ["Q1", "Q2", "Q3", "Q4"]:
        for region, reps in [("north", "ana bruno"), ("south", "carla diego"),
                             ("east", "elena felipe"), ("west", "gabriel helena")]:
            for rep in reps.split():
                units = r.randint(20, 400)
                sales.write(f"{region},{rep},{quarter},{units},{units * r.randint(40, 130)}\n")
END
python3 make-data.py
```

**Você não precisa ler o programa ainda**; no fim da aula 9 você conseguiria escrever um parecido.
O que importa agora é que ele parte de uma semente fixa, então escreve os mesmos bytes em qualquer
máquina, e cada número destas páginas é o número que a sua vai imprimir. O `sha256sum` prova isso,
uma impressão digital por arquivo, e as suas devem bater com estas até o último caractere:

```
ana@vm:~/work$ sha256sum logs/access.log data/sales.csv
4f78595dfc41e21c0a33fb42785b91ed9cf724952850093324658fbb2daaeb91  logs/access.log
79775975672c3b0589a68e166bf50bd008a23d6579c4152e119018870a755759  data/sales.csv
```

## Os três fluxos

A aula 6 seção 13 te deu os números. Esta é para que eles servem.

Todo programa começa com três conexões já abertas, e ele não precisa pedir nenhuma delas:

| | | |
|---|---|---|
| `0` | **stdin** | de onde a entrada vem. O seu teclado, um arquivo, outro programa |
| `1` | **stdout** | para onde os **resultados** dele vão |
| `2` | **stderr** | para onde as **reclamações** dele vão |

**Tanto o `1` quanto o `2` caem na sua tela por padrão**, e é por isso que eles parecem uma coisa só.
Não são, e a seção seguinte inteira depende de você saber disso.

Aqui está a diferença, visível:

```
ana@vm:~/work$ ls logs nosuchdir
ls: cannot access 'nosuchdir': No such file or directory
logs:
access.log
app.log
app.log.1
empty.log
error.log
today.log
ana@vm:~/work$ ls logs nosuchdir > out.txt
ls: cannot access 'nosuchdir': No such file or directory
ana@vm:~/work$ cat out.txt
logs:
access.log
app.log
app.log.1
empty.log
error.log
today.log
```

Um comando, dois destinos. O `> out.txt` capturou a listagem e **o erro ficou na tela**, porque o `>`
redireciona a saída padrão e nada mais.

Isso não é uma esquisitice; é o projeto. Os resultados vão para onde um programa consegue lê-los; as
reclamações vão para onde uma pessoa consegue vê-las. Um pipeline que engolisse as próprias
mensagens de erro seria muito mais difícil de depurar do que um que não engole.

## E repare no que mudou de forma

Olhe aquelas duas saídas de novo. Na tela, o `ls` imprimiu os cinco nomes **ao longo da linha, em
colunas**. No arquivo, ele imprimiu **um por linha**.

**O `ls` pergunta se a saída dele é um terminal, e formata conforme a resposta** — a pergunta do
`isatty()` da aula 6. Colunas são para pessoas; um por linha é para programas.

Isso importa mais do que parece. Quer dizer que:

- o `ls | wc -l` conta arquivos corretamente, porque o `ls` mudou para um por linha por causa do
  pipe;
- e quer dizer que o que você viu na tela nem sempre é o que o comando seguinte recebeu.

A maioria das ferramentas não faz isso. O `ls`, o `grep` (cor) e o `ps` (largura) são os três que
você vai encontrar que fazem. **Quando um pipeline se comporta diferente do que você viu, esta é a
primeira coisa a suspeitar.**

## Para onde os fluxos vão de fato

O `$FDPID` é o `tail` da seção 13 da aula 6, iniciado com
`tail -f logs/app.log > /tmp/out.txt 2>/tmp/err.txt & FDPID=$!`; inicie-o de novo para olhar você
mesmo:

```
ana@vm:~/work$ ls -l /proc/$FDPID/fd
total 0
lr-x------ 1 ana ana 64 Sep 15 07:23 0 -> /dev/null
l-wx------ 1 ana ana 64 Sep 15 07:23 1 -> /tmp/out.txt
l-wx------ 1 ana ana 64 Sep 15 07:23 2 -> /tmp/err.txt
```

Essa é a transcrição da aula 6, e vale uma segunda olhada agora que os números querem dizer algo.
**Redirecionar não é um recurso do programa.** O programa escreve no descritor 1; o shell decidiu o
que o descritor 1 era, antes de o programa começar, na lacuna entre o `fork` e o `exec` da aula 6
seção 03.

Que é por que o `>` funciona em todo comando que já foi escrito, inclusive naqueles cujos autores
nunca pensaram em arquivos.

## Lendo da entrada padrão

A maioria das ferramentas desta aula aceita um nome de arquivo **ou** lê a entrada padrão se você não
der um:

```
wc -l logs/app.log        # from a file
wc -l < logs/app.log      # from stdin, redirected by the shell
cat logs/app.log | wc -l  # from stdin, through a pipe
```

Os três contam a mesma coisa. A diferença é só quem abre o arquivo:

```
ana@vm:~/work$ wc -l logs/app.log
30 logs/app.log
ana@vm:~/work$ wc -l < logs/app.log
30
```

**O `wc` imprimiu o nome do arquivo no primeiro e não no segundo**, porque no segundo ele nunca
soube de um. Isso é uma coisinha que pega as pessoas em scripts: o formato da saída mudou por causa
de como a entrada chegou.

**Um `-` como nome de arquivo quer dizer entrada padrão** em muitas ferramentas, que é como se
mistura as duas:

```
ana@vm:~/work$ printf "header\n" > /tmp/h.txt; printf "body\n" | cat /tmp/h.txt -
header
body
```

Um arquivo, e depois o que veio pelo pipe, nessa ordem — porque é essa a ordem em que os argumentos
estão.

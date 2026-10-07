---
title: O laboratório, e três maneiras de montá-lo
version: 1
---

**Ninguém aprende a limpar dados lendo sobre dados sujos.** Aprende-se na primeira vez em que um
total confiável acaba contando cem pedidos duas vezes, e esse momento só acontece com os arquivos
abertos na sua frente. Por isso toda aula é executada, e você deve executá-la também, numa máquina
que você mesmo monta. Esta seção monta a máquina, e a próxima faz os dados.

O laboratório é um computador Linux com quatro coisas:

- **os arquivos**, em `~/clean/raw`: nove exportações CSV dos sistemas da Quitanda Verde, deixadas
  somente leitura de propósito — a aula 17 diz por quê — e três pequenos arquivos de referência de
  fora da empresa em `~/clean/ref`;
- **PostgreSQL 16**, com um banco chamado `quitanda` e um schema chamado `raw` que guarda cada arquivo
  carregado exatamente como chegou, **toda coluna como texto**;
- **Python 3 com pandas**, num ambiente virtual, mais o RapidFuzz para a correspondência
  aproximada da aula 5 e o Matplotlib para os gráficos da aula 15;
- **R com dplyr**, que só a aula 16 usa.

## Três maneiras de ter um

| caminho | o que você ganha | quanto custa | as transcrições |
|---|---|---|---|
| **uma máquina virtual** (recomendado) | um Ubuntu 24.04 separado do seu sistema | alguns gigabytes de disco, e 2 GB de memória enquanto roda | batem como impressas |
| **instalado** | os mesmos programas no computador que você já usa | um servidor de banco de dados rodando no seu computador | batem no Ubuntu 24.04; perto disso nos outros |
| **online** | uma máquina Linux no navegador | nada no seu computador; horas de uma cota mensal | perto, não exatas |

**A máquina virtual é o caminho recomendado.** A montagem acrescenta um servidor de banco de dados e
pacotes do sistema, que é o tipo de mudança que você talvez não queira no computador em que
trabalha, e um snapshot tirado quando ela termina dá um recomeço limpo sempre que um experimento
der errado. A aula 4 do `virtualization` monta uma no VirtualBox, se você ainda não tem. No
Windows, o WSL rodando Ubuntu 24.04 também é uma máquina virtual, e funciona do mesmo jeito. Dê à
máquina o nome `lab`, se quiser: toda transcrição aqui imprime `ana@lab`, em que `ana` é a analista
e `lab` a máquina. A sua vai imprimir o seu próprio nome.

**Instalado** serve num computador que já roda Ubuntu 24.04, com os mesmos comandos. No macOS ou em
outro Linux os programas são os mesmos e os nomes dos pacotes mudam; isso não foi executado aqui,
então uma versão ou um caminho numa transcrição pode diferir do seu.

**Online**, o GitHub Codespaces dá uma máquina Linux com terminal no navegador. Não custa nada ao
seu computador; o GitHub dá às contas pessoais uma cota mensal e cobra o que passar dela, em termos
que ele define e pode mudar. Não foi usado neste curso. Qual Linux o codespace roda decide se os
comandos abaixo funcionam como impressos, e `cat /etc/os-release` diz isso antes de você começar.

## Montando

Tudo abaixo é digitado num terminal da máquina que você escolheu. Primeiro os programas, dos
pacotes do próprio Ubuntu:

```sh
sudo apt-get update
sudo apt-get install -y postgresql python3-venv r-base-core r-cran-dplyr r-cran-tidyr r-cran-readr
```

`postgresql` é a versão 16 no Ubuntu 24.04, e instalá-lo cria um servidor de banco de dados e o
liga. O servidor ainda não conhece nenhum usuário além do dele, `postgres`, então a linha seguinte
pede que ele crie um com o seu nome de login, com permissão para criar bancos:

```sh
sudo -u postgres createuser --createdb "$USER"
```

Daí em diante o `psql` conecta como você, por um socket na mesma máquina, sem senha: o servidor
pergunta ao sistema operacional quem está do outro lado.

Depois o pandas e as duas bibliotecas ao lado dele, num **ambiente virtual**: um diretório só dele,
`~/venv`, com Python e pacotes próprios, para nada aqui tocar no Python sobre o qual o próprio
Ubuntu roda. As versões são fixas, porque um pandas mais novo pode imprimir um número de outro
jeito, e a aula 17 trata de por que isso importa:

```sh
python3 -m venv ~/venv
source ~/venv/bin/activate
pip install pandas==3.0.6 numpy==2.5.3 rapidfuzz==3.14.6 matplotlib==3.11.2
```

Por último, quatro linhas no fim do `~/.bashrc`, para todo terminal novo começar do mesmo jeito:

```sh
cat >> ~/.bashrc <<'EOF'
# data-cleaning
export TZ=America/Sao_Paulo
export PGDATABASE=quitanda
source ~/venv/bin/activate
EOF
```

`TZ` põe a máquina no relógio da empresa, que a aula 7 precisa. `PGDATABASE` deixa o `psql` achar o
banco sem ouvir o nome dele toda vez, e a última linha faz do `python` o que está em `~/venv`. Abra
um terminal novo e confira:

```
ana@lab:~$ tail -4 .bashrc
# data-cleaning
export TZ=America/Sao_Paulo
export PGDATABASE=quitanda
source ~/venv/bin/activate
```

```
ana@lab:~$ psql --version
psql (PostgreSQL) 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
ana@lab:~$ python --version
Python 3.12.3
ana@lab:~$ python -c 'import pandas; print(pandas.__version__)'
3.0.6
ana@lab:~$ R --version | head -1
R version 4.3.3 (2024-02-29) -- "Angel Food Cake"
```

```
ana@lab:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 online postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
```

`online` é o servidor rodando. Custou este disco, além do sistema operacional:

```
ana@lab:~$ du -sh venv /usr/lib/R /usr/lib/postgresql
264M	venv
74M	/usr/lib/R
44M	/usr/lib/postgresql
```

A maior coisa da máquina é o ambiente Python, com 264 MB, que é o pandas e suas bibliotecas
numéricas. Os arquivos que o curso limpa, feitos na próxima seção, têm menos de 7 MB. **Dado pequeno
é uma escolha**: toda consulta deste curso volta na hora, então a atenção vai para o que a resposta
diz e não para a espera.

## Quando a montagem falha

Três falhas respondem pela maior parte, e cada uma se apresenta.

**O servidor não está rodando.** O `psql` não acha o socket por onde conversa:

```
ana@lab:~$ psql -c "SELECT 1"
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
ana@lab:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 down   postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
```

O `pg_lsclusters` diz `down`. Algo o parou, ou a máquina subiu sem subir o servidor. Ligue o
servidor e confira:

```
ana@lab:~$ sudo service postgresql start
 * Starting PostgreSQL 16 database server
   ...done.
ana@lab:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 online postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
ana@lab:~$ psql -c "SELECT 1"
 ?column? 
----------
        1
(1 row)
```

Se ele não ligar, o arquivo de log da última coluna diz por quê, e as últimas linhas dele são as
que importam.

**Você pulou o `createuser`.** O servidor está de pé e não conhece você. Aqui, um segundo usuário
da mesma máquina, `bia`, que nunca o rodou:

```
bia@lab:~$ psql
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  role "bia" does not exist
```

Rode a linha do `createuser` acima, com o seu próprio nome de login, e tente de novo.

**O `pip` rodou fora do ambiente virtual.** Num terminal aberto antes de o `~/.bashrc` ganhar as
linhas novas, o `python3` é o do próprio Ubuntu, e o Ubuntu se recusa a instalar pacotes nele:

```
ana@lab:~$ python3 -m pip install pandas==3.0.6
error: externally-managed-environment

× This environment is externally managed
```

A mensagem segue sugerindo um ambiente virtual, que é o que o `~/venv` é. Abra um terminal novo, ou
rode `source ~/venv/bin/activate`, e o `pip` instala no lugar certo. Se o próprio
`python3 -m venv` falhar, falta o pacote `python3-venv` na linha do `apt-get`.

Se falhar algo que não está aqui, leia as últimas linhas que ele imprimiu antes de qualquer outra
coisa. O primeiro erro é o que importa, e as linhas depois dele costumam ser consequências.

---
title: O laboratório, e três jeitos de rodá-lo
version: 2
---

**Ninguém entende um esquema estrela só lendo um.** Você entende quando uma consulta que parecia
lenta volta em vinte milissegundos, ou quando um total em que você confiava conta cada livro duas
vezes. Por isso toda lição aqui é executada, e você deve executá-la também, num computador seu.
Nada neste curso roda numa máquina mantida por nós.

O laboratório são dois bancos numa máquina Linux:

- **PostgreSQL 16** guarda o banco operacional da rede, `shop`: quinze tabelas em terceira forma
  normal, o formato que `sql-databases` ensinou você a construir.
- **DuckDB** guarda o warehouse, `wh.duckdb`, um arquivo no seu diretório de trabalho. É um banco
  analítico que roda dentro do programa que o abre, sem servidor, e guarda os dados por coluna. A
  lição 8 é sobre por que isso importa.

A máquina das transcrições é da Ana, a analista de dados da rede. Ela se chama `lab`, o diretório de
trabalho da Ana é `~/wh`, e o prompt dela é `ana@lab:~/wh$`. O seu vai trazer o seu nome. Esta seção
instala os programas, a próxima cria o banco da rede, e a seguinte enche esse banco com dois anos de
vendas.

## Três jeitos de rodar

| | o que é | o que custa ao seu computador |
|---|---|---|
| **uma máquina virtual** (recomendado) | Ubuntu Server 24.04 LTS numa máquina virtual, com Multipass ou outro hipervisor | 2 processadores e 4 GB de memória enquanto ela roda, e um disco de 20 GB |
| instalado | Ubuntu 24.04 como sistema de um computador que você usa, ou dentro do WSL no Windows | cerca de 2 GB de disco, e um servidor de banco que inicia junto com o computador |
| online | DuckDB num navegador, em `shell.duckdb.org` | nada, e só metade do curso |

**A máquina virtual é a recomendação**, porque o curso instala um servidor de banco e depois o
enche, e os dois são mais fáceis de jogar fora que de remover. O Multipass, da Canonical, cria uma
máquina virtual Ubuntu com um comando, no Windows, no macOS e no Linux. Instale-o pelo site dele e,
no terminal do seu próprio computador:

```sh
multipass launch 24.04 --name lab --cpus 2 --memory 4G --disk 20G
multipass shell lab
```

**Esses dois comandos não foram executados para este curso**, porque o computador em que ele foi
gravado não roda hipervisor. O primeiro cria a máquina e o segundo abre um shell dentro dela, como o
usuário `ubuntu`; tudo daqui em diante é digitado nesse shell. Qualquer outro hipervisor faz o mesmo
com mais telas de instalação: VirtualBox no Windows e no Linux, UTM num Mac com Apple silicon,
Hyper-V no Windows. Dê à máquina o Ubuntu Server 24.04 LTS e os tamanhos da tabela.

**Instalado** não custa nada a mais se o seu computador já roda Ubuntu 24.04, ou Windows com o WSL e
a distribuição Ubuntu 24.04, que roda os mesmos comandos. O PostgreSQL passa a iniciar toda vez que o
computador inicia, até você removê-lo. Num Mac, o Homebrew instala o PostgreSQL 16 e os mesmos
pacotes Python, mas os comandos abaixo são os do Ubuntu e o curso não foi gravado assim.

**Online** aparece para você saber que existe. O DuckDB roda dentro do navegador em
`shell.duckdb.org` e consulta um arquivo CSV ou Parquet que você abra nele, o que cobre as consultas
ao warehouse e não a metade do PostgreSQL. Várias empresas hospedam PostgreSQL com uma cota
gratuita; nenhuma é necessária aqui, e uma cota que muda de regras não é coisa em que um curso deva
se apoiar.

## Os programas

Tudo vem do arquivo de pacotes do próprio Ubuntu e do Python Package Index. No shell da máquina:

```sh
sudo apt-get update
sudo apt-get install -y postgresql python3-venv
python3 -m venv ~/wh-env
~/wh-env/bin/pip install duckdb==1.5.6 duckdb-cli==1.5.6 deltalake==1.6.6 pyarrow==25.0.1
cat >> ~/.bashrc <<'END'
export PGDATABASE=shop
export TZ=America/Sao_Paulo
. ~/wh-env/bin/activate
END
. ~/.bashrc
mkdir ~/wh && cd ~/wh
```

As duas primeiras linhas instalam o **PostgreSQL 16**, a versão que o Ubuntu 24.04 traz, e o põem
para rodar. As duas seguintes criam um ambiente virtual Python em `~/wh-env` e instalam nele o
DuckDB na versão em que o curso foi gravado: o programa de linha de comando, a biblioteca Python que
as lições 11 e 12 usam, e o `deltalake` com o `pyarrow` para a lição 10. Um ambiente virtual mantém
tudo isso fora do Python do sistema, e apagar a pasta remove tudo.

As três linhas acrescentadas ao `~/.bashrc` rodam em todo terminal novo. `PGDATABASE` deixa você
digitar `psql` em vez de `psql shop` toda vez; `TZ` faz os horários saírem no fuso de São Paulo,
como nas transcrições; a última linha põe os programas do ambiente virtual na frente do seu path.

Esses comandos foram executados na máquina de gravação, e a saída deles é uma página de progresso de
download que não vale a pena citar. O que eles deixam é isto:

```
ana@lab:~/wh$ psql --version
psql (PostgreSQL) 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
ana@lab:~/wh$ duckdb --version
v1.5.6 (Variegata) 069cc9f9b5
ana@lab:~/wh$ python3 --version
Python 3.12.3
```

Três programas, nas versões em que as transcrições foram feitas. Outro número de correção do
PostgreSQL, 16.16 em vez de 16.15, não muda nada neste curso. Outra versão do DuckDB pode mudar a cara
de um erro ou a largura de uma tabela, então mantenha a versão fixada.

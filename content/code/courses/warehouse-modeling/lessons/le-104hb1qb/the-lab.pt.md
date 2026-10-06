---
title: O laboratório, e três jeitos de rodá-lo
version: 1
---

**Ninguém entende um esquema estrela só lendo um.** Você entende quando uma consulta que parecia
lenta volta em vinte milissegundos, ou quando um total em que você confiava conta cada livro duas
vezes. Por isso toda lição aqui é executada, e você deve executá-la também.

O laboratório são dois bancos numa máquina Linux:

- **PostgreSQL 16** guarda o banco operacional da rede, `shop`: quinze tabelas em terceira forma
  normal, o formato que `sql-databases` ensinou você a construir.
- **DuckDB** guarda o warehouse, `wh.duckdb`, um arquivo no diretório de trabalho da Ana. É um
  banco analítico que roda dentro do programa que o abre, sem servidor, e guarda os dados por
  coluna — a lição 8 é sobre por que isso importa.

```
ana@lab:~/wh$ psql --version
psql (PostgreSQL) 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
ana@lab:~/wh$ duckdb --version
v1.5.6 (Variegata) 069cc9f9b5
```

O script de laboratório do curso, `lab.sh`, fica ao lado do material do curso. Ele cria um usuário
chamado `ana`, gera os dados, carrega tudo no PostgreSQL e instala o DuckDB num ambiente virtual
Python. Na máquina em que o curso foi gravado ele levou cerca de um minuto e ocupou isto de disco:

```
ana@lab:~/wh$ du -sh /var/lib/wh-data /var/lib/wh-pg ~/wh
97M	/var/lib/wh-data
802M	/var/lib/wh-pg
140M	/home/ana/wh
```

Os arquivos de dados têm 97 MB. O PostgreSQL os transforma em 802 MB, por causa dos índices, do
espaço que cada linha carrega para a própria contabilidade e da folga que deixa para atualizações.
Os 140 MB em `~/wh` são a extração e o warehouse feito a partir dela. **Guarde esses três
números**: a lição 8 explica o segundo.

## Três jeitos de rodar

**Numa máquina virtual — o recomendado.** Uma máquina virtual Ubuntu 24.04 com 2 GB de memória e
5 GB de disco livre basta. O `lab.sh` cria um usuário e um servidor de banco, exatamente o tipo de
mudança que você não quer no computador em que trabalha. A lição 4 de `virtualization` monta uma
no VirtualBox, se você ainda não tem.

**Instalado no seu próprio computador.** Instale o PostgreSQL 16 e o DuckDB você mesmo, crie um
banco chamado `shop`, rode o `lab/oltp.sql` do curso e carregue os arquivos CSV que o
`lab/generate.py` escreve. É o que o `lab.sh` faz, um passo de cada vez, e ler o script é a
instrução.

**Online, para metade dele.** O DuckDB também roda dentro do navegador, em `shell.duckdb.org`, e
consulta um arquivo CSV ou Parquet que você abra nele. Isso cobre as consultas ao warehouse e não a
metade do PostgreSQL. O curso não foi gravado assim; o caminho aparece aqui para que um aluno sem
máquina própria ainda tenha a maior parte do curso.

## Quando a instalação falha

Três falhas respondem pela maior parte, e cada uma se anuncia:

- `PostgreSQL 16 is required` — o script não achou o `initdb`. Instale o pacote `postgresql-16` e
  rode de novo; ele continua de onde parou.
- O `pip` não alcança o índice de pacotes — o ambiente virtual fica vazio e o primeiro comando
  `duckdb` responde `command not found`. Um proxy ou um firewall é a causa comum. Quando
  `pip install duckdb-cli` funcionar à mão, o script funciona também.
- `No space left on device` — o banco precisa dos 802 MB acima de uma vez. Libere espaço, ou dê
  um disco maior à máquina virtual, e rode `lab.sh reset`.

Se falhar algo que não está na lista, leia as últimas dez linhas que o script imprimiu. Ele para no
primeiro erro em vez de seguir em frente, então a última linha é a que quebrou.

---
title: O laboratório, e três jeitos de rodá-lo
version: 1
---

**Um pipeline só se entende rodando, e rodando de novo amanhã.** Por isso este curso não entrega
uma máquina a você. Você monta uma, no seu próprio computador, e cada comando de cada lição é
digitado lá.

O laboratório é uma máquina Linux com isto:

- **PostgreSQL 16**, com três bancos: `shop`, o banco operacional onde os caixas e o site
  escrevem; `wh`, o warehouse que os seus pipelines vão encher; e `airflow`, onde o Airflow guarda
  os próprios registros a partir da lição 8.
- **Python 3**, com um ambiente virtual por ferramenta. Airflow, dbt, Prefect e Dagster fixam cada
  um as suas versões das mesmas bibliotecas, e num ambiente só eles brigariam.
- **Os dados da loja**, três meses de vendas sorteados por um gerador com sementes fixas, para que
  os seus números sejam os impressos aqui.
- **Uma pequena API de preços**, escrita para o curso, que pagina as respostas, limita a velocidade
  com que você pode perguntar, e que dá para fazer falhar de propósito.

Tudo isso é montado por um script, `lab.sh`, que vem com o material do curso. Copie o diretório
`lab` para o seu diretório pessoal e rode-o uma vez:

```
ana@vm:~$ sudo bash ~/lab/lab.sh up
```

Ele cria um usuário chamado `ana`, instala tudo em `/opt/etl`, gera os dados e carrega a loja. Com
os pacotes já baixados uma vez, levou cerca de um minuto e meio na máquina em que o curso foi
gravado; da primeira vez, quase toda a espera é o download. Depois confira o que você tem:

```
ana@vm:~/etl$ psql --version
psql (PostgreSQL) 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
ana@vm:~/etl$ python --version
Python 3.13.16
ana@vm:~/etl$ airflow version
3.3.2
ana@vm:~/etl$ dbt --version | head -2
Core:
  - installed: 1.12.5
```

E quanto custou:

```
ana@vm:~/etl$ du -sh /var/lib/etl-data /var/lib/etl-pg /opt/etl
19M	/var/lib/etl-data
79M	/var/lib/etl-pg
1.3G	/opt/etl
```

**Os dados são pequenos e as ferramentas não.** Dezenove megabytes de vendas e 1,3 GB de software
para movê-los. Essa proporção é normal num notebook e o contrário da produção, e a lição 19 é onde
os dados ficam grandes o bastante para importar.

## Três jeitos de rodá-lo

**Numa máquina virtual — o recomendado.** Uma máquina virtual Ubuntu 24.04 com 4 GB de memória e
10 GB de disco livre. A partir da lição 8 o Airflow roda quatro processos ao mesmo tempo, e na
máquina de gravação eles ocupavam cerca de 1,4 GB de memória entre si antes de qualquer DAG rodar.
O script adiciona um usuário, um servidor de banco e seis ambientes Python, que é exatamente o tipo
de mudança que você não quer no computador em que trabalha. A lição 4 de `virtualization` monta
uma no VirtualBox, se você ainda não tem.

**Instalado no seu próprio computador Linux.** Leia o `lab.sh` e faça à mão o que ele faz: instale
o PostgreSQL 16, crie os três bancos, monte os ambientes virtuais com as versões que ele fixa. São
menos de trezentas linhas e cada passo está comentado. É o caminho que mais ensina e o que mais
quebra.

**Em contêineres, só para as ferramentas.** O Airflow publica uma imagem de contêiner oficial e um
arquivo Compose, e o dbt roda em qualquer imagem Python. Isso dá o software mas não este
laboratório — a loja, os dados e o relógio dia a dia estão no `lab.sh` — e o curso não foi gravado
assim. Fica nomeado aqui para quem já trabalha com contêineres e quer trazer as lições para essa
montagem.

---
title: O laboratório, e três maneiras de montá-lo
version: 1
---

**Ninguém aprende a limpar dados lendo sobre dados sujos.** Aprende-se na primeira vez em que um
total confiável acaba contando cem pedidos duas vezes, e esse momento só acontece com os arquivos
abertos na sua frente. Por isso toda aula é executada, e você deve executá-la também, numa máquina
que você mesmo monta.

O laboratório é um computador Linux com quatro coisas:

- **os arquivos**, em `~/clean/raw`: nove exportações CSV dos sistemas da Quitanda Verde, deixadas
  somente leitura de propósito — a aula 17 diz por quê — e três pequenos arquivos de referência de
  fora da empresa em `~/clean/ref`;
- **PostgreSQL 16**, com um banco chamado `quitanda` e um schema chamado `raw` que guarda cada arquivo
  carregado exatamente como chegou, **toda coluna como texto**;
- **Python 3 com pandas**, num ambiente virtual, mais o RapidFuzz para a correspondência
  aproximada da aula 5 e o Matplotlib para os gráficos da aula 15;
- **R com dplyr**, que só a aula 16 usa.

```
ana@lab:~/clean$ psql --version
psql (PostgreSQL) 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
ana@lab:~/clean$ python --version
Python 3.13.16
ana@lab:~/clean$ python -c 'import pandas; print(pandas.__version__)'
3.0.6
ana@lab:~/clean$ R --version | head -1
R version 4.3.3 (2024-02-29) -- "Angel Food Cake"
```

O script do laboratório do curso, `lab.sh`, fica junto do material do curso, com um diretório
`lab/` que guarda o gerador e o script de carga. `sudo bash lab.sh up` cria um usuário chamado
`ana`, escreve os dados, sobe o PostgreSQL, carrega o schema bruto e instala as bibliotecas Python
nas versões com que o curso foi gravado. Ocupou isto de disco:

```
ana@lab:~/clean$ du -sh raw ref /var/lib/clean-pg /opt/clean
6.8M	raw
16K	ref
71M	/var/lib/clean-pg
260M	/opt/clean
```

Os dados têm menos de 7 MB. A maior coisa da máquina é o ambiente Python, com 260 MB, que é o
pandas e suas bibliotecas numéricas. **Dado pequeno é uma escolha**: toda consulta deste curso
volta na hora, então a atenção vai para o que a resposta diz e não para a espera.

## Três maneiras de rodar

**Numa máquina virtual — a recomendada.** Uma máquina virtual Ubuntu 24.04 com 2 GB de memória e
5 GB de disco livre basta. O `lab.sh` adiciona um usuário, um servidor de banco de dados e pacotes
do sistema, que é exatamente o tipo de mudança que você não quer no computador em que trabalha, e
um snapshot tirado depois do `up` dá um recomeço limpo sempre que um experimento der errado. A aula
4 do `virtualization` monta uma no VirtualBox, se você ainda não tem.

**Instalado no seu próprio computador.** Instale o PostgreSQL 16, o Python 3 e, para a aula 16, o
R com os pacotes `dplyr`, `tidyr` e `readr`. Crie um banco chamado `quitanda`, rode o
`lab/generate.py` para escrever os arquivos e rode o `lab/raw.sql` a partir do diretório que contém
`raw/`. É o que o `lab.sh` faz, um passo de cada vez, e ler o script é a instrução. Windows e macOS
funcionam assim também; só muda o gerenciador de pacotes.

**Em contêineres.** O PostgreSQL 16 roda bem a partir da imagem oficial `postgres:16`, e o pandas
não precisa de nada além do Python. Se você já trabalha com contêineres, um contêiner de banco e um
ambiente virtual na sua própria máquina são um laboratório razoável. O curso não foi gravado assim,
então um caminho ou uma versão numa transcrição pode diferir do que você vê.

## Quando a instalação falha

Quatro falhas respondem pela maior parte, e cada uma se apresenta:

- `PostgreSQL 16 is required` — o script não achou o `initdb`. Instale o pacote `postgresql-16` e
  rode o `up` de novo; ele retoma de onde parou.
- `R is required for lesson 16` — instale os quatro pacotes que a mensagem lista. Tudo, exceto a
  aula 16, funciona sem eles, então você também pode voltar a isso depois.
- `python3 -m venv` falha e nomeia um pacote para instalar, `python3-venv` no Ubuntu. Instale-o e
  rode o `up` de novo.
- o `pip` não alcança o índice de pacotes, então o ambiente fica vazio e `import pandas` falha. Um
  proxy ou um firewall é a causa comum. Quando `pip install pandas` funcionar à mão, o script
  funciona também.

Se falhar algo que não está na lista, leia as últimas linhas que o script imprimiu. Ele para no
primeiro erro em vez de seguir adiante, então a última linha é a que quebrou.

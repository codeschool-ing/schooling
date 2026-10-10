---
title: O Streamlit na sua máquina, e três jeitos de tê-lo
version: 1
---

O **Streamlit** é a ponta oposta do Metabase: uma biblioteca Python que transforma um script curto
numa página web com controles e gráficos. Não há menus nem perguntas salvas. O app é o código, e quem
escreve o código decide tudo — o que é a força dele para uma página que nenhuma outra ferramenta
desenha, e o risco dele para as definições, que moram onde o programador as pôs.

Não precisa saber Python para acompanhar. O app da próxima seção aparece inteiro, com uma nota ao lado
de cada parte dizendo o que ela faz, e rodá-lo são três comandos.

## Na máquina virtual — o caminho recomendado

O Streamlit é instalado num **ambiente virtual**: um diretório com uma cópia própria das bibliotecas
do Python, para que o que você instala para este curso não perturbe mais nada na máquina. O Ubuntu
precisa de um pacote para isso; depois o ambiente é criado e o Streamlit é instalado nele com o driver
do PostgreSQL. As versões estão escritas para a sua página bater com a do curso:

```sh
sudo apt install -y python3-venv
```

```
ana@vm:~$ python3 -m venv ~/st
ana@vm:~$ ~/st/bin/pip install -q streamlit==1.65.0 "psycopg[binary]==3.3.6"
ana@vm:~$ ~/st/bin/streamlit version
Streamlit, version 1.65.0
ana@vm:~$ du -sh ~/st
473M	/home/ana/st
```

O `pip install -q` não imprime nada quando dá certo. O ambiente ocupa 473 MB de disco, a maior parte
bibliotecas que o Streamlit usa para desenhar gráficos.

O app se conecta ao banco como o Metabase, por um papel próprio que só lê o que precisa — aqui, duas
views da camada:

```sql
CREATE ROLE streamlit_app LOGIN PASSWORD 'a-third-password-to-choose';
GRANT USAGE ON SCHEMA semantic TO streamlit_app;
GRANT SELECT ON semantic.orders, semantic.customers TO streamlit_app;
```

```
lantern=# CREATE ROLE streamlit_app LOGIN PASSWORD 'a-third-password-to-choose';
CREATE ROLE

lantern=# GRANT USAGE ON SCHEMA semantic TO streamlit_app;
GRANT

lantern=# GRANT SELECT ON semantic.orders, semantic.customers TO streamlit_app;
GRANT
```

## No seu próprio computador, com Python

Se o Python 3 estiver instalado no seu computador, as mesmas duas linhas de `pip` num ambiente virtual
ali instalam as mesmas versões. O app então rodaria no seu computador e se conectaria ao PostgreSQL
dentro da máquina virtual, o que o arranjo da aula 1 de propósito não permite; funciona se o
PostgreSQL também rodar no seu computador. Dentro da máquina virtual, nada precisa ser aberto.

## Online

A empresa do Streamlit oferece um serviço gratuito de hospedagem de apps Streamlit, o Community Cloud,
que publica um app a partir de um repositório de código público. Exige conta, e o app precisa chegar a
um banco na internet, e não a um dentro da sua máquina. O curso não depende dele.

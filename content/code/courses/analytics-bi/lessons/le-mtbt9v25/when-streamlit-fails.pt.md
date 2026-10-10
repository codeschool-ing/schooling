---
title: Quando o app não funciona
version: 1
---

O Streamlit mostra a maioria das falhas em dois lugares ao mesmo tempo: na página, como uma caixa
vermelha com o erro, e no terminal onde ele está rodando, como o mesmo erro com o traceback inteiro. A
última linha do traceback é a que dá nome ao problema.

## `streamlit: command not found`

```
ana@vm:~/revenue$ streamlit run app.py
bash: line 1: streamlit: command not found
```

O Streamlit está instalado dentro do ambiente virtual, e não na máquina, então o shell não o encontra
pelo nome. Chame-o pelo caminho, `~/st/bin/streamlit`, como a última seção faz. (Ativar o ambiente com
`source ~/st/bin/activate` também funciona, e aí `streamlit` sozinho é encontrado até o terminal
fechar.)

## A página mostra uma versão antiga do app

Você subiu o app uma segunda vez enquanto o primeiro ainda rodava, talvez em outro terminal. O segundo
não falha: pega a próxima porta em silêncio.

```
ana@vm:~/revenue$ timeout -s KILL 20 ~/st/bin/streamlit run app.py 2>&1 | grep -o "server started on .*"
server started on 0.0.0.0:8502
```

A porta 8502 não está encaminhada, então o seu navegador na 8501 continua mostrando o primeiro app,
com o código antigo. Pare o antigo com Ctrl+C no terminal dele e suba de novo.

## `No secrets found`

A última linha no terminal:

```
streamlit.errors.StreamlitSecretNotFoundError: No secrets found. Valid paths for a secrets.toml file or secret directories are: /home/ana/.streamlit/secrets.toml, /home/ana/revenue/.streamlit/secrets.toml
```

O arquivo está faltando, com nome errado ou no diretório errado. O Streamlit lista os dois lugares
onde procurou, e o arquivo precisa estar num deles com exatamente esse nome: `secrets.toml`, dentro de
`.streamlit`, ao lado do `app.py` ou na sua pasta pessoal.

## `password authentication failed`

```
psycopg.OperationalError: connection failed: connection to server at "127.0.0.1", port 5432 failed: FATAL:  password authentication failed for user "streamlit_app"
```

A senha em `secrets.toml` não é a do papel. É a mesma mensagem que a aula 3 encontrou para o Metabase,
do mesmo servidor, pelo mesmo motivo.

## Funcionava, eu quebrei a conexão, e continua funcionando

O `@st.cache_data(ttl=600)` guarda cada resposta por dez minutos. Uma conexão quebrada depois da
primeira execução fica invisível até as respostas em cache expirarem, ou até o app ser reiniciado, o
que as apaga. É por isso que as duas falhas acima foram produzidas reiniciando o app: **um cache
esconde uma fonte quebrada exatamente pelo tempo de vida dele**, o que vale para toda ferramenta de BI
que usa cache, inclusive o Metabase.

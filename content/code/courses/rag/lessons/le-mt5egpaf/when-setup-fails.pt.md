---
title: Quando a instalação falha
version: 1
---

A maioria das pessoas que desiste de um curso assim desiste aqui, num erro de uma máquina que
acabou de montar. Estas são as falhas que de fato acontecem, mais ou menos na ordem em que você
as encontraria. Onde a máquina em que o curso foi gravado produziu uma, ela aparece como a máquina
imprimiu.

**O instalador do Ollama para com *This version requires zstd for extraction*.** Aconteceu na máquina
em que este curso foi gravado, e por isso o `zstd` está na linha do `apt-get`. Instale e rode o
instalador de novo; nada ficou instalado pela metade.

**O Ollama está instalado e nada responde.**

```
ana@vm:~/rag$ ollama list
Error: could not connect to ollama server, run 'ollama serve' to start it
ana@vm:~/rag$ python -c "from vectors import embed; embed(\"hello\")" 2>&1 | tail -1
openai.APIConnectionError: Connection error.
```

O programa está no disco e o servidor não está rodando. Na VM o instalador o transformou num serviço,
e `sudo systemctl start ollama` o inicia; `systemctl status ollama` diz por que ele parou, se parou.
Dentro de um contêiner, ou em qualquer lugar sem systemd, `ollama serve &` o roda à mão. Os programas
em Python falham na mesma situação com um traceback longo cuja última linha é a mostrada: o SDK não
conseguiu conectar, e diz isso depois de tentar mais duas vezes.

**O nome do modelo não é bem o que você baixou.**

```
ana@vm:~/rag$ python -c "from openai import OpenAI; OpenAI().chat.completions.create(model=\"llama3.2\", messages=[{\"role\": \"user\", \"content\": \"hi\"}])" 2>&1 | tail -1
openai.NotFoundError: Error code: 404 - {'error': {'message': "model 'llama3.2' not found", 'type': 'not_found_error', 'param': None, 'code': None}}
```

`llama3.2` sem etiqueta quer dizer `llama3.2:latest`, que é outro download além do `llama3.2:3b`.
O `ollama list` mostra os nomes exatamente como um programa precisa escrevê-los.

**Um terminal novo não encontra as bibliotecas.**

```
ana@vm:~/rag$ python3 -c "import openai"
Traceback (most recent call last):
  File "<string>", line 1, in <module>
ModuleNotFoundError: No module named 'openai'
```

As bibliotecas estão dentro de `~/rag/.venv`, e este terminal nunca rodou o `env.sh`. Ou a linha que
o acrescenta ao `~/.bashrc` foi pulada, ou o terminal foi aberto antes de ela ser acrescentada.
`. ~/rag/env.sh` conserta o terminal em que você está.

**O `psql` diz que o papel não existe.**

```
ana@vm:~/rag$ createdb rag
createdb: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  role "ana" does not exist
ana@vm:~/rag$ createdb rag
ana@vm:~/rag$ psql -d rag -c "CREATE EXTENSION vector"
CREATE EXTENSION
```

O PostgreSQL não tem um papel com o nome do seu login: a linha do `createuser` foi pulada, ou foi
rodada com outro login. Rode de novo, e depois `createdb rag`. Se o `CREATE EXTENSION vector`
responder que a extensão *is not available*, falta o pacote `postgresql-16-pgvector`; instale, e o
mesmo comando funciona.

**O Ollama se recusa a carregar o modelo por falta de memória.** A mensagem diz quanto o modelo
precisa e quanto está livre. Feche o que mais estiver rodando na VM, dê mais memória à VM no
Multipass (`multipass stop vm`, depois `multipass set local.vm.memory=8G`), ou use o `llama3.2:1b`.
Esta não aconteceu na máquina em que o curso foi gravado, então fica descrita e não mostrada.

**Uma resposta leva um minuto.** A primeira requisição depois de uma pausa carrega o modelo, e em
quatro processadores sem placa de vídeo um prompt longo leva segundos por mil tokens para ser lido.
É o preço de rodar um modelo localmente, e a aula 9 põe um timeout em toda chamada por causa disso. Se
toda resposta for lenta num computador com placa de vídeo, olhe o `ollama ps`: uma coluna `PROCESSOR`
dizendo `100% CPU` quer dizer que o Ollama não encontrou a placa, e uma divisão como
`40%/60% CPU/GPU` quer dizer que o modelo não coube na memória da placa e parte dele roda no
processador.

**O `pip install` falha ao compilar um pacote.** As versões do `requirements.txt` foram gravadas no
Python 3.12, o que vem com o Ubuntu 24.04. Um Python mais novo pode não ter pacote pronto para uma
delas, e aí o pip tenta compilar e falha. Use o Ubuntu 24.04 na VM, que é a razão de a VM ser o
caminho recomendado.

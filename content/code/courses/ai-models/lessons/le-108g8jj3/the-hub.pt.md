---
title: O Hub é um conjunto de repositórios
version: 1
---

Um modelo no Hugging Face é **um repositório**: um nome no formato `dono/modelo`, um conjunto de
arquivos e um histórico de versões, guardado com git. `Qwen/Qwen3-8B` é um repositório da
organização Qwen; qualquer um pode criar `alguem/Qwen3-8B-qualquer-coisa` ao lado. Os arquivos de
licença da aula 11, "nos respectivos repositórios do Hugging Face", são arquivos exatamente nestes.

A biblioteca que os programas usam para baixar do Hub é a `huggingface_hub`. A função de download
dela diz, nos seis primeiros parâmetros, o que identifica um arquivo:

```
ana@desk:~/desk$ python -c "import inspect, huggingface_hub as h; print(h.__version__); print(*list(inspect.signature(h.hf_hub_download).parameters)[:6], sep=chr(10))"
2.1.1
repo_id
filename
subfolder
repo_type
revision
library_name
```

**`repo_id` e `filename`** nomeiam o arquivo. **`revision`** diz qual versão dele: um branch, uma
tag ou o hash de um commit. Omitido, quer dizer o commit mais novo do branch principal, que é o
apelido da aula 2 seção 06 em outra forma: o mesmo nome, um arquivo diferente no mês que vem, se o
dono fizer push.

É por isso que este curso fixa um commit para toda fonte que lê, e por isso um programa que baixa
pesos deveria fazer o mesmo. **Um modelo baixado só pelo `repo_id` é um modelo que pode mudar entre
duas implantações** sem ninguém do lado da ana mudar uma linha. Fixado num hash de commit, são os
mesmos bytes toda vez, e a avaliação da aula 5 continua valendo para ele.

## O que tem num repositório

Os arquivos que formam a caixa da aula 1 seção 06: os pesos, muitas vezes divididos em vários
arquivos; o tokenizador e a configuração dele, que guarda o template de chat; um arquivo de
configuração com os números de arquitetura com que a aula 3 fez as contas; e o `README.md`, que é o
cartão do modelo. Arquivos de pesos no formato `safetensors` guardam só números. Alguns repositórios
mais antigos ainda trazem pesos no formato pickle do Python, que pode executar código ao ser
carregado, e são um motivo para preferir repositórios que publicam `safetensors` e para não carregar
nada de uma fonte que você não conferiu.

---
title: Instalando o Ollama, o Python e as bibliotecas
version: 1
---

Estes passos são para o Ubuntu 24.04, que é o que você tem nos dois primeiros caminhos da seção
anterior: direto no Linux, dentro do WSL no Windows, ou na máquina virtual. Um Mac dá um primeiro
passo diferente e depois os mesmos, e o fim desta seção diz onde eles se separam.

Abra um terminal. Tudo abaixo é digitado nele.

## Os pacotes do próprio sistema

```sh
sudo apt update
sudo apt install -y python3-venv curl zstd
```

O `python3-venv` deixa o Python criar um ambiente isolado para as bibliotecas do curso, o `curl`
baixa o próximo instalador e conversa com o modelo à mão, e o `zstd` descompacta o Ollama. O Ubuntu
deixa o último de fora de uma instalação mínima, e o instalador para sem ele; a seção sobre falhas
mostra como isso aparece.

## O Ollama, e os dois modelos

O instalador do Ollama é um script de shell no próprio site dele. Baixe-o, e leia-o se quiser antes
de rodar, porque ele instala um serviço e pede `sudo`:

```sh
curl -fsSL https://ollama.com/install.sh -o install-ollama.sh
sh install-ollama.sh
```

Ele termina com `>>> The Ollama API is now available at 127.0.0.1:11434.` e, num computador com
`systemd`, inicia o Ollama como um serviço que volta a cada boot. Agora baixe os dois modelos que o
curso usa:

```sh
ollama pull llama3.2:3b
ollama pull all-minilm
```

O **`llama3.2:3b`** escreve as respostas do assistente, e a partir da aula 9 também as avalia. O
**`all-minilm`** transforma um pedaço de texto em 384 números, para que o assistente encontre os
documentos mais próximos de uma pergunta; é o mesmo modelo pequeno, all-MiniLM-L6-v2, que o `rag` e
o `embeddings-vectors` usam.

```
ana@dev:~$ ollama --version
ollama version is 0.40.0
ana@dev:~$ ollama list
NAME                 ID              SIZE      MODIFIED               
all-minilm:latest    1b226e2802db    45 MB     Less than a second ago    
llama3.2:3b          a80c4f17acd5    2.0 GB    4 seconds ago             
ana@dev:~$ ollama run llama3.2:3b "Say hello to a customer in one short sentence."
"Hello, welcome to our store! How can I assist you today?"
ana@dev:~$ ollama ps
NAME           ID              SIZE      PROCESSOR          CONTEXT    RUNNER      UNTIL              
llama3.2:3b    a80c4f17acd5    2.9 GB    30%/70% CPU/GPU    4096       llamacpp    4 minutes from now    
```

O `ollama ps` lista os modelos que estão na memória agora. **2,9 GB é o que o modelo ocupa enquanto
responde**, e `4 minutes from now` é quando o Ollama o descarrega se ninguém perguntar mais nada. A
coluna `PROCESSOR` diz como o modelo está dividido entre o processador e uma placa de vídeo. Na
máquina da gravação, que não tem placa, ela mostrou `30%/70% CPU/GPU` mesmo assim, enquanto o próprio
log do Ollama, ao iniciar, só encontrou o processador; na sua ela vai dizer o que a sua tem. O seu
olá vai sair com outras palavras: o `ollama run` sorteia as palavras, e o assistente da seção 07 não.

## Um ambiente Python para o curso

Os programas do curso são em Python. As bibliotecas deles vão para um **ambiente virtual** próprio,
em `~/llmobs`, em vez do Python do sistema:

```sh
python3 -m venv ~/llmobs
source ~/llmobs/bin/activate
pip install openai==3.24.0 numpy==2.4.6 opentelemetry-sdk==1.45.0 opentelemetry-exporter-otlp-proto-http==1.45.0 openinference-instrumentation-openai==0.1.63
```

**As versões estão fixadas** porque essas bibliotecas mudam a cada poucas semanas, e uma aula
escrita contra uma versão e rodada contra outra falha de jeitos que parecem erro seu. São o SDK da
OpenAI (`openai`), que conversa com o Ollama tanto quanto com a OpenAI, o `numpy` para a aritmética
da busca, o SDK do OpenTelemetry e o seu exportador, que escrevem os rastros de que este curso
trata, e uma biblioteca de instrumentação que a seção 09 experimenta. As aulas seguintes acrescentam
as delas, cada uma com uma linha de `pip install` onde é usada pela primeira vez.

## Apontando o SDK para o Ollama, e uma chave sua

O Ollama responde no mesmo formato da API da OpenAI, então o SDK conversa com ele sem modificação. O
SDK lê para onde mandar os pedidos, e com que chave, do ambiente. Três variáveis, acrescentadas ao
fim do próprio script de ativação do ambiente, para que estejam definidas sempre que ele estiver:

```sh
cat >> ~/llmobs/bin/activate <<EOF
export OPENAI_BASE_URL=http://127.0.0.1:11434/v1
export OPENAI_API_KEY=ollama
export PSEUDONYM_KEY=$(python3 -c 'import secrets; print(secrets.token_hex(16))')
EOF
source ~/llmobs/bin/activate
```

O Ollama ignora a chave da API, mas o SDK se recusa a começar sem uma, então ela recebe uma palavra
que diz para onde vai. A terceira variável é um segredo seu: trinta e dois caracteres aleatórios,
escritos uma vez. O assistente a usa para registrar **quem** fez uma pergunta sem registrar o nome
da pessoa, e a aula 2 a abre. **Todo terminal novo começa com `source ~/llmobs/bin/activate`**; o
prompt então começa com `(llmobs)`, que as transcrições deste curso deixam de fora.

A conferência de que tudo se encaixa é um pedido pelo SDK:

```
ana@dev:~$ python --version
Python 3.12.3
ana@dev:~$ env | grep ^OPENAI_ | sort
OPENAI_API_KEY=ollama
OPENAI_BASE_URL=http://127.0.0.1:11434/v1
ana@dev:~$ python -c 'from openai import OpenAI; r = OpenAI().chat.completions.create(model="llama3.2:3b", max_tokens=10, messages=[{"role": "user", "content": "Reply with the word ready."}]); print(r.choices[0].finish_reason, r.usage.prompt_tokens, r.usage.completion_tokens, repr(r.choices[0].message.content))'
stop 31 3 'ready.'
```

É a mesma chamada, palavra por palavra, que iria para os servidores da OpenAI com as duas primeiras
variáveis trocadas. O `usage` é o campo que este curso mais lê, e a seção 06 começa por ele.

## Num Mac

Baixe o Ollama para macOS em `ollama.com/download` e arraste-o para Aplicativos; ele roda como um
app com um ícone na barra de menus, e usa a parte gráfica de um chip Apple silicon sozinho. Instale
o Python 3.12 pelo `python.org`. Depois, no Terminal, baixe os dois modelos e siga todos os passos a
partir de "Um ambiente Python para o curso". O shell do macOS é o `zsh`, e o script de ativação
funciona nele sem mudança.

## No Windows

Abra o PowerShell como administrador e instale o WSL com o Ubuntu:

```sh
wsl --install -d Ubuntu-24.04
```

Reinicie quando ele pedir, abra o *Ubuntu 24.04* pelo menu Iniciar, escolha um nome de usuário e uma
senha, e siga esta seção desde o começo, lá dentro. O Ollama instalado dentro do WSL usa uma placa
NVIDIA pelo suporte de drivers do próprio WSL, e roda no processador nos outros casos. **Este
comando não foi rodado para este curso**, que foi gravado em Linux.

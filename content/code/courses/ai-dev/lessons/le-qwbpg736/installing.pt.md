---
title: Instalando o Ollama, o Python e as bibliotecas
version: 1
---

Estes passos são para o Ubuntu 24.04, que é o que você tem nos dois primeiros caminhos da seção
anterior: direto no Linux, dentro do WSL no Windows, ou na máquina virtual. Um Mac dá um primeiro passo
diferente e depois os mesmos, e o fim desta seção diz onde eles se separam.

Abra um terminal. Tudo daqui para baixo é digitado nele.

## Os pacotes do próprio sistema

```sh
sudo apt update
sudo apt install -y python3-venv git curl zstd
```

O `python3-venv` deixa o Python criar um ambiente isolado para as bibliotecas do curso, o `git`
guarda o histórico do projeto, o `curl` baixa o próximo instalador e conversa com o modelo à mão,
e o `zstd` descompacta o Ollama. O Ubuntu deixa este último de fora de uma instalação mínima, e o
instalador para sem ele; a seção sobre falhas mostra como isso aparece.

## O Ollama, e o modelo

O instalador do Ollama é um script de shell no próprio site dele. Baixe-o, e leia antes de rodar
se quiser, porque ele instala um serviço e pede `sudo`:

```sh
curl -fsSL https://ollama.com/install.sh -o install-ollama.sh
sh install-ollama.sh
```

Ele termina com `>>> The Ollama API is now available at 127.0.0.1:11434.` e, num computador com
`systemd`, inicia o Ollama como um serviço que volta a cada boot. Agora baixe o modelo, uns 2 GB:

```sh
ollama pull llama3.2:3b
```

E pergunte alguma coisa a ele:

```
ana@dev:~$ ollama --version
ollama version is 0.40.0
ana@dev:~$ ollama list
NAME           ID              SIZE      MODIFIED               
llama3.2:3b    a80c4f17acd5    2.0 GB    Less than a second ago    
ana@dev:~$ ollama run llama3.2:3b "Say hello to a developer in one short sentence."
Hello!
ana@dev:~$ ollama ps
NAME           ID              SIZE      PROCESSOR    CONTEXT    RUNNER      UNTIL              
llama3.2:3b    a80c4f17acd5    2.6 GB    100% CPU     4096       llamacpp    4 minutes from now    
```

O `ollama ps` lista os modelos que estão na memória agora. **2,6 GB é o que o modelo ocupa
enquanto responde**, `100% CPU` diz que ele rodou no processador porque a máquina da gravação não
tem placa de vídeo, e `4 minutes from now` é quando o Ollama vai descarregá-lo se ninguém
perguntar mais nada. A sua resposta vai sair com outras palavras: um modelo sorteia as palavras,
e a seção 08 desta aula mostra como.

## Um ambiente Python para o curso

Os programas do curso são em Python, e importam as bibliotecas dos próprios provedores. Elas vão
para um **ambiente virtual** só delas, em `~/aidev`, e não para o Python do sistema:

```sh
python3 -m venv ~/aidev
source ~/aidev/bin/activate
pip install anthropic==1.11.0 openai==3.23.0 google-genai==2.27.0 mcp==2.2.0 numpy==2.4.6 wordllama==0.4.0.post1 tiktoken==0.14.0 pytest==9.1.1 hypothesis==6.168.3 jsonschema==4.26.0
```

**As versões estão fixadas** porque essas bibliotecas mudam a cada poucas semanas, e uma aula
escrita contra uma versão e rodada contra outra falha de jeitos que parecem erro seu. São os SDKs
dos três provedores (`anthropic`, `openai`, `google-genai`), o do Model Context Protocol (`mcp`),
o tokenizador da OpenAI (`tiktoken`), um modelo pequeno de embeddings (`wordllama`) com o `numpy`,
e três bibliotecas para testar e conferir (`pytest`, `hypothesis`, `jsonschema`).

## Apontando os SDKs para o Ollama

O Ollama responde no mesmo formato que a API da Anthropic e a da OpenAI, então os SDKs delas
conversam com ele sem modificação. Cada SDK lê do ambiente para onde mandar os pedidos, e com que
chave. São quatro variáveis, acrescentadas ao fim do script de ativação do próprio ambiente para
que fiquem definidas sempre que ele estiver:

```sh
cat >> ~/aidev/bin/activate <<'EOF'
export ANTHROPIC_BASE_URL=http://127.0.0.1:11434
export ANTHROPIC_API_KEY=ollama
export OPENAI_BASE_URL=http://127.0.0.1:11434/v1
export OPENAI_API_KEY=ollama
EOF
source ~/aidev/bin/activate
```

O Ollama ignora a chave, mas os dois SDKs se recusam a começar sem uma, então ela recebe uma
palavra que diz para onde vai. **Todo terminal novo começa com `source ~/aidev/bin/activate`**; o
prompt então passa a começar com `(aidev)`, que as transcrições deste curso deixam de fora.

A conferência de que tudo se encaixa é um pedido pelo SDK da Anthropic:

```
ana@dev:~$ python --version
Python 3.12.3
ana@dev:~$ env | grep -E "_(BASE_URL|API_KEY)=" | sort
ANTHROPIC_API_KEY=ollama
ANTHROPIC_BASE_URL=http://127.0.0.1:11434
OPENAI_API_KEY=ollama
OPENAI_BASE_URL=http://127.0.0.1:11434/v1
ana@dev:~$ python -c 'import anthropic; r = anthropic.Anthropic().messages.create(model="llama3.2:3b", max_tokens=40, messages=[{"role": "user", "content": "Reply with the word ready."}]); print(r.stop_reason, r.usage.output_tokens, repr(r.content[0].text))'
end_turn 3 'Ready.'
```

Essa é a mesma chamada, palavra por palavra, que iria para os servidores da Anthropic com as
outras duas variáveis. `stop_reason` e `usage` são os dois campos que este curso mais lê, e a
aula 2 começa por eles.

## Num Mac

Baixe o Ollama para macOS em `ollama.com/download` e arraste-o para Aplicativos; ele roda como um
app com um ícone na barra de menus, e usa sozinho a parte gráfica de um chip Apple silicon.
Instale o Python 3.12 pelo `python.org`. Depois, no Terminal, rode `ollama pull llama3.2:3b` e
todos os passos de "Um ambiente Python para o curso" em diante. O shell do macOS é o `zsh`, e o
script de ativação funciona nele sem mudança.

## No Windows

Abra o PowerShell como administrador e instale o WSL com o Ubuntu:

```sh
wsl --install -d Ubuntu-24.04
```

Reinicie quando ele pedir, abra o *Ubuntu 24.04* pelo menu Iniciar, escolha um nome de usuário e
uma senha, e siga esta seção desde o começo, lá dentro. O Ollama instalado dentro do WSL usa uma
placa NVIDIA pelo suporte de driver do próprio WSL, e roda no processador caso contrário. **Este
comando não foi rodado para este curso**, que foi gravado no Linux.

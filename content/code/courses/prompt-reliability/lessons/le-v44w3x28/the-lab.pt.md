---
title: Seu laboratório, e três jeitos de montá-lo
version: 2
---

Um prompt que funcionou quando você testou foi testado uma vez. **Este curso trata de testá-lo as
outras trinta e nove**: escrever o que é uma boa resposta, rodar o prompt em mensagens que ele
nunca viu e contar. Tudo o que vem depois desta seção é um jeito de deixar essa contagem mais
honesta, mais barata ou mais difícil de enganar.

Contar exige um modelo que você possa chamar centenas de vezes sem pensar no assunto. Uma aula
daqui faz de quarenta a algumas centenas de chamadas. Por isso o curso recomenda um modelo que roda
no seu próprio computador: o **Ollama**, um programa gratuito que baixa modelos abertos e responde a
pedidos na sua máquina, com o **`llama3.2:3b`**, um modelo pequeno da Meta. Sem conta, sem cartão,
sem chave de API, e o mesmo modelo em todos os cursos de IA desta escola, então quem monta uma vez
tem para todos.

O laboratório são três coisas:

- **o Ollama e o `llama3.2:3b`**, instalados nesta seção;
- **o Python 3**, que roda o harness e não precisa de nada além da biblioteca padrão;
- **o `~/triage`**, um diretório com o harness, o conjunto de teste e os prompts, montado na
  próxima seção.

## Três jeitos de ter um

| caminho | o que você ganha | quanto custa | as transcrições |
|---|---|---|---|
| **instalado** (recomendado) | o Ollama no computador que você já usa | 2,0 GB de disco para o modelo, mais o próprio Ollama, e 2,9 GB de memória enquanto ele responde | parecidas; suas respostas podem variar na redação |
| **uma máquina virtual** | Ubuntu Server 24.04 LTS com o Ollama dentro | o mesmo, mais o disco e a memória da própria máquina virtual; sem placa de vídeo, então mais lento | parecidas, como no instalado |
| **online** | um modelo pago atrás de uma API, acessado com a sua própria chave | dinheiro por token, e os números do curso não serão os seus | diferentes |

**Instalado é o caminho recomendado.** O Ollama é um programa e um diretório de modelos; ele não
mexe em mais nada do seu sistema, e usa a sua placa de vídeo quando encontra uma que consiga usar,
o que uma máquina virtual não consegue dar a ele. O modelo precisa de memória mais do que de
qualquer outra coisa: carregado, ele ocupou 2,9 GB na máquina em que estas aulas foram capturadas,
o que um computador com 8 GB tem de sobra. Um com menos deve ficar com o modelo menor descrito
abaixo.

Todas as capturas deste curso foram feitas no Ubuntu 24.04 com o Ollama 0.40.0, numa máquina com
quatro núcleos de processador e sem placa de vídeo. **Um modelo de linguagem não é uma
calculadora**: com as configurações que o harness usa, o mesmo prompt dá a mesma resposta toda vez
numa mesma máquina. Outra máquina, outra versão do Ollama ou outra compilação do modelo pode
redigir uma resposta de outro jeito e, de vez em quando, rotulá-la de outro jeito. Então as suas
contagens podem ficar a algumas unidades das impressas aqui. O que cada aula mostra deve continuar
valendo: se uma mudança consertou treze respostas aqui e duas na sua máquina, a aula é sobre por
que ela mexeu em alguma coisa.

## Instalado

No Linux, o script do próprio Ollama instala o programa e o configura como um serviço que sobe com
o computador:

```sh
curl -fsSL https://ollama.com/install.sh | sh
```

No macOS e no Windows, baixe o instalador em ollama.com e execute. **Esses dois não foram rodados
para este curso.** No Windows, os comandos do curso são digitados num terminal Linux: instale o
WSL com o Ubuntu 24.04 (`wsl --install -d Ubuntu-24.04` no PowerShell) e instale o Ollama dentro
dele com a linha de Linux acima, para que o modelo e o harness morem no mesmo lugar.

Depois baixe o modelo. É um comando só, e na primeira vez ele traz uns dois gigabytes:

```sh
ollama pull llama3.2:3b
```

Confira o que você tem:

```
ana@lab:~/triage$ python3 --version
Python 3.12.3
ana@lab:~/triage$ ollama --version
ollama version is 0.40.0
ana@lab:~/triage$ ollama list
NAME           ID              SIZE      MODIFIED       
llama3.2:3b    a80c4f17acd5    2.0 GB    57 minutes ago    
ana@lab:~/triage$ du -sh /usr/local/lib/ollama
2.1G	/usr/local/lib/ollama
```

O `ollama list` mostra o que está no disco, e o `du`, quanto o próprio Ollama ocupou: 2,1 GB, a
maior parte bibliotecas para placas de vídeo. O Python 3 já vem no Ubuntu e no macOS; em outro
sistema, instale-o a partir de python.org. A versão 3.8 ou mais nova basta.

### Um computador mais fraco

Se o seu computador tem menos de 8 GB de memória, ou se uma resposta leva mais de meio minuto, use
o **`llama3.2:1b`**, da mesma família, com um terço do tamanho:

```sh
ollama pull llama3.2:1b
```

Ele ocupa 1,3 GB em disco. Todo comando do curso aceita `--set model=llama3.2:1b`, ou você pode
trocar o modelo em `DEFAULTS`, no topo do `pl.py`, uma vez só. Aqui está o melhor prompt desta
aula rodado com ele, e quanto de memória os dois modelos ocuparam depois de responder:

```
ana@lab:~/triage$ pl run prompts/v3-examples.txt cases/dev.jsonl --out runs/v3-1b.jsonl --set model=llama3.2:1b
40 calls, prompt 1d9c6ec4, llama3.2:1b, written to runs/v3-1b.jsonl
ana@lab:~/triage$ ollama ps
NAME           ID              SIZE      PROCESSOR          CONTEXT    RUNNER      UNTIL              
llama3.2:1b    baf6a787fdff    2.0 GB    25%/75% CPU/GPU    4096       llamacpp    4 minutes from now    
llama3.2:3b    a80c4f17acd5    2.9 GB    30%/70% CPU/GPU    4096       llamacpp    3 minutes from now    
ana@lab:~/triage$ pl check runs/v3-1b.jsonl
check      pass  fail
json         36     4
fields       36     4
labels       36     4
category     14    26
urgency       9    31
all           9    31
```

2,0 GB de memória contra 2,9, e **9 respostas de 40 passando onde o `llama3.2:3b` passa 28**. Ele
roda, e é um modelo bem mais fraco: espere contagens muito mais baixas nestas aulas com ele. As
verificações são o assunto deste curso, e funcionam do mesmo jeito.

## Numa máquina virtual

Se você prefere manter tudo separado do seu sistema, monte uma máquina virtual com o **Ubuntu
Server 24.04 LTS**: VirtualBox no Windows e no Linux, UTM num Mac. Dê a ela pelo menos 8 GB de
memória e 20 GB de disco, e dentro dela siga os passos de Linux acima. A aula 4 de
`virtualization` monta uma no VirtualBox passo a passo.

Uma máquina virtual não ganha placa de vídeo, então cada resposta é calculada no processador. Foi
assim que este curso foi capturado, e uma execução de quarenta mensagens levou alguns minutos:
funciona, e é mais lento do que seria no computador que está por baixo.

## Online, com a sua própria chave

O último caminho é um modelo comercial atrás de uma API: você cria uma conta num provedor, cadastra
uma forma de pagamento e recebe uma chave. O harness fala com um modelo por uma função só,
`call()`, e esta versão dela fala a API de chat compatível com a da OpenAI que a maioria dos
provedores oferece:

```python
def call(prompt, params):
    """One request to an OpenAI-compatible API, paid for with your own key."""
    body = {"model": params["model"], "temperature": float(params["temperature"]),
            "seed": int(params["seed"]), "max_tokens": int(params["num_predict"]),
            "messages": [{"role": "user", "content": prompt}]}
    req = urllib.request.Request(os.environ["PL_BASE"] + "/chat/completions",
                                 json.dumps(body).encode(),
                                 {"Content-Type": "application/json",
                                  "Authorization": "Bearer " + os.environ["PL_KEY"]})
    start = time.time()
    try:
        with urllib.request.urlopen(req, timeout=600) as r:
            reply = json.load(r)
    except urllib.error.HTTPError as e:
        die("the API answered %d: %s" % (e.code, e.read().decode().strip()))
    choice, usage = reply["choices"][0], reply.get("usage", {})
    return {"text": choice["message"]["content"], "stop": choice["finish_reason"],
            "tokens_in": usage.get("prompt_tokens", 0),
            "tokens_out": usage.get("completion_tokens", 0),
            "seconds": round(time.time() - start, 2)}
```

Troque a `call()` do `pl.py` por ela, ponha em `PL_BASE` o endereço do provedor e em `PL_KEY` a sua
chave, e passe o nome do modelo do provedor com `--set model=...`. Ela foi testada contra o próprio
endereço compatível com a OpenAI do Ollama, `http://127.0.0.1:11434/v1`, e contra nenhum provedor;
confira o endereço, os nomes dos modelos e os preços na documentação do seu.

**Este caminho custa dinheiro a cada chamada**, e uma aula que roda um prompt em quarenta mensagens
dez vezes são quatrocentas chamadas. Alguns provedores oferecem uma cota gratuita; o curso nunca
depende de uma, porque uma cota gratuita é uma condição que outra pessoa pode mudar. Um modelo
comercial também é muito mais forte que o `llama3.2:3b`, então algumas das falhas que estas aulas
contam não vão acontecer com você, o que é boa notícia para o seu prompt e menos boa para a aula.

## Onde este curso começa

`prompt-engineering` apresentou as técnicas: exemplos few-shot nas aulas 20 e 21, temperatura na
aula 13, injeção na aula 7. **Este curso retoma várias delas de propósito**, com outra pergunta.
Lá a pergunta era o que é uma técnica. Aqui é se ela ainda funciona na quadragésima mensagem, e como
você saberia se ela parasse de funcionar.

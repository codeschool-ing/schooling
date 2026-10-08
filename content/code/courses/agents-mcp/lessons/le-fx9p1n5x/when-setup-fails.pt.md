---
title: Quando a montagem não funciona
version: 2
---

Estas são as falhas encontradas durante a gravação deste curso, cada uma com o que imprimiu. Quase todas são um passo esquecido, e a mensagem diz qual depois que você sabe lê-la.

```
ana@lab:~/agents$ ANTHROPIC_BASE_URL=http://127.0.0.1:11435 python agent.py "Which ways can I pay?" 2>&1 | tail -n 1
anthropic.APIConnectionError: Connection error.
ana@lab:~/agents$ env -u ANTHROPIC_API_KEY -u ANTHROPIC_BASE_URL python agent.py "Which ways can I pay?" 2>&1 | tail -n 1
TypeError: "Could not resolve authentication method. Expected one of api_key, auth_token, or credentials to be set. Or for one of the `X-Api-Key` or `Authorization` headers to be explicitly omitted"
ana@lab:~/agents$ python3.11 -c "import shop; print(shop.search_help(\"returns\"))" 2>&1 | tail -n 1
AttributeError: module 'math' has no attribute 'sumprod'
ana@lab:~/agents$ ollama run llama3.2:3x "Hello"
pulling manifest pulling manifest pulling manifest pulling manifest pulling manifest pulling manifest pulling manifest 
Error: pull model manifest: file does not exist
ana@lab:~/agents$ ollama ps
NAME                 ID              SIZE      PROCESSOR          CONTEXT    RUNNER      UNTIL              
all-minilm:latest    1b226e2802db    48 MB     56%/44% CPU/GPU    256        llamacpp    4 minutes from now    
llama3.2:3b          a80c4f17acd5    3.5 GB    41%/59% CPU/GPU    8192       llamacpp    4 minutes from now    
```

**`APIConnectionError: Connection error.`** Nada respondeu no endereço que o programa recebeu. Aqui o endereço era o do gravador, e o gravador não estava rodando; a mesma linha aparece quando o próprio Ollama está parado, e aí o `ollama --version` também avisa, com `Warning: could not connect to a running Ollama instance` debaixo da versão. No Linux, `sudo systemctl start ollama` o inicia; no macOS e no Windows, abra o aplicativo do Ollama.

**`Could not resolve authentication method`.** A biblioteca não achou chave nenhuma, o que quer dizer que o `ollama.env` não chegou a este shell. Ou o ambiente foi ativado antes de o arquivo ser acrescentado ao `.venv/bin/activate`, ou este é um terminal novo em que ninguém digitou `. .venv/bin/activate`. Sem a URL base, o programa também teria ido ao endereço de verdade do fornecedor em vez do Ollama.

**`module 'math' has no attribute 'sumprod'`.** Um Python anterior ao 3.12. O `shop.py` usa `math.sumprod`, que chegou no 3.12; a linha acima rodou o 3.11 de propósito para mostrar isso. Dentro do ambiente ativado, `python --version` deve dizer 3.12 ou mais novo. Num Ubuntu mais antigo, instale um Python mais novo antes de criar o `.venv`, porque um ambiente virtual fica com o Python com que foi criado.

**`pull model manifest: file does not exist`.** O Ollama não tem modelo com esse nome, e aqui o nome foi digitado errado: `3x` no lugar de `3b`. O `ollama list` mostra os nomes que você tem, exatamente como um programa precisa escrevê-los.

**A coluna `CONTEXT` do `ollama ps` diz 4096.** A configuração de contexto não pegou. O Ollama a lê quando começa, então o serviço precisa ser reiniciado depois que ela é escrita, e no Linux ela tem de estar no ambiente do serviço, não no do seu shell. O sintoma sem essa conferência é pior que um erro: uma conversa longa perde o começo, e o modelo responde como se a Bia nunca tivesse dito quem era.

**Um download para no meio.** Um modelo tem alguns gigabytes, e uma conexão que cai durante o `ollama pull` o encerra com erro. Rode o mesmo `ollama pull` de novo: ele continua do que já está no disco.

**Instalar o Ollama à mão a partir do arquivo compactado.** No Linux, o arquivo de `ollama.com/download` é comprimido com zstd, e num sistema sem o programa `zstd` o `tar` para com um erro que cita `unzstd`. `sudo apt install zstd` resolve. O script de instalação não precisa de nada disso, e é por isso que ele é o caminho indicado acima.

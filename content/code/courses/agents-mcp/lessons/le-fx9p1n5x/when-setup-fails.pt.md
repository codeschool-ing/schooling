---
title: Quando o laboratório não sobe
version: 1
---

O `lab.sh` para no primeiro comando que falha (`set -euo pipefail`), então as últimas linhas que ele imprimiu nomeiam o passo. Estas são as falhas que o script verifica, e as que ele não tem como verificar, na ordem em que a montagem as encontra.

**`python3 is required`, `npm is required`, `ip is required`, `openssl is required`.** O passo `need` procura os quatro programas antes de mexer em qualquer coisa. No Ubuntu 24.04, `apt-get install python3 python3-venv nodejs npm iproute2 openssl` cobre todos; o Node.js precisa ser a versão 22, que o pacote do próprio Ubuntu não é, então instale pelo NodeSource ou com o `nvm`.

**`embeddings-vectors' lab is required beside this course`.** O laboratório lê `minilm.py`, `help.jsonl` e `books.jsonl` de `../embeddings-vectors/lab`. Se o diretório do curso foi copiado sozinho, copie aquele ao lado; nada daquele laboratório precisa estar montado ou rodando.

**O pip falha no meio das bibliotecas.** Em geral é uma rede que não alcança o PyPI, ou um Python diferente do 3.11 para o qual ainda não existem wheels do `onnxruntime`. As versões fixadas em `PYLIBS` são aquelas com que toda transcrição foi feita; trocar uma muda o que as aulas imprimem.

**`sha256sum: WARNING: 1 computed checksum did NOT match`.** O modelo de embeddings baixado do bucket do Chroma não é o arquivo com que o curso foi gravado. Não edite o checksum para passar: apague a cópia baixada pela metade e rode o `up` de novo, e se continuar diferente, o bucket agora serve outro arquivo e as notas de busca das aulas não vão bater.

**O `tiktoken` levanta `ValueError` sobre um hash durante o `build_tokenizer`.** A codificação foi reconstruída a partir do js-tiktoken e o tiktoken a recusou, o que quer dizer que o pacote do npm mudou. O script fixa `js-tiktoken@1.0.21` por esse motivo.

**`labllm did not start; see /run/labllm.out`.** Leia esse arquivo. `Address already in use` quer dizer que alguma coisa ocupa a porta 8600, muitas vezes um labllm de uma montagem anterior que nunca foi parado: `ss -ltnp | grep 8600` nomeia o processo, e `sudo bash lab.sh down` para o do laboratório.

**Um programa imprime `[scripted-1 has no reply written for this conversation]`.** O laboratório funciona; o curso não tem regra para o que foi perguntado. O labllm só responde às conversas que as aulas roteirizam, então uma pergunta sua cai nesta resposta. Esse é o limite honesto de um substituto, e o `/var/log/labllm/requests.jsonl` mostra exatamente o que ele recebeu.

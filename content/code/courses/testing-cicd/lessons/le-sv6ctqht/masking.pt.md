---
title: Mascaramento nos logs, e os limites dele
version: 1
---

Serviços de CI tentam manter segredos fora dos logs **mascarando**: antes de uma linha da saída de um
job ser guardada, toda ocorrência do valor de um segredo registrado é trocada por asteriscos. É uma
rede de segurança útil, e funciona por correspondência exata, que é tanto o motivo de funcionar quanto
onde ela para.

Aqui o laboratório faz o papel do mascarador com `sed`, trocando o valor exato do token, e uma linha de
depuração descuidada faz o papel da saída do job:

```
ana@laptop:~/shipquote$ printf 'Authorization: Bearer lab-live-token\n' | sed 's/lab-live-token/***/g'
Authorization: Bearer ***
ana@laptop:~/shipquote$ printf 'Bearer lab-live-token' | base64 | sed 's/lab-live-token/***/g'
QmVhcmVyIGxhYi1saXZlLXRva2Vu
ana@laptop:~/shipquote$ printf 'Bearer lab-live-token' | base64 | base64 -d; echo
Bearer lab-live-token
```

A primeira linha é mascarada: o valor apareceu como foi escrito, então foi achado e trocado. A segunda
linha é o mesmo cabeçalho **codificado em base64**, como muitas ferramentas fazem com credenciais, e
passou intacta, porque os bytes `lab-live-token` não aparecem nela. A terceira mostra o que qualquer
pessoa que leia esse log consegue fazer: decodificar, e lá está o token.

O GitHub documenta exatamente esse limite: o mascaramento casa com o valor do segredo como foi
registrado, e um valor transformado, codificado, quebrado em linhas ou impresso pela metade não é
mascarado. O mesmo vale para as variáveis mascaradas do GitLab. **O mascaramento é a rede embaixo do
trapézio, não o número.**

## Não imprimir de jeito nenhum

A defesa que se sustenta é um programa que nunca imprime os próprios segredos. Depois de uma cotação
pela transportadora na produção, o log foi vasculhado atrás do token:

```
ana@laptop:~/shipquote$ curl -s "http://127.0.0.1:8300/quote?cep=01310-100&weight=1200&subtotal=5000"; echo
{"cep": "01310-100", "zone": "SP", "cents": 1860, "price": "R$ 18,60"}
ana@laptop:~/shipquote$ grep -c lab-live-token ~/envs/production/app.log
0
ana@laptop:~/shipquote$ tail -2 ~/envs/production/app.log
GET /version 200 0.1ms v=1.5.0
GET /quote?cep=01310-100&weight=1200&subtotal=5000 200 38.1ms v=1.5.0
```

**Nenhuma linha o contém.** O log de requisições registra o método, o caminho, o status, o tempo e a
versão, e nada dos cabeçalhos; o cliente da transportadora manda o token num cabeçalho e nunca o grava
em lugar nenhum. Quando a transportadora falha, a linha que `price` registra traz a mensagem do erro,
que a seção 10 mostra, e uma mensagem de erro HTTP não inclui os cabeçalhos da requisição.

Três hábitos mantêm isso assim:

- **Registre o que o programa decidiu, não o que ele recebeu.** "Transportadora indisponível, usando a
  tabela" ajuda quem está de plantão; um despejo do objeto da requisição ajuda quem ler o log depois.
- **Nunca ligue saída de depuração que imprime cabeçalhos ou ambiente num ambiente compartilhado.**
  `set -x` num passo de shell imprime cada comando com as variáveis expandidas; a depuração de
  requisições de um framework imprime cabeçalhos `Authorization`.
- **Procure vazamentos de propósito.** O `grep -c` acima, rodado contra logs e artefatos, é um teste
  como outro qualquer, e pode rodar no pipeline.

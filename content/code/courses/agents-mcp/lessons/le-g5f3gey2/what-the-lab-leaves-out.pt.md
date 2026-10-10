---
title: O que o laboratório deixa de fora
version: 2
---

O `second_machine.sh` escreveu os tokens em arquivos. Numa implantação de verdade, um cliente os obtém pelo fluxo que a especificação define, e este é esse fluxo no fim da cadeia da seção 04, na ordem em que um cliente o segue:

1. **Registrar-se, ou ser conhecido.** A especificação diz que clientes e servidores de autorização devem aceitar **Client ID Metadata Documents**: o id do cliente é uma URL onde um documento que o descreve está publicado. O pré-registro é o outro caminho. O registro dinâmico de clientes, em que revisões anteriores se apoiavam, está obsoleto em 2026-07-28.
2. **Mandar a pessoa ao endpoint de autorização** com um pedido de autorização que leva um desafio **PKCE** (o `S256` dos metadados: o cliente guarda um segredo aleatório e manda o hash dele, então um código de autorização roubado não serve sem o segredo), os escopos que quer, e o **parâmetro `resource`** nomeando a URL canônica do servidor MCP (RFC 8707). A pessoa faz login e consente lá, nunca no cliente.
3. **Trocar o código por um token** no endpoint de token, provando o segredo do PKCE, e conferir se a resposta veio do emissor que o cliente registrou antes de redirecionar.
4. **Mandar o token** no cabeçalho `Authorization` em todo pedido a esse servidor, e a nenhum outro.

Duas regras da especificação ficam dos dois lados desse fluxo, e as duas são sobre para onde um token pode ir. **Um cliente não pode mandar a um servidor nenhum token que não tenha sido emitido para aquele servidor pelo servidor de autorização dele.** E **um servidor não pode repassar um token que recebeu**: se ele chama outro serviço, obtém um token próprio para esse serviço. A segunda regra tem nome nas notas de segurança da especificação, *token passthrough* (repasse de token). O motivo é a checagem de audiência da seção 06 vista do outro lado: um servidor que repassasse tokens deixaria qualquer cliente agir no serviço de baixo com o que o token permitisse, e o serviço de baixo não conseguiria distinguir.

O que o laboratório roda é tudo o que um servidor precisa fazer com um token depois de tê-lo: conferi-lo, conferir se foi emitido para este servidor, conferir o escopo, e recusar sem dizer que checagem falhou. Essa metade não depende de como o token foi obtido.

Quando terminar com a segunda máquina, desmonte-a:

```
ana@lab:~/agents$ sudo bash second_machine.sh down
```

Não imprime nada. O namespace, o cabo e os dois nomes no `/etc/hosts` somem; o usuário `mcpd` e o `/srv/mcp` ficam até o próximo `up` trocar os arquivos.

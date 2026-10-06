---
title: O Helicone no laboratório, e o pedido que ele recusou
version: 1
---

O Helicone é código aberto, e publica uma imagem única que roda tudo num contêiner: o gateway e a API
(chamados `jawn`), as telas web, PostgreSQL, ClickHouse e MinIO. `sudo bash lab.sh helicone` o inicia a
partir dessa imagem, num digest fixo. É uma imagem de 14 GB, o que diz alguma coisa sobre quanto custa
um contêiner com cinco serviços dentro. O gateway responde na porta 8585:

```
ana@lab:~/obs$ curl -s http://127.0.0.1:8585/healthcheck; echo
{"status":"healthy :)"}
ana@lab:~/obs$ python via_gateway.py
InternalServerError: Invalid API base "http://127.0.0.1:8600"
```

**O Helicone se recusou a repassar para o labobs.** O gateway mantém uma lista dos domínios de
fornecedores para os quais aceita repassar, e `http://127.0.0.1:8600` não está nela. Ali terminou o que
o laboratório conseguiu fazer com o Helicone: sem a chave de um fornecedor real para onde repassar, não
havia nada para ele registrar, e nenhuma resposta desta aula passou por ele.

A recusa merece um parágrafo, porque está certa. Um gateway que repassasse para qualquer URL num
cabeçalho seria um relé aberto: qualquer um capaz de lhe mandar um pedido poderia fazê-lo chamar
qualquer endereço que ele alcance, inclusive os serviços internos atrás dele, o ataque chamado
**falsificação de requisição do lado do servidor** (SSRF). Permitir só domínios de fornecedores
conhecidos é a defesa, e é a configuração a procurar em qualquer gateway, comprado ou feito em casa. Um
servidor de modelo interno seria acrescentado a essa lista por quem cuida do gateway, o que é uma
mudança que alguém tem de fazer de propósito.

## O que não foi rodado

O Helicone hospedado, onde a maioria das equipes o usa, não foi alcançado do laboratório, e nenhum
pedido passou pelo gateway auto-hospedado até um fornecedor real. O que a documentação descreve e este
curso não verificou: os painéis de pedidos, custo e latência por usuário e propriedade; o cache e os
limites configurados por cabeçalhos; e as sessões que agrupam uma cadeia de chamadas. Cada um se
comporta como a versão de gateway de algo que as aulas 3 a 5 construíram a partir de spans, e a
comparação honesta é a da última seção, não uma lista de funcionalidades.

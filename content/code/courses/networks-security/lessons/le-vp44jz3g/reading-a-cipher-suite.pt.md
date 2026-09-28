---
title: Lendo uma suíte de cifras
version: 1
---

As duas respostas da seção anterior disseram o que cada conexão usou. Uma **suíte de cifras**
(cipher suite) do TLS 1.2 nomeia quatro escolhas de uma vez, e cada parte corresponde a uma aula
deste curso:

| parte de `ECDHE-ECDSA-AES256-GCM-SHA384` | o que ela escolhe | aula |
|---|---|---|
| `ECDHE` | acordo de chaves: Diffie-Hellman de curva elíptica, **efêmero**, novo a cada conexão | 10 |
| `ECDSA` | como o servidor prova que tem a chave do seu certificado: uma assinatura ECDSA | 11, 12 |
| `AES256-GCM` | a cifra simétrica para os dados, autenticada | 10 |
| `SHA384` | o hash usado dentro do handshake para derivar as chaves | 11 |

O TLS 1.3 simplificou o nome à parte que varia, `TLS_AES_256_GCM_SHA384`: o acordo de chaves é sempre
Diffie-Hellman efêmero e a assinatura é fixada pelo certificado, então nenhum dos dois fica para
negociar. **Isso eliminou categorias inteiras de escolhas fracas de uma vez**: o TLS 1.3 não tem
suíte sem sigilo futuro (forward secrecy) nem cifra sem autenticação.

O que exigir em um servidor, dito como propriedades e não como uma lista que vai envelhecer:

- **acordo de chaves efêmero** (`ECDHE` ou `DHE`): sigilo futuro, para que uma chave roubada no ano
  que vem não abra as gravações deste ano;
- **criptografia autenticada** (`GCM` ou `CHACHA20-POLY1305`): a recusa de um byte alterado, da aula 10;
- **nada** de troca de chaves RSA, suítes em modo CBC, RC4, 3DES ou qualquer coisa marcada `EXPORT` ou `NULL`.

Um servidor que oferece só TLS 1.2 e 1.3 com essas propriedades, como este, não precisa de mais
nenhuma configuração de cifras para a maioria dos usos; os padrões do software atual são a lista acima.

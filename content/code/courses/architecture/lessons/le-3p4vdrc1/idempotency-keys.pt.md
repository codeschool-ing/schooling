---
title: Chaves de idempotência, e o pagamento mandado duas vezes
version: 1
---

O mesmo problema existe sem nenhum broker. Um cliente aperta "pagar", a requisição chega à API de
pagamentos e o cartão é cobrado, e então a conexão cai antes de a resposta chegar. O navegador, ou o
servidor da loja, não consegue dizer se a cobrança aconteceu, exatamente a incerteza da aula 2. Tentar de
novo pode cobrar duas vezes; não tentar pode deixar o pedido sem pagamento.

**A correção é uma chave escolhida por quem chama, mandada em toda tentativa da mesma requisição.** Quem
chama gera um valor único uma vez, para este pagamento, e o manda na primeira tentativa e em todo retry,
em geral num cabeçalho chamado `Idempotency-Key`. O servidor guarda cada chave com a resposta que
produziu:

| o servidor vê uma chave que é… | ele faz |
| --- | --- |
| nova | o trabalho, e depois guarda a chave e a resposta juntas |
| já guardada com uma resposta | nada novo: devolve a resposta guardada |
| guardada e ainda em andamento | responde `409 Conflict`, para quem chama esperar e perguntar de novo |

A API da Stripe tornou esse padrão conhecido, e um rascunho do IETF descreve o cabeçalho
`Idempotency-Key` para HTTP em geral. Duas regras o fazem funcionar:

- **Quem chama cria a chave, não o servidor**, porque o objetivo é identificar a tentativa através de
  uma falha que o servidor pode nunca ter visto.
- **A chave é criada uma vez por operação pretendida, antes da primeira tentativa**, e guardada por quem
  chama, para um retry depois de quem chama reiniciar ainda mandar a mesma. Uma chave gerada nova a cada
  retry não identifica nada.

O armazenamento de chaves no servidor é a tabela `processed` da seção anterior, com a resposta guardada
ao lado. O id da mensagem no broker e a chave HTTP são a mesma ideia em dois lugares: **um nome estável
para um efeito pretendido, para toda repetição poder ser casada com ele.**

## Onde a Quitanda precisa de uma

Onde quer que um efeito não seja idempotente por natureza e um retry seja possível: cobrar um cartão,
criar um pedido a partir de um formulário de checkout que um cliente nervoso manda duas vezes, mandar
um reembolso, baixar estoque. Em cada caso o identificador já existe ou é barato de criar, o id do
pedido, a sessão de checkout, e a versão cara é a descoberta depois que o extrato do banco de um cliente
mostra a cobrança duas vezes.

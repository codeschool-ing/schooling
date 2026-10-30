---
title: Qual ação, em qual orçamento
version: 1
---

**Uma ação ligada a um orçamento roda sem uma pessoa, sobre números atrasados, então a pergunta não é o que ela pode
fazer, mas o que ela pode fazer com segurança enquanto ninguém olha.** A função da etapa anterior publicou três
decisões e não executou nenhuma. Esta etapa é sobre quem consome o `ops-actions`, e nada nela rodou: parar uma máquina
exige o Compute Engine, e nenhum emulador responde por ele.

## Três ações, da branda à drástica

| ação | o que faz | desfeita por | segura em |
|---|---|---|---|
| chamado ou acionamento | avisa quem pode agir, pelas rotas da lição 14 | nada a desfazer | todo orçamento |
| parar as máquinas do sandbox | para as instâncias do Compute Engine em execução num projeto ou pasta; os discos ficam e continuam custando | ligá-las de novo | um sandbox, nunca produção |
| remover a conta de faturamento | desliga o projeto do faturamento, e todo serviço pago nele para | ligá-la de novo, à mão | um projeto de que ninguém depende |

**O chamado e o acionamento são o que o orçamento da loja recebe.** Um orçamento de produção que parasse produção
transformaria um problema de custo numa queda que os clientes sentem, e a lição 15 já tem nome para isso.

**Parar máquinas é o que o sandbox recebe.** O Google publica um exemplo que faz exatamente isso a partir de uma
mensagem de orçamento: quando `costAmount` passa de `budgetAmount`, ele lista as instâncias de uma zona e para as que
estão rodando. Parar é o grau certo de força para um sandbox: o trabalho é pausado em vez de perdido, os discos ficam,
e o dono religa o que ainda precisa. Na versão da loja o consumidor lê o `ops-actions`, pega só `stop-sandbox`, e para
as instâncias dos projetos sob a pasta sandbox.

**Remover a conta de faturamento é o outro exemplo do Google**, e a coisa mais drástica que um orçamento pode
disparar. Ele deixa vazia a conta de faturamento do projeto, o que para de uma vez tudo o que é pago no projeto. Isso
cabe num projeto que existe para experimentar e de que ninguém sentiria falta por um dia, e em nenhum outro lugar.

## Do que o consumidor precisa

- **Uma conta de serviço própria, com o papel mais estreito que faz o trabalho.** Parar instâncias é uma permissão no
  Compute Engine; desligar o faturamento é um papel de faturamento. A regra da lição 17 vale: nenhum arquivo de chave,
  a função roda como essa identidade.
- **Um jeito de desfazer, por escrito.** O chamado que acompanha o `stop-sandbox` diz quais máquinas foram paradas,
  para o dono saber o que ligar de novo.
- **Um teste com uma mensagem, antes de confiar nele.** O primeiro cruzamento real de um orçamento é o pior momento
  para descobrir que o filtro da função também pega produção. Publicar uma mensagem inventada num tópico de teste, como
  a etapa anterior fez, é como isso se descobre numa terça à tarde.

**Uma ação não substitui a pessoa; ela ganha tempo para ela.** O sandbox parado em 102% ainda tem uma pessoa cujo
experimento custou mais que o planejado, e é o chamado que chega até ela.

---
title: Métricas de proteção e o critério de sucesso
version: 1
---

Uma mudança pode subir a métrica primária e fazer estrago em outro lugar. Um checkout de um passo
que esconde a taxa de entrega até o pedido chegar vai subir a conversão e os reembolsos juntos.
**Métricas de proteção** (em inglês, *guardrails*) são os números que não podem piorar, escritos
junto com a primária:

- **taxa de reembolso e de reclamação**, para que a conversão não seja comprada com decepção;
- **tempo de carregamento da página e taxa de erro**, para pegar uma versão lenta ou quebrada;
- **valor médio do primeiro pedido**, para notar uma versão que vende caixas menores.

Uma métrica de proteção não é testada para melhora. Ela é vigiada para dano, e um dano claro para o
teste, diga o que disser a métrica primária.

## O critério de sucesso

A última parte, e a mais esquecida, é a regra que transforma o resultado numa decisão, escrita antes
de o dado existir. Para o teste da Panela ela diz:

| | |
|---|---|
| **lançar** | a conversão sobe, a diferença é significativa a 5 por cento bilateral, e nenhuma métrica de proteção fica claramente pior |
| **não lançar** | a conversão cai significativamente, ou uma métrica de proteção fica claramente pior |
| **inconclusivo** | qualquer outra coisa; o teste rodou pelo tempo planejado e o efeito, se houver, é menor do que ele consegue detectar |

e duas linhas práticas:

- o teste roda pelo **número de visitantes que a aula 8 calcula, em semanas inteiras**, e não é
  parado antes porque parece bom (a aula 11 mostra o que parar cedo faz);
- **um resultado inconclusivo é um resultado**: ele diz que o efeito, se existir, é menor que 0,6
  ponto, e isso basta para decidir se a mudança vale manter por outros motivos.

## Escreva tudo

Tudo nesta aula cabe numa página, e times que rodam muitos testes guardam essa página como modelo: a
mudança, a hipótese com tamanho e motivo, a métrica primária e a unidade dela, as métricas
secundárias, as de proteção, o critério de sucesso, a amostra e a duração planejadas, e a data em
que foi escrita. **Escrever antes do teste é o ponto inteiro**: um critério escolhido depois de ver o
dado é uma descrição do dado, não um teste dele.

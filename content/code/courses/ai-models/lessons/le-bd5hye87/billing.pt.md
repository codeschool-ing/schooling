---
title: Quem manda a conta
version: 1
---

A página de preços do Hugging Face começa com a mesma afirmação que a do OpenRouter:

```
# huggingface/hub-docs@08175d0f docs/inference-providers/pricing.md
   3| Access 200+ models from leading AI inference providers with centralized, transparent, pay-as-you-go pricing. No infrastructure management required—just pay for what you use, with no markup from Hugging Face.
```

O que a conta recebe para começar é pouco, e a página diz isso:

```
# huggingface/hub-docs@08175d0f docs/inference-providers/pricing.md
   9| | Account Type                     | Monthly Credits          | Can be spent on                   | Extra usage (pay-as-you-go)     |
  10| | -------------------------------- | ------------------------ | --------------------------------- | ------------------------------- |
  11| | Free Users                       | $0.10, subject to change | Inference Providers               | yes (credits purchase required) |
  12| | PRO Users                        | $2.00                    | All Hugging Face compute services | yes                             |
```

Dez centavos por mês bastam para experimentar um modelo nos quarenta casos da aula 5 e não bastam
para rodar uma mesa: daí em diante, compram-se créditos. E há dois caminhos para o dinheiro:

```
# huggingface/hub-docs@08175d0f docs/inference-providers/pricing.md
  24| | Feature | **Routed by Hugging Face** | **Custom Provider Key** |
  25| | :--- | :--- | :--- |
  26| | **How it Works** | Your request routes through HF to the provider | You set a custom provider key in HF settings |
  27| | **Billing** | Pay-as-you-go on your HF account | Billed directly by the provider |
```

**Roteado pelo Hugging Face**, o provedor é pago pela conta da ana no Hugging Face, uma conta para
todos os provedores, com os créditos mensais aplicados primeiro. **Com uma chave própria do
provedor**, a requisição continua passando pelo Hugging Face, mas o provedor cobra a ana direto, na
conta e nos termos que ela tem com ele, e os créditos não valem.

Lado a lado com a aula 15, os dois roteadores fazem a mesma oferta com padrões diferentes:

| | OpenRouter | Hugging Face |
|---|---|---|
| preço por token | o do provedor, sem margem | o do provedor, sem margem |
| taxa na compra de créditos | 5,5%, no mínimo US$ 0,80 | nenhuma declarada na página de preços |
| escolha padrão de provedor | com peso para o mais barato | o mais rápido |
| escolher um provedor | `provider.order`, `only`, `ignore` | um sufixo no modelo, ou `provider=` |
| trazer a própria chave do provedor | sim, com taxa além de uma cota grátis | sim |

Qual sai mais barato depende do volume e de qual padrão o código usa, e o segundo é o que se resolve
primeiro, porque é decidido a cada requisição e não aparece na resposta. Para a ana, cuja avaliação
na aula 5 foi de um modelo num provedor, um provedor nomeado na string do modelo é o ajuste que
mantém a avaliação verdadeira.

---
title: Lendo um classificador
version: 1
---

**A acurácia, a fração prevista corretamente, é 89,4%, e é o número menos informativo que o modelo
produziu.** Um modelo que prevê "fica" para todo cliente, sem olhar nada, acerta 83,5% das vezes,
porque a maioria dos clientes fica. A contribuição real do modelo é a distância entre os dois, e a
acurácia esconde essa distância. Sempre que uma categoria é rara, a acurácia lisonjeia.

Outros dois números descrevem o que o modelo faz por quem vai usá-lo.

- **Precisão**, 78,8%: dos clientes que o modelo marca, quantos saem de fato. É o que o time de
  retenção vive: de cada cem clientes para quem liga, setenta e nove estavam mesmo saindo e vinte e um
  estavam bem.
- **Revocação** (*recall*), 48,5%: dos clientes que saem, quantos o modelo marca. É o que o negócio
  vive: de cada cem clientes que vão embora, o modelo avisou sobre quarenta e oito.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 600 230\" role=\"img\" data-fig=\"l17-confusion\" aria-label=\"A matriz de confusão do modelo de churn com limiar de 0,5, como quatro caixas. Saiu e foi marcado: 204. Saiu e não foi marcado: 217. Ficou e foi marcado: 55. Ficou e não foi marcado: 2082. A precisão se lê na coluna dos marcados, a revocação na linha dos que saíram.\"><text x=\"200.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">marcados</text><text x=\"360.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">não marcados</text><text x=\"108.0\" y=\"75.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">saíram</text><rect x=\"120.0\" y=\"40.0\" width=\"160.0\" height=\"70.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"200.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">204</text><text x=\"200.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pegos</text><rect x=\"280.0\" y=\"40.0\" width=\"160.0\" height=\"70.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">217</text><text x=\"360.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">perdidos</text><text x=\"108.0\" y=\"145.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ficaram</text><rect x=\"120.0\" y=\"110.0\" width=\"160.0\" height=\"70.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"200.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">55</text><text x=\"200.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">alarmes falsos</text><rect x=\"280.0\" y=\"110.0\" width=\"160.0\" height=\"70.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">2082</text><text x=\"360.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">deixados em paz</text><path d=\"M121 41 h158 v68 h-158 Z\" stroke=\"var(--phosphor)\" stroke-width=\"2.5\" fill=\"none\"></path><text x=\"200.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">precisão: pegos ÷ marcados</text><text x=\"452.0\" y=\"75.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">revocação: pegos ÷ saíram</text></svg>", "caption": "As mesmas quatro contagens dão toda medida. A precisão é o que o time de retenção vê; a revocação é o que o negócio vê."}
```

As duas puxam em sentidos opostos. Marque mais clientes e a revocação sobe, porque mais dos que saem
são pegos, e a precisão cai, porque mais dos marcados nunca iam sair. **Não existe ajuste que maximize
as duas**, e por isso a próxima etapa escolhe um a partir do que os erros custam.

## Os dois erros não são iguais

Um **alarme falso** custa o que se faz com o cliente marcado: uma ligação, um desconto dado a quem
pagaria o preço cheio. Um **cliente perdido sem aviso** custa o cliente, tudo o que ele gastaria. Na
Panela o segundo é muito mais caro que o primeiro, então o negócio deveria aceitar muitos alarmes
falsos para pegar mais gente saindo, o que quer dizer um limiar mais baixo que o padrão de 0,5.

Esse padrão não tem significado próprio. É o ponto em que o modelo acha que sair é tão provável quanto
ficar, e nada no negócio diz que é ali que a ação deve começar.

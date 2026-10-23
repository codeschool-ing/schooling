---
title: "Táticas: os movimentos que servem a uma qualidade"
version: 1
---

**Uma tática é uma decisão de projeto que influencia a resposta de um atributo de qualidade**: um
movimento conhecido, menor que um padrão, com efeito conhecido e custo conhecido. Len Bass, Paul
Clements e Rick Kazman as catalogaram em *Software Architecture in Practice*, e o catálogo é a ponte
entre um cenário e um projeto: dado o que o cenário exige, que movimentos estão disponíveis?

## Algumas do catálogo

| atributo | tática | o que ela faz | o custo que costuma trazer |
| --- | --- | --- | --- |
| disponibilidade | **redundância** | uma segunda cópia assume quando a primeira falha | mais coisa para operar, e manter as cópias em sincronia |
| disponibilidade | **alternativa local** | uma resposta degradada a partir de dados locais quando a remota está inacessível | os dados locais podem estar desatualizados |
| desempenho | **cache** | guardar uma resposta calculada perto de onde ela é necessária | desatualização, e memória |
| desempenho | **introduzir concorrência** | fazer trabalho independente ao mesmo tempo | complexidade, problemas de ordem |
| desempenho | **limitar a demanda** | enfileirar, estrangular ou descartar requisições acima da capacidade | algumas requisições esperam ou são recusadas |
| modificabilidade | **usar um intermediário** | pôr uma interface ou um adaptador entre duas partes | um salto a mais e mais uma coisa para nomear |
| modificabilidade | **encapsular** | esconder uma decisão atrás de uma interface | a interface precisa ser bem projetada |
| segurança | **auditoria** | registrar quem fez o quê, de forma imutável | armazenamento, e proteger o próprio log |

A coluna de custo é a razão de o catálogo importar: **toda tática paga uma qualidade com outra**, e
dar nome à tática dá nome ao pagamento.

## Do cenário às táticas na Carcará

- **QS-02, embarque sem sinal**, usa *alternativa local*: cada celular guarda a lista de passagens
  da viagem. O custo é a desatualização: uma passagem vendida depois da última sincronização não
  está na lista. O projeto acrescenta uma segunda tática para esse caso, uma **conferência online**
  quando há sinal, e uma regra para quando não há: o motorista aceita uma passagem que o app não
  conhece se o passageiro mostrar o e-mail da compra, e a leitura é enviada depois para conferência.
- **QS-01, compras no pico**, usa *limitar a demanda* na borda, uma fila na frente da compra quando
  a carga passa de 2.500 por minuto, e *cache* dos resultados de busca de viagens por trinta
  segundos.
- **QS-04, um novo meio de pagamento em dez dias**, usa *usar um intermediário*: o adaptador de
  pagamento e sua interface `PaymentPort`, da aula 2. Um novo meio é um novo adaptador atrás da mesma
  porta.

## Os trade-offs, à vista

Escrever as táticas mostra onde as qualidades colidem, que é a conversa que a aula 13 de
`architecture-role` chamou de centro do trabalho do arquiteto. O embarque sem sinal e a recusa
rápida de passagens canceladas são o exemplo do começo desta aula:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l06-tradeoff\" aria-label=\"Um gráfico com duas linhas contra o intervalo de sincronização dos celulares dos motoristas, de 5 a 60 minutos. O tempo máximo em que uma passagem cancelada ainda pode ser aceita na porta sobe em linha reta com o intervalo, de 5 a 60 minutos. O número de sincronizações por celular num dia de dez horas cai à medida que o intervalo cresce: 120 com 5 minutos, 40 com 15, 10 com 60. A escolha de Celeste, 15 minutos, aparece marcada.\"><path d=\"M80.0 250.0 L640.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M80.0 250.0 L80.0 40.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M640.0 250.0 L640.0 40.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M80.0 250.0 L80.0 255.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">5</text><path d=\"M181.8 250.0 L181.8 255.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"181.8\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">15</text><path d=\"M334.5 250.0 L334.5 255.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"334.5\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">30</text><path d=\"M487.3 250.0 L487.3 255.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"487.3\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">45</text><path d=\"M640.0 250.0 L640.0 255.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"640.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">60</text><text x=\"360.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">intervalo de sincronização, minutos</text><text x=\"72.0\" y=\"250.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">0</text><text x=\"72.0\" y=\"180.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">20</text><text x=\"72.0\" y=\"110.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">40</text><text x=\"72.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">60</text><text x=\"648.0\" y=\"250.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">0</text><text x=\"648.0\" y=\"180.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">40</text><text x=\"648.0\" y=\"110.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">80</text><text x=\"648.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">120</text><path d=\"M80.0 232.5 L640.0 40.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M80.0 40.0 L90.2 75.0 L100.4 100.0 L110.5 118.8 L120.7 133.3 L130.9 145.0 L141.1 154.5 L151.3 162.5 L161.5 169.2 L171.6 175.0 L181.8 180.0 L192.0 184.4 L202.2 188.2 L212.4 191.7 L222.5 194.7 L232.7 197.5 L242.9 200.0 L253.1 202.3 L263.3 204.3 L273.5 206.2 L283.6 208.0 L293.8 209.6 L304.0 211.1 L314.2 212.5 L324.4 213.8 L334.5 215.0 L344.7 216.1 L354.9 217.2 L365.1 218.2 L375.3 219.1 L385.5 220.0 L395.6 220.8 L405.8 221.6 L416.0 222.4 L426.2 223.1 L436.4 223.8 L446.5 224.4 L456.7 225.0 L466.9 225.6 L477.1 226.1 L487.3 226.7 L497.5 227.2 L507.6 227.7 L517.8 228.1 L528.0 228.6 L538.2 229.0 L548.4 229.4 L558.5 229.8 L568.7 230.2 L578.9 230.6 L589.1 230.9 L599.3 231.2 L609.5 231.6 L619.6 231.9 L629.8 232.2 L640.0 232.5\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M181.8 250.0 L181.8 40.0\" stroke=\"var(--paper)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><circle cx=\"181.8\" cy=\"197.5\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"181.8\" cy=\"180.0\" r=\"4\" fill=\"var(--amber)\"></circle><text x=\"187.8\" y=\"46.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Celeste: 15 min</text><text x=\"456.7\" y=\"91.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">passagem cancelada ainda aceita, pior caso (min)</text><text x=\"334.5\" y=\"205.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">sincronizações por celular, dia de 10 h</text></svg>", "caption": "As duas linhas são aritmética, não medição: o pior caso é igual ao intervalo, e um dia de dez horas tem 600 minutos divididos por ele. Onde ficar nelas é uma decisão de negócio.", "same": ["Celeste: 15 min"]}
```

Quanto mais vezes os celulares sincronizam, mais cedo uma passagem cancelada é recusada, e mais
dados móveis e bateria os celulares dos motoristas gastam. Celeste escolheu **sincronizar a cada 15
minutos enquanto o ônibus está numa rodoviária ou tem sinal**, aceitando que uma passagem cancelada
no último quarto de hora ainda possa ser aceita na porta. Essa escolha é um registro de decisão, e o
cenário com que ela negocia está nomeado nele.

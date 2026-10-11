---
title: Janelas deslizantes
version: 1
---

**Uma janela deslizante faz a pergunta que a janela fixa só aproxima: quantas requisições este cliente
fez nos últimos dez segundos, contando para trás a partir de agora?** A janela anda com o relógio em
vez de pular, então não há fronteira para atravessar. Ela vem em duas formas, uma exata e uma barata.

## O log: exato, e pago em memória

O **log deslizante** (*sliding log*) guarda a hora de toda requisição aceita. Quando chega uma nova,
ele joga fora as horas com mais de dez segundos, conta o que sobrou e aceita a requisição se a contagem
estiver abaixo do limite.

Rode contra ele a rajada na fronteira da seção anterior. Na primeira requisição depois da fronteira da
janela fixa, o log ainda guarda as dez requisições do último segundo, todas com menos de dez segundos,
então a contagem é dez e a requisição é recusada. Ele continua recusando até a mais antiga dessas dez
completar dez segundos. **Nenhum intervalo de dez segundos chega a ter mais de dez**, que é a promessa
que as pessoas achavam que a janela fixa fazia.

O custo é o próprio log. Um limite de 10 a cada 10 segundos guarda até dez horários por cliente; um
limite de 1.000 por hora guarda até mil, para cada cliente, e toda requisição percorre todos eles. Para
limites pequenos isso não é nada. Para limites grandes com muitos clientes, é a memória que a janela
fixa estava economizando.

## O contador: dois números e uma suposição

O **contador de janela deslizante** (*sliding window counter*) guarda só duas contagens de janela fixa
por cliente, a da janela atual e a da anterior, e estima a contagem deslizante a partir delas. Ele
supõe que as requisições da janela anterior se espalharam por igual nela, então a parte dessa janela
que ainda está dentro dos últimos dez segundos teve uma parcela proporcional delas:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"Uma janela fixa anterior de dez segundos teve 8 requisições e a atual tem 3 até agora. Quatro segundos depois do início da atual, os últimos dez segundos cobrem 60 por cento da anterior, então a estimativa é 8 vezes 0,6 mais 3, ou seja, 7,8.\"><defs><marker id=\"l12-slide-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"60\" y=\"50\" width=\"300\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"210.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">janela anterior: 8 requisições</text><rect x=\"360\" y=\"50\" width=\"300\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"570\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">janela atual:</text><text x=\"570\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">3 até agora</text><rect x=\"180\" y=\"112\" width=\"300\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"330.0\" y=\"129.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">os últimos dez segundos</text><line x1=\"480\" y1=\"36\" x2=\"480\" y2=\"160\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><text x=\"480\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">agora</text><line x1=\"180\" y1=\"168\" x2=\"360\" y2=\"168\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l12-slide-ah)\" marker-start=\"url(#l12-slide-ah)\"></line><text x=\"270.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">6 s de 10: 0,6</text><text x=\"120\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">já fora</text><text x=\"350\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">estimativa  =  8 × 0,6  +  3  =  7,8</text><text x=\"350\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">abaixo do limite de 10, então a requisição é aceita</text></svg>", "caption": "O contador supõe que as requisições da janela anterior se espalharam por igual."}
```

Com limite de dez, uma estimativa de 7,8 deixa a requisição passar. Contra a rajada na fronteira ele
faz o que o log faz: um décimo de segundo depois do início da janela nova, as dez da janela anterior
contam como 10 × 0,99 = 9,9, e a requisição seguinte é recusada.

A suposição é onde ele pode errar, nas duas direções:

| as requisições da janela anterior estavam | a estimativa | o efeito |
|---|---|---|
| espalhadas por igual | certa | nenhum |
| concentradas no começo dela | alta demais: elas já estão fora dos últimos dez segundos | um cliente é recusado quando tinha espaço |
| concentradas no fim dela | baixa demais: estão todas ainda dentro | um cliente consegue algumas além do limite |

Nenhum dos dois erros passa do que cabe numa janela, e o custo é de dois contadores qualquer que seja o
limite. **Essa troca é o motivo de o contador ser a escolha comum para limites grandes com muitos
clientes, e o log para limites pequenos em que a exatidão importa**, como poucas tentativas de login
por minuto.

Nenhum dos dois está no `limits.py`. O limitador que ele usa guarda dois números por cliente, como o
contador, e não tem fronteira, como o log.

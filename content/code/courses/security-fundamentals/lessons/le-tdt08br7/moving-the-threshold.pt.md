---
title: Mexendo no limite
version: 1
---

A correção óbvia para quem adivinha devagar é um limite mais baixo. Três falhas em dez minutos em vez
de cinco:

```
ana@laptop:~$ python3 detect.py 3
threshold 3: 21 alerts
  TP   9   FP  12
  FN   2   TN  75
precision 43%   recall 82%
```

A revocação salta de 27% para **82%**: nove dos onze casos do exercício são pegos agora, e só as duas
janelas de duas falhas de quem adivinhava devagar escapam. A precisão sobe também, para 43%, porque os
verdadeiros positivos cresceram mais rápido que os falsos. Mas olhe os falsos positivos em si: **de sete
para doze.** O backup continua lá, e agora as cinco janelas da equipe com três ou quatro erros de
digitação também alertam. O número de alertas que uma pessoa precisa olhar numa semana dobrou, de dez
para vinte e um.

Essa é a troca que toda detecção faz. **Baixar um limite pega mais, e alerta sobre mais coisas
inofensivas.** Subir faz o contrário. Nenhum limite nesta regra pega quem adivinha devagar e deixa a
equipe em paz, porque três falhas de um atacante e três falhas de uma pessoa com os dedos frios têm a
mesma cara neste log.

```schooling-figure
{"svg": "<svg id=\"sf-threshold\" viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A semana da loja como casos pelo número de falhas em dez minutos. Casos inofensivos, acima da linha: 60 com uma falha, 15 com duas, 4 com três, 1 com quatro, 7 com seis (o backup). Casos do exercício, abaixo da linha: 2 com duas falhas, 6 com três, 3 com oito. Um limite de 5 alerta em tudo de cinco para cima: o backup e quem adivinha rápido. Um limite de 3 também pega quem adivinha devagar e cinco janelas inofensivas da equipe.\"><text x=\"20\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">inofensivos</text><text x=\"20\" y=\"214.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">exercício</text><text x=\"155.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><rect x=\"134\" y=\"48.0\" width=\"42\" height=\"102.0\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"155.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">60</text><text x=\"225.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><rect x=\"204\" y=\"124.5\" width=\"42\" height=\"25.5\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"225.0\" y=\"116.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">15</text><rect x=\"204\" y=\"170\" width=\"42\" height=\"18\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"225.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2</text><text x=\"295.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><rect x=\"274\" y=\"143.2\" width=\"42\" height=\"6.8\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"295.0\" y=\"135.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4</text><rect x=\"274\" y=\"170\" width=\"42\" height=\"54\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"295.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">6</text><text x=\"365.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><rect x=\"344\" y=\"148.3\" width=\"42\" height=\"1.7\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"365.0\" y=\"140.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1</text><text x=\"435.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5</text><text x=\"505.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">6</text><rect x=\"484\" y=\"138.1\" width=\"42\" height=\"11.9\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"505.0\" y=\"130.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">7</text><text x=\"575.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">7</text><text x=\"645.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">8</text><rect x=\"624\" y=\"170\" width=\"42\" height=\"27\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"645.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3</text><text x=\"400\" y=\"290.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">falhas em dez minutos</text><path d=\"M260 14 L260 270\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></path><text x=\"266\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">limite 3</text><path d=\"M400 14 L400 270\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></path><text x=\"406\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">limite 5</text></svg>", "caption": "Tudo à direita da linha gera alerta. Mover a linha para a esquerda pega mais dos dois."}
```

### Corrigir a causa, e não esconder o sintoma

Sete dos falsos positivos têm uma causa só: uma conta cuja senha expirou. Dá para mandar o detector
ignorar essa conta:

```
ana@laptop:~$ python3 detect.py 3 svc-backup
threshold 3: 14 alerts
  TP   9   FP   5
  FN   2   TN  75
precision 64%   recall 82%
```

A precisão sobe para 64% e a revocação não se mexe, o que parece ganho de graça. Não é de graça, e o
motivo importa. **Uma exceção por nome é um furo por nome.** Quem descobrir que falhas da `svc-backup`
nunca geram alerta ganhou uma conta para adivinhar em silêncio. Ignorar uma fonte barulhenta é uma
decisão, e ela vai para o registro de riscos com data, como o controle compensatório da aula 4.

A correção melhor é antes: dar ao backup uma credencial que funcione, e as falhas dele param de
acontecer. O detector então não precisa de exceção, e no dia em que a conta do backup falhar seis vezes
às duas da manhã de novo, isso é notícia que merece alerta.

### Melhor que um limite

Um limite sobre uma contagem é a regra mais simples que existe. Detecções reais alcançam precisão e
revocação mais altas acrescentando informação, boa parte dela os sinais da aula 7: se as falhas são
contra uma conta ou contra muitas, se a origem já fez login com sucesso alguma vez, se um sucesso vem
depois das falhas (uma pessoa esquecida) ou nunca vem (quem adivinha). Cada sinal a mais separa dois
casos que a contagem sozinha não separava. As aulas 6 e 7 de `soc-response` trabalham exatamente nisso.

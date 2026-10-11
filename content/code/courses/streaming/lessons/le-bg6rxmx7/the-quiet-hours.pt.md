---
title: As horas quietas
version: 1
---

**Às três da manhã um stream custa o mesmo que ao meio-dia.** Os brokers mantêm a memória, os
consumidores continuam fazendo poll, os discos guardam a semana. Esse foi o aviso da lição 1, e dá
para medir no seu próprio cluster: deixe-o sem nada para fazer e pergunte o que ele segura.

## Um broker sem nada para fazer

Nada foi escrito há um tempo. A memória residente do nó, há quanto tempo ele roda e quanto tempo de
processador usou no total:

```
ubuntu@stream:~/work$ ps -o rss,etime,time -p $(pgrep -f '^[^ ]*java .*node1')
  RSS     ELAPSED     TIME
543552      01:28 00:00:13
```

Um minuto depois, ainda sem nada escrito, e o disco que o cluster inteiro ocupa depois dos cinco
tópicos desta lição:

```
ubuntu@stream:~/work$ ps -o rss,etime,time -p $(pgrep -f '^[^ ]*java .*node1')
  RSS     ELAPSED     TIME
553948      02:28 00:00:14
ubuntu@stream:~/work$ du -sh ~/kafka-data
33M	/home/ubuntu/kafka-data
```

`RSS` está em kilobytes: mais de meio gigabyte, segurado por um nó sem nada para fazer. No minuto
entre as duas linhas ele usou um segundo de processador. **A memória não volta quando o tráfego
para**: os 512 MB de heap Java que o `cluster.sh` deu ao nó ficam reservados enquanto ele roda. O
tempo de processador quase não se mexe, que é a boa notícia: um broker ocioso é barato de rodar mas
não é de graça manter, porque uma máquina alugada por hora é cobrada pela hora, faça o processador
dela o que fizer.

## Quando o batch sai mais barato

Ponha lado a lado a pergunta da lição 1 e a aritmética desta lição. Um stream vale o que custa quando
alguém age sobre a resposta antes de o batch tê-la produzido. **O que ele custa são sobretudo as
horas sem nada dentro.** Para a Ponto Final, aberta doze horas por dia, metade de cada dia são horas
quietas, e os dados de vendas em si cabem em megabytes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Um dia de meia-noite a meia-noite. As lojas vendem das nove às vinte e uma, desenhado como uma faixa de tráfego. O custo de um stream é uma linha reta pelas vinte e quatro horas, igual às três da manhã e ao meio-dia. O custo de um batch noturno é um único bloco curto às duas da manhã.\" data-fig=\"l17-day\"><text x=\"20\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">vendas</text><line x1=\"130\" y1=\"75\" x2=\"690\" y2=\"75\" stroke=\"var(--wire)\" stroke-width=\"0.8\"></line><text x=\"20\" y=\"125\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">stream</text><line x1=\"130\" y1=\"140\" x2=\"690\" y2=\"140\" stroke=\"var(--wire)\" stroke-width=\"0.8\"></line><text x=\"20\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">batch noturno</text><line x1=\"130\" y1=\"195\" x2=\"690\" y2=\"195\" stroke=\"var(--wire)\" stroke-width=\"0.8\"></line><text x=\"130.0\" y=\"25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">00:00</text><line x1=\"130.0\" y1=\"32\" x2=\"130.0\" y2=\"200\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 4\"></line><text x=\"340.0\" y=\"25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">09:00</text><line x1=\"340.0\" y1=\"32\" x2=\"340.0\" y2=\"200\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 4\"></line><text x=\"620.0\" y=\"25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">21:00</text><line x1=\"620.0\" y1=\"32\" x2=\"620.0\" y2=\"200\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 4\"></line><text x=\"690.0\" y=\"25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">24:00</text><line x1=\"690.0\" y1=\"32\" x2=\"690.0\" y2=\"200\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 4\"></line><path d=\"M 340.0 75 C 363.33333333333337 50 386.6666666666667 45 421.6666666666667 48 C 456.6666666666667 52 503.3333333333333 46 550.0 50 C 596.6666666666667 55 608.3333333333333 70 620.0 75 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"var(--phosphor-dim)\"></path><rect x=\"130.0\" y=\"113\" width=\"560.0\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"235.0\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">horas quietas</text><text x=\"480.0\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pago a toda hora</text><rect x=\"176.66666666666666\" y=\"168\" width=\"9.333333333333343\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"190.66666666666666\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">02:00</text></svg>", "caption": "As vendas acontecem em doze horas; o stream é pago em vinte e quatro.", "same": ["stream"]}
```

Então a resposta raramente é toda de um lado:

- **Faça stream do que é usado para agir**, o estoque no site, um cartão a bloquear, uma promessa que
  depende do agora, e mantenha essa parte pequena: poucos tópicos, poucos consumidores.
- **Faça batch do que é lido depois**: relatórios, treino de modelos, o warehouse. Eles podem ler o
  mesmo log uma vez por noite, como a lição 1 descreveu, e pagar vinte minutos.
- **Acompanhe o dia onde a plataforma permitir.** Consumidores são programas comuns; rodar menos
  deles à noite, ou nenhum consumidor de relatório até de manhã, é barato de arranjar, e o lag a que
  eles voltam é exatamente o acúmulo que a lição 16 ensinou a ler.
- **Confira a conta todo mês contra a aritmética.** Um stream que custa mais que as mensagens dele
  vezes os bytes vezes os dias diz que outra coisa está crescendo: partições que ninguém usa, grupos
  de consumidores que ninguém lê, retenção que ninguém escolheu.

Um stream que nunca dorme é uma decisão, e como todas as outras deste curso ele tem um motivo escrito
ao lado, ou é um padrão que ninguém olhou.

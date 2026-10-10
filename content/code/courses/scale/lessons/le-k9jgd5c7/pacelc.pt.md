---
title: O resto do tempo, latência contra consistência
version: 1
---

O CAP só fala do tempo durante uma partição, e partições são raras. A réplica síncrona da seção 03
custou **0,77 ms por transação** numa rede perfeitamente saudável. O CAP não tem nada a dizer sobre
esse custo, e ele é pago em todo commit, todo dia.

O **PACELC** de Daniel Abadi estende o enunciado para cobri-lo:

> **Se há uma Partição, escolha entre Disponibilidade e Consistência; Senão (*Else*), escolha entre
> Latência e Consistência.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Uma árvore de decisão. No topo: há uma partição? Se sim, escolher disponibilidade ou consistência. Se não, senão, escolher latência ou consistência. Sob o ramo do senão, os números medidos da bilheteria: commit assíncrono 2,008 milissegundos, síncrono 2,778.\"><rect x=\"270\" y=\"15\" width=\"180\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"35\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">há partição?</text><path d=\"M300 55 L180 100\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M180 100 L184.8 94.9 L187.0 100.6 Z\" fill=\"var(--wire)\" stroke=\"none\"></path><path d=\"M420 55 L540 100\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M540 100 L533.0 100.6 L535.2 94.9 Z\" fill=\"var(--wire)\" stroke=\"none\"></path><text x=\"225\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">sim</text><text x=\"500\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">não (senão)</text><rect x=\"30\" y=\"100\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"100\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">disponibilidade</text><text x=\"180\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">ou</text><rect x=\"190\" y=\"100\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"260\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">consistência</text><rect x=\"390\" y=\"100\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"460\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">latência</text><text x=\"540\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">ou</text><rect x=\"550\" y=\"100\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"620\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">consistência</text><text x=\"180\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">raro: a metade do CAP</text><text x=\"540\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">todo pedido: a metade que o CAP deixa de fora</text><text x=\"460\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">async 2.008 ms</text><text x=\"620\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">sync 2.778 ms</text></svg>", "caption": "PACELC: o CAP cobre o ramo esquerdo; o ramo direito é a troca paga em todo pedido."}
```

A segunda metade é a decisão de todo dia. Manter cópias consistentes quer dizer que uma escrita não
termina até as cópias concordarem, e concordar leva pelo menos uma ida e volta entre elas. Não
esperar é mais rápido e deixa uma janela em que as cópias discordam. **Todo sistema replicado
escolhe um ponto nessa linha**, geralmente por operação, e os números da seção 03 são quanto a
escolha vale:

| a escolha da bilheteria | cada commit custa | uma leitura na réplica |
|---|---|---|
| réplica assíncrona | 2,008 ms | pode não ter as últimas escritas |
| réplica síncrona (`on`) | 2,778 ms | ainda pode não tê-las, por pouco: a réplica as tem mas talvez não as tenha aplicado |
| `remote_apply` | mais que o `on`, pelo tempo de aplicação da réplica | vê toda escrita confirmada |

O PACELC também classifica os sistemas da aula 5 melhor que o CAP. Um banco que espera a maioria das
réplicas em toda escrita é **PC/EC**: consistente durante uma partição e consistente no resto,
pagando latência sempre. Um banco que responde da cópia mais próxima é **PA/EL**: disponível durante
uma partição e rápido no resto, pagando em desatualização sempre. Vários, o Cassandra entre eles,
deixam cada consulta escolher, e a escolha é feita com a aritmética da próxima seção.

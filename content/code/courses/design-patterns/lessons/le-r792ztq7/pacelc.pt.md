---
title: "PACELC: a troca num dia comum"
version: 1
---

**O CAP só fala enquanto a rede está quebrada. O PACELC acrescenta a frase para o resto do tempo:
*senão*, com todos os links saudáveis, você ainda escolhe entre responder rápido e responder com o
dado mais recente.** Daniel Abadi propôs a extensão em 2010 e a publicou em 2012, e o nome soletra
a frase em inglês: se houver **P**artição, escolha **A** ou **C**; **E**lse, senão, escolha
**L**atência ou **C**onsistência.

A conclusão errada que muita gente tira do CAP é que ele quase não importa, já que partições são
raras. A conclusão está meio certa. A escolha que o CAP descreve é rara; a que o PACELC acrescenta é
feita em toda escrita de um dado que mora em mais de um lugar, e é a que os seus usuários sentem
como uma tela lenta ou uma tela desatualizada.

O motivo é a distância. Bia renova um empréstimo em Centro, e a biblioteca mantém uma réplica em
outra região para leituras e por segurança. A primária pode dizer "pronto" assim que o próprio disco
tem a mudança, ou pode esperar até a réplica também ter. O programa abaixo põe números nas duas
opções. Os números são inventados para o exemplo e fixos, então a saída é a mesma em toda execução:

```schooling-example
{"language": "python", "file": "latency.py", "parts": [
 {"code": "# latency.py\nLOCAL_MS = 3      # the write on the primary's own disk\nONE_WAY_MS = 55   # primary to the replica in another region, or back", "note": "Dois números fazem as vezes da rede. São suposições escritas no programa, não medições: uma escrita no disco da própria primária, e a viagem até uma réplica em outra região."},
 {"code": "\n\ndef renew(mode: str) -> tuple[int, int]:\n    \"\"\"When Bia is told the renewal is done, and when the replica has it.\"\"\"\n    on_replica = LOCAL_MS + ONE_WAY_MS\n    if mode == \"sync\":\n        told = on_replica + ONE_WAY_MS\n    else:\n        told = LOCAL_MS\n    return told, on_replica", "note": "Bia renova *Dom Casmurro*, e a devolução passa de 16 para 30 de março. No modo `sync`, a primária espera a réplica confirmar antes de avisá-la; no `async`, avisa na hora e manda a mudança depois."},
 {"code": "\n\nif __name__ == \"__main__\":\n    for mode in (\"sync\", \"async\"):\n        told, on_replica = renew(mode)\n        print(f\"{mode}: Bia waits {told} ms\")\n        for t in (20, 40, 80, 120):\n            due = \"30 March\" if t >= on_replica else \"16 March\"\n            note = \"  <- stale, and Bia was told it is done\" if told <= t < on_replica else \"\"\n            print(f\"  replica read at {t:3} ms: due {due}{note}\")", "note": "Alguém lê o empréstimo de Bia na réplica em quatro momentos. A seta marca uma leitura velha mesmo depois de Bia já ter ouvido que a renovação está feita."}
]}
```

```
ana@laptop:~/patterns/acid-cap$ python3 latency.py
sync: Bia waits 113 ms
  replica read at  20 ms: due 16 March
  replica read at  40 ms: due 16 March
  replica read at  80 ms: due 30 March
  replica read at 120 ms: due 30 March
async: Bia waits 3 ms
  replica read at  20 ms: due 16 March  <- stale, and Bia was told it is done
  replica read at  40 ms: due 16 March  <- stale, and Bia was told it is done
  replica read at  80 ms: due 30 March
  replica read at 120 ms: due 30 March
```

Esperar a réplica custa a Bia 113 ms em vez de 3, toda vez, num dia em que nada está errado. Em
troca, ninguém consegue ler a data antiga depois de ela ter ouvido a nova. Não esperar faz o balcão
parecer instantâneo e abre uma janela: em 20 e 40 ms a réplica ainda diz 16 de março, embora Bia
tenha ouvido aos 3 ms que o empréstimo vai até 30 de março. **Essa janela é a consistência eventual,
e ela é o preço de todo dia da latência baixa, sem falha nenhuma em lugar nenhum.** Aos 80 ms os
dois modos concordam, porque a essa altura a mudança já atravessou.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 300\" role=\"img\" data-fig=\"l10-pacelc\" aria-label=\"PACELC como árvore de decisão. No alto, a pergunta: a rede está particionada? O ramo do sim, que é o teorema CAP, se divide em duas folhas: A, continuar disponível e aceitar que as filiais discordem, ou C, recusar do lado que não tem certeza. O ramo do não, o caso de todo dia, também se divide em dois: L, responder rápido da cópia mais próxima e aceitar leituras velhas, ou C, esperar as réplicas antes de dizer pronto. Um sistema é descrito por uma escolha de cada lado, como PA/EL ou PC/EC.\"><defs><marker id=\"l10-pacelc-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"235.0\" y=\"17.0\" width=\"230.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a rede está particionada?</text><path d=\"M300.0 51.0 L300.0 70.0 L180.0 70.0 L180.0 98.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-pacelc-dp-ah-paper-dim)\"></path><path d=\"M400.0 51.0 L400.0 70.0 L520.0 70.0 L520.0 98.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-pacelc-dp-ah-paper-dim)\"></path><text x=\"232.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">sim: CAP</text><text x=\"470.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">não: Else</text><rect x=\"80.0\" y=\"99.0\" width=\"200.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">raro, e não é você quem escolhe</text><rect x=\"420.0\" y=\"99.0\" width=\"200.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"520.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">todo o resto do tempo</text><path d=\"M180.0 133.0 L180.0 150.0 L95.0 150.0 L95.0 178.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-pacelc-dp-ah-paper-dim)\"></path><rect x=\"17.0\" y=\"180.0\" width=\"156.0\" height=\"76.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"15\" font-weight=\"700\" fill=\"var(--amber)\">A</text><text x=\"95.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">continuar disponível;</text><text x=\"95.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">as filiais podem discordar</text><path d=\"M180.0 133.0 L180.0 150.0 L265.0 150.0 L265.0 178.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-pacelc-dp-ah-paper-dim)\"></path><rect x=\"187.0\" y=\"180.0\" width=\"156.0\" height=\"76.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"265.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"15\" font-weight=\"700\" fill=\"var(--amber)\">C</text><text x=\"265.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">recusar onde</text><text x=\"265.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">não há certeza</text><path d=\"M520.0 133.0 L520.0 150.0 L435.0 150.0 L435.0 178.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-pacelc-dp-ah-paper-dim)\"></path><rect x=\"357.0\" y=\"180.0\" width=\"156.0\" height=\"76.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"435.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"15\" font-weight=\"700\" fill=\"var(--amber)\">L</text><text x=\"435.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">responder rápido;</text><text x=\"435.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">leituras podem ser velhas</text><path d=\"M520.0 133.0 L520.0 150.0 L605.0 150.0 L605.0 178.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-pacelc-dp-ah-paper-dim)\"></path><rect x=\"527.0\" y=\"180.0\" width=\"156.0\" height=\"76.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"605.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"15\" font-weight=\"700\" fill=\"var(--amber)\">C</text><text x=\"605.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">esperar as réplicas;</text><text x=\"605.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">toda leitura é atual</text><text x=\"350.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">um sistema é nomeado por uma escolha de cada lado: PA/EL, PC/EC, PA/EC</text></svg>", "caption": "O CAP é a metade esquerda da árvore. O PACELC acrescenta a metade direita, a troca feita quando nada está quebrado."}
```

## Onde os sistemas reais ficam

Um sistema é descrito com uma letra de cada lado da árvore: PA/EL abre mão da consistência nos dois
casos, PC/EC a mantém nos dois. O artigo de Abadi coloca as versões padrão de Dynamo, Cassandra e
Riak em PA/EL, e sistemas distribuídos totalmente ACID, como o VoltDB e o Megastore do Google, em
PC/EC. As palavras *versões padrão* fazem o trabalho aí, porque o botão costuma estar exposto:

| sistema | o padrão | a outra escolha, e o que custa |
|---|---|---|
| PostgreSQL com réplica | a réplica é atualizada de forma assíncrona; uma leitura nela pode estar atrás | `synchronous_commit` com um standby nomeado faz o `COMMIT` esperar por ele: EC, ao custo da latência de todo commit |
| Amazon DynamoDB | leituras eventualmente consistentes | uma leitura fortemente consistente sob pedido, pelo dobro da capacidade de leitura |
| Apache Cassandra | o nível de consistência é escolhido por consulta | `QUORUM` espera a maioria das réplicas; `ONE` responde com a primeira |

A última coluna diz algo sobre projeto que as letras escondem. Quando um banco deixa você escolher
por consulta, a pergunta *o nosso sistema é PA/EL ou PC/EC?* não tem resposta única, e fazê-la é
perguntar a coisa errada. A próxima seção faz uma pergunta melhor.

---
title: Comparar execuções contra a dispersão
version: 1
---

O jeito comum de decidir que uma mudança ajudou é rodar a configuração antiga e a nova uma vez cada e
ficar com o número maior. **Isso compara duas sementes tanto quanto duas configurações**, e a
dispersão das seções anteriores diz quanto uma semente sozinha move o resultado: quatro imagens em
360, por nada.

A versão honesta custa mais execuções e nada além disso. Rode cada configuração com as mesmas cinco
sementes e pergunte se a distância entre as configurações é maior que a dispersão dentro de cada uma.
Três configurações aqui: a de antes, uma camada oculta duas vezes mais larga e uma taxa de
aprendizado cinco vezes maior.

```
PENDING compare
```

Quinze linhas acrescentadas ao `runs.jsonl`, cada uma com o seu commit e nenhuma suja. Lê-las é mais
um programa, que não precisa de nada do PyTorch. Salve como `~/dl/report.py`:

```schooling-example
{
  "language": "python",
  "file": "report.py",
  "parts": [
    {
      "code": "\"\"\"report: what runs.jsonl says, one block per configuration and commit.\"\"\"\nimport json\nimport statistics\nfrom collections import defaultdict\n\ngroups, dirty = defaultdict(dict), 0\nfor line in open(\"runs.jsonl\"):\n    run = json.loads(line)\n    if run[\"code\"][\"dirty\"]:\n        dirty += 1\n        continue",
      "note": "Uma execução feita com código sem commit fica de fora e é contada. Ninguém consegue recuperar aquele código, então o número dela não pode ser conferido, só acreditado."
    },
    {
      "code": "    key = (json.dumps(run[\"config\"], sort_keys=True), run[\"code\"][\"commit\"])\n    groups[key][run[\"seed\"]] = run[\"metrics\"][\"val_acc\"]",
      "note": "As execuções são agrupadas por configuração E commit: as mesmas configurações sobre código diferente são experimentos diferentes. Dentro de um grupo, uma semente rodada duas vezes fica com o resultado mais recente em vez de contar duas vezes."
    },
    {
      "code": "for (config, commit), by_seed in groups.items():\n    accs = list(by_seed.values())\n    sd = statistics.stdev(accs) if len(accs) > 1 else 0.0\n    print(f\"{config}  commit {commit}\")\n    print(f\"  {len(accs)} seeds  mean {statistics.mean(accs):.4f}  \"\n          f\"min {min(accs):.4f}  max {max(accs):.4f}  sd {sd:.4f}\")\nprint(f\"left out: {dirty} run(s) from uncommitted code\")"
    }
  ]
}
```

```
PENDING report
```

O `report.py` é código como o resto, então a transcrição termina com o commit dele. Sem commit, ele
marcaria como suja toda execução seguinte.

## Lendo o relatório

A execução da semente 0 da seção anterior e a repetição dela aqui viraram uma só, e a execução suja
ficou fora do relatório, com uma contagem ao lado. O que sobra são três grupos de cinco.

**A camada mais larga não mudou nada mensurável.** A média dela, 0,9200, fica 0,0011 abaixo dos
0,9211 da mais estreita, menos de meia imagem, contra um desvio padrão perto de 0,006 em cada uma. As
cinco execuções dela caem entre 0,9111 e 0,9278, inteiramente dentro da mesma faixa das execuções de
32 unidades. E repare no que uma execução sozinha teria dito: **na semente 0 a camada mais larga
ganhou, 0,9194 a 0,9167**, e na semente 4 perdeu, 0,9111 a 0,9250. Qualquer um dos dois resultados,
sozinho, teria sido escrito como descoberta.

**A taxa de aprendizado mais alta é uma diferença real.** A pior semente dela, 0,9500, superou a
melhor semente de qualquer uma das outras configurações, 0,9278. A média andou 0,037, cerca de treze
imagens em 360, o que é várias vezes a dispersão.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 260\" role=\"img\" aria-label=\"Um eixo horizontal de acurácia de validação de 0,90 a 0,98 e três linhas de cinco pontos, um por semente. As linhas de hidden 32 e hidden 64 com taxa de aprendizado 0,01 ficam uma sobre a outra entre 0,911 e 0,928. A linha com taxa 0,05 fica inteira à direita, entre 0,950 e 0,972.\"><path d=\"M190 50 L670 50\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"20\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">hidden 32  lr 0.01</text><circle cx=\"290.2\" cy=\"50\" r=\"5\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><circle cx=\"340.0\" cy=\"50\" r=\"5\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><circle cx=\"273.4\" cy=\"50\" r=\"5\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><circle cx=\"340.0\" cy=\"41\" r=\"5\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><circle cx=\"340.0\" cy=\"32\" r=\"5\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><path d=\"M190 100 L670 100\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"20\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">hidden 64  lr 0.01</text><circle cx=\"306.4\" cy=\"100\" r=\"5\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><circle cx=\"356.8\" cy=\"100\" r=\"5\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><circle cx=\"290.2\" cy=\"100\" r=\"5\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><circle cx=\"340.0\" cy=\"100\" r=\"5\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><circle cx=\"256.6\" cy=\"100\" r=\"5\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><path d=\"M190 150 L670 150\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">hidden 32  lr 0.05</text><circle cx=\"623.2\" cy=\"150\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"539.8\" cy=\"150\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"523.6\" cy=\"150\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"523.6\" cy=\"141\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"490.0\" cy=\"150\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><rect x=\"248.60000000000002\" y=\"28\" width=\"116.2\" height=\"92\" rx=\"6\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"306.7\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">as cinco sementes se sobrepõem</text><text x=\"556.6\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">sem sobreposição</text><path d=\"M190 200 L670 200\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M190.0 200 L190.0 206\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"190.0\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.90</text><path d=\"M310.0 200 L310.0 206\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"310.0\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.92</text><path d=\"M430.0 200 L430.0 206\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"430.0\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.94</text><path d=\"M550.0 200 L550.0 206\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"550.0\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.96</text><path d=\"M670.0 200 L670.0 206\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"670.0\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.98</text><text x=\"430\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">acurácia de validação, um ponto por semente</text></svg>", "caption": "Quinze execuções, um ponto cada. A largura da camada oculta não moveu nada que as sementes já não movessem; a taxa de aprendizado moveu a linha inteira."}
```

## Uma regra prática, e o limite dela

Ponha as execuções lado a lado e procure sobreposição. **Quando os intervalos se sobrepõem muito, não
foi mostrado que a mudança faça alguma coisa**, digam o que disserem as médias. Quando a pior
execução de uma configuração supera a melhor da outra nas mesmas sementes, a mudança fez algo.

Entre esses dois casos fica uma zona cinzenta, em que as médias diferem por cerca de um desvio
padrão e os intervalos se sobrepõem um pouco. Um teste estatístico, um teste t pareado nas cinco
sementes por exemplo, põe um número em quão surpreendente a distância seria por acaso. Com cinco
sementes nenhum teste enxerga um efeito pequeno, e **a resposta é mais sementes, não um teste mais
esperto.**

Dois hábitos mantêm isso honesto:

- **As mesmas sementes para toda configuração.** A semente 0 de uma contra a semente 0 da outra
  compara igual com igual: os mesmos pesos iniciais, até onde os formatos permitem, e a mesma ordem
  de lotes.
- **Escolher na validação, relatar no teste.** Toda comparação aqui leu o conjunto de validação.
  Escolher a melhor de quinze execuções na validação e citar esse número o exagera, que é o ponto da
  aula 1 sobre qualquer configuração escolhida olhando para um conjunto. O conjunto de teste é lido
  uma vez, para a configuração já escolhida.

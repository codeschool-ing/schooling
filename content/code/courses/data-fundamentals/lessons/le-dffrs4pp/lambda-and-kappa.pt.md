---
title: Lambda e Kappa, dois jeitos de ter as duas coisas
version: 1
---

**Lambda e Kappa são duas respostas a um mesmo desejo: uma resposta rápida e uma correta, a partir dos
mesmos dados.** A aula até aqui mostrou por que as duas se afastam. Um fluxo responde em minutos e
precisa apostar numa marca d'água; um job em lote responde na manhã seguinte e vê tudo. As duas
arquiteturas aparecem aqui para que você as reconheça num diagrama ou numa vaga de emprego. Nenhuma das
duas é construída neste curso.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Lambda: os eventos vão para uma camada de lote que recalcula toda noite a partir de todos os eventos brutos e para uma camada de velocidade que processa como fluxo as horas desde então; uma camada de serviço junta as duas para os leitores. Kappa: os eventos vão para um log que os guarda em ordem; um job de fluxo o lê para uma saída, e uma versão nova reproduz o log desde o offset 0 numa segunda saída.\" data-fig=\"lambda-kappa\"><defs><marker id=\"lambda-kappa-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"14\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\" font-weight=\"600\">Lambda</text><rect x=\"14\" y=\"70\" width=\"112\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"70.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">eventos</text><rect x=\"176\" y=\"38\" width=\"210\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"281.0\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">camada de lote</text><text x=\"281.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">todos os eventos brutos,</text><text x=\"281.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">recalculados toda noite</text><rect x=\"176\" y=\"100\" width=\"210\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"281.0\" y=\"109.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">camada de velocidade</text><text x=\"281.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">as horas desde o último</text><text x=\"281.0\" y=\"139.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">lote, como fluxo</text><rect x=\"436\" y=\"66\" width=\"130\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"501.0\" y=\"85.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">camada de serviço</text><text x=\"501.0\" y=\"100.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">junta as duas</text><rect x=\"608\" y=\"70\" width=\"98\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"657.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">leitores</text><line x1=\"126\" y1=\"86\" x2=\"174\" y2=\"62\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#lambda-kappa-ah)\"></line><line x1=\"126\" y1=\"100\" x2=\"174\" y2=\"124\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#lambda-kappa-ah)\"></line><line x1=\"386\" y1=\"62\" x2=\"434\" y2=\"84\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#lambda-kappa-ah)\"></line><line x1=\"386\" y1=\"124\" x2=\"434\" y2=\"102\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#lambda-kappa-ah)\"></line><line x1=\"566\" y1=\"93\" x2=\"606\" y2=\"93\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#lambda-kappa-ah)\"></line><line x1=\"14\" y1=\"172\" x2=\"706\" y2=\"172\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 4\"></line><text x=\"14\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\" font-weight=\"600\">Kappa</text><rect x=\"14\" y=\"236\" width=\"112\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"70.0\" y=\"259.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">eventos</text><rect x=\"170\" y=\"222\" width=\"150\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"245.0\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">o log</text><text x=\"245.0\" y=\"259.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cada evento guardado,</text><text x=\"245.0\" y=\"274.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">em ordem</text><rect x=\"374\" y=\"206\" width=\"160\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"454.0\" y=\"227.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">job de fluxo v1</text><rect x=\"374\" y=\"268\" width=\"160\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"454.0\" y=\"283.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">job de fluxo v2,</text><text x=\"454.0\" y=\"298.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">reproduzindo desde o offset 0</text><rect x=\"584\" y=\"206\" width=\"122\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"645.0\" y=\"227.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">saída v1</text><rect x=\"584\" y=\"270\" width=\"122\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"645.0\" y=\"291.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">saída v2</text><line x1=\"126\" y1=\"259\" x2=\"168\" y2=\"259\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#lambda-kappa-ah)\"></line><line x1=\"320\" y1=\"248\" x2=\"372\" y2=\"228\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#lambda-kappa-ah)\"></line><line x1=\"320\" y1=\"272\" x2=\"372\" y2=\"290\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\" marker-end=\"url(#lambda-kappa-ah)\"></line><line x1=\"534\" y1=\"227\" x2=\"582\" y2=\"227\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#lambda-kappa-ah)\"></line><line x1=\"534\" y1=\"291\" x2=\"582\" y2=\"291\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\" marker-end=\"url(#lambda-kappa-ah)\"></line></svg>", "caption": "A Lambda calcula a resposta duas vezes e junta as duas; a Kappa calcula uma vez e, para mudá-la, reproduz o log numa saída nova.", "same": ["Kappa", "Lambda"]}
```

## Lambda: dois caminhos, juntados

**A arquitetura Lambda roda o mesmo cálculo duas vezes, uma em lote e outra como fluxo.** Nathan Marz a
descreveu em 2011. Cada evento vai para dois lugares:

- uma **camada de lote** (*batch layer*) guarda todos os eventos brutos e, toda noite, recalcula a
  resposta a partir do histórico inteiro, eventos atrasados incluídos. A resposta dela é correta e tem
  horas de idade;
- uma **camada de velocidade** (*speed layer*) processa os mesmos eventos como fluxo e cobre só as horas
  desde a última execução do lote. A resposta dela é fresca e pode errar nas bordas;
- uma **camada de serviço** (*serving layer*) junta as duas: a resposta do lote para tudo até a noite
  passada, a da velocidade para hoje.

Na Roda Livre, isso é a contagem ao vivo das viagens de hoje, corrigida de madrugada pelo job da
seção 03. As viagens atrasadas do Passeio Público estão erradas na contagem ao vivo de segunda e certas
no relatório de terça, e ninguém precisa escolher um atraso permitido de um dia.

O custo é o óbvio. **A mesma lógica é escrita duas vezes, em dois sistemas, por pessoas que podem cometer
dois erros diferentes.** Quando a definição de "viagem" muda, as duas precisam mudar no mesmo dia, e na
manhã em que as duas respostas discordam alguém precisa descobrir qual código está errado.

## Kappa: um caminho, reproduzido de novo

**A arquitetura Kappa mantém só o caminho de fluxo, e reprocessa reproduzindo o log.** Jay Kreps a
propôs em 2014, num artigo cujo título questiona a Lambda. Ela se apoia na propriedade do log vista na
seção 04: os eventos ficam guardados, em ordem, e um consumidor pode lê-los de novo a partir do
offset 0.

Então existe um código só. Quando ele muda, uma segunda cópia da versão nova começa do início do log e
escreve numa saída nova. Quando ela alcança o presente, os leitores passam para a saída nova e a antiga
é apagada. Um backfill vira um replay.

O custo vai para dois lugares. O log agora precisa guardar cada evento por tanto tempo quanto alguém
possa querer reprocessá-lo, o que pode significar anos de eventos. E o código de fluxo precisa acertar
sozinho com os dados atrasados, porque nenhum job da madrugada vai corrigi-lo.

## Nenhuma das duas é um produto

As duas são padrões, e a maioria das plataformas reais fica em algum lugar entre elas: um fluxo para as
poucas respostas que precisam de minutos, lote para todo o resto, e uma cópia bruta dos eventos guardada
num armazenamento barato para que qualquer um dos dois possa rodar de novo. `streaming` constrói a metade
do fluxo e `pipelines-etl` a metade do lote. O que esta seção deixa com você é a pergunta a que as duas
respondem, e a próxima seção a transforma numa decisão.

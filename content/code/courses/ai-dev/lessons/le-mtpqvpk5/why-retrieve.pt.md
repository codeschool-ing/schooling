---
title: Por que recuperar
version: 1
---

Um assistente de suporte da loja tem de responder a partir das regras da própria loja: trinta dias
para uma devolução, 15,00 de frete, o que quer dizer E1042. Nenhum modelo foi treinado com isso, e a
aula 1 seção 07 mostrou o que um modelo faz com uma pergunta para a qual não foi treinado. **A geração
aumentada por recuperação (RAG) põe as regras relevantes na requisição**, no momento da pergunta, para
o modelo continuar a partir do texto certo em vez de reconstruí-lo.

::: track ai
Você construiu isto de ponta a ponta no `rag`, com um banco vetorial de verdade e um conjunto de
avaliação de centenas de perguntas. Esta aula é a versão que um desenvolvedor encontra quando a
tarefa é "ponha busca na nossa página de suporte": pequena, com toda parte visível, e com as
checagens que você deve manter qualquer que seja o tamanho.
:::

::: track *
A técnica inteira são três passos, e esta aula constrói cada um em poucas linhas de Python: achar os
trechos relevantes para a pergunta, pô-los no prompt, e conferir que a resposta os usa.
:::

## O manual

O manual de suporte da loja são oito arquivos Markdown curtos, escritos para o curso como o resto da
loja:

```
ana@dev:~/shop$ git add docs && git commit -qm "Support handbook" && ls docs/handbook && wc -w docs/handbook/*.md | tail -1
account.md
contact.md
coupons.md
payment-errors.md
products.md
returns.md
shipping.md
warranty.md
 793 total
ana@dev:~/shop$ python -c 'import tiktoken, pathlib; print(sum(len(tiktoken.get_encoding("o200k_base").encode(p.read_text())) for p in pathlib.Path("docs/handbook").glob("*.md")), "tokens in the handbook")'
993 tokens in the handbook
```

**993 tokens.** Isso é pequeno o bastante para mandar inteiro com cada pergunta, e para um manual
desse tamanho seria uma escolha razoável. A recuperação passa a valer quando os documentos deixam de
caber, ou deixam de ser baratos de mandar: algumas centenas de páginas de políticas, um catálogo de
produtos, todo chamado de suporte já aberto. A conta da aula 2 decide onde fica essa linha para você,
e este manual é pequeno para cada passo do pipeline caber numa tela.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Geração aumentada por recuperação numa figura. Antes, o manual é cortado em 26 trechos e cada um vira um embedding num índice. Quando chega uma pergunta, ela é buscada no índice, os três primeiros trechos entram no prompt com os ids, o modelo responde citando-os, e um verificador confere as citações antes de a resposta aparecer.\"><defs><marker id=\"pl-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma vez, antes</text><rect x=\"20\" y=\"34\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">manual</text><text x=\"80.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8 arquivos</text><rect x=\"180\" y=\"34\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"240.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">trechos</text><text x=\"240.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">26, com ids</text><rect x=\"340\" y=\"34\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">índice</text><text x=\"400.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">26 × 256</text><path d=\"M142 59 L176 59\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pl-ah)\"></path><path d=\"M302 59 L336 59\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pl-ah)\"></path><text x=\"20\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a cada pergunta</text><rect x=\"20\" y=\"136\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pergunta</text><rect x=\"160\" y=\"136\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"220.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">busca</text><text x=\"220.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3 primeiros</text><rect x=\"300\" y=\"136\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">prompt</text><text x=\"360.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">trechos + pergunta</text><rect x=\"440\" y=\"136\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"500.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">modelo</text><text x=\"500.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">resposta + [ids]</text><rect x=\"580\" y=\"136\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">checagem</text><text x=\"640.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">citações</text><path d=\"M142 161 L156 161\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pl-ah)\"></path><path d=\"M282 161 L296 161\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pl-ah)\"></path><path d=\"M422 161 L436 161\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pl-ah)\"></path><path d=\"M562 161 L576 161\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pl-ah)\"></path><path d=\"M400 86 L400 110 L220 110 L220 132\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pl-ah)\"></path></svg>", "caption": "A linha de cima roda quando os documentos mudam; a de baixo roda a cada pergunta. A aula 6 constrói cada caixa.", "same": ["prompt"]}
```

## Recuperação ou treino

O outro jeito de dar a um modelo o seu conhecimento é treiná-lo mais com os seus documentos (ajuste
fino, ou fine-tuning). Para fatos que mudam, a recuperação ganha em tudo o que importa aqui:

- **Uma mudança é uma edição.** O prazo de devolução muda num arquivo hoje e já está na próxima
  resposta. Um modelo ajustado sabe o prazo antigo até alguém treiná-lo de novo.
- **A resposta pode citar.** Um trecho tem um id, então a resposta pode dizer de onde veio, e um
  programa pode conferir (aula 6 seção 08). Conhecimento dentro dos parâmetros de um modelo não tem
  endereço.
- **O que não está nos trechos pode ser recusado.** "Os documentos não dizem" é uma frase que um
  modelo consegue escrever quando foi instruído a responder só com o que recebeu.

Ajuste fino serve para mudar como um modelo escreve, o formato ou o tom, não para ensinar fatos que
vão mudar.

---
title: Uma tarefa, um contexto
version: 2
---

A função de anúncios acima responde perguntas sobre anúncios, então o prompt dela precisa conter
anúncios. O assistente de atendimento responde perguntas sobre as políticas da Marginalia, e o prompt
dele não tem motivo para contê-los. Mesmo assim é um desenho comum dar a um assistente tudo de que ele
possa precisar, "anúncios relacionados" ao lado das políticas, para o caso de um cliente perguntar sobre
os dois:

```schooling-example
{
  "language": "python",
  "file": "mixed.py",
  "parts": [
    {
      "code": "import sys\n\nfrom answer import ask, sources_for\nfrom listings import LISTINGS, as_sources\n\nquestion = sys.argv[1]\npolicies = sources_for(question)\nprint(\"policies only:          \", ask(question, policies))\nprint(\"policies and listings:  \", ask(question, policies + as_sources(LISTINGS)))",
      "note": "A mesma pergunta respondida duas vezes: pelas políticas que a busca achou, e por essas políticas com os seis anúncios acrescentados ao mesmo prompt."
    }
  ]
}
```
```
ana@vm:~/rag$ python mixed.py "How many days do I have to return a printed book?"
policies only:           According to [1], you have 30 days from delivery to return a printed book. This is the most recent and updated policy, as stated in the source date (2026-02-02).
policies and listings:   According to [1], you have 30 days from delivery to return a printed book in the condition you received it.
```

**Trinta dias, citados, nas duas vezes.** O modelo ignorou a frase do vendedor, e a resposta está
certa. O desenho continua errado. Uma pergunta sobre a política de devoluções, de um cliente que nunca
olhou um anúncio, foi respondida a partir de um contexto que tinha a instrução de um vendedor, e a
resposta estar certa dependeu de o modelo escolher ignorá-la, neste modelo, desta vez.

O isolamento é a regra que daí decorre: **uma tarefa, um contexto, e texto não confiável só nos
contextos cuja tarefa precisa dele.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Dois pipelines separados. Perguntas de atendimento são respondidas a partir das políticas da própria Marginalia pelo pipeline da aula 7, com resposta citada. Comparações de anúncios são respondidas a partir de texto escrito por vendedores, por uma chamada sem ferramentas e sem memória, e a resposta só aparece se toda frase estiver fundamentada num anúncio, ou um aviso seguro no lugar. Uma linha tracejada entre os dois diz que nenhum texto a atravessa.\"><defs><marker id=\"rg-8ce9ae\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 5 L0 10 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"10\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">perguntas de atendimento</text><rect x=\"10\" y=\"40\" width=\"150\" height=\"56\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a pergunta</text><text x=\"85.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">do cliente</text><rect x=\"190\" y=\"40\" width=\"150\" height=\"56\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"265.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">políticas</text><text x=\"265.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">da própria Marginalia</text><rect x=\"370\" y=\"40\" width=\"150\" height=\"56\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"445.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">resposta</text><text x=\"445.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pipeline da aula 7</text><rect x=\"550\" y=\"40\" width=\"150\" height=\"56\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"625.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">resposta</text><text x=\"625.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">citada</text><path d=\"M160 68.0 L188 68.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-8ce9ae)\"></path><path d=\"M340 68.0 L368 68.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-8ce9ae)\"></path><path d=\"M520 68.0 L548 68.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-8ce9ae)\"></path><text x=\"10\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">comparar anúncios</text><rect x=\"10\" y=\"150\" width=\"150\" height=\"56\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a pergunta</text><text x=\"85.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">do cliente</text><rect x=\"190\" y=\"150\" width=\"150\" height=\"56\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"265.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">anúncios</text><text x=\"265.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">escritos por vendedores</text><rect x=\"370\" y=\"150\" width=\"150\" height=\"56\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"445.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">resposta</text><text x=\"445.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sem ferramentas nem memória</text><rect x=\"550\" y=\"150\" width=\"150\" height=\"56\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"625.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">verificação</text><text x=\"625.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">fundamentada ou recusada</text><path d=\"M160 178.0 L188 178.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-8ce9ae)\"></path><path d=\"M340 178.0 L368 178.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-8ce9ae)\"></path><path d=\"M520 178.0 L548 178.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-8ce9ae)\"></path><path d=\"M20 120 L700 120\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"700\" y=\"132\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">nenhum texto atravessa esta linha</text></svg>", "caption": "Duas tarefas, dois contextos. Os anúncios nunca entram no prompt do assistente de atendimento, e a chamada que os lê não pode fazer nada além de escrever uma resposta que é conferida antes de alguém vê-la."}
```

- O assistente de atendimento lê os documentos da própria Marginalia, filtrados pelas permissões da
  aula 14. Nenhum texto de vendedor, nenhuma página da web, nenhuma palavra de outro cliente.
- A função de anúncios lê anúncios, e nada mais: nenhum dado de conta, nenhuma memória do cliente,
  nenhuma ferramenta. O que quer que uma injeção a faça dizer é conferido contra os anúncios antes de
  ser mostrado.
- Quando uma tarefa precisa do resultado da outra, recebe a **saída conferida**, e não o texto bruto: o
  id de um anúncio e um estado de conservação de uma lista fixa, nunca a descrição.

O mesmo raciocínio separa tarefas dentro de uma conversa. Um pedido de resumo de um arquivo enviado roda
numa chamada própria, e o que volta para o chat é o resumo, rotulado como resumo de um envio, e não o
arquivo.

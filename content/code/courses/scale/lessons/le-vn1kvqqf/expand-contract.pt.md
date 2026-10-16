---
title: Expandir, migrar, contrair
version: 1
---

Algumas mudanças não podem ser instantâneas: um renomear, a divisão de uma coluna em duas, uma
coluna nova obrigatória, uma mudança de tipo. E há um segundo problema que a trava não explica:
**durante uma implantação, versões velhas e novas do programa rodam ao mesmo tempo.** Uma implantação
gradual troca as cópias da aula 1 uma de cada vez, então por alguns minutos algumas cópias leem o
esquema do jeito velho e outras do novo. Um renomear feito num passo quebra a versão que não o
esperava.

A resposta é nunca fazer uma mudança com que uma das versões em execução não consiga conviver. Toda
mudança que quebra é dividida em **passos seguros cada um por si**, nesta ordem:

1. **Expandir.** Acrescentar a coisa nova ao lado da velha: uma coluna nova, que aceita nulo ou com
   padrão constante, ou uma tabela nova. Instantâneo, e invisível ao programa que já está rodando.
2. **Escrever as duas.** Implantar uma versão do programa que escreve a coluna nova além da velha, e
   ainda lê a velha.
3. **Preencher.** Encher a coluna nova nas linhas gravadas antes do passo 2, em lotes pequenos, como
   a seção 08 faz.
4. **Ler a nova.** Implantar uma versão que lê a coluna nova. A velha agora só é escrita, nunca lida.
5. **Contrair.** Implantar uma versão que para de escrever a coluna velha e, quando nenhuma versão em
   execução a mencionar, descartá-la.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Cinco passos em três implantações para renomear uma coluna. Expandir: acrescentar a coluna nova. Implantação 1: escrever as duas colunas, ler a velha. Preencher as linhas antigas. Implantação 2: ler a coluna nova. Implantação 3: parar de escrever a velha, depois descartá-la. Sob cada passo, quais versões do programa rodam, e que todas funcionam com o esquema daquele momento.\"><path d=\"M30 130 L690 130\" stroke=\"var(--wire)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"90\" cy=\"130\" r=\"7\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.5\"></circle><rect x=\"30\" y=\"50\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"90\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">expandir</text><text x=\"90\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nova coluna</text><circle cx=\"225\" cy=\"130\" r=\"7\" fill=\"var(--paper)\" stroke=\"none\" stroke-width=\"1.5\"></circle><rect x=\"165\" y=\"50\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></rect><text x=\"225\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">implantação 1</text><text x=\"225\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">escreve as duas</text><circle cx=\"360\" cy=\"130\" r=\"7\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.5\"></circle><rect x=\"300\" y=\"50\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">preencher</text><text x=\"360\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">linhas antigas</text><circle cx=\"495\" cy=\"130\" r=\"7\" fill=\"var(--paper)\" stroke=\"none\" stroke-width=\"1.5\"></circle><rect x=\"435\" y=\"50\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></rect><text x=\"495\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">implantação 2</text><text x=\"495\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lê a nova</text><circle cx=\"630\" cy=\"130\" r=\"7\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.5\"></circle><rect x=\"570\" y=\"50\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"630\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">contrair</text><text x=\"630\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">implantação 3, e descarta</text><path d=\"M90 160 L250 160\" stroke=\"var(--paper-dim)\" stroke-width=\"6\" fill=\"none\"></path><text x=\"82\" y=\"160\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v1</text><path d=\"M225 180 L520 180\" stroke=\"var(--paper-dim)\" stroke-width=\"6\" fill=\"none\"></path><text x=\"217\" y=\"180\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v2</text><path d=\"M495 200 L655 200\" stroke=\"var(--paper-dim)\" stroke-width=\"6\" fill=\"none\"></path><text x=\"487\" y=\"200\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v3</text><path d=\"M630 220 L690 220\" stroke=\"var(--paper-dim)\" stroke-width=\"6\" fill=\"none\"></path><text x=\"622\" y=\"220\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v4</text><text x=\"690\" y=\"238\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">versões do programa rodando</text></svg>", "caption": "Expandir, migrar, contrair: todo passo é seguro para toda versão em execução naquele momento."}
```

Cinco passos e três implantações para o que um `ALTER TABLE … RENAME` teria feito, e cada passo pode
ser parado ou revertido sem perder nada. **O custo é tempo e cuidado; a economia é que nenhum passo
precisa que o sistema pare.**

## A coluna que esta aula acrescenta

A bilheteria vai passar a registrar em qual portão cada ingresso foi lido, uma coluna nova `gate`. É
um caso menor que um renomear, e usa três dos passos:

- **expandir**: `ADD COLUMN gate text`, que a seção 03 já rodou, aceitando nulo;
- **linhas novas ganham um valor**: numa implantação de verdade, a próxima versão do programa grava
  o `gate` em toda venda. Aqui um padrão, `SET DEFAULT 'A'`, faz o papel dessa versão, e também é
  instantâneo;
- **preencher** os dois milhões de linhas antigas, seção 08;
- e então tornar a coluna **obrigatória**, seção 09, sem uma leitura sob a trava mais forte.

O passo de contrair não aparece, porque nada está sendo substituído. Num renomear é o passo que as
pessoas pulam, e uma coluna velha que toda versão escreve e nenhuma lê é o resultado de costume.

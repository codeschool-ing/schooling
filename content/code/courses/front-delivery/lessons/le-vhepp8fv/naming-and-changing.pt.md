---
title: Dando nome aos tokens, e mudando-os depois
version: 1
---

**O nome de um token é uma interface, e os produtos que o usam dependem dele como código depende do nome
de uma função.** O valor por trás de `accent` pode mudar todo mês sem ninguém perceber, e é esse o ponto.
O nome `accent` não pode mudar sem que toda folha de estilo que diz `var(--accent)` quebre, em silêncio:
uma propriedade personalizada desconhecida simplesmente não resolve para nada, e o botão perde a cor sem
erro em lugar nenhum.

## Nomes que sobrevivem

Três hábitos mantêm os nomes estáveis:

- **dê nome ao significado, não ao valor.** `accent`, `muted`, `space-4`; nunca `green`, `grey-text` ou
  `space-16px`. Um nome que descreve o valor vira mentira no dia em que o valor muda.
- **uma ordem só para as partes**, a mesma em todo lugar: categoria, depois variante, depois estado, como
  `button-background-hover`. Qual ordem importa menos que ter uma, porque as pessoas adivinham nomes, e
  uma ordem consistente acerta o palpite.
- **poucas palavras, escolhidas uma vez.** `surface` ou `background`, `muted` ou `subtle`: escolha uma e
  escreva. Dois sinônimos num sistema são dois tokens que ninguém sabe ao certo se são diferentes.

## Mudando um nome

Quando um nome precisa mudar, a mudança é feita em duas versões, nunca numa:

1. **acrescente o nome novo e mantenha o antigo como apelido** dele, marcado como obsoleto: `subtle` é
   `{theme.muted}` por um tempo. Todo produto continua funcionando, e um aviso, na documentação ou de uma
   regra de lint, diz a cada um para migrar.
2. **remova o nome antigo** quando nada mais o usar, numa versão cujo número diz que ela pode quebrar
   coisas.

A aula 7 dá significado aos números de versão: acrescentar um token é uma mudança minor, remover ou
renomear um é uma mudança major. Essa regra é o motivo de um design system precisar de versões.

## Os mesmos nomes na ferramenta de design

Ferramentas de design guardam as próprias variáveis, e a falha mais comum de um design system é a
ferramenta e o código se afastarem: o `Accent/Default` de uma designer e o `--accent` de um desenvolvedor
que começaram iguais e são dois verdes um ano depois. O formato do Design Tokens Community Group existe
para que o arquivo de tokens seja a fonte única que os dois leem, exportado da ferramenta ou importado
nela. Seja qual for o lado que é a fonte, **é um arquivo com um dono, e o outro lado é gerado a partir
dele**, exatamente como o `tokens.css` é gerado do `tokens.json`.

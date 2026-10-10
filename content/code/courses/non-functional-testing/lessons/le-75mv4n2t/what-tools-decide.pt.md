---
title: O que uma ferramenta consegue decidir
version: 1
---

A aula 12 plantou oito defeitos. Eis quem os achou:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 380\" role=\"img\" data-fig=\"l13-who-finds\" aria-label=\"Os oito defeitos do book.html contra três colunas: o axe com as tags da WCAG, o Lighthouse e o que sobrou para uma pessoa. O axe achou quatro: o lang ausente, a nota cinza, o logo sem alt e o campo de nome sem rótulo. O Lighthouse achou esses quatro e o tabindex positivo. Nada relatou o contorno de foco removido nem a div usada como botão, que a aula 14 testa com o teclado, nem o erro mostrado só em vermelho, que a aula 15 testa com um leitor de tela.\"><text x=\"430.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">axe, tags WCAG</text><text x=\"540.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">Lighthouse</text><text x=\"650.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">sobrou para uma pessoa</text><rect x=\"24.0\" y=\"42.0\" width=\"690.0\" height=\"28.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"48.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">1</text><text x=\"70.0\" y=\"56.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">sem lang no &lt;html&gt;</text><circle cx=\"430.0\" cy=\"56.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"540.0\" cy=\"56.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"650.0\" cy=\"56.0\" r=\"7\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></circle><rect x=\"24.0\" y=\"78.0\" width=\"690.0\" height=\"28.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"48.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">2</text><text x=\"70.0\" y=\"92.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nota cinza, 2.85:1</text><circle cx=\"430.0\" cy=\"92.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"540.0\" cy=\"92.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"650.0\" cy=\"92.0\" r=\"7\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></circle><rect x=\"24.0\" y=\"114.0\" width=\"690.0\" height=\"28.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"48.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">3</text><text x=\"70.0\" y=\"128.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">contorno de foco removido</text><circle cx=\"430.0\" cy=\"128.0\" r=\"7\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></circle><circle cx=\"540.0\" cy=\"128.0\" r=\"7\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></circle><rect x=\"600.0\" y=\"117.0\" width=\"100.0\" height=\"22.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"650.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">aula 14</text><rect x=\"24.0\" y=\"150.0\" width=\"690.0\" height=\"28.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"48.0\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">4</text><text x=\"70.0\" y=\"164.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">logo sem alt</text><circle cx=\"430.0\" cy=\"164.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"540.0\" cy=\"164.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"650.0\" cy=\"164.0\" r=\"7\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></circle><rect x=\"24.0\" y=\"186.0\" width=\"690.0\" height=\"28.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"48.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">5</text><text x=\"70.0\" y=\"200.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">campo de nome sem rótulo</text><circle cx=\"430.0\" cy=\"200.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"540.0\" cy=\"200.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"650.0\" cy=\"200.0\" r=\"7\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></circle><rect x=\"24.0\" y=\"222.0\" width=\"690.0\" height=\"28.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"48.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">6</text><text x=\"70.0\" y=\"236.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">tabindex=&quot;1&quot;</text><circle cx=\"430.0\" cy=\"236.0\" r=\"7\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></circle><circle cx=\"540.0\" cy=\"236.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"650.0\" cy=\"236.0\" r=\"7\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></circle><rect x=\"24.0\" y=\"258.0\" width=\"690.0\" height=\"28.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"48.0\" y=\"272.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">7</text><text x=\"70.0\" y=\"272.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Book é uma &lt;div&gt;</text><circle cx=\"430.0\" cy=\"272.0\" r=\"7\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></circle><circle cx=\"540.0\" cy=\"272.0\" r=\"7\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></circle><rect x=\"600.0\" y=\"261.0\" width=\"100.0\" height=\"22.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"650.0\" y=\"272.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">aula 14</text><rect x=\"24.0\" y=\"294.0\" width=\"690.0\" height=\"28.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"48.0\" y=\"308.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">8</text><text x=\"70.0\" y=\"308.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">erro só em vermelho</text><circle cx=\"430.0\" cy=\"308.0\" r=\"7\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></circle><circle cx=\"540.0\" cy=\"308.0\" r=\"7\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></circle><rect x=\"600.0\" y=\"297.0\" width=\"100.0\" height=\"22.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"650.0\" y=\"308.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">aula 15</text><text x=\"360.0\" y=\"352.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cheio: relatado · vazio: não relatado</text></svg>", "caption": "Quem achou cada defeito. Os três que impedem quem usa teclado ou leitor de tela de reservar um assento são os três que nenhuma ferramenta relatou.", "same": ["Lighthouse"]}
```

**Quatro para o axe, cinco para o Lighthouse e três que nenhuma ferramenta relatou.** Não é azar
com esta página. É o formato do teste automático de acessibilidade, e decorre do que um programa
consegue saber.

## Decidível a partir do documento

Uma regra consegue decidir o que o documento diz por si só. Um `<img>` tem `alt` ou não tem. Um
campo tem um rótulo que o navegador consegue calcular ou não tem. Duas cores têm uma razão, e a
razão fica acima de 4.5 ou abaixo. Esses são fatos sobre a marcação e os estilos calculados, e as
regras do axe são exatamente esses fatos, e é por isso que **quando o axe relata uma violação ele
quase sempre está certo**. A Deque desenha as regras para não relatar nada de que não tenha
certeza, e para pôr o resto no `incomplete`.

## Não decidível a partir do documento

O que uma regra não consegue decidir é qualquer coisa que exija saber **para que** a página serve:

- **Se um controle funciona.** A `<div>` do `book.html` tem um tratador de clique. Nada no
  documento diz que ela é o botão que reserva o assento, então nenhuma regra consegue dizer que um
  usuário de teclado precisa alcançá-la. Um `<button>` de verdade sem tratador passaria em toda
  regra e não faria nada.
- **Se o foco aparece.** `outline: none` é CSS válido, e uma página pode desenhar o foco de outro
  jeito: um fundo, uma borda, uma sombra. Uma regra não distingue um indicador ausente de um
  diferente, então não diz nada.
- **Se uma ordem faz sentido.** A ordem de tabulação é calculável; se ela bate com a ordem em que
  uma pessoa lê e preenche o formulário é um julgamento.
- **Se um nome está certo.** `alt="boxoffice"` passa. `alt="image"` também, e `alt="a red
  rectangle"` também. Uma regra confere que o nome existe, não que ele diz o que a imagem diz.
- **O que acontece depois.** A borda vermelha só aparece depois que Book é apertado com o nome
  vazio. Uma auditoria da página como ela carrega nunca vê o estado de erro, e uma auditoria do
  estado de erro vê uma borda colorida, o que não viola nada que uma regra consiga conferir.

O tamanho da parte indecidível depende de como se conta. O estudo da própria Deque sobre as suas
auditorias achou as regras automáticas pegando um pouco mais da metade dos problemas em
**quantidade**, porque os decidíveis, o contraste acima de todos, também são os mais comuns.
Contando por **critério de sucesso**, uma boa parte da WCAG 2.2 AA não tem regra que a decida, e a
plataforma em que este curso roda escreve a sua estimativa no cabeçalho da suíte de
acessibilidade: talvez um terço da WCAG, "and it is the third that regresses silently", o terço
que regride em silêncio. De um jeito ou de outro, o número que importa é o da figura acima: os
defeitos que impedem alguém de reservar um assento foram os que nenhuma ferramenta relatou.

## A falsa sensação de segurança

**Uma auditoria verde é prova de que uma lista de regras passou, e de nada mais.** O perigo é um
relatório que diz "0 violations" ou "Accessibility: 90" acabar como a linha da nota de versão que
diz que a página é acessível. Três coisas mantêm a afirmação honesta:

- **Diga qual ferramenta, quais regras, quais estados.** "axe 4.13.0, tags WCAG 2.2 A e AA,
  `book2.html` como carrega: 0 violações" é uma frase verdadeira. "Acessível" não é resultado de
  teste.
- **Junte a toda barreira automática uma passada manual nas mesmas páginas**: o teclado, aula 14,
  e um leitor de tela, aula 15. A ferramenta roda em todo commit; a passada manual roda quando uma
  página muda e antes de uma entrega.
- **Escreva os achados manuais como testes onde der.** A aula 14 transforma "o botão Book pode ser
  alcançado e apertado pelo teclado" num script, e depois que é um script ele é uma barreira como o
  `audit.js`.

A suíte que esta escola roda sobre as próprias telas diz a mesma coisa no cabeçalho: o axe acha o
que é decidível a partir do documento, e o que ele não acha, "those are read by a person, and
saying so here is the difference between a check and a claim of compliance": isso é lido por uma
pessoa, e dizer isso é a diferença entre uma checagem e uma declaração de conformidade.

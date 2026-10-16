---
title: "Mapas de contexto: como os modelos se encontram"
version: 1
---

**Um mapa de contextos é um desenho dos contextos delimitados e da relação entre cada par que
conversa: quem depende de quem, e quem se adapta quando o outro muda.** Os contextos são os
substantivos; o mapa é sobre os verbos. É o documento estratégico de que um desenvolvedor novo
precisa no primeiro dia, porque diz que mudanças são dele e quais precisam ser negociadas.

A ideia errada é achar que integração é detalhe técnico: uma chamada HTTP aqui, uma tabela
compartilhada ali. Toda ligação entre dois modelos é também uma relação entre as pessoas donas
deles. Quando o catálogo renomeia um campo, o código de alguém quebra, e o mapa é onde você decide de
antemão de quem é esse problema. No vocabulário do DDD, o contexto do qual os outros dependem é o
**upstream**, e o que depende é o **downstream**. As mudanças descem; as reclamações sobem.

## As relações

Evans deu nome à maioria delas, e os nomes pegaram porque cada um é uma resposta diferente a "quem
se adapta?":

| relação | quem se adapta a quem | quando serve |
|---|---|---|
| parceria (*partnership*) | os dois, juntos; dão certo ou errado como um só | duas equipes que planejam os lançamentos em conjunto |
| núcleo compartilhado (*shared kernel*) | ninguém sozinho: um pedaço pequeno de modelo pertence aos dois e só muda de comum acordo | um tipo de valor de que os dois dependem e que nenhum quer copiar |
| cliente/fornecedor | o upstream planeja para as necessidades do downstream | as necessidades do downstream contam nos planos do upstream |
| conformista | o downstream adota o modelo do upstream como ele é | o upstream não vai mudar por você, e o modelo dele é bom o bastante |
| camada anticorrupção | o downstream traduz o modelo do upstream para o seu | o upstream não vai mudar, e o modelo dele estragaria o seu |
| serviço aberto, linguagem publicada | o upstream oferece um protocolo documentado para todos | muitos downstreams, então acordos um a um não escalariam |
| caminhos separados | ninguém: os dois não se integram | o custo de ligar é maior que o benefício |

## O mapa da biblioteca

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l11-context-map\" aria-label=\"O mapa de contextos da biblioteca. Cinco caixas: o serviço bibliográfico nacional e o provedor de pagamentos, ambos externos, desenhados tracejados; e o catálogo, o empréstimo e as aquisições da própria biblioteca. Uma seta do serviço bibliográfico até o catálogo passa por uma caixinha marcada ACL, a camada anticorrupção. Uma seta do catálogo para o empréstimo é marcada cliente/fornecedor, com U do lado do catálogo e D do lado do empréstimo. Uma seta do provedor de pagamentos para o empréstimo é marcada conformista. Entre o catálogo e as aquisições fica uma caixinha marcada ISBN, o núcleo compartilhado, ligada aos dois.\"><defs><marker id=\"l11-context-map-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"65.0\" y=\"20.0\" width=\"210.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"170.0\" y=\"33.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">serviço bibliográfico</text><text x=\"170.0\" y=\"46.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">nacional</text><rect x=\"465.0\" y=\"20.0\" width=\"190.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"560.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">provedor de pagamentos</text><text x=\"360.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">fora da biblioteca</text><rect x=\"85.0\" y=\"178.0\" width=\"170.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">catálogo</text><rect x=\"475.0\" y=\"178.0\" width=\"170.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"560.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">empréstimo</text><rect x=\"85.0\" y=\"282.0\" width=\"170.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">aquisições</text><path d=\"M170.0 60.0 L170.0 104.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><rect x=\"140.0\" y=\"105.0\" width=\"60.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ACL</text><path d=\"M170.0 135.0 L170.0 177.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-context-map-dp-ah-paper-dim)\"></path><text x=\"206.0\" y=\"120.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">camada anticorrupção</text><path d=\"M255.0 200.0 L474.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-context-map-dp-ah-paper-dim)\"></path><text x=\"365.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cliente/fornecedor</text><text x=\"266.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"700\" fill=\"var(--amber)\">U</text><text x=\"462.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"700\" fill=\"var(--amber)\">D</text><path d=\"M560.0 60.0 L560.0 177.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-context-map-dp-ah-paper-dim)\"></path><text x=\"570.0\" y=\"120.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">conformista</text><text x=\"548.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"700\" fill=\"var(--amber)\">U</text><text x=\"548.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"700\" fill=\"var(--amber)\">D</text><path d=\"M170.0 222.0 L170.0 238.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><rect x=\"138.0\" y=\"238.0\" width=\"64.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"170.0\" y=\"255.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ISBN</text><path d=\"M170.0 272.0 L170.0 282.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><text x=\"212.0\" y=\"255.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">núcleo compartilhado</text><text x=\"560.0\" y=\"290.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">U upstream, D downstream</text></svg>", "caption": "Toda linha tem nome, e o nome diz quem se adapta quando o outro lado muda.", "same": ["U upstream, D downstream"]}
```

Leia o mapa uma linha de cada vez.

**Do catálogo para o empréstimo é cliente/fornecedor.** O balcão de empréstimo mostra títulos e
autores, então depende do catálogo. Os donos do catálogo tratam o empréstimo como cliente: antes de
mudar a forma de uma entrada de catálogo, perguntam do que a tela do balcão precisa. Sem esse acordo,
a relação escorrega para conformista por padrão, e o empréstimo fica sem voz.

**Catálogo e aquisições compartilham um núcleo: o ISBN.** Os dois precisam ler, validar e formatar
ISBNs, e duas cópias desse código um dia discordariam sobre um hífen. Então um módulo pequeno pertence
aos dois, e mudá-lo exige que os dois concordem. Um núcleo compartilhado funciona enquanto fica
pequeno; no momento em que ganha uma classe `Book`, virou de novo o modelo corporativo único.

**Do provedor de pagamentos para o empréstimo é conformista.** O modelo de pagamento do provedor, com
os próprios status de pendente, confirmado e estornado, é o que é, e a biblioteca é um cliente entre
milhares. O modelo também é razoável, então o empréstimo simplesmente usa as palavras dele para os
estados de pagamento. Ser conformista não é derrota quando o modelo do upstream é bom; economiza uma
tradução de que ninguém precisa.

**Do serviço bibliográfico nacional para o catálogo passa por uma camada anticorrupção.** O serviço
não vai mudar por causa de uma biblioteca, e o modelo dele encaixa mal: nomes de campo abreviados,
títulos em maiúsculas, autores escritos com o sobrenome primeiro. Adotá-lo poria esses hábitos no
código do próprio catálogo. A próxima seção constrói a camada.

## Para que serve o mapa

Um mapa que bate com o código é uma ferramenta de planejamento. Uma equipe downstream consegue ver
que é conformista e decidir se isso ainda é aceitável. Uma equipe prestes a criar uma integração
consegue ver que está criando uma nova dependência de upstream, e escolher a relação antes que a
primeira linha de código escolha por ela. **O mapa descreve a organização tanto quanto o software**,
que é a observação de Conway, de 1968: os sistemas acabam com a forma da comunicação entre as equipes
que os constroem.

`architecture-modeling`, o curso depois deste, desenha mapas de contexto como modelos de pleno
direito. Aqui um rascunho numa página basta, desde que toda linha nele tenha um nome da tabela.

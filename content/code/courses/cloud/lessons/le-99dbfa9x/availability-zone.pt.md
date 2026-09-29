---
title: Zonas de disponibilidade
version: 1
---

A imagem comum é um prédio grande por região, ou um prédio por zona e nada mais. A definição da
própria AWS é mais cuidadosa: **uma zona de disponibilidade é um ou mais datacenters separados, com
energia, rede e conectividade redundantes**, dentro de uma região. A `sa-east-1` tem três, chamadas
`sa-east-1a`, `sa-east-1b` e `sa-east-1c`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Uma região, sa-east-1, desenhada como um contorno tracejado que contém três zonas de disponibilidade, sa-east-1a, sa-east-1b e sa-east-1c. Cada zona é um ou mais datacenters com energia própria, refrigeração própria e rede própria. As três zonas se ligam por links de baixa latência, e a AWS documenta que ficam a muitos quilômetros umas das outras e a menos de 100 km entre si.\"><defs><marker id=\"rgz-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"680\" height=\"262\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"36\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">sa-east-1</text><text x=\"118\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">uma região: uma área geográfica, São Paulo</text><rect x=\"44\" y=\"70\" width=\"176\" height=\"132\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"56\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">sa-east-1a</text><text x=\"56\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um ou mais datacenters</text><text x=\"56\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">energia própria</text><text x=\"56\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">refrigeração própria</text><text x=\"56\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">rede própria</text><rect x=\"272\" y=\"70\" width=\"176\" height=\"132\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"284\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">sa-east-1b</text><text x=\"284\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um ou mais datacenters</text><text x=\"284\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">energia própria</text><text x=\"284\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">refrigeração própria</text><text x=\"284\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">rede própria</text><rect x=\"500\" y=\"70\" width=\"176\" height=\"132\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"512\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">sa-east-1c</text><text x=\"512\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um ou mais datacenters</text><text x=\"512\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">energia própria</text><text x=\"512\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">refrigeração própria</text><text x=\"512\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">rede própria</text><path d=\"M132 202 L132 232 L588 232 L588 202\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M360 202 L360 232\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"360\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">links de baixa latência entre zonas: muitos km, menos de 100 km</text></svg>", "caption": "Uma região, três zonas. Uma falha dentro de uma caixa, uma enchente ou uma entrada de energia que caiu, fica dentro daquela caixa; a região segue nas outras duas."}
```

A razão de ser de uma zona é o **isolamento**. Cada uma tem suas próprias entradas de energia, sua
própria refrigeração e seu próprio equipamento de rede, para que os desastres comuns de um prédio
fiquem dentro dele. Uma entrada de energia que cai, uma central de refrigeração que para, uma enchente
no subsolo, uma mudança errada num conjunto de switches: cada um deles deve parar na fronteira da zona.
A AWS documenta que suas zonas ficam separadas por uma distância significativa, muitos quilômetros, e todas a menos de 100 km umas das outras. Essa
distância é o meio-termo em que o projeto inteiro se apoia: longe o bastante para um evento local não
alcançar duas delas, perto o bastante para a ida e volta entre elas continuar curta.

**Perto o bastante importa, porque as zonas foram feitas para serem usadas juntas.** Elas se ligam por
links dedicados de alta largura de banda e baixa latência, para que uma aplicação rode em duas zonas ao
mesmo tempo e um banco de dados mantenha uma cópia numa segunda zona enquanto faz o commit. Cem
quilômetros de fibra, ida e volta, são 200 km, e aos 200 km por milissegundo que esta aula calcula
duas seções adiante, isso dá um piso de 1 ms. Conversar entre duas zonas é barato em tempo. Não é
de graça em dinheiro, e a seção sobre sobreviver à queda de uma zona põe preço nisso.

## O seu "a" não é o meu "a"

**O nome de uma zona é um rótulo na sua conta, não o endereço de um prédio.** A AWS associa os nomes
às zonas físicas de forma independente para cada conta. O motivo documentado é a carga: se a
`sa-east-1a` de todas as contas fosse o mesmo prédio, a maioria escolheria "a" por hábito, e essa
zona lotaria enquanto as outras ficariam meio vazias. Então a `sa-east-1a` da sua conta e a
`sa-east-1a` da conta de um colega podem ser prédios diferentes.

O nome estável é o **ID da zona**, que tem a forma `sae1-az1` e significa a mesma zona física em toda
conta. Listar os nomes com os IDs é uma chamada à API do EC2, e ela não foi executada aqui: não há
conta neste curso.

Na maior parte do tempo a associação é invisível, porque tudo o que você constrói está numa conta só e
os seus nomes são coerentes entre si. Ela importa no dia em que duas contas precisam concordar sobre
uma zona. Imagine que o seu time roda a aplicação numa conta e o time de banco de dados roda o banco em
outra, e os dois põem a sua parte "na `sa-east-1a`" para manter o tráfego dentro de uma zona. Os nomes
batem. Os prédios podem não bater, e se não baterem, toda consulta cruza zonas e é cobrada pela tarifa
entre zonas, enquanto os dois times têm certeza de que não. **Compare IDs de zona, nunca nomes de
zona**, sempre que houver mais de uma conta envolvida.

## Do que uma zona não protege

Uma zona protege contra uma falha local de um prédio. Ela não faz nada contra um erro que não é local.
Um deploy ruim que você empurra para as duas zonas quebra as duas zonas. Um problema regional no
próprio software do provedor, do tipo que a última seção desta aula trata, alcança todas as zonas
daquela região, porque as zonas compartilham os sistemas de controle da região. Duas zonas são uma
defesa contra o chão sob um prédio, e só isso.

Azure e Google Cloud também têm zonas, com nomes próprios: a Azure numera as zonas como 1, 2 e 3
dentro de uma região, e o Google dá a elas o nome da região com uma letra, como
`southamerica-east1-a`. A forma é a mesma em todo lugar: uma região é a unidade que você escolhe por
lei, latência e preço, e as zonas são as unidades entre as quais você se espalha contra falhas.

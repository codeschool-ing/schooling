---
title: O endereço dentro da placa
version: 1
---

Uma placa de rede tem um número gravado nela na fábrica. Seis bytes, escritos como doze dígitos
hexadecimais em pares: `a4:83:e7:2f:91:0c`.

Este é o **endereço MAC**, e é o endereço a que um quadro é endereçado — o que, pela aula dois,
significa que é o endereço que importa por exatamente um salto e é jogado fora no fim dele.

## O que o diferencia de um endereço IP

Duas propriedades, e entre as duas elas explicam por que os dois existem.

**Ele não muda.** Pertence à placa, e não à rede. Leve um notebook de casa para um escritório e
para outro país e o MAC é idêntico nos três, enquanto o endereço IP é diferente toda vez.

**Ele não tem estrutura.** Um endereço IP pode ser dividido numa parte de rede e numa parte de
host, que é o que torna o roteamento possível: um roteador guarda uma linha para um milhão de
endereços. Um MAC não pode ser dividido em nada. Não existe "rede de MACs" — os três primeiros
bytes identificam o fabricante e mais nada de útil.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 208\" role=\"img\" aria-label=\"Uma comparação dos dois endereços. O endereço IP aparece mudando em três lugares enquanto o MAC permanece idêntico, e uma nota diz que um é dado pela rede e o outro pela fábrica.\"><text x=\"140\" y=\"34\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">o mesmo notebook</text><text x=\"400\" y=\"34\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">o endereço IP dele</text><text x=\"614\" y=\"34\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">o endereço MAC dele</text><rect x=\"24\" y=\"48\" width=\"232\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"140\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">em casa</text><text x=\"400\" y=\"70\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">192.168.1.24</text><text x=\"614\" y=\"70\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">a4:83:e7:2f:91:0c</text><rect x=\"24\" y=\"94\" width=\"232\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"140\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">no escritório</text><text x=\"400\" y=\"116\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">10.14.3.87</text><text x=\"614\" y=\"116\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">a4:83:e7:2f:91:0c</text><rect x=\"24\" y=\"140\" width=\"232\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"140\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">na rede de um café</text><text x=\"400\" y=\"162\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">172.20.9.5</text><text x=\"614\" y=\"162\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">a4:83:e7:2f:91:0c</text><text x=\"400\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">dado pela rede</text><text x=\"614\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">dado pela fábrica</text></svg>", "caption": "Onde você está, e o que você é. A rede decide o primeiro; o fabricante decidiu o segundo."}
```

Junte os dois e a divisão de trabalho fica clara. O endereço IP diz **onde no mundo**, e é agrupado
para que o roteamento seja possível. O MAC diz **qual placa neste fio**, e não precisa de estrutura
porque a pergunta só é feita entre as poucas dezenas de coisas plugadas no mesmo comutador.

## Por que um quadro precisa de um

Uma objeção justa a esta altura: se toda máquina já tem um endereço IP, por que o quadro não
carrega simplesmente esse?

Porque o cabo não sabe o que é um endereço IP, e isso não é figura de linguagem. A Ethernet foi
projetada para mover quadros entre placas num meio compartilhado, e é anterior à ideia de que esses
quadros carregariam pacotes de internet. Ela carrega qualquer coisa: já foi usada para protocolos
que não existem mais e será usada para outros ainda não escritos.

**A camada de baixo não deve saber o que a de cima está carregando.** É a regra que a aula cinco
generaliza, e o endereço MAC é o exemplo mais claro dela no curso inteiro: um esquema de
endereçamento completo pertencente ao fio, ignorante do esquema de endereçamento que viaja dentro.

Há um ganho prático também. Como a placa conhece o próprio endereço e só aceita quadros que o
carregam, uma máquina consegue ignorar quase tudo num fio compartilhado sem acordar nada. A placa
filtra em hardware; o sistema operacional nunca vê o resto.

## Três tipos de destino

O destino de um quadro nem sempre é uma placa.

**Unicast** é uma placa específica, que é quase todo o tráfego.

**Broadcast** é `ff:ff:ff:ff:ff:ff`, e toda placa do fio aceita. É como uma máquina faz uma pergunta
quando ainda não sabe a quem perguntar — que é a próxima seção, e a seguinte.

**Multicast** é um grupo: placas que optaram por ele aceitam e o resto não. É como uma televisão
acha uma caixa de som para tocar, e como uma impressora se anuncia.

A razão de conhecer os três é que tráfego de broadcast chega em toda máquina e custa um pouco de
trabalho a cada uma, que é o argumento por redes menores que você viu uma seção atrás. Uma rede não
é lenta por ser grande; é lenta porque tudo nela é interrompido por tudo perguntando.

## Ele deveria ser único, e não é bem

Fabricantes recebem blocos, então em princípio toda placa do mundo tem um número diferente. Na
prática duplicatas existem — máquinas virtuais os geram, hardware barato os reaproveita, e o
endereço de uma placa simplesmente pode ser trocado por software na maioria dos sistemas.

O que importa por um motivo: **um MAC não é uma identidade**. Qualquer coisa que confie num — uma
rede que admite um aparelho porque reconhece o número, uma licença amarrada a ele — está confiando
num valor que o aparelho escolheu relatar.

O contrário também vale saber. Como o número é estável, ele pode ser usado para **reconhecer** um
aparelho entre visitas, que é do que os telefones se defendem inventando um MAC diferente para cada
rede em que entram. Se você já se perguntou por que o endereço de um telefone parece diferente em
cada Wi-Fi, isso é deliberado.

## Onde isto te deixa

Um endereço MAC identifica uma placa de rede, está preso ao hardware e não à rede, não tem
estrutura interna, e é a quem um quadro é endereçado no seu único salto.

O que deixa a pergunta para a qual esta aula vinha construindo. Uma máquina tem um pacote para
`192.168.1.99`, já concluiu pela máscara que isso é local, então precisa montar um quadro — e um
quadro precisa de um **endereço MAC**. Ela não tem um. Nunca viu esse vizinho antes.

Como ela descobre é a próxima seção.

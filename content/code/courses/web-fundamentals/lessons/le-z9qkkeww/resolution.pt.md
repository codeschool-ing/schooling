---
title: Quatro perguntas, e só a última sabe
version: 1
---

Você digitou um nome. Antes de qualquer coisa da aula seis acontecer — antes de uma conexão, antes de
uma requisição — algo precisa transformar aquele nome num endereço. Aqui está exatamente o quê, em
ordem.

## O elenco

**Sua máquina** tem um pedacinho de software que sabe perguntar e mais nada. Ele não procura; pergunta
a um servidor e espera.

**Um resolvedor recursivo** é quem faz o trabalho. É um servidor cuja função é caçar a resposta por
quantos passos forem precisos e entregar a você um único resultado. O seu veio do roteador que deu um
endereço a você na aula quatro, a menos que você o tenha trocado.

**Os servidores raiz** sabem uma coisa: quem administra cada domínio de topo.

**Os servidores de TLD** — os de `ing`, de `com`, de `br` — sabem quais servidores foram nomeados
como respondendo por cada domínio registrado debaixo deles.

**Os servidores autoritativos** de um domínio guardam os registros de verdade. São as únicas máquinas
desta lista que sabem a resposta.

## A caminhada

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"O resolvedor pergunta a um servidor raiz, que nomeia os servidores do domínio de topo; pergunta a um desses, que nomeia os servidores do domínio; e pergunta a um desses, que enfim responde com um endereço.\"> <rect x=\"20\" y=\"30\" width=\"160\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect> <text x=\"100\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">sua máquina</text> <path d=\"M186 52 L254 52\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path> <rect x=\"260\" y=\"30\" width=\"200\" height=\"44\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o resolvedor — é ele que caminha</text> <rect x=\"180\" y=\"100\" width=\"360\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">um servidor raiz</text> <text x=\"560\" y=\"122\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">pergunte aos de ing</text> <rect x=\"180\" y=\"160\" width=\"360\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">um servidor de ing</text> <text x=\"560\" y=\"182\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">pergunte aos deles</text> <rect x=\"180\" y=\"220\" width=\"360\" height=\"44\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">um servidor autoritativo de codeschool.ing</text> <text x=\"560\" y=\"242\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">203.0.113.7</text> <text x=\"100\" y=\"122\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">passo 1</text> <text x=\"100\" y=\"182\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">passo 2</text> <text x=\"100\" y=\"242\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">passo 3</text> <text x=\"360\" y=\"294\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">os dois primeiros respondem eu não, eles — de uma lista que já têm</text> <text x=\"360\" y=\"314\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">ninguém consulta nada por ninguém, e por isso nenhum passo disto é um gargalo</text> </svg>", "caption": "Quatro perguntas e uma resposta. Tudo antes do último passo é um encaminhamento, não uma consulta."}
```

Sua máquina pergunta ao resolvedor: *qual é o endereço de `app.codeschool.ing`?*

O resolvedor pergunta a um servidor raiz. A raiz não sabe, e diz isso de forma útil: *pergunte aos
servidores de `ing`, aqui estão eles.*

O resolvedor pergunta a um deles. Esse também não sabe: *pergunte aos servidores de
`codeschool.ing`, aqui estão eles.*

O resolvedor pergunta a um deles, e esse sabe, porque alguém pôs o registro ali. Ele responde com o
endereço.

O resolvedor entrega a você aquele endereço, e a conexão da aula seis pode começar.

Repare no formato. Ninguém caça nada em seu nome além do resolvedor, e ninguém no caminho consulta
nada por ele — cada servidor responde *eu não, eles* de uma lista que já tem. É por isso que o
sistema inteiro custa tão pouco para operar e por que nenhum passo dele é um gargalo.

## Quase nada disso costuma acontecer

A caminhada acima é o caso frio. Na prática a maioria das perguntas é respondida bem antes da raiz.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Quatro caches em ordem: o do próprio navegador, o do sistema operacional, o do resolvedor, e só então a caminhada até a raiz. A maioria das perguntas para no terceiro.\"> <rect x=\"20\" y=\"34\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".22\" stroke=\"var(--phosphor)\"></rect> <text x=\"200\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o cache do próprio navegador</text> <text x=\"520\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">nada sai do processo</text> <rect x=\"20\" y=\"80\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"200\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o do sistema operacional</text> <text x=\"520\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">nada sai da máquina</text> <rect x=\"20\" y=\"126\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".14\" stroke=\"var(--phosphor)\"></rect> <text x=\"200\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o do resolvedor — o movimentado</text> <text x=\"520\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">a alguns milissegundos</text> <rect x=\"20\" y=\"172\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"200\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">e só então, a caminhada</text> <text x=\"520\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">possivelmente outro continente</text> <text x=\"360\" y=\"240\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a linha de baixo é o que acontece para a primeira pessoa a perguntar</text> <text x=\"360\" y=\"262\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">quanto tempo cada linha guarda uma resposta é um número que você escolhe, e é a próxima leitura</text> </svg>", "caption": "Quatro lugares de onde uma resposta pode vir, em ordem. A maioria das perguntas nunca chega ao quarto."}
```

Há caches em cada nível: no navegador, no sistema operacional, no resolvedor, e o do resolvedor é o
que faz o trabalho pesado. Um resolvedor servindo cem mil pessoas já foi avisado de onde ficam os
servidores de `ing`, e os de `codeschool.ing`, segundos depois de a primeira pessoa perguntar.

Então um nome popular custa uma pergunta e uma resposta, ambas a uma máquina a alguns milissegundos.
A caminhada de quatro passos é o que acontece para a primeira pessoa, e para nomes que ninguém pediu
recentemente.

É também onde a próxima leitura começa, porque quanto tempo cada cache guarda uma resposta é um
número que você escolhe, e ele decide quanto tempo suas mudanças levam para aparecer.

## Quanto custa quando está frio

Ponha ao lado da aula três. Uma consulta fria são algumas idas e voltas a servidores que podem estar
em outros continentes, e acontece **antes** da conexão, que é antes da criptografia, que é antes da
requisição.

Para uma página que puxa recursos de cinco hosts, isso são potencialmente cinco consultas frias, cada
uma enfileirada na frente de tudo que aquele host fará. É uma causa comum e invisível de uma primeira
visita lenta, e é a razão de existirem as dicas do próprio navegador — pedir que ele resolva um nome
cedo, antes de a página precisar.

## De onde vem seu resolvedor, e o que trocá-lo significa

O `DHCP` da aula quatro entregou a você um resolvedor junto com o endereço, e para a maioria das
pessoas é um que o provedor administra.

Você pode trocar, e os públicos são bem conhecidos — um par de oitos, um par de uns. O que isso de
fato muda vale ser dito com honestidade. Às vezes é mais rápido e às vezes mais lento, dependendo de
onde você está e de quão bom é o do seu provedor. Isso move o registro de cada nome que você consulta
de uma empresa para outra, em vez de removê-lo. E contorna o que quer que o seu provedor estivesse
fazendo naquela camada, que em algumas redes é uma filtragem que você queria e em outras uma que não.

## A pergunta em si costuma estar às claras

Historicamente essa troca inteira roda sobre UDP, na porta 53, em texto puro: uma perguntinha, uma
respostinha, sem conexão, exatamente como a aula seis previu que seria.

Texto puro quer dizer que qualquer um no caminho vê cada nome que você pede — o que, depois da
leitura sobre HTTPS, é a lacuna no quadro. A conexão é cifrada; a pergunta sobre onde se conectar não
era.

Dois arranjos fecham isso. **DNS sobre TLS** põe a mesma troca dentro de uma conexão cifrada numa
porta própria. **DNS sobre HTTPS** põe dentro de tráfego HTTPS comum, então ela não é só ilegível mas
indistinguível de qualquer outra coisa. Navegadores trazem isso e alguns ligam por padrão.

É genuinamente contestado em vez de simplesmente melhor, e vale conhecer o argumento: mover cada
consulta para dentro de HTTPS a um punhado de grandes provedores concentra em poucas mãos um registro
que antes ficava espalhado por milhares de provedores de acesso, e tira as consultas da vista de
operadores de rede que as usavam para bloquear malware e aplicar regras que uma escola ou uma mãe
pediu. As duas metades disso são verdade ao mesmo tempo.

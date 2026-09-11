---
title: A requisição que nunca foi feita
version: 1
---

A outra memória de um navegador não tem nada a ver com quem você é. Ela economiza **requisições**, e
a requisição mais rápida deste curso é a que não acontece.

Um cache faz duas perguntas, nesta ordem. Posso guardar isto? E posso usar o que guardei sem
conferir? Quase tudo abaixo é resposta a uma das duas.

## Fresca, velha, e os dois desfechos

Uma resposta chega com uma instrução:

```
Cache-Control: max-age=3600
```

Pela próxima hora aquela cópia está **fresca**. Uma requisição ao mesmo endereço nessa hora não
produz atividade de rede nenhuma: o navegador serve a própria cópia e nada sai da máquina. Zero
bytes, zero milissegundos, e nenhuma linha em nenhum log de servidor.

Depois da hora ela está **velha**, o que não quer dizer inútil. Quer dizer *pergunte antes de usar*.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Uma cópia em cache que ainda está fresca é usada sem requisição nenhuma. Uma cópia velha produz uma requisição condicional, respondida com um 304 pequeno que mantém a cópia ou com um 200 inteiro trazendo conteúdo novo.\"> <rect x=\"230\" y=\"26\" width=\"260\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a página pede algo de novo</text> <path d=\"M300 70 L180 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path> <path d=\"M420 70 L540 110\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path> <rect x=\"20\" y=\"116\" width=\"320\" height=\"70\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a cópia ainda está fresca</text> <text x=\"180\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">nenhuma requisição</text> <rect x=\"380\" y=\"116\" width=\"320\" height=\"70\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"540\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a cópia ficou velha</text> <text x=\"540\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">If-None-Match: \"a4f21c\"</text> <path d=\"M470 192 L400 228\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path> <path d=\"M610 192 L640 228\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path> <rect x=\"240\" y=\"234\" width=\"290\" height=\"56\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"385\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">304 — nada mudou</text> <text x=\"385\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">sem corpo: 300 bytes, e a cópia volta a ser fresca</text> <rect x=\"546\" y=\"234\" width=\"154\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"623\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">200 — novo</text> <text x=\"623\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a coisa inteira</text> </svg>", "caption": "Três desfechos, e o da esquerda nunca toca a rede. É isso que o frescor compra."}
```

A pergunta é uma **requisição condicional**. O navegador manda o que já tem, como impressão digital,
e o servidor compara:

```
If-None-Match: "a4f21c"
```

Se nada mudou, a resposta é `304 Not Modified` — uma linha de status e alguns cabeçalhos, sem corpo
nenhum. Trezentos bytes em vez de duzentos kilobytes, e o navegador mantém o que tinha, agora fresco
de novo.

Se algo mudou, a resposta é um `200` comum com o conteúdo novo, e o ciclo recomeça.

Essa impressão digital é a `ETag`, que um servidor define na saída. Ela pode ser um hash do
conteúdo, um número de versão, qualquer coisa — a única exigência é que mude quando o conteúdo muda.
Há um mecanismo mais antigo usando datas e `If-Modified-Since`, ainda perfeitamente comum, que é a
mesma ideia com um segundo de resolução em vez de exatidão.

## As três instruções que as pessoas confundem

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Três instruções comparadas. max-age guarda uma cópia e a usa sem perguntar. no-cache guarda uma cópia e pergunta sempre. no-store não guarda nada.\"> <rect x=\"20\" y=\"30\" width=\"216\" height=\"120\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"128\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">max-age=3600</text> <text x=\"128\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">guarda uma cópia</text> <text x=\"128\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">e usa a cópia</text> <text x=\"128\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">sem perguntar nada</text> <rect x=\"252\" y=\"30\" width=\"216\" height=\"120\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">no-cache</text> <text x=\"360\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">guarda uma cópia</text> <text x=\"360\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">e pergunta sempre</text> <text x=\"360\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">antes de usá-la</text> <rect x=\"484\" y=\"30\" width=\"216\" height=\"120\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\"></rect> <text x=\"592\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">no-store</text> <text x=\"592\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">não guarda nada</text> <text x=\"592\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">para um extrato ou</text> <text x=\"592\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">máquina compartilhada</text> <text x=\"360\" y=\"192\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">os dois nomes do meio são os que as pessoas trocam</text> <text x=\"360\" y=\"220\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">no-cache pergunta; no-store recusa</text> </svg>", "caption": "Só uma destas três se recusa a guardar uma cópia, e não é a que tem cache no nome."}
```

`max-age=N` — guarde, e use sem perguntar por N segundos.

`no-cache` — guarde, e **pergunte toda vez** antes de usar. Apesar do nome, isto não é uma recusa a
cachear. É o arranjo que rende um `304` na maioria das requisições e conteúdo correto em todas, e é
o que você quer para qualquer coisa que muda de forma imprevisível.

`no-store` — não anote isto de jeito nenhum. Esta é a recusa, e é a resposta certa para um extrato
bancário ou qualquer coisa pessoal numa máquina compartilhada.

Trocar esses dois nomes é comum o bastante para merecer um momento de memorização deliberada:
**`no-cache` pergunta, `no-store` recusa.**

## Quem está com a cópia

A outra metade do `Cache-Control` é sobre *qual* cache, e errar isso não é um problema de desempenho
e sim um vazamento.

`private` quer dizer que só o navegador que pediu pode guardar isto. `public` quer dizer que
qualquer coisa no caminho pode: uma CDN, um proxy corporativo, um cache no provedor.

Uma página com o nome de alguém, o histórico de pedidos, o saldo — isso é `private`, e marcar como
`public` põe a página de um visitante num cache compartilhado do qual o próximo visitante é servido.
É um cabeçalho pequeno e já vazou dados de gente real mais de uma vez, porque o defeito é invisível
para quem está testando na própria máquina.

Há uma diretiva específica para caches compartilhados — `s-maxage` — que deixa você dizer uma coisa a
uma CDN e outra aos navegadores. Vale saber que existe no ponto em que você tem uma CDN e quer
manter algo na borda por mais tempo do que no navegador de alguém.

## Velho de propósito

Duas diretivas valem conhecer porque mudam o que acontece no pior minuto do dia de um site.

`stale-while-revalidate` diz: quando a cópia ficar velha, **sirva assim mesmo** e busque uma fresca
em segundo plano. O visitante não espera nada, e o próximo visitante recebe a versão nova. Custa um
instante de conteúdo levemente antigo em troca de nunca fazer ninguém esperar por uma revalidação.

`stale-if-error` diz: se a origem estiver quebrada, sirva a cópia antiga em vez de um erro. Um site
cujos servidores caíram consegue seguir respondendo com as páginas de ontem, o que é uma queda bem
diferente de uma tela em branco.

As duas são instruções a caches que as suportam — uma CDN, em geral, e não um navegador — e as duas
são o tipo de coisa barata de configurar de antemão e impossível de configurar durante o incidente
que ela teria coberto.

## O cabeçalho que um cache pode ignorar

Uma nota honesta, porque poupa uma discussão depois. Estas são instruções e não leis.

Um navegador pode descartar qualquer coisa a qualquer momento porque está com pouco disco. Um proxy
pode estar configurado por alguém que discorda de você. Uma CDN aplica as próprias regras por cima
das suas. `max-age` é um teto de quanto tempo um cache pode usar uma cópia, e não uma promessa de que
vai.

Então um cache é algo em que você confia estatisticamente e nunca individualmente — e é por isso que
a correção nunca pode depender de uma cópia ainda estar ali, e por que as perguntas de cache que
valem são todas do tipo *o que acontece se isto não estiver lá?*

## Quanto vale

Ponha números nisso, porque a abstração esconde o tamanho da coisa.

Uma página com sessenta recursos, numa segunda visita. Sem cache, sessenta requisições e talvez dois
megabytes. Com requisições condicionais, sessenta requisições e talvez vinte kilobytes de `304` — as
idas e voltas continuam pagas. Com cópias frescas, **zero requisições**, e a página se monta do disco
antes de a rede ser consultada.

A diferença entre a segunda e a terceira é toda a razão de a próxima leitura existir. Frescor vale
um bocado, e o preço de pedi-lo é que você prometeu algo que não consegue retirar com facilidade.

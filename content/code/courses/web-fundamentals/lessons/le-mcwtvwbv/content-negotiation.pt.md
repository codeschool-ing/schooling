---
title: Pedindo no seu próprio idioma
version: 1
---

Um endereço pode ter várias respostas. A mesma página existe em cinco idiomas aqui; um relatório
existe como página web e como planilha; uma fotografia existe comprimida de três jeitos diferentes.
O HTTP tem um mecanismo para escolher entre elas, e o navegador já vem usando isso em seu nome.

## A metade que pede

A requisição leva uma lista curta de cabeçalhos `Accept`, e cada um é uma preferência ordenada em
vez de uma exigência.

```
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
Accept-Language: pt-BR,pt;q=0.9,en;q=0.8
Accept-Encoding: gzip, br
```

Os números são a ordenação. Um item sem `q` vale 1, o mais desejado; `q=0.9` vale um pouco menos;
`q=0.8` menos ainda. Então aquela segunda linha se lê: *português brasileiro se você tiver, senão
português de qualquer tipo, senão inglês, e se nada disso, me surpreenda.*

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"O navegador manda uma lista ordenada: português brasileiro primeiro, depois português, depois inglês. O servidor tem português, inglês e espanhol. A primeira linha da lista que ele consegue atender é português, e é isso que ele manda.\"> <text x=\"20\" y=\"24\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">o que o navegador pediu, em ordem</text> <rect x=\"20\" y=\"34\" width=\"300\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"170\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pt-BR — sem q, o mais desejado</text> <rect x=\"20\" y=\"80\" width=\"300\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"170\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pt — q=0.9</text> <rect x=\"20\" y=\"126\" width=\"300\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"170\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">en — q=0.8</text> <text x=\"400\" y=\"24\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">o que o servidor tem</text> <rect x=\"400\" y=\"34\" width=\"300\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-dasharray=\"4 3\"></rect> <text x=\"550\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">sem variante brasileira</text> <rect x=\"400\" y=\"80\" width=\"300\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"550\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">português — tem</text> <rect x=\"400\" y=\"126\" width=\"300\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"550\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">inglês — tem, e não precisa aqui</text> <rect x=\"20\" y=\"192\" width=\"680\" height=\"42\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".16\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"213\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Content-Language: pt — a primeira linha da lista que dava para atender</text> <text x=\"360\" y=\"262\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">uma preferência que não dá para atender não é erro; o servidor serve a próxima da lista</text> </svg>", "caption": "A lista é ordenada, não obrigatória. O servidor desce por ela e para na primeira coisa que tem."}
```

O servidor tem o que tem, percorre a lista e serve o melhor que conseguir casar. Se não tem
português serve inglês e ninguém falhou — negociação é uma preferência, e uma preferência que não dá
para atender não é um erro.

O `Accept-Encoding` é o mesmo mecanismo usado para outra coisa completamente: compressão. O navegador
está dizendo *eu sei desempacotar estes formatos*, e um servidor que consegue comprimir vai
comprimir, tipicamente deixando uma página com um quarto do tamanho. É a melhoria de desempenho mais
barata de toda a lista e é negociada num cabeçalho que ninguém olha.

## A metade que responde, e o cabeçalho que todo mundo esquece

O servidor escolhe, e então precisa dizer o que escolheu: `Content-Language: pt`, ou
`Content-Encoding: gzip`.

E precisa dizer mais uma coisa, e é aí que isto dá errado em produção.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"O mesmo cache servindo dois visitantes. Sem o cabeçalho Vary os dois recebem a cópia guardada para o primeiro visitante. Com ele, as duas são arquivadas separadamente e cada um recebe o idioma certo.\"> <text x=\"180\" y=\"22\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">sem cabeçalho Vary</text> <rect x=\"20\" y=\"34\" width=\"320\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">arquivado sob: /precos</text> <rect x=\"20\" y=\"92\" width=\"320\" height=\"44\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">primeiro visitante pediu em português</text> <rect x=\"20\" y=\"150\" width=\"320\" height=\"44\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".22\" stroke=\"var(--amber)\"></rect> <text x=\"180\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">segundo pediu em inglês, recebeu português</text> <text x=\"180\" y=\"224\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">uma chave, dois visitantes, um deles errado</text> <text x=\"540\" y=\"22\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">Vary: Accept-Language</text> <rect x=\"380\" y=\"34\" width=\"320\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"540\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">arquivado sob: /precos mais o idioma</text> <rect x=\"380\" y=\"92\" width=\"320\" height=\"44\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">primeiro visitante pediu em português</text> <rect x=\"380\" y=\"150\" width=\"320\" height=\"44\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">segundo pediu em inglês, recebeu inglês</text> <text x=\"540\" y=\"224\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">duas chaves, dois visitantes, os dois certos</text> <text x=\"360\" y=\"266\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">o defeito nunca se reproduz para quem o construiu, porque essa pessoa é sempre a primeira visitante</text> </svg>", "caption": "Um cache arquiva uma resposta sob o endereço. Se a resposta dependeu de um cabeçalho, o cabeçalho tem que fazer parte da chave."}
```

Entre você e o servidor há caches, e um cache guarda uma resposta sob o endereço que foi pedido. Se
um endereço pode produzir respostas diferentes, um cache que arquiva todas sob a mesma chave vai
entregar a página em português para a próxima pessoa, seja ela quem for.

`Vary: Accept-Language` é a instrução que conserta: *esta resposta dependeu daquele cabeçalho, então
arquive sob os dois.* Deixe de fora e o site funciona perfeitamente para quem visita primeiro e está
errado para todo mundo depois — e é por isso que este defeito quase sempre é relatado como *o site
está no idioma errado para algumas pessoas*, e quase nunca se reproduz para quem o construiu.

O mesmo vale para qualquer cabeçalho em que uma decisão foi baseada. Se a resposta muda com o
`Accept-Encoding`, diga; se muda com algo que você inventou, diga também.

## Por que os sites fazem de outro jeito

Agora a parte honesta, porque a maioria dos sites que você usa não escolhe idioma assim.

Um idioma escolhido a partir de um cabeçalho é invisível e não dá para compartilhar. Você não pode
mandar a alguém um link para a página como você a viu, porque o link não carrega idioma e o
navegador da pessoa vai pedir o dela. Você não consegue sobrepor com facilidade — um brasileiro
lendo documentação em inglês está brigando com as próprias configurações. E você não consegue ver,
pelo endereço, qual versão está olhando.

Então o arranjo comum usa o cabeçalho **uma vez**, como primeiro palpite, e depois lembra a escolha:
`/pt/precos` e `/en/pricing` como endereços separados, ou um cookie guardando uma decisão que o
visitante tomou. Cada endereço passa a ter uma resposta, links dão para compartilhar, e o problema
de cache some porque não sobrou nada para variar.

Este site faz assim também. Sua primeira visita é adivinhada pelo navegador; depois disso é uma
escolha guardada, e o palpite não é consultado de novo.

A negociação segue sendo a ferramenta certa para coisas sobre as quais o visitante não tem opinião —
compressão, formatos de imagem — e para interfaces em que quem chama é um programa e não uma pessoa.
O que traz o último caso.

## Imagens, onde ela mais trabalha hoje

O lugar onde a negociação se paga sem ninguém pensar nisso é em figuras.

Um navegador manda algo como `Accept: image/avif,image/webp,image/png,*/*`, e um servidor que tem a
mesma fotografia em três formatos escolhe o mais novo que aquele navegador entende. A imagem é a
mesma foto e pode ter metade dos bytes, e nenhum endereço mudou, nenhuma marcação mudou e nenhum
visitante tomou decisão alguma.

Esse é o argumento a favor da negociação numa frase: ela funciona para coisas em que **existe uma
resposta certa sobre a qual o visitante não tem opinião**, e degrada em silêncio quando um navegador
é velho demais para aceitar a melhor.

Compressão é a mesma história da página anterior. A escolha entre um codec de vídeo moderno e um
antigo também. Em cada caso chega uma lista de preferências, o servidor escolhe o melhor que
consegue servir, e ninguém é questionado sobre algo que não saberia responder.

## Quando nada casa

A especificação tem um código para *não tenho nada do que você disse que aceitaria* — `406 Not
Acceptable` — e na prática ele quase nunca é a coisa certa a mandar.

O motivo é que a requisição era uma preferência, então servir alguma coisa é quase sempre mais útil
que servir nada. Um navegador pedindo português e recebendo inglês consegue ler o inglês; um
navegador recebendo um `406` ganha uma página de erro com que não pode fazer nada. A regra que a
maioria dos servidores segue é atender a lista se der e senão mandar o padrão, e guardar o `406`
para o caso em que quem chama é um programa que genuinamente não consegue interpretar outra coisa.

## O mesmo endereço, HTML ou dados

O `Accept` também escolhe formato, e é aqui que você vai usar negociação de propósito.

Um endereço para um pedido pode responder `text/html` a um navegador e `application/json` a um
programa, com o mesmo código decidindo o que é verdade e só o último passo decidindo como escrever.
A alternativa são dois endereços que se afastam com o tempo, e eles se afastam.

Vale conhecer o argumento contrário: um único endereço com duas formas é mais difícil de cachear,
mais difícil de depurar — o mesmo link dá coisas diferentes para ferramentas diferentes — e fácil de
errar de jeitos que só aparecem para um tipo de chamador. Os dois arranjos são defensáveis. O que
não é é escolher um por acidente, que é o que acontece quando ninguém sabe que o mecanismo existe.

---
title: Cópias, mais perto
version: 1
---

A aula três deu a você um número contra o qual não dá para argumentar: a luz leva tempo, e uma
requisição que cruza um oceano paga a travessia duas vezes antes de um único byte de conteúdo andar.

Uma **rede de distribuição de conteúdo** é a resposta a esse número, e é simples. Mantenha cópias dos
seus arquivos em máquinas pelo mundo todo, e responda cada visitante a partir da mais próxima.

## O que ela é de fato

Algumas centenas de localidades — *bordas* — cada uma com um cache. O nome do seu site resolve, para
cada visitante, para a borda mais próxima dele, que é o que o `CNAME` para o nome de um provedor da aula
anterior costuma estar arranjando.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Um visitante é respondido pela borda mais próxima, que tem uma cópia. Só quando uma borda não tem cópia é que uma requisição chega ao servidor de origem, uma vez, e depois disso cada visitante seguinte é servido localmente.\"> <rect x=\"20\" y=\"34\" width=\"180\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"110\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">um visitante em São Paulo</text> <path d=\"M206 56 L254 56\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path> <rect x=\"260\" y=\"34\" width=\"200\" height=\"44\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a borda em São Paulo</text> <text x=\"480\" y=\"56\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">responde em 8 ms</text> <rect x=\"20\" y=\"106\" width=\"180\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"110\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">um visitante em Lisboa</text> <path d=\"M206 128 L254 128\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path> <rect x=\"260\" y=\"106\" width=\"200\" height=\"44\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a borda em Lisboa</text> <text x=\"480\" y=\"128\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">responde em 6 ms</text> <rect x=\"260\" y=\"178\" width=\"200\" height=\"44\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">uma borda sem cópia</text> <path d=\"M466 200 L534 200\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path> <rect x=\"540\" y=\"178\" width=\"160\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect> <text x=\"620\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">seu único servidor</text> <text x=\"360\" y=\"252\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a linha de baixo acontece uma vez por borda, e então para de acontecer</text> </svg>", "caption": "A distância deixa de importar para o que está em cache, e seu servidor deixa de ouvir falar da maior parte do tráfego."}
```

Um visitante em São Paulo pergunta à borda de São Paulo. Se ela tem o arquivo, responde em alguns
milissegundos e o seu servidor nem fica sabendo da requisição. Se não tem, busca do seu servidor uma
vez, guarda uma cópia, e cada visitante depois disso é servido localmente.

Duas coisas seguem daí, e a segunda é a que as pessoas subutilizam. A distância deixa de importar para
qualquer coisa em cache. E a carga do seu servidor cai para o que as bordas não conseguiram responder,
que para um site de arquivos é quase nada.

## O que ela consegue e o que não consegue deixar mais rápido

Seja preciso aqui, porque é onde se desperdiça dinheiro.

**Coisas em cache ficam dramaticamente mais rápidas** — imagens, folhas de estilo, scripts, fontes, e
qualquer página que seja a mesma para todo mundo. A ida e volta encolhe de duzentos milissegundos para
dez.

**Coisas fora do cache ficam um pouco mais lentas.** Uma requisição que a borda não consegue responder
ainda viaja até o seu servidor, agora com um salto a mais no meio. Um painel personalizado, um resultado
de busca, um envio de formulário — nenhum deles é ajudado, e uma rede mal configurada acrescenta alguns
milissegundos a cada um.

**O seu servidor ser lento fica intocado.** Se uma página leva dois segundos para ser montada, ela leva
dois segundos para ser montada na frente de uma borda também. Este é o mal-entendido que vende mais
assinaturas: uma CDN aproxima as coisas, e não tem opinião sobre quanto tempo você leva para produzi-las.

O instinto para levar: **uma CDN conserta distância, não velocidade.** A aula três separou esses dois
números, e esta é a ferramenta para um deles.

## O que é seguro pôr lá

A regra vem da aula sete, e errar nela é um vazamento em vez de uma lentidão.

Qualquer coisa **pública e idêntica para todo mundo** pertence à borda, guardada pelo tempo que o nome
dela permitir — que é onde nomes com hash se pagam, porque um arquivo com impressão digital pode ficar
um ano em máquinas que você não controla.

Qualquer coisa **pessoal é `private`**, e a borda precisa ser avisada de não guardá-la. Um cache
compartilhado com a página de um visitante e entregando ao próximo é exatamente a falha da leitura sobre
cache, agora distribuída por cem países.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Arquivos públicos e páginas idênticas para todo mundo pertencem à borda, guardados por bastante tempo. Qualquer coisa pessoal precisa ser marcada como privada, porque um cache compartilhado entregando a página de um visitante ao próximo agora está distribuído pelo mundo.\"> <text x=\"180\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">guarde na borda</text> <rect x=\"20\" y=\"36\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">arquivos com impressão digital no nome</text> <rect x=\"20\" y=\"82\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">imagens, fontes, folhas de estilo</text> <rect x=\"20\" y=\"128\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">páginas idênticas para todo mundo</text> <text x=\"540\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">marque como private</text> <rect x=\"380\" y=\"36\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"540\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">qualquer coisa atrás de um login</text> <rect x=\"380\" y=\"82\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"540\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">um carrinho, um pedido, um saldo</text> <rect x=\"380\" y=\"128\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"540\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">qualquer coisa com um nome nela</text> <text x=\"360\" y=\"204\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a falha da aula sete, agora distribuída por cem países</text> <text x=\"360\" y=\"232\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">decida por rota, quando a rota é escrita, e não durante um incidente</text> </svg>", "caption": "Um cabeçalho decide em qual coluna uma resposta está, e uma das duas colunas é um vazamento."}
```

O cabeçalho que os separa é o daquela leitura, e o hábito prático é decidir por rota em vez de
globalmente: arquivos e páginas públicas guardados na borda, qualquer coisa atrás de um login marcada
como `private`, e a decisão tomada quando a rota é escrita em vez de durante um incidente.

## As outras coisas que ela faz

Vale conhecer, porque é por isso que a maioria dos sites acaba atrás de uma mesmo quando distância não é
o problema deles.

**Ela absorve ataques.** Uma enxurrada mirada no seu site atinge algumas centenas de máquinas de
capacidade enorme em vez do seu único servidor, e os provedores filtram os tipos óbvios sem que se peça.

**Ela termina a criptografia na borda**, que é a próxima leitura, e é também por que ela tem um
certificado do seu nome.

**Ela sobrevive ao seu servidor cair**, se você pedir — servindo o que tem em vez de um erro, que é o
`stale-if-error` da aula sete numa escala bem maior.

**Ela custa menos que a banda da sua própria máquina**, em geral, o que surpreende quem espera que a
conveniência seja a parte cara.

## De onde vêm as cópias, e a palavra que as pessoas erram

Dois mecanismos, e eles são confundidos com frequência.

**Pull** é o arranjo comum, e é o que a figura acima descreve: a borda busca da sua origem na primeira
vez que alguém pede, e guarda a resposta. Você não muda nada em como publica.

**Push** quer dizer que você envia para a rede você mesmo e a origem nunca é consultada. É usado onde os
arquivos são grandes e previsíveis — bibliotecas de vídeo, downloads de software — e transforma publicar
num passo do seu build.

A palavra com que se deve ter cuidado é **origem**. Ela quer dizer o seu próprio servidor, a coisa atrás
das bordas, e aparece nas configurações de todo provedor e em toda explicação de por que algo está velho.
Ficar confortável com ela agora poupa ler três parágrafos duas vezes mais tarde.

## Com o que ela não ajuda em nada

Um parágrafo honesto, porque uma CDN é vendida como produto geral de desempenho e não é um.

Ela não faz nada por uma consulta lenta ao banco. Não faz nada por uma página que carrega quatro
megabytes de script. Não faz nada por uma requisição que precisa ser personalizada. E não faz nada pela
primeira visita a um nome cujo DNS é lento, que a aula anterior cobriu e que fica inteiramente na frente
disto.

Ponha ao lado da aula três: uma CDN ataca a **latência** para coisas em cache, e deixa **o tempo que o
seu servidor leva** exatamente onde estava. São números separados, e nenhuma quantidade do primeiro
conserta o segundo.

## Os dois jeitos de dar errado

Os dois são comuns e os dois são reconhecíveis.

**Guardar algo pessoal**, discutido acima, que é o grave.

**Não conseguir enxergar além dela.** Quando uma página está errada, a pergunta *meu servidor está
errado ou a borda está com algo velho?* é a mesma pergunta do DNS da aula passada, e tem a mesma
resposta: pergunte direto à origem, contornando a borda. Todo provedor oferece um jeito; descubra qual é
no dia em que configurar, e não no dia em que precisar.

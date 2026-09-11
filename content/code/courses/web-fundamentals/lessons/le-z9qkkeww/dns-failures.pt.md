---
title: Quando o nome é o problema
version: 1
---

*É sempre o DNS* é uma piada com alta taxa de acerto, e a razão é estrutural: a resolução de nomes
acontece antes de tudo, então quando ela falha o sintoma parece que o que vinha depois falhou. Um
site que não carrega, uma entrega de e-mail que volta, uma chamada de interface que esgota o tempo.

Esta leitura é sobre distinguir, rápido, e é em boa parte sobre aprender quatro respostas.

## As quatro respostas, e o que cada uma quer dizer

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Quatro respostas possíveis a uma consulta e o que cada uma quer dizer: o nome não existe, o nome existe sem registro daquele tipo, algo quebrou no caminho, e nada respondeu.\"> <rect x=\"20\" y=\"32\" width=\"680\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"120\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">NXDOMAIN</text> <text x=\"250\" y=\"50\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o nome não existe, e algo autoritativo disse isso</text> <text x=\"250\" y=\"70\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">um erro de digitação, um registro ainda não criado, um domínio vencido</text> <rect x=\"20\" y=\"92\" width=\"680\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"120\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">NOERROR, vazio</text> <text x=\"250\" y=\"110\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o nome existe e não tem registro daquele tipo</text> <text x=\"250\" y=\"130\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o confuso: parece uma resposta e não tem nada</text> <rect x=\"20\" y=\"152\" width=\"680\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"120\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">SERVFAIL</text> <text x=\"250\" y=\"170\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">algo quebrou no caminho, ou a resposta não foi crida</text> <text x=\"250\" y=\"190\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o que falha em alguns resolvedores e não em outros</text> <rect x=\"20\" y=\"212\" width=\"680\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"120\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">um tempo esgotado</text> <text x=\"250\" y=\"230\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">nada respondeu</text> <text x=\"250\" y=\"250\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">em geral o seu resolvedor, e não o domínio</text> </svg>", "caption": "Ler qual destas quatro voltou é quase todo o diagnóstico, e toda ferramenta imprime isso."}
```

**`NXDOMAIN`** — o nome não existe. Alguém autoritativo para essa parte da árvore disse isso. Erros
de digitação produzem isso; um registro que você ainda não criou também; um domínio que venceu semana
passada também.

**`NOERROR` sem nada dentro** — o nome existe, e não tem registro do tipo que você pediu. Esta é a
que confunde as pessoas, porque parece uma resposta e não contém nada. É o que você recebe pedindo
`AAAA` num nome que só tem `A`, ou um `MX` num domínio que não recebe e-mail.

**`SERVFAIL`** — algo quebrou no caminho. Os servidores autoritativos estavam inalcançáveis, ou
responderam algo que o resolvedor se recusou a acreditar. Esta é a que falha para umas pessoas e não
para outras, porque depende de qual resolvedor você usa e de quão rigoroso ele é.

**Um tempo esgotado** — nada respondeu. Em geral o seu resolvedor e não o domínio: a rede, o
roteador, ou a porta 53 bloqueada em algum ponto entre você e ele.

Ler a resposta é quase todo o diagnóstico, e todas as ferramentas a imprimem.

## É DNS mesmo?

Três perguntas, em ordem, e cada uma leva segundos.

**O nome resolve?** Pergunte direto com `dig`, `nslookup` ou `host`. Se você recebe um endereço, o
DNS fez o trabalho dele e o problema está em algum lugar do resto deste curso.

**Resolve para a coisa certa?** Um endereço velho não é uma falha de DNS; é um cache segurando algo
que você mudou, e a leitura anterior diz por quanto tempo.

**Resolve para outras pessoas?** Um resolvedor público que você normalmente não usa é a segunda
opinião mais rápida que existe. A mesma resposta quer dizer que a falha é compartilhada; respostas
diferentes querem dizer que você está olhando para cache, para uma filtragem do resolvedor, ou para
algo que os cronômetros da leitura anterior explicam.

## O movimento que resolve a maioria das discussões

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Perguntar a um resolvedor diz no que o mundo acredita agora; perguntar direto ao servidor autoritativo diz o que você publicou. A diferença separa uma mudança errada de uma mudança que ainda não está no ar.\"> <rect x=\"20\" y=\"34\" width=\"320\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">pergunte a um resolvedor</text> <rect x=\"20\" y=\"88\" width=\"320\" height=\"46\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"180\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">no que o mundo acredita agora</text> <rect x=\"380\" y=\"34\" width=\"320\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"540\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">dig @ns1.provider.net nome</text> <rect x=\"380\" y=\"88\" width=\"320\" height=\"46\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o que você de fato publicou</text> <rect x=\"20\" y=\"156\" width=\"330\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect> <text x=\"185\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">certo à direita, velho à esquerda:</text> <text x=\"185\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">você está esperando um TTL</text> <rect x=\"370\" y=\"156\" width=\"330\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect> <text x=\"535\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">errado à direita:</text> <text x=\"535\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">esperar não vai ajudar</text> <text x=\"360\" y=\"246\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">um comando, e ele separa as duas perguntas que as pessoas vivem confundindo</text> </svg>", "caption": "Um cache diz o que se acredita. O servidor autoritativo diz o que é verdade."}
```

A resposta de um resolvedor diz no que o mundo acredita agora. A resposta do **servidor autoritativo**
diz o que você de fato publicou. Perguntar direto a ele pula todo cache entre você e a verdade.

```
dig @ns1.dnsprovider.net www.example.com
```

A diferença entre essas duas respostas separa as duas perguntas que as pessoas vivem confundindo:
*minha mudança está errada* e *minha mudança ainda não está no ar*. Se a resposta autoritativa está
certa e a do resolvedor está velha, você está esperando um TTL e não há o que consertar. Se a
resposta autoritativa está errada, esperar não vai ajudar.

Esse comando resolveu mais discussões que qualquer outro desta aula.

## As três falhas que respondem pela maior parte

**Uma mudança feita no provedor errado.** Depois de os `NS` terem sido apontados para outro lugar, o
painel antigo continua funcionando, continua mostrando seus registros, e é lido por ninguém. Tudo que
você faz ali parece dar certo. Confira quais servidores são autoritativos antes de editar qualquer
coisa.

**Um ponto final.** Em arquivos de registro, um nome terminado em ponto é completo, e um sem ponto
tem o domínio acrescentado ao fim. Escreva `mail.provider.net` sem o ponto e você criou um registro
apontando para `mail.provider.net.example.com`, que não existe. Lê-se corretamente num painel, e está
errado.

**Registros que nunca foram copiados.** Trocar de provedor de DNS move tudo de uma vez, e a vítima
habitual é o e-mail, porque os `MX` e os `TXT` moram no provedor antigo e quem fez a mudança estava
pensando no site.

## `SERVFAIL`, e a assinatura que quebra para metade do mundo

Merece uma seção porque o sintoma é muito distinto.

Existe uma extensão — o `DNSSEC` — que assina respostas de DNS, para que um resolvedor consiga dizer
se o que recebeu é o que o domínio publicou. Ela fecha um ataque real: sem ela, uma resposta é um
pacotinho não autenticado que qualquer um em posição de forjar um pode substituir.

O jeito como ela falha é o que importa aqui. Quando as assinaturas de um domínio estão erradas —
vencidas, ou uma chave rotacionada sem o nível acima ser atualizado — um resolvedor que **valida**
recusa a resposta e devolve `SERVFAIL`, enquanto um resolvedor que não valida responde tranquilo.

Então o site está fora para quem usa um resolvedor e perfeitamente bem para quem usa outro, sem
padrão geográfico. Isso é quase uma assinatura da falha, e é o caso em que a pergunta *funciona por
outro resolvedor?* dá o diagnóstico em vez de uma segunda opinião.

## Duas pistas falsas

Um arquivo na sua própria máquina — o `hosts` — mapeia nomes para endereços antes de o DNS ser
consultado. Ele é genuinamente útil para testes, e é a razão da tarde ocasional passada depurando um
nome que resolve corretamente para todo mundo menos para quem está investigando. Se a sua máquina
discorda do mundo, olhe ali primeiro.

E o cache do próprio navegador guarda nomes pelas razões dele, no ritmo dele, ignorando o seu TTL. Um
nome que está corrigido em todo lugar e errado numa aba do navegador em geral é isso, e reiniciar o
navegador é um teste mais rápido do que acreditar nele.

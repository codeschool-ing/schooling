---
title: Em outro lugar, e por quanto tempo
version: 1
---

Uma resposta `3xx` é um servidor dizendo *aqui não — lá*. Ela leva um cabeçalho `Location` com o
endereço novo, e o navegador vai, em geral sem mostrar a ninguém que isso aconteceu.

Isso é simples. A parte que merece uma seção é que há vários desses códigos, eles diferem de formas
que não aparecem enquanto você testa, e um deles é quase irreversível.

## Permanente, temporário, e quem tem permissão de lembrar

| código | por quanto tempo | o que acontece com o método |
|---|---|---|
| `301` | permanente | historicamente virava um `GET` |
| `302` | temporário | historicamente virava um `GET` |
| `303` | veja esta outra coisa | deliberadamente vira um `GET` |
| `307` | temporário | mantido como estava |
| `308` | permanente | mantido como estava |

Dois eixos, e os dois são sobre o que outra pessoa pode agora supor.

**Permanente ou temporário** decide quem pode lembrar. Um `302` é uma instrução para esta
requisição: pergunte de novo da próxima vez e você pode ser mandado a outro lugar. Um `301` é uma
afirmação sobre o mundo — *este endereço mudou* — e tudo que ouve isso tem direito de anotar. O
navegador anota. Caches anotam. Buscadores movem o índice e param de visitar o endereço antigo.

**O método** é o segundo eixo, e a história é feia. `301` e `302` foram especificados para manter o
método, os navegadores mudavam `POST` para `GET` assim mesmo, software demais passou a depender
desse comportamento para que ele pudesse ser corrigido, e `307` e `308` foram acrescentados para
significar *o que os outros dois deveriam significar*. Se um redirecionamento pode um dia receber
algo que não seja um `GET`, use esses.

O `303` é o esquisito que sempre vira um `GET`, de propósito, e resolve um incômodo real: depois de
um formulário ser enviado, responda `303` apontando para uma página de resultado, e o navegador
busca essa página com um `GET`. Agora o endereço na barra é uma página que dá para recarregar,
favoritar e compartilhar sem reenviar o formulário — e é por isso que uma loja que diz *não aperte
atualizar* é uma loja a que faltam três caracteres.

## O que é difícil de desfazer

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Depois de um redirect temporário o navegador pergunta de novo na próxima visita, então um erro dá para corrigir. Depois de um permanente o navegador vai direto ao endereço guardado sem perguntar, então não dá para alcançar o erro e corrigi-lo.\"> <text x=\"180\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">302, temporário</text> <rect x=\"20\" y=\"36\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">primeira visita: pergunta, é mandado adiante</text> <rect x=\"20\" y=\"90\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">próxima visita: pergunta de novo</text> <rect x=\"20\" y=\"144\" width=\"320\" height=\"62\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">então um redirect errado dá para corrigir</text> <text x=\"180\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">e a correção chega a todo mundo</text> <text x=\"540\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">301, permanente</text> <rect x=\"380\" y=\"36\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"540\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">primeira visita: pergunta, é mandado adiante</text> <rect x=\"380\" y=\"90\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".22\" stroke=\"var(--amber)\"></rect> <text x=\"540\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">próxima visita: nem pergunta</text> <rect x=\"380\" y=\"144\" width=\"320\" height=\"62\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".22\" stroke=\"var(--amber)\"></rect> <text x=\"540\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">então um redirect errado não dá para corrigir</text> <text x=\"540\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">para quem já o recebeu</text> <text x=\"360\" y=\"242\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">não dá para servir uma correção a um navegador que parou de perguntar</text> <text x=\"360\" y=\"272\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">então: publique como 302, confirme, e só aí faça 301</text> </svg>", "caption": "A diferença entre os dois não é quanto tempo a mudança dura. É quem tem permissão de anotá-la."}
```

Um `301` é guardado pelo navegador, e por muito tempo, em alguns navegadores até o perfil ser
limpo. A próxima visita ao endereço antigo não produz requisição nenhuma: o navegador já sabe, e vai
direto ao lugar novo.

Que é exatamente o que você queria, até o redirecionamento estar errado.

Publique um `301` mandando o site inteiro para um endereço que se revela quebrado, perceba em cinco
minutos e corrija — e todo visitante que o carregou nesses cinco minutos continua sendo mandado ao
endereço quebrado, pelo próprio navegador, sem que nenhuma requisição chegue a você para corrigir.
Não há nada que você possa servir a eles, porque eles não estão perguntando.

A regra que sai daí não custa nada: **publique um redirecionamento novo como `302`, e mude para
`301` quando tiver certeza.** Um redirecionamento temporário não é lembrado, então um erro dura o
tempo que o erro durar.

## Correntes, e quanto custam

Cada redirecionamento é uma ida e volta completa: uma requisição para fora, uma resposta de volta,
depois outra requisição. Numa conexão móvel com 120 ms de latência eles são visíveis.

E eles se acumulam sem ninguém decidir. Um site que migrou para HTTPS, depois para um nome `www`,
depois para um prefixo de idioma responde três redirecionamentos antes de servir uma página.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Quatro requisições em sequência antes de qualquer conteúdo ser servido: HTTP puro redireciona para HTTPS, que redireciona para o nome www, que redireciona para o prefixo de idioma, que enfim responde com a página.\"> <rect x=\"20\" y=\"30\" width=\"470\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect> <text x=\"34\" y=\"49\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">http://example.com/</text> <text x=\"506\" y=\"49\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">301 — uma ida e volta</text> <rect x=\"20\" y=\"78\" width=\"470\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect> <text x=\"34\" y=\"97\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">https://example.com/</text> <text x=\"506\" y=\"97\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">301 — duas</text> <rect x=\"20\" y=\"126\" width=\"470\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect> <text x=\"34\" y=\"145\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">https://www.example.com/</text> <text x=\"506\" y=\"145\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">302 — três</text> <rect x=\"20\" y=\"174\" width=\"470\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"34\" y=\"193\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">https://www.example.com/pt/</text> <text x=\"506\" y=\"193\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">200 — a página</text> <text x=\"360\" y=\"242\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">num link móvel de 120 ms, isso é um terço de segundo gasto só para chegar</text> <text x=\"360\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">a correção é responder à primeira requisição com o último endereço, não apagar as regras</text> </svg>", "caption": "Cada salto foi alguém sendo razoável num dia diferente. O visitante paga por todos de uma vez."}
```

Três idas e voltas antes do primeiro byte de conteúdo. Cada uma era razoável no dia em que foi
acrescentada, e ninguém as acrescentou ao mesmo tempo — que é o formato da maioria dessas coisas:
nenhuma decisão isolada estava errada, e o total está.

A correção não é remover — cada uma está fazendo um trabalho — mas colapsar, para que o primeiro
servidor responda com o endereço final de uma vez. Digitar um endereço à mão e observar a corrente é
uma checagem de cinco minutos que a maioria dos sites nunca teve feita.

## Redirecionamentos que você não escreveu

Uma última coisa que vale conhecer, porque é onde moram as surpresas: várias camadas entre o
visitante e o seu código podem emitir um, e o código que você está lendo nunca o menciona.

O servidor web pode estar configurado para forçar HTTPS. Um framework pode acrescentar ou remover
uma barra final para que `/precos` e `/precos/` não virem dois endereços. Uma CDN na frente de tudo
pode mandar visitantes a uma borda regional. Cada um é uma linha num arquivo que outra pessoa
mantém.

Então quando uma corrente está mais longa do que devia, o movimento útil não é ler a aplicação. É
pedir cada endereço um a um e olhar o que responde — que é um `curl -I` ou dois, e resolve em um
minuto uma discussão que de outro jeito dura uma semana.

Uma corrente também pode fechar num círculo: A manda você para B, B manda você de volta para A.
Navegadores param depois de um tempo e mostram *redirecionamentos demais*, que é uma mensagem sobre
um laço em vez de sobre um número. São quase sempre duas regras cada uma correta e que discordam —
uma forçando o `www` a aparecer, outra forçando a sumir.

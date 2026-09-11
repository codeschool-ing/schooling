---
title: O outro arranjo, e quanto ele custa
version: 1
---

A consulta do fim da leitura anterior é um custo real: cada requisição, em cada serviço, pergunta a
um repositório compartilhado quem é esta pessoa. Então há um segundo arranjo em uso amplo, e ele
remove a consulta movendo a informação para dentro da própria credencial.

## Uma afirmação que carrega a própria prova

Em vez de um identificador opaco, o navegador guarda um **token** contendo os fatos — quem é esta
pessoa, o que ela pode fazer, quando isso deixa de valer — seguidos de uma assinatura feita com uma
chave que só o servidor tem.

O servidor verifica a assinatura e acredita no conteúdo. Sem tabela, sem consulta, sem nada
compartilhado. Qualquer serviço com a chave consegue conferir, e é por isso que este arranjo se
espalhou com sistemas feitos de muitos serviços pequenos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Um identificador de sessão é conferido contra uma tabela, então apagar a linha o revoga na hora. Um token é conferido contra uma assinatura, então não há o que apagar e ele segue válido até expirar.\"> <text x=\"180\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">um identificador de sessão</text> <rect x=\"20\" y=\"36\" width=\"320\" height=\"42\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">conferido contra uma tabela</text> <rect x=\"20\" y=\"88\" width=\"320\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">custa uma consulta por requisição</text> <rect x=\"20\" y=\"140\" width=\"320\" height=\"42\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">apague a linha e acaba na hora</text> <text x=\"540\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">um token assinado</text> <rect x=\"380\" y=\"36\" width=\"320\" height=\"42\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"540\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">conferido contra uma assinatura</text> <rect x=\"380\" y=\"88\" width=\"320\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"540\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">não custa consulta nem repositório</text> <rect x=\"380\" y=\"140\" width=\"320\" height=\"42\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".3\" stroke=\"var(--amber)\"></rect> <text x=\"540\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">nada a apagar: válido até expirar</text> <text x=\"360\" y=\"220\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a mesma propriedade é a vantagem e o problema</text> <text x=\"360\" y=\"248\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">é por isso que existem validades curtas, e por que o refresh traz a tabela de volta</text> </svg>", "caption": "Não é velho e novo. Um deles dá para retirar e o outro não, e todo o resto vem daí."}
```

Duas coisas sobre isso são comumente mal entendidas, e as duas importam.

**Assinado não é cifrado.** O conteúdo é legível por quem tiver o token, em geral depois de um passo
de decodificação que não precisa de chave nenhuma. A assinatura impede que ele seja *alterado*, não
que seja lido. Então nada entra num token que você não escreveria num cartão-postal.

**Nada o confere contra a realidade.** O servidor acredita no token porque a assinatura é válida, e
a assinatura era válida no momento em que foi feita. O que leva direto ao problema.

## Você não consegue retirá-lo

Um identificador de sessão é conferido contra uma tabela, então apagar a linha encerra tudo em todo
lugar, dentro de um segundo.

Um token é conferido contra uma assinatura, então não há o que apagar. Se o acesso de alguém é
retirado — a pessoa saiu da empresa, a conta foi comprometida, a assinatura acabou — o token dela
segue funcionando até expirar, porque todo servidor que o vê chega à mesma conclusão a que chegou
ontem.

A resposta habitual são validades curtas: um token bom por quinze minutos, mais um **token de
refresh** de vida mais longa usado para obter um novo. Revogar então quer dizer recusar o refresh, e
o pior caso são quinze minutos de acesso que você queria interromper.

Repare no que isso custa. O token de refresh tem que ser conferido contra algo que possa ser
revogado — que é uma tabela, num repositório compartilhado, consultada a cada refresh. A consulta
voltou. Ela é simplesmente consultada com menos frequência, o que é uma melhoria real e não a coisa
que foi vendida.

## O que um deles de fato parece

Vale ver uma vez, porque desmistifica a coisa e torna o aviso acima concreto.

O formato comum são três pedaços separados por pontos: uma pequena descrição de como foi assinado,
as afirmações em si, e a assinatura. Os dois primeiros são texto comum, codificado de um jeito que
sobrevive a ser posto num cabeçalho — uma codificação, não uma cifra. Cole um em qualquer dos sites
que os decodificam e você vai ler o id de usuário de alguém, o papel dela e um horário de expiração,
sem chave e sem permissão.

Esse é o cartão-postal, visto. É também por que *o token é criptografado* é uma das coisas mais
perigosas que um time pode acreditar sobre o próprio sistema.

## O erro que o formato tornou possível

Mais uma coisa, porque é a melhor ilustração de por que um servidor nunca deve aceitar instruções da
credencial que está conferindo.

Aquele primeiro pedaço — a descrição de como foi assinado — faz parte do token, e portanto faz parte
do que quem envia controla. Bibliotecas antigas liam e usavam o que ele nomeasse. Alguém reparou que
um dos valores permitidos queria dizer *não assinado de jeito nenhum*, escreveu um token alegando ser
administrador, disse que não estava assinado, e foi acreditado.

A correção se enuncia como uma regra que vale além de tokens: **quem verifica decide o algoritmo.** O
que chega pode ser conferido contra o que se esperava; nunca pode ter permissão de escolher.

## Onde guardar

Esta é a decisão que de fato chega ao código, e costuma ser tomada copiando um tutorial.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Uma credencial guardada num cookie com HttpOnly é ilegível para scripts e precisa de SameSite contra falsificação. Uma credencial guardada no armazenamento local é legível por todo script da página e não tem equivalente de HttpOnly.\"> <text x=\"180\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">num cookie</text> <rect x=\"20\" y=\"36\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">HttpOnly: nenhum script o lê</text> <rect x=\"20\" y=\"86\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">SameSite: requisição forjada não o leva</text> <rect x=\"20\" y=\"136\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o navegador o anexa por você</text> <text x=\"540\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">no armazenamento local</text> <rect x=\"380\" y=\"36\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".28\" stroke=\"var(--amber)\"></rect> <text x=\"540\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">não existe HttpOnly para ele</text> <rect x=\"380\" y=\"86\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".28\" stroke=\"var(--amber)\"></rect> <text x=\"540\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">todo script da página o lê</text> <rect x=\"380\" y=\"136\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"540\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">seu código o anexa na mão</text> <text x=\"360\" y=\"216\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o argumento antigo a favor da direita era a falsificação de requisição</text> <text x=\"360\" y=\"242\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">o SameSite respondeu isso, e nada responde a linha acima dele</text> </svg>", "caption": "A escolha não é onde fica mais organizado guardar. É a qual ataque você está escolhendo se expor."}
```

**Num cookie**, com `HttpOnly`, `Secure` e `SameSite`. O navegador o anexa, nenhum script o lê, e os
atributos de duas leituras atrás valem exatamente como antes.

**No armazenamento local**, lido pelo código da própria página e anexado à mão em cada requisição.
Este é o arranjo que a maioria dos tutoriais mostra, e tem uma propriedade que vale dizer com
clareza: **não existe `HttpOnly` para o armazenamento local.** Todo script rodando na página lê tudo
que está ali. O ataque de script entre sites da leitura de atributos — aquele que o `HttpOnly` foi
inventado para responder — funciona de novo, por inteiro.

A troca que as pessoas descrevem é *cookies são vulneráveis a falsificação de requisição,
armazenamento local não*, e isso era verdade antes de o `SameSite` existir. Hoje o resumo honesto é
mais estreito: um cookie com os três atributos definidos é o padrão mais seguro, e o armazenamento
local é uma escolha que você faz quando algo da sua arquitetura exige, sabendo do que abre mão.

## Escolhendo entre os dois arranjos

Nenhum é o moderno e nenhum é o antigo; eles respondem perguntas diferentes.

Sessões quando você precisa encerrar acesso na hora, quando tudo é uma aplicação só, e quando uma
consulta por requisição é acessível — o que, para a maioria dos sites, é.

Tokens quando muitos serviços precisam conferir a mesma credencial sem dividir um repositório, quando
o custo desse repositório é real, e quando você consegue conviver com a revogação atrasada por um
tempo conhecido.

E a nota honesta para terminar: um bocado de sistemas usa tokens porque tokens era o que o tutorial
usava, descobre depois que não consegue desconectar ninguém, e acrescenta uma tabela para corrigir.
Escolher de propósito é quase todo o valor de conhecer os dois.

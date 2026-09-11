---
title: Seis tipos de registro, e o que cada um responde
version: 1
---

Os servidores autoritativos do fim da leitura anterior guardam um conjunto de **registros** do
domínio. Cada registro é um nome, um tipo e um valor, e o tipo decide qual pergunta ele responde.

Há dezenas. Seis carregam quase todo o trabalho.

| tipo | responde | valor |
|---|---|---|
| `A` | qual endereço IPv4? | `203.0.113.7` |
| `AAAA` | qual endereço IPv6? | `2001:db8::7` |
| `CNAME` | sobre qual outro nome eu deveria perguntar? | `alvo.example.net` |
| `MX` | para onde vai o e-mail deste domínio? | uma prioridade e um nome |
| `TXT` | texto livre, para quem quiser | qualquer string |
| `NS` | quais servidores são autoritativos aqui? | um nome |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Um conjunto de registros de um domínio: dois registros de endereço, um apelido para a documentação, registros de e-mail com prioridades, um registro de texto para verificação, e os registros de servidor de nomes que são a própria delegação.\"> <rect x=\"20\" y=\"30\" width=\"680\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"34\" y=\"47\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">example.com. A 203.0.113.7</text> <text x=\"470\" y=\"47\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">o site, em IPv4</text> <rect x=\"20\" y=\"70\" width=\"680\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"34\" y=\"87\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">example.com. AAAA 2001:db8::7</text> <text x=\"470\" y=\"87\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">o mesmo site, em IPv6</text> <rect x=\"20\" y=\"110\" width=\"680\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"34\" y=\"127\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">docs.example.com. CNAME pages.provider.net.</text> <text x=\"470\" y=\"127\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">vá perguntar sobre aquele</text> <rect x=\"20\" y=\"150\" width=\"680\" height=\"34\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"34\" y=\"167\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">example.com. MX 10 mail1.provider.net.</text> <text x=\"470\" y=\"167\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">número menor, tentado antes</text> <rect x=\"20\" y=\"190\" width=\"680\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"34\" y=\"207\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">example.com. TXT \"v=spf1 include:provider.net ~all\"</text> <text x=\"560\" y=\"207\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">quem pode enviar</text> <rect x=\"20\" y=\"230\" width=\"680\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\"></rect> <text x=\"34\" y=\"247\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">example.com. NS ns1.dnsprovider.net.</text> <text x=\"470\" y=\"247\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a própria delegação</text> <text x=\"360\" y=\"282\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">um domínio, seis linhas, cinco destinos diferentes — e nenhum deles é um servidor seu</text> </svg>", "caption": "Um nome, um tipo e um valor. O tipo é tudo que decide qual pergunta ele responde."}
```

## Os dois registros de endereço

O `A` dá um endereço IPv4; o `AAAA` dá um IPv6. O nome não é abreviação de nada interessante — um
endereço IPv6 tem quatro vezes o tamanho de um IPv4, então quatro `A`.

Um nome pode ter os dois, e deveria. Um nome também pode ter vários de cada, e um resolvedor os
entrega em ordem variável, que é a forma mais antiga e mais rudimentar de espalhar tráfego por várias
máquinas. Ela não faz ideia se alguma delas está viva, e é por isso que é um jeito de dividir carga e
não um jeito de sobreviver a uma falha.

## `CNAME`, e as duas regras que pegam todo mundo

Um `CNAME` diz *este nome é outro nome para aquele; vá perguntar de novo*. É como você aponta para
algo cujo endereço você não controla e que pode mudar sem avisar — um provedor de hospedagem, uma
CDN, um serviço de documentação.

Duas regras, e as duas produzem falhas confusas.

**Um nome com `CNAME` não pode ter nenhum outro registro.** Nem `MX`, nem `TXT`, nada. O apelido
substitui o nome inteiro, então qualquer outra coisa naquele nome é ignorada ou recusada conforme a
quem você perguntar.

**O domínio puro não pode ter um**, porque o domínio puro precisa levar registros `NS` e — pela regra
acima — um `CNAME` não pode ficar ao lado deles.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Um CNAME não pode ficar no domínio puro, porque o domínio puro precisa levar os registros de servidor de nomes e um CNAME não divide um nome com nada. Num subdomínio, tudo bem.\"> <text x=\"180\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">no domínio puro</text> <rect x=\"20\" y=\"36\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">example.com. NS ns1...</text> <rect x=\"20\" y=\"82\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".24\" stroke=\"var(--amber)\"></rect> <text x=\"180\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">example.com. CNAME ...</text> <rect x=\"20\" y=\"128\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".3\" stroke=\"var(--amber)\"></rect> <text x=\"180\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">recusado: um apelido não divide com nada</text> <text x=\"540\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">num subdomínio</text> <rect x=\"380\" y=\"36\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"540\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">docs.example.com. CNAME ...</text> <rect x=\"380\" y=\"82\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">não há mais nada naquele nome</text> <rect x=\"380\" y=\"128\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">aceito, e é o jeito habitual</text> <text x=\"360\" y=\"200\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">é por isso que tanta documentação de hospedagem insiste discretamente no www</text> <text x=\"360\" y=\"226\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">e por que provedores inventaram ALIAS e achatamento, que são deles e não do padrão</text> </svg>", "caption": "Duas regras com uma consequência: o domínio puro é o único nome que você não consegue apontar para um nome."}
```

Essa segunda regra é a razão de tanta documentação de hospedagem pedir que você use `www`. É também
por que provedores inventaram tipos de registro fora do padrão — `ALIAS`, `ANAME`, ou um recurso
chamado achatamento — que se comportam como um `CNAME` no domínio puro resolvendo o alvo eles mesmos
e respondendo com um endereço. Funcionam, não fazem parte da especificação, e só existem onde o seu
provedor de DNS os oferece.

## `MX`, para onde vai o e-mail

O e-mail não usa os registros de endereço. Uma mensagem para `voce@example.com` é entregue
consultando os registros `MX` de `example.com`.

```
example.com.  MX  10 mail1.provider.net.
example.com.  MX  20 mail2.provider.net.
```

O número é uma prioridade, e **menor é preferido**. Quem envia tenta o 10 primeiro e cai para o 20,
que é como um servidor de e-mail reserva é expresso.

Dois erros são comuns o bastante para nomear. Um `MX` nomeia um **servidor, não um endereço** — pôr
um endereço ali falha. E o nome para o qual ele aponta não pode ele mesmo ser um `CNAME`, uma regra
que as pessoas quebram justamente porque um `CNAME` parece o jeito organizado de fazer.

## `TXT`, que virou o que mais importa

O `TXT` era um lugar para pôr um recado. Virou o mecanismo de uso geral para provar que você controla
um domínio e para dizer coisas sobre o seu e-mail.

Tudo que pede para você *verificar seu domínio* — uma autoridade certificadora, um provedor de
e-mail, um serviço de analytics — faz isso mandando você publicar uma string que eles deram.
Publicá-la prova que você controla os registros, o que prova que você controla o domínio.

E três arranjos que decidem se o seu e-mail é acreditado moram todos aqui:

**SPF** lista os servidores autorizados a enviar e-mail alegando ser de você. **DKIM** publica uma
chave que assina suas mensagens de saída, para quem recebe conferir que não foram alteradas.
**DMARC** diz o que quem recebe deve fazer quando uma mensagem falha nos dois primeiros, e para onde
mandar um relatório sobre isso.

Eles merecem uma aula própria e ganham a linha aqui por um motivo: **um domínio sem nada nesses
registros é um domínio do qual qualquer um consegue mandar e-mail.** É a configuração vazia mais
consequente desta aula inteira.

## `NS`, que é a própria delegação

Os registros `NS` nomeiam os servidores autoritativos deste domínio. São a coisa que os servidores de
TLD devolvem durante a caminhada, e mudá-los é o que *trocar os servidores de nomes* quer dizer num
painel.

É também a única mudança desta aula que move tudo de uma vez: aponte seus `NS` para um provedor de
DNS novo e todos os seus registros passam a ser o que estiver na conta daquele provedor, inclusive
registros que não estão lá. A falha habitual é o e-mail parar, porque os `MX` estavam no provedor
antigo e ninguém os copiou.

## Mais três que vale reconhecer

Não é tudo, e estes aparecem com frequência suficiente para um olhar vazio custar caro.

`CAA` nomeia quais autoridades certificadoras podem emitir certificados para o seu domínio. Ele fecha
um buraco real no cadeado da aula seis: sem ele, qualquer autoridade da lista do navegador pode
emitir para o seu nome.

`SRV` dá um serviço, um protocolo, uma prioridade, um peso, uma porta e um host. É a resposta geral
para *onde mora este serviço*, e você o encontra em sistemas de chat e em ferramentas internas mais
do que na web pública.

`PTR` mapeia um endereço de volta a um nome — a consulta reversa. Você raramente define um, e um
servidor de e-mail sem nome reverso é um servidor de e-mail cujas mensagens são arquivadas como spam,
que é como a maioria das pessoas ouve falar dele pela primeira vez.

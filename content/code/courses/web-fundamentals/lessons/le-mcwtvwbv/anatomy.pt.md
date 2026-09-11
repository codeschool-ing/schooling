---
title: Uma requisição é um pedaço de texto
version: 1
---

Aqui está tudo que seu navegador enviou para pedir uma página. Não um resumo — estes são os
caracteres que desceram a pilha, passaram pelos envelopes da aula anterior e foram para o fio.

```
GET /courses/web-fundamentals HTTP/1.1
Host: codeschool.ing
User-Agent: Mozilla/5.0 (X11; Linux x86_64)
Accept: text/html,application/xhtml+xml
Accept-Language: pt-BR,pt;q=0.9,en;q=0.8
Connection: keep-alive

```

Essa é a requisição inteira. É texto puro, tem quatro partes, e uma delas é invisível.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Uma requisição dividida em suas quatro partes: uma linha inicial com o método, o caminho e a versão; várias linhas de cabeçalho; uma linha em branco que marca o fim dos cabeçalhos; e um corpo, ausente nesta requisição.\"> <rect x=\"20\" y=\"30\" width=\"470\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"34\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">GET /courses/web-fundamentals HTTP/1.1</text> <text x=\"510\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">a linha inicial — uma, sempre</text> <rect x=\"20\" y=\"72\" width=\"470\" height=\"86\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"34\" y=\"90\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">Host: codeschool.ing</text> <text x=\"34\" y=\"112\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">User-Agent: Mozilla/5.0 (X11; Linux x86_64)</text> <text x=\"34\" y=\"134\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">Accept-Language: pt-BR,pt;q=0.9</text> <text x=\"510\" y=\"112\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">cabeçalhos — quantos quiser</text> <rect x=\"20\" y=\"166\" width=\"470\" height=\"26\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"510\" y=\"179\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">linha vazia — fim dos cabeçalhos</text> <rect x=\"20\" y=\"200\" width=\"470\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-dasharray=\"4 3\"></rect> <text x=\"255\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">o corpo, e um GET não tem</text> <text x=\"510\" y=\"220\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">presente em POST, PUT, PATCH</text> <text x=\"360\" y=\"262\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">uma resposta tem as mesmas quatro partes, com um número onde estava o método</text> </svg>", "caption": "Quatro partes, e a que mais trabalha é a que você não vê."}
```

## As quatro partes

A **linha inicial** é uma linha com três coisas: o que você quer que seja feito (`GET`), em que
você quer que seja feito (`/courses/web-fundamentals`) e qual versão do protocolo você está falando
(`HTTP/1.1`). Nada mais nessa linha, nunca.

Os **cabeçalhos** são linhas de `Nome: valor`, uma por linha, em nenhuma ordem particular. Eles
descrevem a requisição em vez de serem ela: quem está pedindo, o que aceita receber, qual o tamanho
do corpo. Os nomes não se importam com maiúsculas — `host`, `Host` e `HOST` são o mesmo cabeçalho —
porque softwares diferentes os escreveram de jeitos diferentes por trinta anos.

A **linha em branco** é a terceira parte, e ela faz trabalho de verdade. É como a outra ponta sabe
que os cabeçalhos acabaram e que o que vier é conteúdo. Tire-a e o servidor fica esperando um
cabeçalho que não vem.

O **corpo** é a quarta parte, e esta requisição não tem um. Um `GET` pede algo e não tem nada a
enviar. O envio de um formulário traria os campos dele aqui embaixo, depois da linha em branco.

## A resposta tem o mesmo formato

```
HTTP/1.1 200 OK
Content-Type: text/html; charset=utf-8
Content-Length: 5218
Date: Tue, 16 Sep 2025 09:41:02 GMT

<!doctype html><html lang="pt-BR">...
```

Linha inicial, cabeçalhos, linha em branco, corpo — as mesmas quatro partes, com a primeira linha
carregando coisas diferentes: a versão, um número de três dígitos e uma ou duas palavras de
explicação.

Essa explicação é enfeite. `200 OK`, `200 Fine`, `200 Tudo bem` são a mesma resposta, porque nada lê
as palavras: o **número** é o contrato e a frase é para quem estiver olhando. Algumas versões mais
novas do protocolo nem enviam a frase.

## Como a outra ponta sabe onde o corpo acaba

Uma conexão é um fluxo de bytes, então algo precisa dizer onde o conteúdo para. Há duas respostas e
você vai ver as duas.

O `Content-Length` diz de antemão, em bytes, e quem recebe conta. Simples, e exige que quem envia
saiba o tamanho antes de enviar qualquer coisa — o que um servidor gerando uma página conforme vai
não sabe.

A alternativa é enviar o corpo em pedaços, cada um anunciando o próprio tamanho, terminando com um
pedaço de tamanho zero. Isso se chama chunked, e é como chega qualquer coisa gerada na hora.

Errar o tamanho vale a pena conhecer porque a falha é estranha em vez de barulhenta: um tamanho
maior que o corpo deixa quem recebe esperando bytes que nunca vêm, e um tamanho menor que o corpo
deixa a sobra para ser lida como o começo da próxima resposta.

## O servidor não lembra de nada

Leia a requisição de novo e repare no que está nela. O host, o idioma, quais formatos são
aceitáveis, o caminho inteiro. Tudo isso, em cada requisição.

Isso não é desperdício. O HTTP é **sem estado**: cada requisição é completa por si, e o servidor,
entre duas delas, não é obrigado a lembrar de absolutamente nada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Três requisições do mesmo navegador chegam a três servidores diferentes. Cada requisição carrega tudo que é preciso para respondê-la, e nenhum servidor guarda nada entre uma e outra.\"> <rect x=\"20\" y=\"40\" width=\"150\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect> <text x=\"95\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">um navegador</text> <text x=\"95\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">requisição 1</text> <text x=\"95\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">requisição 2</text> <text x=\"95\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">requisição 3</text> <text x=\"95\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">cada uma completa</text> <path d=\"M176 96 L446 60\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path> <path d=\"M176 122 L446 122\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path> <path d=\"M176 148 L446 184\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path> <rect x=\"452\" y=\"36\" width=\"248\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"576\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">servidor A</text> <text x=\"576\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">não guarda nada depois</text> <rect x=\"452\" y=\"98\" width=\"248\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"576\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">servidor B</text> <text x=\"576\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">não guarda nada depois</text> <rect x=\"452\" y=\"160\" width=\"248\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"576\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">servidor C</text> <text x=\"576\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">não guarda nada depois</text> <text x=\"360\" y=\"238\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">três requisições de uma visita, respondidas por três máquinas, e nenhuma sabe da outra</text> </svg>", "caption": "Como nenhum servidor guarda nada entre requisições, qualquer um deles pode responder a próxima."}
```

É uma escolha incomum e é por causa dela que a web escalou. Um servidor que não lembra de nada pode
ser substituído no meio da conversa por outro servidor, e a próxima requisição cai em qualquer
máquina que estiver livre — que é exatamente o que o balanceador da aula passada está fazendo. Se
cada conexão carregasse uma memória, o mesmo visitante teria que voltar à mesma máquina enquanto
navegasse, e a falha de uma máquina encerraria a sessão de todo mundo que estava nela.

O preço chega na hora: uma loja precisa saber o que está no seu carrinho, e o protocolo acabou de
se recusar a lembrar. Tudo na próxima aula — cookies, sessões, tokens — existe para pôr estado em
cima de um protocolo que se recusa a guardar qualquer um. Não ter estado não é a ausência do
recurso; é o recurso, com o custo empurrado para cima, onde você escolhe como pagar.

## E é por isso que o `Host` é obrigatório

Um cabeçalho daquela requisição é exigido pela versão que ela declara, e o motivo merece um momento.

`Host: codeschool.ing` diz ao servidor qual site é o desejado. O endereço levou o pacote até uma
máquina, mas uma máquina costuma responder por centenas de nomes — é isso que hospedagem
compartilhada é — e quando a requisição chega o endereço já não basta para distingui-los.

Antes de esse cabeçalho existir, um servidor podia hospedar exatamente um site por endereço, e
endereços já estavam acabando. Uma linha de texto transformou uma máquina em quantos sites você
quiser, e a economia de pôr algo na web mudou junto.

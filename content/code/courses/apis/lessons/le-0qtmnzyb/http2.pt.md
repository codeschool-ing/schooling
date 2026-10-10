---
title: HTTP/2 por baixo
version: 1
---

**Uma chamada gRPC é um `POST` HTTP/2 para o nome completo do método, com as mensagens no corpo e o
status em trailers**, cabeçalhos que chegam depois que o corpo terminou. Nada disso é escondido, e
com o servidor rodando de novo dá para fazer uma chamada com o `curl` e os bytes da seção sobre o
fio.

A ideia errada é a de que o gRPC é um protocolo à parte, ao lado do HTTP. Ele é um jeito de usar o
HTTP/2, e **só o HTTP/2**. Pergunte em HTTP/1.1, que é o que o `curl` fala se ninguém disser outra
coisa:

```
ana@api:~/shelf$ curl -sS http://127.0.0.1:50051/shelf.stock.v1.Stock/GetStock
curl: (1) Received HTTP/0.9 when not allowed
```

O servidor respondeu no enquadramento binário do HTTP/2, e o `curl`, esperando uma linha de status em
texto, não conseguiu ler o que voltou. Nada no depósito estava errado; os dois programas não falavam
o mesmo protocolo.

## Uma chamada feita à mão

A mensagem da requisição é um `BookRef`, codificado do mesmo jeito que antes:

```
ana@api:~/shelf$ echo 'isbn: "9786500000016"' | protoc --encode=shelf.stock.v1.BookRef stock.proto > ask.bin
ana@api:~/shelf$ od -An -tx1 ask.bin
 0a 0d 39 37 38 36 35 30 30 30 30 30 30 31 36
```

Quinze bytes. No corpo da requisição **cada mensagem vem precedida de cinco bytes**: um que diz se a
mensagem está comprimida, aqui `00`, e quatro que dão o comprimento dela, aqui `00 00 00 0f`, que é
15. O `printf` escreve os cinco e o `cat` acrescenta a mensagem:

```
ana@api:~/shelf$ { printf '\x00\x00\x00\x00\x0f'; cat ask.bin; } > ask.grpc
```

Depois a chamada em si: `--http2-prior-knowledge` faz o `curl` falar HTTP/2 desde o primeiro byte,
`-D -` imprime os cabeçalhos, o corpo vai para um arquivo, e os dois `-H` dão o tipo de conteúdo que
o gRPC espera e o `te: trailers` que a especificação dele pede:

```
ana@api:~/shelf$ curl -sS --http2-prior-knowledge -D - -o reply.grpc -H 'content-type: application/grpc' -H 'te: trailers' --data-binary @ask.grpc http://127.0.0.1:50051/shelf.stock.v1.Stock/GetStock
HTTP/2 200 
content-type: application/grpc
grpc-accept-encoding: identity, deflate, gzip

grpc-status: 0
```

**A linha de status diz 200 e o resultado de verdade vem por último.** A linha vazia é o fim dos
cabeçalhos; tudo depois dela chegou quando o corpo já tinha acabado, e `grpc-status: 0` é `OK`. O
corpo traz uma mensagem com o mesmo prefixo de cinco bytes, sendo `21` o 33:

```
ana@api:~/shelf$ od -An -tx1 reply.grpc
 00 00 00 00 21 0a 0d 39 37 38 36 35 30 30 30 30
 30 30 31 36 12 0c 44 6f 6d 20 43 61 73 6d 75 72
 72 6f 18 0a 20 01
ana@api:~/shelf$ tail -c +6 reply.grpc | protoc --decode=shelf.stock.v1.StockLevel stock.proto
isbn: "9786500000016"
title: "Dom Casmurro"
copies: 10
availability: IN_STOCK
```

Dez exemplares, porque dois foram reservados na seção sobre o servidor. Agora peça um método que o
serviço não tem:

```
ana@api:~/shelf$ curl -sS --http2-prior-knowledge -D - -o /dev/null -H 'content-type: application/grpc' -H 'te: trailers' --data-binary @ask.grpc http://127.0.0.1:50051/shelf.stock.v1.Stock/GetPrice
HTTP/2 200 
content-type: application/grpc
grpc-status: 12
grpc-message: Method not found!
```

O HTTP continua dizendo 200, porque a troca HTTP deu certo. **A chamada falhou com o código 12,
`UNIMPLEMENTED`**, e a mensagem veio nos trailers. Uma ferramenta que julgasse o tráfego gRPC pelo
status HTTP contaria isso como sucesso.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Uma chamada gRPC dentro de um stream HTTP/2, numa conexão que outras chamadas compartilham. O cliente envia um frame HEADERS com :method POST, :path /shelf.stock.v1.Stock/GetStock, content-type application/grpc e te trailers, depois um frame DATA com um byte de flag 00, um comprimento de quatro bytes 00 00 00 0f e a mensagem de 15 bytes. O servidor responde com HEADERS trazendo :status 200, um frame DATA com 00, 00 00 00 21 e a mensagem de 33 bytes, e um último frame HEADERS, os trailers, com grpc-status 0.\"><rect x=\"10\" y=\"10\" width=\"700\" height=\"310\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"22\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma conexão TCP: outras chamadas correm ao lado desta, cada uma no seu stream</text><rect x=\"24\" y=\"40\" width=\"672\" height=\"268\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"36\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">um stream HTTP/2 = uma chamada</text><text x=\"190\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cliente → servidor</text><text x=\"530\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">servidor → cliente</text><rect x=\"40\" y=\"94\" width=\"300\" height=\"92\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"52\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">HEADERS</text><text x=\"52\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">:method: POST</text><text x=\"52\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">:path: /shelf.stock.v1.Stock/GetStock</text><text x=\"52\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">content-type: application/grpc</text><text x=\"52\" y=\"171\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">te: trailers</text><rect x=\"40\" y=\"198\" width=\"300\" height=\"62\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"52\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">DATA</text><text x=\"52\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">00 | 00 00 00 0f | 0a 0d 39 37 …</text><text x=\"52\" y=\"249\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">flag | comprimento 15 | o BookRef</text><rect x=\"380\" y=\"94\" width=\"300\" height=\"52\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"392\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">HEADERS</text><text x=\"392\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">:status: 200</text><text x=\"500\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">content-type: application/grpc</text><rect x=\"380\" y=\"158\" width=\"300\" height=\"62\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"392\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">DATA</text><text x=\"392\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">00 | 00 00 00 21 | 0a 0d 39 37 …</text><text x=\"392\" y=\"209\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">flag | comprimento 33 | o StockLevel</text><rect x=\"380\" y=\"232\" width=\"300\" height=\"62\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"392\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">HEADERS, depois do corpo: os trailers</text><text x=\"392\" y=\"268\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">grpc-status: 0</text><text x=\"392\" y=\"284\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o resultado de verdade da chamada</text></svg>", "caption": "Uma chamada gRPC é um POST HTTP/2 para o nome completo do método. O resultado chega por último, nos trailers, que é a parte que o fetch() de um navegador não consegue ler."}
```

## O que o HTTP/2 dá a ele

O HTTP/2 leva muitos **streams** numa conexão, cada um com os seus frames, e uma chamada gRPC é um
stream. Assim, um watch que fica aberto por uma hora não atrasa as reservas feitas na mesma conexão,
e o canal de um cliente abre uma conexão TCP com o depósito e envia todas as chamadas por ela. O
mesmo enquadramento é o que torna possível um stream em qualquer sentido: os frames de dados
continuam chegando até um dos lados dizer que terminou.

## Por que um navegador não consegue chamá-lo

O JavaScript de uma página pede uma requisição ao navegador com `fetch()`, e o navegador escolhe o
protocolo. **O `fetch()` não dá à página jeito nenhum de ler trailers**, nem controle sobre o
enquadramento do HTTP/2, então o status de toda chamada ficaria fora de alcance. Dois arranjos
contornam isso, e os dois põem alguma coisa entre o navegador e o serviço.

**O gRPC-Web** é uma variante do protocolo que leva os trailers para o fim do corpo, onde um
navegador consegue lê-los. A página usa uma biblioteca cliente de gRPC-Web, e um proxy na frente do
serviço, em geral o Envoy, traduz para gRPC de verdade.

**A transcodificação JSON** põe na frente do serviço um gateway que aceita requisições REST comuns,
com corpo em JSON, e transforma cada uma numa chamada gRPC. O `.proto` diz qual caminho corresponde a
qual método, por anotações que o gateway lê; o `grpc-gateway` e o filtro de transcodificação do Envoy
são os dois que você mais vai encontrar.

Nenhum dos dois roda nesta aula, porque cada um precisa de um proxy que o curso não instala. E o
depósito escuta sem TLS, só em 127.0.0.1; um serviço gRPC entre máquinas roda sobre TLS como
qualquer outro HTTP, e a aula 13 trata de HTTPS.

---
title: Uma API, e a requisição assinada que todo cliente manda
version: 1
---

**Todo jeito de usar a AWS termina na mesma coisa: uma requisição HTTPS ao endpoint de um serviço,
assinada com Signature Version 4.** A linha de comando, um SDK, um `curl` digitado à mão e o console
num navegador são quatro programas que montam essa requisição. O serviço não consegue distingui-los
por nada além do cabeçalho `User-Agent`, e aplica as mesmas políticas a todos. Esta lição desmonta a
requisição, manda uma à mão, e encerra o curso.

A imagem errada é que o console é a AWS e a linha de comando é uma ferramenta à parte. **A API é a
AWS**, e todo cliente é uma conveniência por cima dela. É por isso que uma permissão funciona igual
quando uma pessoa clica ou um script chama, e por isso a chave vazada da lição 12 não precisa de
console para causar estrago.

## A requisição que a linha de comando mandou

Reinicie o moto no primeiro terminal (Ctrl+C, depois `moto_server -p 4567`) para que esta lição
comece de uma AWS vazia. O `--debug` imprime algumas centenas de linhas para um comando. **O `grep`
do comando guarda cinco delas**, o método e o endereço, o corpo e três cabeçalhos, e corta todo o
resto que ele imprimiu:

```
ana@laptop:~/aws$ aws sts get-caller-identity --debug 2>&1 | grep -oE "'body': \{[^}]*\}|method=POST, url=[^,]*|'(Content-Type|X-Amz-Date|Authorization)': b'[^']*'"
'body': {'Action': 'GetCallerIdentity', 'Version': '2011-06-15'}
method=POST, url=http://localhost:4567/
'Content-Type': b'application/x-www-form-urlencoded; charset=utf-8'
'X-Amz-Date': b'20261016T190152Z'
'Authorization': b'AWS4-HMAC-SHA256 Credential=test/20261016/sa-east-1/sts/aws4_request, SignedHeaders=content-type;host;x-amz-date, Signature=dd8c5bbd7312a210d418c1ef957215a5aee54248ae42856cba4e9067667c8484'
```

Leia isso como a requisição que o STS recebeu:

- **um `POST` ao endpoint**, `http://localhost:4567/` aqui porque o `env.sh` aponta todo serviço
  para o moto, e `https://sts.sa-east-1.amazonaws.com/` contra a AWS;
- **um corpo que nomeia a ação e a versão da API**, `Action=GetCallerIdentity` e
  `Version=2011-06-15`, enviado como formulário;
- **o horário**, `X-Amz-Date`, que faz parte do que é assinado, então uma requisição capturada não
  pode ser repetida para sempre: a AWS recusa uma cujo horário esteja longe demais do relógio dela;
- **o cabeçalho `Authorization`**: o algoritmo, o id da chave com a data, a região e o serviço a que
  ele se limita, a lista de cabeçalhos assinados, e a assinatura em si.

**O segredo não está na requisição.** A assinatura é um hash que só quem tem o segredo conseguiria
calcular, e a AWS, que tem uma cópia, o calcula de novo e compara.

## Como a assinatura é feita

O SigV4 monta uma **requisição canônica**, uma grafia fixa do método, do caminho, da query, dos
cabeçalhos assinados e de um hash do corpo, para que os dois lados façam o hash exatamente dos
mesmos bytes. O `--debug` também a imprime:

```
ana@laptop:~/aws$ aws sts get-caller-identity --debug 2>&1 | grep -A9 "CanonicalRequest:" | sed "s/^.* - DEBUG - //"
CanonicalRequest:
POST
/

content-type:application/x-www-form-urlencoded; charset=utf-8
host:localhost:4567
x-amz-date:20261016T190153Z

content-type;host;x-amz-date
ab821ae955788b0e33ebd34c208442ccfc2d406e2edc5e7a39bd6458fbb4f843
```

O `sed` tira o prefixo do log da primeira linha. A requisição canônica vira hash e entra numa **string
a assinar** com a data e o escopo `20261016/sa-east-1/sts/aws4_request`. A chave que a assina não é
o próprio segredo, mas uma **derivada** dele em quatro passos: a data, a região, o serviço e a
palavra fixa `aws4_request`. Então uma chave de assinatura vazada de um dia, uma região e um serviço
não serve para mais nada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l26-sigv4\" aria-label=\"Como uma assinatura Signature Version 4 é feita, em duas colunas. À esquerda, a requisição: a requisição canônica (método, caminho, query, cabeçalhos assinados e um hash do corpo) vira hash e entra na string a assinar com a data e o escopo. À direita, a chave: o segredo é combinado com a data, depois a região, depois o serviço, depois a palavra aws4_request, dando a chave de assinatura. A chave de assinatura assina a string a assinar, e o resultado vai para o cabeçalho Authorization. O segredo em si nunca é enviado.\"><defs><marker id=\"l26-sigv4-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l26-sigv4-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l26-sigv4-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"170.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">a requisição</text><text x=\"540.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">a chave</text><rect x=\"60.0\" y=\"44.0\" width=\"220.0\" height=\"56.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">requisição canônica</text><text x=\"170.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">POST / host x-amz-date</text><path d=\"M170.0 102.0 L170.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l26-sigv4-af-ah-paper-dim)\"></path><text x=\"180.0\" y=\"121.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">SHA-256</text><rect x=\"60.0\" y=\"142.0\" width=\"220.0\" height=\"56.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">string a assinar</text><text x=\"170.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">20261016/sa-east-1/sts</text><rect x=\"460.0\" y=\"28.0\" width=\"160.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">secret</text><rect x=\"460.0\" y=\"72.0\" width=\"160.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">+ 20261016</text><rect x=\"460.0\" y=\"116.0\" width=\"160.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">+ sa-east-1</text><rect x=\"460.0\" y=\"160.0\" width=\"160.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">+ sts</text><rect x=\"460.0\" y=\"204.0\" width=\"160.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">+ aws4_request</text><path d=\"M540.0 61.0 L540.0 71.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l26-sigv4-af-ah-paper-dim)\"></path><path d=\"M540.0 105.0 L540.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l26-sigv4-af-ah-paper-dim)\"></path><path d=\"M540.0 149.0 L540.0 159.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l26-sigv4-af-ah-paper-dim)\"></path><path d=\"M540.0 193.0 L540.0 203.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l26-sigv4-af-ah-paper-dim)\"></path><text x=\"630.0\" y=\"132.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">HMAC</text><text x=\"552.0\" y=\"254.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">chave de assinatura</text><rect x=\"240.0\" y=\"262.0\" width=\"240.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Authorization: … Signature=…</text><path d=\"M170.0 200.0 L170.0 284.0 L238.0 284.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l26-sigv4-af-ah-phosphor)\"></path><path d=\"M540.0 237.0 L540.0 284.0 L482.0 284.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l26-sigv4-af-ah-amber)\"></path><text x=\"360.0\" y=\"322.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">o segredo assina; ele nunca é enviado</text></svg>", "caption": "Os dois lados calculam a mesma assinatura: o cliente com o segredo dele, a AWS com a cópia dela."}
```

## Assinando à mão com o `curl`

O `curl` conhece o SigV4 desde a versão 7.75: `--aws-sigv4` nomeia o provedor, a região e o
serviço, e `--user` dá o id da chave e o segredo. Esse é um cliente da AWS inteiro, num comando:

```
ana@laptop:~/aws$ curl -s --aws-sigv4 "aws:amz:sa-east-1:sts" --user test:test -d 'Action=GetCallerIdentity&Version=2011-06-15' http://localhost:4567/; echo
<GetCallerIdentityResponse xmlns="https://sts.amazonaws.com/doc/2011-06-15/"><GetCallerIdentityResult><UserId>AKIAIOSFODNN7EXAMPLE</UserId><Account>123456789012</Account><Arn>arn:aws:sts::123456789012:user/moto</Arn></GetCallerIdentityResult><ResponseMetadata><RequestId>3TDb3dzK2QmumYo7ZldnIn1yTcYAUa7IjkwdkKxaAxRIyDDVRGn8</RequestId></ResponseMetadata></GetCallerIdentityResponse>
ana@laptop:~/aws$ curl -s -o /dev/null -v --aws-sigv4 "aws:amz:sa-east-1:sts" --user test:test -d 'Action=GetCallerIdentity&Version=2011-06-15' http://localhost:4567/ 2>&1 | grep -iE "^> (POST|authorization|x-amz-date)"
> POST / HTTP/1.1
> Authorization: AWS4-HMAC-SHA256 Credential=test/20261016/sa-east-1/sts/aws4_request, SignedHeaders=host;x-amz-date, Signature=ac65559ddf52040c5090812a8e6c82daa8f9832bb58188e7694bbf7621c7c51d
> X-Amz-Date: 20261016T190153Z
```

**A resposta é XML**, a forma crua que a linha de comando transformou no JSON que imprime. O segundo
comando mostra os cabeçalhos que o `curl` mandou. O `Authorization` tem o mesmo formato que a linha
de comando montou, com um `SignedHeaders` mais curto, já que o `curl` escolheu assinar só dois. O
moto aceitou os dois. Aqui ele não verifica permissões, então aceitaria também uma requisição sem
assinatura. É a verificação da lição 7 que faz a assinatura importar no laboratório, e a AWS sempre
a verifica.

Assinar à mão é como chamar a AWS de uma linguagem ou ferramenta sem SDK, e como entender o que um
SDK faz. **Para qualquer coisa que rode todo dia, use um SDK**, que também cuida das novas
tentativas, das páginas e da cadeia de credenciais que o resto desta lição e a lição 10 descrevem.

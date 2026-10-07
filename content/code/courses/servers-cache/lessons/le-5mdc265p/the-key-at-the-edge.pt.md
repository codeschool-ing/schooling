---
title: A chave na borda
version: 1
---

Uma borda guarda uma cópia por chave, e a chave padrão dela é a URL e o host. Toda diferença na URL é uma
cópia diferente, inclusive diferenças que não mudam nada para a origem, e as mais comuns delas são os
**parâmetros de rastreamento**: `?utm_source=news` num link de newsletter,
`?utm_source=ads&utm_medium=cpc` num anúncio. A página é a mesma, e sem cuidado cada variante é um erro
de cache separado em cada borda do mundo.

As duas primeiras linhas do `vcl_recv` tiram todo parâmetro `utm_` antes de a chave ser calculada:

```
ana@web:~$ for q in '?utm_source=news' '?utm_source=ads&utm_medium=cpc' '' '?page=2'; do printf '%-34s ' "$q"; curl -s -o /dev/null -D - -H 'Host: ipelivros.example' "http://localhost:6081/api/books/4$q" | grep -i x-cache; done
?utm_source=news                   X-Cache: MISS
?utm_source=ads&utm_medium=cpc     X-Cache: HIT
                                   X-Cache: HIT
?page=2                            X-Cache: MISS
```

A primeira requisição errou e guardou o livro sob a URL limpa. A segunda, com dois parâmetros de
rastreamento diferentes, foi **um acerto na mesma cópia**, e a URL sem query nenhuma também. `?page=2` é
um parâmetro de verdade, que a origem poderia responder diferente, então ficou na chave e errou.

Esta é a versão da regra da aula 5 vista do outro lado. Lá, a chave precisava incluir tudo o que muda a
resposta, senão a resposta de uma pessoa chegava a outra. Aqui, ela não deve incluir nada que não mude,
senão o cache se enche de duplicatas e a taxa de acerto cai. Os dois erros estão na chave, e os dois são
achados do mesmo jeito: lendo os cabeçalhos de acerto e erro para URLs que deveriam, e que não deveriam,
dividir uma cópia.

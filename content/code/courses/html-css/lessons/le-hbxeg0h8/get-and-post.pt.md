---
title: GET ou POST
version: 1
---

`method` decide onde os dados do formulário vão na requisição, e a escolha decorre do que a requisição faz, não de gosto. A aula 6 de `web-fundamentals` descreveu os dois métodos; isto é o que eles significam para um formulário.

**`get` põe os dados no endereço.** A busca do começo desta aula enviou `GET /search?q=Clarice+Lispector`. Tudo fica visível na barra de endereços, pode ser favoritado, compartilhado e repetido com o botão voltar. Isso está certo para uma requisição que **só lê**: uma busca, um filtro, uma página de resultados. Enviá-la duas vezes não faz mal.

**`post` põe os dados no corpo da requisição.** O formulário de encomenda enviou:

```
ana@laptop:~/site$ probe order.html fill '#name' 'Ana Souza' fill '#email' ana@example.com fill '#cep' 05422-000 fill '#copies' 2 fill '#title' 'Vidas Secas' send button
POST /order
Content-Type: application/x-www-form-urlencoded
name=Ana+Souza&email=ana%40example.com&cep=05422-000&copies=2&title=Vidas+Secas
```

O endereço é só `/order`, e os dados viajam depois dos cabeçalhos, codificados do mesmo jeito, `name=Ana+Souza&…`, com um `Content-Type` dizendo isso. Isso está certo para uma requisição que **muda algo**: fazer uma encomenda, assinar uma lista, publicar um comentário. Um navegador a quem se pede para mandar um POST de novo, por um recarregamento ou pelo botão voltar, avisa antes de fazer isso, porque enviar uma encomenda duas vezes é uma segunda encomenda.

## Duas regras que decorrem disso

**Tudo o que é privado vai por POST.** Uma barra de endereços acaba no histórico do navegador, nos logs do servidor e às vezes no endereço que o próximo site recebe como página de origem. Uma senha ou o número de um documento pessoal numa query string ficou anotado em todos esses lugares. O POST o mantém fora do endereço; o HTTPS, que a aula 6 de `web-fundamentals` cobriu, o mantém fora do alcance de todo o resto no caminho.

**Um envio de arquivo precisa de `method="post"` e `enctype="multipart/form-data"`.** A codificação padrão, a das duas requisições acima, não consegue carregar um arquivo. Com `<input type="file">` no formulário e esse `enctype`, o corpo é dividido em partes, uma por campo, e o arquivo vai numa parte própria.

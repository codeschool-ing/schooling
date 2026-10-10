---
title: A aplicação que o curso publica
version: 1
---

**O curso precisa de algo para publicar, e quanto menor for, mais claramente cada mudança aparece.**
Então a aplicação é um quadro de avisos chamado `bulletin`, e ela faz uma coisa só: responde a toda
requisição com três linhas dizendo qual versão ela é, que mensagem recebeu e se tem um token. Cada uma
das três é definida por uma parte diferente do curso. A versão vem da imagem, a mensagem da
configuração no Git, e o token dos segredos das aulas 9 a 11.

São dois arquivos numa pasta própria. Crie-a com `mkdir ~/bulletin && cd ~/bulletin`.

## O programa

Salve isto como `~/bulletin/index.cgi`:

```sh
#!/bin/sh
# Answers every request with what this copy of bulletin was given.
echo "Content-Type: text/plain"
echo
echo "bulletin $VERSION"
echo "message: ${MESSAGE:-none}"
if [ -r /secrets/token ]; then
  echo "token: sha256:$(sha256sum /secrets/token | cut -c1-12)"
else
  echo "token: none"
fi
```

É um script CGI: o servidor web o executa uma vez por requisição e envia o que ele imprimir. Isso
importa mais adiante. Como o script roda de novo a cada requisição, um arquivo de token que muda
debaixo dele é visto já na requisição seguinte, e a aula 11 depende disso. **Ele nunca imprime o
próprio token**, só os doze primeiros caracteres do SHA-256 dele, o que basta para distinguir dois
tokens e não serve para nada a quem lê a página.

## A imagem

Salve isto como `~/bulletin/Dockerfile`:

```dockerfile
FROM busybox:1.37
ARG VERSION=dev
ENV VERSION=$VERSION
COPY --chmod=0755 index.cgi /www/cgi-bin/index.cgi
USER 65534
EXPOSE 8080
CMD ["httpd", "-f", "-p", "8080", "-h", "/www"]
```

O BusyBox traz um servidor web pequeno, o `httpd`, e quando uma pasta não tem `index.html` ele roda
`cgi-bin/index.cgi` no lugar. A versão é um **argumento de build gravado na imagem**, então
`bulletin:1.0` diz `1.0` onde quer que rode e não há como convencê-la do contrário. `USER 65534` é o
usuário `nobody`: nada aqui precisa de root.

Construa, experimente e envie:

```
ana@laptop:~/bulletin$ docker build --quiet --build-arg VERSION=1.0 -t localhost:5001/bulletin:1.0 .
sha256:18a3c2c67bc3617fd719c80fcf32fc820b23a436d9bd51e04ca660a97afdf28b
ana@laptop:~/bulletin$ docker run -d --rm --name try -p 127.0.0.1:9090:8080 -e MESSAGE="Hello from Docker." localhost:5001/bulletin:1.0
7fb07b00c41d02b14ac3b7806dbea5e985a866914be15c661b53ec551b1259ea
ana@laptop:~/bulletin$ curl -s localhost:9090
bulletin 1.0
message: Hello from Docker.
token: none
ana@laptop:~/bulletin$ docker stop try
try
ana@laptop:~/bulletin$ docker push localhost:5001/bulletin:1.0
The push refers to repository [localhost:5001/bulletin]
44136fa355b3: Pushed
791c5bdd85b8: Pushed
f698af0560ba: Pushed
68fe9bff2ad4: Pushed
1.0: digest: sha256:18a3c2c67bc3617fd719c80fcf32fc820b23a436d9bd51e04ca660a97afdf28b size: 855
ana@laptop:~/bulletin$ curl -s localhost:5001/v2/_catalog
{"repositories":["bulletin"]}
```

As três linhas voltaram como escritas: a versão da imagem, a mensagem do ambiente do `docker run`, e
`token: none` porque nada foi montado. O push pôs a imagem no registry da seção anterior, e o
catálogo agora a lista.

**Daqui em diante, uma versão do `bulletin` é uma imagem nesse registry, e nada mais.** Ninguém
publica a partir do `~/bulletin` diretamente. Essa separação, entre a coisa que é construída uma vez
e a descrição de onde ela deve rodar, é a maior parte do que as duas próximas seções tratam.

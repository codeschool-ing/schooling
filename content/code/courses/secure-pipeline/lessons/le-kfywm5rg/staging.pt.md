---
title: Staging feito para uma execução e jogado fora
version: 1
---

"Staging" costuma ser o nome de um servidor: uma cópia de produção que vive por muito tempo, onde um
time faz deploy antes da coisa de verdade, compartilhada por todo mundo, com os dados que a última
pessoa deixou nela. Uma varredura apontada para esse servidor mede o estado dele naquele dia, o que
inclui deploys pela metade de outras pessoas. **O staging que este pipeline usa é feito para uma
execução e apagado quando ela termina.** É uma rede Docker só dele, a imagem que a execução acabou de
construir e o scanner ao lado, na mesma rede. Não há mais nada nela, e nada nela é alcançável a
partir do host.

### Por que um por execução

Cada propriedade desse arranjo tira de uma varredura uma forma de mentir ou de causar dano.

- **Nada passa de uma execução para outra.** O banco começa vazio toda vez, então um achado não pode
  depender de um link que alguém criou na execução de ontem.
- **Duas execuções não colidem.** O nome da rede leva o id do processo do script que a criou, então
  dois pipelines varrendo ao mesmo tempo ganham cada um a sua.
- **Nada é publicado.** A porta do contêiner é alcançável na rede privada e em nenhum outro lugar:
  nem no host, nem na rede local em que o laptop está.
- **O scanner só alcança o que está ali.** Apontado para um nome nessa rede, ele só consegue varrer o
  serviço que a execução construiu.
- **Nenhum dado real fica exposto.** Um servidor de staging carregado com uma cópia de produção é uma
  cópia de produção com controles mais fracos. Este não guarda nada.

**A imagem é a que o pipeline entrega.** A varredura roda contra `linkbox:<commit>`, iniciada como o
Dockerfile a inicia, com o gunicorn. Varrer o serviço sob `flask run` num laptop seria varrer outro
servidor, com outros cabeçalhos e outras páginas de erro, e os achados descreveriam algo que ninguém
implanta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"sp-l04-staging\" aria-label=\"O ambiente de staging de uma execução do pipeline. Dentro da sua máquina, uma rede Docker chamada linkbox-staging seguida do id do processo tem dois contêineres: o serviço, a imagem linkbox no commit, ouvindo na porta 8000, e o scanner rodando zap-baseline.py. O scanner manda requisições ao serviço e lê as respostas. A rede é criada pelo ci/dast.sh quando começa e removida pelo trap dele quando termina. Nada é publicado na porta 8000 do host, e com -silent o scanner não chama ninguém de fora.\"><defs><marker id=\"sp-l04-staging-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"270\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"24\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a sua máquina</text><rect x=\"30\" y=\"50\" width=\"470\" height=\"210\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"46\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">rede linkbox-staging-&lt;pid&gt;</text><rect x=\"60\" y=\"100\" width=\"180\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o serviço</text><text x=\"150.0\" y=\"141.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">linkbox:&lt;commit&gt; :8000</text><rect x=\"300\" y=\"100\" width=\"170\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"385.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o scanner</text><text x=\"385.0\" y=\"141.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">zap-baseline.py</text><path d=\"M298 122 L242 122\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l04-staging-ah-phosphor)\"></path><path d=\"M242 144 L298 144\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l04-staging-ah-phosphor)\"></path><text x=\"270\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">requisições</text><text x=\"270\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">respostas</text><text x=\"265\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">criada pelo ci/dast.sh quando começa, removida pelo trap quando termina</text><rect x=\"515\" y=\"70\" width=\"185\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"607.5\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">127.0.0.1:8000</text><text x=\"607.5\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nada publicado</text><rect x=\"515\" y=\"170\" width=\"185\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"607.5\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">lá fora</text><text x=\"607.5\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">-silent: o ZAP não chama ninguém</text></svg>", "caption": "Tudo o que uma varredura toca fica numa rede privada que existe para uma execução."}
```

### Montando à mão

O pipeline vai fazer isso num script, duas seções adiante. Fazer à mão primeiro mostra cada peça.
Construa a imagem a partir do código da aula 3; sem `CI_COMMIT` definido, o script de build a marca
como `linkbox:dev`:

```
ana@vm:~$ cd linkbox
ana@vm:~/linkbox$ bash ci/build.sh
sha256:1b5f69ebcc9f7a8fa9f1d372415f9e0e1f2f1e6e909c5ec329d925c95f68691a
```

Crie a rede, suba o serviço nela e peça a página inicial de um segundo contêiner na mesma rede. A
imagem do ZAP já está na máquina e traz o `curl`, então ela serve de segundo contêiner. O último
comando pergunta à porta 8000 do próprio host, onde nada escuta:

```
ana@vm:~/linkbox$ docker network create linkbox-staging
e7b3e89df325c4f551f2fb8f5ae3947501c01ec22a0894ae2ffea79e3b9d83f6
ana@vm:~/linkbox$ docker run -d --rm --name linkbox-app --network linkbox-staging linkbox:dev
a436665d429fea055e285f54252e300be9cf974618b262c9352196a8a2aae815
ana@vm:~/linkbox$ docker run --rm --network linkbox-staging zaproxy/zap-stable:2.17.0 curl -sI http://linkbox-app:8000/
HTTP/1.1 200 OK
Server: gunicorn
Date: Fri, 23 Oct 2026 04:46:42 GMT
Connection: close
Content-Type: text/html; charset=utf-8
Content-Length: 127

ana@vm:~/linkbox$ curl -sS http://127.0.0.1:8000/
curl: (7) Failed to connect to 127.0.0.1 port 8000 after 0 ms: Couldn't connect to server
```

O contêiner responde pelo nome, `linkbox-app`, porque o Docker roda um servidor de nomes em toda rede
que um usuário cria; a rede bridge padrão não tem esses nomes, e esse é um dos motivos para criar uma
rede em vez de usar a padrão. O host não recebe nada, porque o `docker run` não publicou porta
nenhuma.

**A resposta é o defeito.** Ela cita o servidor e não traz `Content-Security-Policy`, nem
`X-Frame-Options`, nem `X-Content-Type-Options`. Daria para achar isso com `curl` e uma lista de
cabeçalhos para procurar, e muitos times começam assim. O scanner da próxima seção faz a mesma
leitura com umas sessenta regras em vez de três, e continua fazendo a cada execução.

### Dois limites deste staging

Uma rede criada assim ainda deixa os contêineres saírem para a internet, por padrão.
`docker network create --internal` fecharia isso, ao preço de todo contêiner nela perder qualquer
acesso externo de que precise. Este pipeline deixa a rede comum e confia na opção do próprio scanner,
na próxima seção, para que ele não chame lugar nenhum.

E um staging deste tamanho não reproduz o que fica na frente de produção: um proxy reverso, uma rede
de distribuição de conteúdo, um balanceador de carga, e qualquer um deles pode acrescentar ou
remover um cabeçalho. Uma varredura do staging diz o que o serviço manda. O que o navegador do
usuário recebe é outra pergunta, e responder a ela significa varrer o endereço de produção com uma
varredura que só lê, de propósito e com o acordo do dono.

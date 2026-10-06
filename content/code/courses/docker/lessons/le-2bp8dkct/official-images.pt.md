---
title: Imagens que outra pessoa mantém
version: 1
---

**A maioria dos containers que você roda não foi construída por você.** Um banco de dados, um cache,
uma fila de mensagens, um servidor web: cada um é publicado como imagem por alguém que sabe
configurá-lo, e rodá-lo é um comando. A habilidade que esta aula ensina é ler uma imagem dessas bem o
bastante para confiar nela e configurá-la, porque tudo o que ela faz ao iniciar é decidido por quem a
escreveu.

## Quem a publicou

O Docker Hub marca três tipos de publicador, e a marca é a primeira coisa a conferir:

- **Docker Official Images**: um conjunto curado, `postgres`, `redis`, `python`, `alpine` e muitas
  outras, mantidas pelo Docker junto com os mantenedores de cada projeto. Os nomes delas não têm
  barra, porque moram num namespace chamado `library`, que o `docker` preenche para você.
- **Verified Publisher**: imagens de uma empresa que o Docker verificou, no namespace dessa empresa,
  como as imagens do próprio fabricante de um banco ou as ferramentas de um provedor de nuvem.
- **Sponsored Open Source**: imagens de projetos de código aberto no programa de patrocínio do Docker.

Qualquer outra coisa é uma imagem que alguém enviou. Ela pode ser excelente, e ninguém a conferiu. A
aula 20 mostra como olhar dentro de qualquer imagem antes de confiar nela; a marca é o primeiro
filtro, o barato.

## Baixando uma

A primeira execução de uma imagem faz o download dela. A Ana a baixa sozinha, para observar:

```
ana@vm:~$ docker pull postgres:17
17: Pulling from library/postgres
affbe3357b39: Pulling fs layer
b86134c2eeb6: Pulling fs layer
99ce35cabaf9: Pulling fs layer
c9432d362cca: Pulling fs layer
dc30f2779c66: Pulling fs layer
3be737420556: Pulling fs layer
d43ee31e40df: Pulling fs layer
e30751283c57: Pulling fs layer
8aebe6431dc8: Pulling fs layer
c5602f014e9e: Pulling fs layer
fcdd3a481359: Pulling fs layer
52fc2be321a4: Pulling fs layer
57644501a07f: Pulling fs layer
99ce35cabaf9: Download complete
affbe3357b39: Download complete
b86134c2eeb6: Download complete
57644501a07f: Download complete
e30751283c57: Download complete
c9432d362cca: Download complete
d43ee31e40df: Download complete
dc30f2779c66: Download complete
c5602f014e9e: Download complete
3be737420556: Download complete
fcdd3a481359: Download complete
8aebe6431dc8: Download complete
fcdd3a481359: Pull complete
52fc2be321a4: Download complete
b86134c2eeb6: Pull complete
57644501a07f: Pull complete
a7cb71218182: Download complete
affbe3357b39: Pull complete
e30751283c57: Pull complete
c5602f014e9e: Pull complete
3be737420556: Pull complete
3de48e9ae1ea: Download complete
c9432d362cca: Pull complete
d43ee31e40df: Pull complete
dc30f2779c66: Pull complete
8aebe6431dc8: Pull complete
99ce35cabaf9: Pull complete
52fc2be321a4: Pull complete
Digest: sha256:ae69c452f483507a6b99fb654cf93aad7fe156ffd2c56247707eef4e36d3c12b
Status: Downloaded newer image for postgres:17
docker.io/library/postgres:17
```

**Treze camadas, cada uma com o nome de uma forma curta do próprio digest**, baixadas em paralelo e
depois desempacotadas uma a uma, "Pull complete". A linha `Digest` nomeia a imagem exata que ela tem
agora, e a última linha dá o nome completo: `docker.io/library/postgres:17`, registry, namespace,
repositório e tag, as partes que a aula 15 desmonta.

## O que ela vai fazer ao iniciar

A configuração de uma imagem diz o que roda se o `docker run` não receber comando, e a aula 3 a leu
no JSON cru. O `docker image inspect` lê os mesmos campos:

```
ana@vm:~$ docker image inspect postgres:17 --format "{{json .Config.Entrypoint}} {{json .Config.Cmd}}"
["docker-entrypoint.sh"] ["postgres"]
ana@vm:~$ docker image inspect postgres:17 --format "{{json .Config.ExposedPorts}}"
{"5432/tcp":{}}
```

**O `Entrypoint` é `docker-entrypoint.sh`, e o `Cmd` é `postgres`**, que é passado a ele como
argumento. O entrypoint é um script de shell que os autores da imagem escreveram, e é nele que
acontece tudo aquilo em que a próxima etapa se apoia: no primeiro início ele cria os arquivos do
banco, define a senha, roda os seus scripts de preparação e só então inicia o servidor. Toda imagem
de banco séria funciona assim, e a documentação dela lista as variáveis de ambiente que o entrypoint
lê.

O `ExposedPorts` diz que o servidor escuta na `5432`. Isso é documentação, não uma porta aberta: a
aula 17 mostra que nada fica acessível de fora até uma porta ser publicada.

## Escolhendo uma tag

A página da imagem lista as tags, e elas seguem um padrão que vale conhecer:

| tag | o que ela nomeia |
| --- | --- |
| `17` | a versão 17.x mais nova, que muda a cada correção |
| `17.11` | exatamente essa versão menor, que só muda em reconstruções da mesma versão |
| `17-alpine` | o mesmo PostgreSQL sobre Alpine em vez de Debian: menor, com `musl` em vez de `glibc` |
| `17-trixie` | o mesmo PostgreSQL sobre Debian 13, explicitamente |
| `latest` | o que os autores resolveram chamar de mais recente, o que para um banco é uma armadilha |

**Escolha pelo menos a versão principal**, porque os arquivos de dados de um banco pertencem a uma
versão principal, como a aula 8 mostrou. A aula 16 trata de por que `latest` nunca é uma versão.

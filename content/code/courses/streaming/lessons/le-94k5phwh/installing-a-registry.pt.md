---
title: Instalando um registro de esquemas
version: 1
---

Um registro de esquemas é um pequeno serviço web com um banco de dados por trás. Os produtores
pedem a ele um id quando escrevem, os consumidores pedem um esquema quando leem, e os próprios
esquemas ficam guardados nele, numerados. **O Kafka não vem com um**, e nada no broker sabe que um
registro existe: para o Kafka, uma mensagem continua sendo uma chave e um valor feitos de bytes.

O registro mais conhecido é o da Confluent, publicado sob a Confluent Community License, que
proíbe oferecê-lo como serviço hospedado concorrente do da própria Confluent. Este curso usa o
**Apicurio Registry**, um registro com licença Apache, da Red Hat, que também responde na API da
Confluent, de modo que o cliente Python que você já tem conversa com ele sem mudar nada. A versão
3.3.3 é um único arquivo no Maven Central, o repositório onde as bibliotecas Java são publicadas,
e roda no Java que você instalou na lição 1.

## Baixando

O arquivo tem 159 MB, com um checksum ao lado:

```sh
cd ~
curl -fsSLO https://repo.maven.apache.org/maven2/io/apicurio/apicurio-registry-app/3.3.3/apicurio-registry-app-3.3.3-all.tar.gz
curl -fsSLO https://repo.maven.apache.org/maven2/io/apicurio/apicurio-registry-app/3.3.3/apicurio-registry-app-3.3.3-all.tar.gz.sha512
```

Compare os dois, como fez com o Kafka:

```
ubuntu@stream:~$ sha512sum apicurio-registry-app-3.3.3-all.tar.gz | cut -d" " -f1
dd081e0bb14bb94ac9806eb768667b10a7292a8a75a81cbbfec1c99d920bc35697fc5e567d74b7bf94a0105648b90480842822959815d2965e0dc6c9524c92d3
ubuntu@stream:~$ cat apicurio-registry-app-3.3.3-all.tar.gz.sha512; echo
dd081e0bb14bb94ac9806eb768667b10a7292a8a75a81cbbfec1c99d920bc35697fc5e567d74b7bf94a0105648b90480842822959815d2965e0dc6c9524c92d3
```

O arquivo não tem um diretório próprio no topo, então crie um e descompacte dentro dele. Depois
instale o lado Avro do cliente Python. `confluent-kafka[avro]` traz o cliente do registro e o
serializador Avro; o resto da linha fixa as versões do que ele puxa, para que as suas sejam as
mesmas com que estas transcrições foram feitas:

```sh
mkdir -p ~/apicurio
tar -xzf apicurio-registry-app-3.3.3-all.tar.gz -C ~/apicurio
pip install "confluent-kafka[avro]==2.16.0" fastavro==1.13.1 avro==1.12.2 requests==2.34.2 httpx2==2.13.1 authlib==1.8.0 attrs==26.1.0 cachetools==7.2.1
```

## Iniciando

O registro é um único programa Java, `quarkus-run.jar`, e sem configuração ele guarda os esquemas
**em memória** e escuta na porta 8080. Inicie-o em segundo plano com a saída indo para um arquivo,
e espere ele responder:

```
ubuntu@stream:~/work$ nohup java -jar ~/apicurio/quarkus-run.jar > ~/apicurio/registry.log 2>&1 &
ubuntu@stream:~/work$ until curl -s localhost:8080/apis/ccompat/v7/subjects; do sleep 1; done; echo
[]
```

A linha do `until` pede a lista de subjects uma vez por segundo até alguém responder. `[]` é uma
lista vazia: o registro está no ar e ainda não guarda nada. O seu shell também imprime um número de
job e um id de processo quando você inicia algo com `&`, que não estão na transcrição e mudam a
cada vez.

**Em memória quer dizer que pará-lo esquece todos os esquemas.** É a troca certa para um
laboratório, onde cada lição registra o que precisa, e a errada em qualquer outro lugar: um
registro que perde os esquemas transformou cada mensagem escrita com eles em bytes que ninguém
consegue ler. Uma instalação de verdade o aponta para um banco de dados, PostgreSQL ou o próprio
Kafka, com uma configuração cada. Também o põe atrás de autenticação, porque um registro em que
qualquer um escreve é um jeito de mudar o que todo consumidor acredita que uma mensagem diz.

Duas coisas para saber antes da próxima seção:

- O Apicurio responde a API da Confluent em `/apis/ccompat/v7`, então todo
  cliente desta lição recebe `http://localhost:8080/apis/ccompat/v7` onde a documentação da
  Confluent escreveria `http://localhost:8081`.
- Ele não sobe sozinho, como o cluster. Depois de reiniciar a máquina virtual, rode de novo a
  linha do `nohup`; os esquemas terão sumido, e os comandos da lição os registram de novo.

Se o `until` ficar em loop por mais de um minuto, o motivo está no fim de
`~/apicurio/registry.log`. O mais comum é outro programa na porta 8080, que `ss -ltnp | grep 8080`
nomeia.

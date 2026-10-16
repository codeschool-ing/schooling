---
title: A conta de um segundo serviço
version: 1
---

O custo de um serviço é pago em grande parte fora do código dele. **Cada um precisa de tudo o que o
monólito precisava uma vez, de novo**, e o trabalho que era feito uma vez para o sistema inteiro passa
a ser feito por serviço, para sempre.

Mesmo parado, cada serviço é um processo com um runtime dentro. Aqui estão os dois contêineres do
laboratório, sem fazer nada:

```
ana@vm:~/lab/split$ docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}"
NAME            MEM USAGE / LIMIT
split-shop-1    18.27MiB / 15.72GiB
split-stock-1   10.85MiB / 15.72GiB
```

Dois programas Python pequenos, e cada um guarda o seu próprio interpretador
na memória. O número por contêiner é pequeno aqui e é por serviço: na JVM, um serviço que quase não
faz nada costuma começar com algumas centenas de megabytes, e dez deles são uma máquina.

Memória é a parte barata. A lista que cresce a cada serviço é esta:

| por serviço | o que é |
| --- | --- |
| um pipeline | construir, testar e publicar uma imagem a cada commit |
| uma implantação | a sua própria configuração, o seu número de cópias, o seu rollout e rollback |
| health checks | um jeito de a plataforma saber que ele está de pé e pronto, aula 19 |
| logs que dá para juntar | um id de requisição em cada linha, como o `X-Request-Id` aqui, e um lugar para buscar todos juntos |
| métricas e alertas | a sua própria taxa de erro, latência e saturação, com alguém acionado quando dão errado |
| um contrato de API | versionado, documentado e testado contra quem chama, porque não pode mais mudar junto com eles |
| segredos e identidade | as suas próprias credenciais, e um jeito de os serviços saberem quem está chamando, que `apis` cobre |
| um dono | uma equipe que responde por ele às três da manhã |

**Multiplique a tabela pelo número de serviços** antes de decidir um número. A Quitanda com dois
serviços paga duas vezes. Dividida por cada substantivo, catálogo, estoque, pedidos, pagamentos e
entrega, paga cinco vezes, por uma loja que uma equipe de seis conseguiria rodar como um programa.

## Onde o custo cai

O custo por serviço cai com trabalho de plataforma: um modelo de pipeline compartilhado, uma
plataforma de implantação que todo serviço usa do mesmo jeito, logs e métricas coletados sem cada
equipe construir os seus. Empresas com centenas de serviços mantêm uma equipe de plataforma
exatamente para isso. **Essa plataforma é ela mesma um custo**, e é um dos motivos pelos quais
microsserviços servem melhor a organizações grandes do que a pequenas. A aula 3 olha dois produtos
desse trabalho de plataforma, funções serverless e a service mesh, que tiram parte da lista de cada
equipe.

Pare os serviços da aula agora:

```sh
docker compose down -v
```

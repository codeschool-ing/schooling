---
title: Revisões, e por que nenhuma delas muda nunca
version: 1
---

Toda vez que um serviço do Cloud Run é publicado, ou que a configuração dele muda de qualquer jeito
que afete como os contêineres rodam, **o Cloud Run cria uma nova revisão: um retrato imutável da
imagem e de toda configuração em volta dela.** A revisão antiga não é editada nem apagada. Ela
fica, com nome próprio, pronta para receber tráfego de novo no momento em que alguém pedir.

## O que uma revisão guarda

Uma revisão é a imagem, nomeada pelo digest, junto com tudo que está no `template` do serviço:
variáveis de ambiente, CPU e memória, concorrência, tempo limite, conta de serviço, limites de
escala, as configurações de rede da lição 12. Mude qualquer uma delas e a próxima publicação é uma
revisão nova. O que **não** está numa revisão é a divisão de tráfego, que pertence ao serviço, e o
nome e o endereço do serviço. Essa divisão é o que o resto desta lição usa: revisões são coisas, e o
tráfego é uma decisão sobre elas.

Revisões recebem o nome do serviço, seguido de um número e de um sufixo aleatório que o Cloud Run
gera, a menos que você dê um sufixo. A documentação do próprio gcloud diz como, e é um dos comandos
que este laboratório consegue rodar, porque a ajuda não precisa de conta:

```
ana@laptop:~/gcp$ gcloud run deploy --help | grep -A5 -- '^     --revision-suffix'
     --revision-suffix=REVISION_SUFFIX
        Specify the suffix of the revision name. Revision names always start
        with the service name automatically. For example, specifying
        [--revision-suffix=v1] for a service named 'helloworld', would lead to
        a revision named 'helloworld-v1'. Set empty string to clear the suffix
        and resume server-assigned naming.
```

**Escolher o sufixo torna o nome previsível**, `orders-v1` e `orders-v2` em vez de uma sequência que
você só conhece depois da publicação, e é isso que deixa um arquivo do Terraform ou um script de
volta atrás nomear uma revisão antes de ela existir. O resto desta lição usa esses dois nomes.

## Duas revisões, lado a lado em casa

Nada em casa cria uma revisão, mas as duas com que esta lição trabalha podem rodar lado a lado,
cada uma informada do próprio nome como o Cloud Run informa, pelo `K_REVISION`. A versão 2 é o mesmo
programa com uma mudança de configuração: `ORDERS_DELAY_MS=250`, no lugar de uma consulta nova ao
banco que acabou saindo lenta. A partir de `~/gcp`, com a imagem `orders:1` da lição 8:

```
ana@laptop:~/gcp$ docker run -d --name orders-v1 -p 8081:8080 -e K_REVISION=orders-v1 orders:1
6cb4c04a1f23beab418e36ced682d75453a1aae51ce7afc5584440af11e5b433
ana@laptop:~/gcp$ docker run -d --name orders-v2 -p 8082:8080 -e K_REVISION=orders-v2 -e ORDERS_DELAY_MS=250 orders:1
b0d010f5bfb93cc662ea2f8fc313d1cdd41d2a34235c7eb2f7d9988ce5a7bea3
ana@laptop:~/gcp$ curl -s localhost:8081/orders | python3 -m json.tool | tail -2
    "revision": "orders-v1"
}
ana@laptop:~/gcp$ curl -s -o /dev/null -w "%{time_total}\n" localhost:8081/orders
0.001487
ana@laptop:~/gcp$ curl -s localhost:8082/orders | python3 -m json.tool | tail -2
    "revision": "orders-v2"
}
ana@laptop:~/gcp$ curl -s -o /dev/null -w "%{time_total}\n" localhost:8082/orders
0.251924
```

Cada resposta diz a sua revisão, que é como uma linha de log ou uma resposta conta de onde veio
quando o tráfego está dividido entre elas. E o `-w "%{time_total}"` mostra o que a mudança fez: **a
versão 1 respondeu em poucos milissegundos e a versão 2 em cerca de um quarto de segundo**, neste
laptop. Essa diferença é exatamente o que uma liberação gradual existe para pegar antes que todo
usuário a sinta, e a seção 05 a usa.

## O que a imutabilidade compra

Uma revisão que nunca muda é o motivo de voltar atrás ser seguro. A revisão que atendia ontem ainda
está lá, byte por byte e configuração por configuração, então mandar tráfego de volta para ela
retorna a um estado conhecido em vez de a uma tentativa de reconstruí-lo. **Voltar atrás no Cloud
Run é uma mudança de tráfego, não uma publicação**: nada de build, nada de baixar imagem nova,
nada que possa falhar diferente da última vez.

Isso também quer dizer que revisões se acumulam. O Cloud Run as guarda, até um limite por serviço
que a página de cotas do Google define, e uma revisão que não atende tráfego não custa nada com
cobrança por requisição, porque não tem instâncias. Revisões velhas são apagadas à mão ou por um
script quando ninguém mais vai voltar para elas.

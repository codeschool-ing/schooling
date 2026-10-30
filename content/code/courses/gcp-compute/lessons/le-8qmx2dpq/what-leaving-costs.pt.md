---
title: O que custa sair
version: 1
---

O custo de sair de um provedor costuma ser discutido como um sentimento. **Ele pode ser estimado, e
a estimativa tem três partes: mover os dados, reescrever o que toca o Google diretamente e rodar dois
sistemas enquanto a mudança acontece.** Só a primeira tem tabela de preços; as outras duas se medem
no tempo das pessoas, o que as torna maiores e menos visíveis.

## Mover os dados

Dados saindo do Google Cloud para a internet são cobrados por GiB, em faixas que barateiam conforme
o volume do mês cresce. Na página de preços de rede em 30 de outubro de 2026, para o Premium Tier de
Iowa até a América do Norte: o primeiro GiB do mês é grátis, depois 0,12 por GiB até 1 TiB, 0,11 até
10 TiB e 0,08 acima disso. Um programa curto dá preço a uma mudança de qualquer tamanho; salve como
`~/gcp/egress.py`:

```python
# egress.py
import sys

# Premium Tier, Iowa to North America, per GiB in a month (30 October 2026)
TIERS = [(1, 0.0), (1024, 0.12), (10240, 0.11), (float('inf'), 0.08)]


def cost(gib):
    total, below = 0.0, 0
    for top, price in TIERS:
        if gib > below:
            total += (min(gib, top) - below) * price
        below = top
    return total


for arg in sys.argv[1:]:
    gib = float(arg) * 1024
    print(f'{arg:>6} TiB  {cost(gib):>10.2f} USD')
```

As faixas são uma lista de onde cada uma termina e quanto cobra, e `cost` percorre essa lista,
cobrando cada fatia do volume na taxa dela. Três tamanhos:

```
ana@laptop:~/gcp$ python3 egress.py 1 5 50
     1 TiB      122.76 USD
     5 TiB      573.32 USD
    50 TiB     4413.32 USD
```

As fotos da loja, algumas centenas de GiB, custariam algumas dezenas de dólares para mover; uma
empresa com 50 TiB de histórico paga alguns milhares antes de qualquer outra coisa acontecer, e isso
supondo que a mudança caiba num mês. **A saída de dados é o tipo de aprisionamento que cresce em
silêncio**, porque todo mês a loja guarda mais do que apaga.

Duas coisas mudam esse número. O Google anunciou em 2024 que dispensa essas cobranças para um
cliente que leva todos os dados para fora do Google Cloud, mediante pedido e sob condições próprias;
leia os termos atuais antes de contar com isso. E os dados também podem sair em dispositivos
físicos, o que troca um preço de rede por um de frete nos casos muito grandes.

## Reescrever o que toca o Google

É a parte que as costuras da seção anterior existem para encolher. Conte os pontos de chamada: cada
import de uma biblioteca cliente do Google, cada recurso no Terraform, cada vínculo do IAM. Para a
loja como desenhada na lição 22, isso é o módulo que publica no Pub/Sub, o gatilho do Eventarc, o
job do Cloud Scheduler, o Terraform de quatro serviços e as permissões entre eles. Semanas, não
meses, porque os serviços em si são contêineres.

Uma loja que chamasse o Firestore de quarenta lugares, ou pusesse regras de negócio nas
configurações de nova tentativa do Cloud Tasks, contaria diferente, e a contagem é a estimativa.

## Rodar os dois ao mesmo tempo

**Nenhuma migração de verdade vira numa noite.** Durante semanas, os dados são copiados e mantidos
em sincronia, o tráfego muda serviço por serviço, e os dois provedores cobram tudo que está rodando
em dobro. Uma regra aproximada é que a sobreposição custa tanto quanto os próprios sistemas durante
o tempo que dura, então dois meses de sobreposição numa conta mensal de 2.000 dólares são uns 4.000
dólares de infraestrutura duplicada, mais o tempo de quem fica olhando as duas.

## A saída, com preço

Juntando tudo, o custo de sair é um número com três termos: a saída de dados, pelo programa;
semanas de reescrita, pela contagem de pontos de chamada; e a sobreposição, pela conta. **Anotar esse
número uma vez por ano transforma o aprisionamento de medo em quantidade**, e uma quantidade que
cresce mais rápido que o sistema é a que vale atacar.

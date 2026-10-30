---
title: Modo Native ou Datastore, e uma conta por operação
version: 1
---

**Um banco do Firestore é criado num de dois modos, Native ou Datastore, e a escolha é feita uma vez.**
O modo Native é o que esta aula usou: documentos, coleções, subcoleções, as bibliotecas cliente do
Firebase para celulares e navegadores, listeners em tempo real que empurram mudanças para um app, e
regras de segurança que deixam esses clientes lerem o banco direto. O modo Datastore é a API do antigo
Cloud Datastore sobre o armazenamento do Firestore: entidades, kinds e ancestrais, a biblioteca
`google-cloud-datastore`, só para servidores, sem nenhum dos recursos de celular e de listener.

**A ideia errada é que o modo Datastore é o legado que se evita.** É o modo certo para um banco que só
servidores tocam, e o guia do Google para escolher um modo o descreve para projetos de servidor; o que
falta nele, os listeners e os SDKs móveis, é exatamente o que um back-end nunca usa. O app da Quitanda
lê o histórico de pedidos direto do celular e escuta o status da entrega de um pedido em andamento,
que é trabalho do modo Native. Um serviço interno sem app seria tão bem servido pelo modo Datastore.

| | modo Native | modo Datastore |
|---|---|---|
| unidade | documento, numa coleção | entidade, de um kind |
| hierarquia | subcoleções | caminhos de ancestrais, grupos de entidades |
| clientes | bibliotecas de servidor, e Firebase para celular e web | só bibliotecas de servidor |
| listeners em tempo real e clientes offline | sim | não |
| índices | de campo único automáticos, compostos declarados | embutidos automáticos, compostos declarados |
| no emulador | o padrão, sem `--database-mode` | `--database-mode=datastore-mode` |

**O Firestore também tem duas edições agora, Standard e Enterprise**, que a ajuda do emulador lista como
valores de `--edition`. Os preços desta aula são os da edição Standard: a página lida para eles diz
isso na primeira linha e aponta outra página para a Enterprise, cujos preços por isso não aparecem
aqui.

## Uma conta por operação

**O Firestore Standard é cobrado pelo que é feito, não pelo que está ligado**: leituras, escritas e
exclusões de documentos, cada uma por 100.000, e armazenamento por GiB-mês, com uma cota gratuita
todo dia. Não há instância, nem nó, nem nada para dimensionar. De cloud.google.com/firestore/pricing,
lida em 2026-10-30, `southamerica-east1`, USD:

| | grátis por dia | além disso |
|---|---|---|
| leituras de documento | 50.000 | 0,045 por 100.000 |
| escritas de documento | 20.000 | 0,135 por 100.000 |
| exclusões de documento | 20.000 | 0,015 por 100.000 |
| dados guardados | 1 GiB | 0,135 por GiB-mês |

**A cota gratuita é por projeto, para um banco**: a página diz que ela vale só para o banco
`(default)`, e um banco nomeado paga desde a primeira leitura. Uma consulta é cobrada uma leitura por
documento que devolve, e pelo menos uma leitura mesmo quando não devolve nada; as entradas de índice
não são cobradas numa consulta com no máximo um campo de faixa, e são cobradas uma leitura a cada 1.000
numa consulta com mais.

`price.py`:

```python
"""Firestore Standard edition, southamerica-east1, USD, list prices read on
2026-10-30 from cloud.google.com/firestore/pricing. The free quota is per day."""
PER_100K = {'reads': 0.045, 'writes': 0.135, 'deletes': 0.015}
FREE_PER_DAY = {'reads': 50_000, 'writes': 20_000, 'deletes': 20_000}
STORAGE_GIB_MONTH, FREE_GIB = 0.135, 1


def month(per_day, gib, days=30):
    usd = {op: max(0, n - FREE_PER_DAY[op]) * days / 100_000 * PER_100K[op] for op, n in per_day.items()}
    usd['storage'] = max(0, gib - FREE_GIB) * STORAGE_GIB_MONTH
    return usd


app = month({'reads': 400_000, 'writes': 6_000, 'deletes': 0}, gib=2)
report = month({'reads': 400_000 + 1_800_000, 'writes': 6_000, 'deletes': 0}, gib=2)
for name, bill in (('the app', app), ('the app and a nightly full read', report)):
    lines = ', '.join(f'{k} {v:,.2f}' for k, v in bill.items())
    print(f'{name:<32} {sum(bill.values()):>8,.2f}   ({lines})')
```

```
ana@laptop:~/gcp$ python3 price.py
the app                              4.86   (reads 4.72, writes 0.00, deletes 0.00, storage 0.14)
the app and a nightly full read     29.16   (reads 29.02, writes 0.00, deletes 0.00, storage 0.14)
Terminated
Terminated
```

**O app custa 4,86 por mês**: 400.000 leituras por dia, todo cliente abrindo o histórico de pedidos, das
quais 350.000 passam da cota gratuita, 10,5 milhões por mês a 0,045 por 100.000; 6.000 escritas por
dia, dentro das 20.000 grátis; e 2 GiB de documentos e suas entradas de índice, 1 deles grátis. **Um
relatório noturno que lê os 1,8 milhão de pedidos multiplica isso por seis**, para 29,16, por uma
consulta que lê todo documento uma vez por dia. Esse é o formato de uma conta do Firestore: quase nada
para um app que lê o que mostra, e uma linha que cresce com todo documento que uma consulta descuidada
toca. Um relatório sobre tudo pertence ao data warehouse da aula 13, onde ler tudo é aquilo para que a
conta foi feita.

**Uma tela pode receber preço antes de ser construída**, porque as leituras dela se contam. O histórico
de pedidos mostra vinte pedidos: vinte leituras por visita. Se ele escuta mudanças em vez de ler uma
vez, cada pedido que muda enquanto a tela está aberta é mais uma leitura, e a página de preços diz que
um listener que reconecta depois de mais de 30 minutos offline é cobrado como uma consulta nova. Uma
caixa de busca que roda uma consulta a cada tecla é uma consulta por letra, cada uma cobrada pelo
menos uma leitura mesmo quando não devolve nada. Nada disso é caro no tamanho da Quitanda; cada um é
um multiplicador, e a conta é o produto dos multiplicadores.

**E o emulador não cobra nada e não conta nada.** Nem as leituras que uma consulta teria cobrado nem as
entradas de índice que ela leu ficaram visíveis nesta aula, porque o emulador não produz as métricas
do Query Explain. No Google Cloud elas são a entrada desta conta, ao lado da página de uso do console;
aqui, a conta é feita a partir da página de preços e das consultas que dá para contar à mão.

---
title: Capacidade, edições e a slot-hora
version: 1
---

**A cobrança por capacidade cobra a computação em vez dos bytes.** Você deixa de pagar por TiB lido e
paga por **slot-hora**: um slot, uma CPU virtual, por uma hora. Uma consulta que lê 2 TiB com um filtro
simples e uma que lê 2 GiB com cinco joins podem custar o contrário do que o sob demanda cobraria
delas, porque o que se cobra é o quanto os slots trabalharam, não o quanto leram. Tudo nesta seção vem
da página de preços, lida em 2026-10-30, e da documentação do Google sobre edições e reservas. Nada
disso roda aqui: reservas, atribuições e compromissos não têm emulador nem plano de controle neste
laboratório.

## Três edições

**A capacidade é comprada numa de três edições**, Standard, Enterprise e Enterprise Plus, e a edição
define tanto o preço de uma slot-hora quanto os recursos que uma consulta rodando nela pode usar. Estes
são os preços sem compromisso para São Paulo:

| southamerica-east1 | USD por slot-hora | por slot, num mês de 730 horas |
|---|---|---|
| Standard | 0,062 | 45,26 |
| Enterprise | 0,093 | 67,89 |
| Enterprise Plus | 0,155 | 113,15 |

**A coluna mensal é da própria página**, e é o preço por hora vezes 730. Cem slots por um mês inteiro em
cada edição:

```
ana@laptop:~/gcp$ python3 -c 'print(100 * 730 * 0.062, 100 * 730 * 0.093, 100 * 730 * 0.155)'
4526.0 6789.0 11315.0
```

**4.526, 6.789 e 11.315 USD por mês** por cem slots que nunca param. Ninguém paga isso por capacidade
que não usa, e a próxima seção é como a conta acompanha o trabalho.

**As edições diferem no que uma consulta pode fazer**, e a documentação de edições do Google lista as
diferenças recurso por recurso. Duas estão na própria página de preços. **Compromissos só são vendidos
para Enterprise e Enterprise Plus**, então o Standard é sem compromisso e nada mais. E **o BigQuery ML
é oferecido em capacidade pelo Enterprise e pelo Enterprise Plus**. O Standard é o slot mais barato e o
mais limitado, feito para um time que roda SQL comum e quer um teto previsível para isso.

## Reservas e atribuições

**Slots são comprados para dentro de uma reserva, e uma reserva é ligada a projetos por uma
atribuição.** Uma reserva é um grupo nomeado de capacidade numa região e numa edição:
`quitanda-etl`, Enterprise, em `southamerica-east1`. Uma atribuição diz de quais projetos as
consultas tiram dela. Um projeto sem atribuição continua sob demanda. Então a escolha do modelo é feita
por projeto, e uma empresa pode deixar as analistas sob demanda e pôr as transformações noturnas em
slots.

No Google Cloud, a reserva e a atribuição são dois comandos, mostrados aqui como você os digitaria e
não rodados:

```sh
bq mk --reservation --location=southamerica-east1 --edition=ENTERPRISE \
  --slots=0 --autoscale_max_slots=200 quitanda-etl
bq mk --reservation_assignment --location=southamerica-east1 \
  --reservation_id=planner-dev:southamerica-east1.quitanda-etl \
  --job_type=QUERY --assignee_type=PROJECT --assignee_id=planner-dev
```

**`--slots=0` é a baseline e `--autoscale_max_slots=200` é o teto.** Com baseline zero, a reserva não
tem slot nenhum até uma consulta pedir, e nunca tem mais de duzentos. A próxima seção é o que acontece
entre os dois.

## Compromissos

**Um compromisso compra slots por um ou três anos a um preço menor.** A página de preços os lista para
Enterprise e Enterprise Plus, regionais, com no mínimo 50 slots e em passos de 50, renovados
automaticamente a menos que marcados para cancelar. Slots comprometidos viram a baseline das reservas
que os usam, e a página mostra estes preços para São Paulo, sob o título que ela chama de compromissos
de recurso:

| southamerica-east1, USD por slot-hora | sem compromisso | compromisso de 1 ano | compromisso de 3 anos |
|---|---|---|---|
| Enterprise | 0,093 | 0,0744 | 0,0558 |
| Enterprise Plus | 0,155 | 0,124 | 0,093 |

**Um compromisso é um desconto numa hora que você paga, use ou não.** Um ano tira um quinto do preço do
Enterprise, e três anos tiram dois quintos. A página também lista descontos por gasto para o BigQuery,
um esquema separado em que você se compromete com um valor de gasto e não com um número de slots; este
curso não os precifica. Um compromisso compartilhado pela organização também está nas palavras da
página: "There is no need to buy slot commitments for every project."

**A cobrança de slots também tem mínimo.** A capacidade "is billed per second with a one-minute minimum
duration by default", por segundo com mínimo de um minuto, e uma reserva pode aderir ao que a página
chama de fluid scaling, "per-second billing with no minimum duration". Ela também deixa duas coisas de
fora. **A capacidade não cobre armazenamento**, que é cobrado como na aula 13 seja qual for o modelo
das consultas, e não cobre o BI Engine, que a aula 18 precifica.

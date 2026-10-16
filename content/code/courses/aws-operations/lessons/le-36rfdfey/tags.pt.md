---
title: Tags de alocação de custo, e o que elas não fazem depois
version: 1
---

Uma conta chega como um total e uma lista de serviços. Nenhum dos dois diz **de quem** era o dinheiro, e
essa é a pergunta que uma conta precisa responder antes que alguém possa agir sobre ela: uma equipe que
não vê o próprio gasto não consegue reduzi-lo, e um custo sem dono cresce até alguém achá-lo, como mostram
os recursos ociosos da lição 23. A resposta na AWS são as **tags**, e três regras as fazem funcionar para
custo.

**Uma lista curta de chaves, escrita.** A da loja tem três: `owner`, a equipe que responde pelo recurso;
`environment`, `prod`, `staging` ou `dev`; e `service`, aquilo de que ele faz parte. Mais chaves são mais
jeitos de ser inconsistente; três que todo recurso tem valem mais que dez que alguns recursos têm.
`Owner`, `owner` e `team` são três chaves para o sistema de cobrança, então a grafia faz parte da lista.

**Tags são aplicadas onde os recursos são criados.** O Terraform da lição 6 pôs `default_tags` no provider,
e todo recurso que ele criou as levou; um recurso feito à mão no console leva o que a pessoa lembrou. Uma
**tag policy** no AWS Organizations pode impor a grafia de chaves e valores, e uma service control policy
pode recusar a criação de um recurso sem elas; os dois são recursos de organização que o laboratório não
tem.

**Uma tag conta para custo só depois de ativada, e só dali em diante.** No console de cobrança, ou com
`update-cost-allocation-tags-status`, uma chave vira uma **tag de alocação de custo**, e a partir daí a
conta e o Cost Explorer podem agrupar por ela. **A ativação não é retroativa**: os custos do mês passado
foram registrados sem a tag e continuam assim. Uma equipe que ativa `owner` em março vê donos a partir de
março, e é por isso que as chaves se ativam no dia em que a lista é escrita, e não no dia em que alguém
pergunta.

```
ana@laptop:~/aws/owners$ aws ce update-cost-allocation-tags-status --cost-allocation-tags-status TagKey=owner,Status=Active 2>&1 | grep -m1 ERROR
aws: [ERROR]: An error occurred (500) when calling the UpdateCostAllocationTagsStatus operation (reached max retries: 2): <!doctype html>
```

O moto não tem dados de cobrança, então a ativação é um 500 aqui; na AWS ela leva até um dia para aparecer
no Cost Explorer. A AWS também cria algumas tags sozinha, `aws:createdBy` entre elas, que podem ser ativadas
do mesmo jeito e dizem que identidade criou um recurso, útil quando a tag `owner` falta.

---
title: Uma resposta de questionário é uma afirmação até algo sustentá-la
version: 1
---

Toda resposta no `providers.json` veio do fornecedor. Algumas apontam para algo que a Tarefa pode ler e
cobrar do fornecedor; outras são só o que o fornecedor disse. O `--evidence` lista as respostas que
**atendem um requisito sem nada por trás**:

```
ana@lab:~/guard$ guard vendor --evidence
provider-a  OUT  should 4/4  unbacked 1  fails incident_hours = 72
            unbacked: SHOULD exit_deletion
provider-b  OUT  should 2/4  unbacked 0  fails training = true
provider-c  in   should 3/4  unbacked 5
            unbacked: MUST training
            unbacked: MUST retention_days
            unbacked: SHOULD subprocessors
            unbacked: SHOULD pinning
            unbacked: SHOULD exit_deletion
```

O `provider-c` passa em dois dos seus MUSTs só com a própria palavra. Ele diz que não treina com dados
de clientes e que guarda prompts por 30 dias, e nenhuma das duas afirmações está em documento algum
que a Tarefa tenha. São exatamente as duas respostas em que a decisão se apoia, então **antes de
assinar, as duas entram no contrato** como cláusulas, e a coluna de evidência muda de `null` para o
número de uma cláusula. Um fornecedor que não aceita escrever o que disse no questionário respondeu
outra pergunta.

Os SHOULDs sem evidência importam menos e ainda merecem uma linha na decisão: a promessa do
`provider-c` de apagar tudo no fim do contrato, sem respaldo, é a promessa de que a Tarefa vai precisar
no dia em que sair.

## Quanto vale cada tipo de evidência

- **Uma cláusula de contrato** obriga o fornecedor, e descumpri-la é algo sobre o que a Tarefa pode
  agir.
- **Um relatório de auditoria** é uma parte independente dizendo que os controles existiram durante um
  período. Vale ler o período e o escopo, porque um relatório sobre o sistema de cobrança do fornecedor
  não diz nada sobre onde os prompts são guardados.
- **Uma página no site do fornecedor** descreve a prática de hoje, e o fornecedor pode mudá-la amanhã
  sem avisar ninguém. É melhor que nada e menos que uma cláusula.
- **Uma conversa de vendas** não é evidência.

## Uma avaliação envelhece

Fornecedores mudam seus termos, suas regiões e seus subprocessadores. A avaliação é repetida **pelo
menos uma vez por ano, e sempre que o fornecedor anunciar uma mudança nos termos**, rodando a mesma
lista contra as respostas novas. E a saída é planejada no primeiro dia, não no último: que versão de
modelo o assistente fixa, como os dados são apagados e confirmados, e para onde a Tarefa iria. **Um
fornecedor de que a Tarefa não consegue sair é um fornecedor cujo próximo aumento de preço a Tarefa não
consegue recusar**, e essa é uma questão de segurança tanto quanto comercial, porque o dia em que um
fornecedor deixa de atender um MUST é o dia em que sair precisa ser possível.

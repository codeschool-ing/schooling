---
title: Dado pessoal sensível
version: 1
---

Alguns dados pessoais podem ferir muito mais a pessoa se vazarem, forem mal usados ou usados para
decidir sobre ela. A LGPD os lista no **artigo 5º, II**: dado pessoal sobre

- origem racial ou étnica;
- convicção religiosa;
- opinião política;
- filiação a sindicato ou a organização de caráter religioso, filosófico ou político;
- **saúde** ou vida sexual;
- dado genético ou biométrico,

*quando vinculado a uma pessoa natural.* Essa lista é fechada — a lei não deixa uma empresa decidir
que outra coisa é "sensível" para fins legais — e tudo o que está nela é tratado com mais rigor:
menos bases legais (aula 7), mais cuidado, consequências mais pesadas quando dá errado.

## Na Ipê

Uma farmácia mora dentro do quarto item. `health.prescriptions` é dado de saúde por qualquer
leitura: quem recebeu receita de quê, de qual médico, quando. Essa tabela foi posta num schema
próprio no laboratório desde o começo, e as aulas 1 e 2 mantiveram todo papel fora dela. Mas uma
lista de *tabelas* sensíveis é a parte fácil.

**Dado sobre saúde é dado de saúde em qualquer tabela em que esteja.** A próxima seção o acha numa
tabela chamada `sales.order_items`, que ninguém pensaria em proteger como um prontuário, e a seção 9
o acha digitado em chamados de suporte. O teste da lei é o que o dado *revela*, não onde ele está
arquivado.

## Biometria e genética

A Ipê não coleta nenhuma das duas, e a maioria dos times de dados nunca vai coletar — até um
fornecedor oferecer "entre com o seu rosto" ou um parceiro mandar um conjunto de dados de bem-estar.
As duas estão na lista, as duas são difíceis de mudar se vazarem (uma senha se troca; uma digital,
não), e as duas merecem uma conversa com o encarregado antes de a primeira linha ser guardada.

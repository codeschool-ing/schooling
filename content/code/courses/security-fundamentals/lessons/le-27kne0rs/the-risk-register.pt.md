---
title: O registro de riscos
version: 1
---

Tudo o que esta aula fez até aqui precisa morar em algum lugar, ou mora na memória de uma pessoa e
vai embora com ela. **O registro de riscos é o documento que guarda os riscos da organização, as
notas, os tratamentos e os donos**, e é a primeira coisa que um auditor pede para ver.

É uma tabela. Uma planilha basta para uma loja de nove pessoas; organizações maiores usam uma
ferramenta, e as colunas são as mesmas. Uma linha do registro da loja, escrita por inteiro:

| campo | R1 |
|---|---|
| id | R1 |
| descrição | um criminoso varrendo a internet entra no portal da equipe com a senha padrão de instalação e lê a folha de pagamento |
| ativo | folha de pagamento (confidencialidade) |
| dono | bruno, financeiro |
| probabilidade × impacto inerentes | 4 × 4 = 16 |
| tratamento | mitigar |
| controles | senha única; MFA; portal alcançável só da rede do escritório |
| probabilidade × impacto residuais | 1 × 4 = 4 |
| aceito por, em | bruno, 2026-09-14 |
| próxima revisão | 2027-03-14 |
| situação | controles no lugar |

Três colunas carregam a maior parte do valor.

**A descrição é uma frase, não uma palavra.** "Portal" não é um risco. A cadeia da aula 2, ameaça,
vulnerabilidade, ativo e impacto, é o que permite a alguém, daqui a seis meses, entender o que se
quis dizer e conferir se ainda é verdade. Se o portal for refeito depois com outro login, a frase
diz na hora se esta linha ainda vale.

**O dono é uma pessoa.** "TI" ou "diretoria" não respondem a pergunta nem assinam decisão.

**A data de revisão é uma promessa.** Riscos se mexem: a loja começa a aceitar pedidos por telefone,
uma lei nova muda o impacto de um vazamento, um controle que funcionava deixa de ser mantido. Um
registro escrito uma vez e arquivado é a foto de uma loja que não existe mais. A loja revisa o
registro a cada seis meses e sempre que algo grande muda, e tanto as funções do NIST da aula 15
quanto o sistema de gestão da ISO da aula 14 tornam essa revisão uma exigência, e não um hábito.

### O que um registro não é

Não é uma lista de vulnerabilidades saída de um scanner. Um scanner produz achados, e o achado mais
grave numa máquina que ninguém usa não chega nem perto do topo desta tabela. Achados alimentam o
registro quando criam ou mudam um risco; a maioria nunca vira linha.

Também não é o registro de tudo o que poderia acontecer. Um registro com quatrocentas linhas é um
que ninguém lê. A habilidade é a que esta aula praticou: escrever os riscos que importam como
frases, ordená-los, decidir, assinar e voltar a eles.

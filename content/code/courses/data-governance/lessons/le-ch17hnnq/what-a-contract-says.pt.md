---
title: O que um contrato diz
version: 1
---

Um contrato de dados útil responde às perguntas que um consumidor faria de outro jeito por mensagem,
uma de cada vez, com meses de intervalo:

| parte | a pergunta | exemplo |
|---|---|---|
| **esquema** | que campos, de que tipos? | `items`, um `bigint` |
| **semântica** | o que cada campo significa? | unidades pedidas, e não linhas |
| **qualidade** | o que está garantido sobre os valores? | todo CEP tem o formato `00000-000` |
| **atualidade** | quando fica pronto, e cobrindo o quê? | até as 6h, os pedidos do dia anterior |
| **dono** | quem responde por ele? | o chefe de vendas (aula 9) |
| **privacidade** | que dado pessoal, com que base, guardado por quanto tempo, onde? | classes da aula 6; art. 7º, V; 30 dias; Brasil |
| **versão** | que versão da promessa é esta? | `1.0.0` |

As quatro primeiras são o que a engenharia de dados costuma chamar de contrato. As três últimas são o
que este curso acrescenta, e não são extras opcionais: um conjunto de dados pessoais mandado a outra
empresa **é** um compartilhamento de dados pessoais, e o contrato é onde a finalidade, a base e a
retenção ficam escritas para as pessoas dos dois lados.

## Formatos para ele

Não existe um formato obrigatório. Alguns times usam JSON Schema ou esquemas Avro para a primeira parte
e um documento para o resto. O **Open Data Contract Standard** (ODCS), mantido sob a Linux Foundation,
põe tudo num documento YAML só, com nomes de campos combinados, que ferramentas conseguem ler. O
laboratório usa JSON simples com as mesmas ideias, para o verificador da seção 5 ser curto o bastante
para ler inteiro.

O que importa mais do que o formato são duas propriedades:

- **o contrato mora num repositório**, versionado, revisado como código, perto do que quer que produza
  o dado;
- **uma máquina o confere** contra o que é servido de fato, toda vez que um dos dois muda. Um contrato
  lido só por pessoas é documentação, e documentação se desatualiza.

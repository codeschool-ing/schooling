---
title: Deixando a coluna de fora
version: 1
---

O instinto é razoável: se o modelo não deve decidir por idade, não mostre a idade a ele. O nome disso é
**justiça por desconhecimento** (*fairness through unawareness*), e a segunda tabela do `by_age.py` mostra
o que ela fez aqui.

**Ela deixou os assinantes mais jovens em situação pior.** Com a idade no modelo, 26,7% dos jovens que
saíram receberam crédito; sem ela, 19,4%. Os assinantes jovens saem mais por motivos que os dados só
capturam pela idade, então um modelo que não vê a idade deixa de reconhecer parte deles, e o crédito que
poderia tê-los segurado vai para outro lugar. Se o crédito é um benefício, e é, tirar a coluna tirou um
benefício justamente do grupo que se queria proteger.

**E ela não tirou a idade.** O modelo sem a coluna continua tratando as faixas de forma diferente; ele
moveu créditos dos jovens para os velhos, porque outras colunas andam junto com a idade e o modelo lê
essas no lugar dela. Essas colunas são **proxies**, e a próxima seção mede quanto da idade elas carregam.

Nada disso quer dizer que a idade deva estar em todo modelo. Quer dizer que **usar ou não uma
característica protegida é uma decisão sobre resultados, não sobre colunas**, e tem de ser tomada olhando
o que cada escolha faz com cada grupo. Três posições se defendem, e servem a situações diferentes:

- **Deixar de fora e aceitar o que os proxies carregam**, quando usá-la seria ilegal ou inaceitável, como
  seria na maioria das decisões de crédito, contratação ou seguro.
- **Deixar fora do modelo e guardar para medir**, para que as tabelas desta aula continuem podendo ser
  impressas. Sem a coluna, ninguém consegue verificar se um modelo trata um grupo de forma diferente.
- **Usar, abertamente e por um motivo declarado**, quando a decisão beneficia o grupo e o motivo aguenta
  ser dito em voz alta: *assinantes mais jovens saem mais, então recebem mais créditos de retenção.*

A posição do meio é a que esta aula recomenda como padrão. Uma empresa que apaga a coluna protegida dos
seus dados não tornou o modelo justo; tornou-se incapaz de descobrir.

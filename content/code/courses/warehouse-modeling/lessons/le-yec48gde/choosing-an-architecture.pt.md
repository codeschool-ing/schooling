---
title: Escolhendo uma arquitetura, e defendendo a escolha
version: 1
---

Esta lição e as três anteriores descreveram vários jeitos de organizar o mesmo warehouse: uma estrela central, um
núcleo normalizado com marts dependentes, marts independentes, um lakehouse em camadas medalhão, uma mesh de produtos
por domínio. Não são degraus de uma escada, e o mais novo não é o melhor. Cada um responde a uma pergunta sobre a
organização tanto quanto sobre os dados.

- **Quantos times produzem dados de que outros precisam?** Um ou dois: um warehouse central é mais simples, e uma
  mesh acrescentaria uma plataforma e um processo de governança para coordenar pessoas que já sentam juntas. Dezenas: o
  time central vira o gargalo, e a mesh existe para esse problema.
- **Os times que produzem dados conseguem assumir a publicação?** A propriedade por domínio pede que times de produto
  rodem pipelines, mantenham contratos e respondam pela qualidade. Um time que não consegue gente para isso vai
  publicar algo pior do que um time central teria construído.
- **Existe uma plataforma em que se apoiar?** Sem armazenamento compartilhado, catálogo e conferência de contratos
  rodada pela plataforma, "propriedade por domínio" são cinquenta marts independentes com outro nome.
- **Quais são os números que precisam bater?** Onde quer que dois departamentos informem a mesma medida à mesma
  diretoria, a definição precisa ser conformada, seja quem for o dono do pipeline. A matriz de barramento é o jeito
  mais barato de ver onde estão.

Para a Ponto Final, a resposta é curta. Uma pessoa de dados, sete lojas, um site: **uma estrela central, com marts
dependentes feitos de views**, e os dois marts independentes aposentados assim que seus números forem conciliados e
nomeados. Uma mesh seria uma plataforma com um cliente só.

::: track software-architecture
A discussão é a mesma que a lição 2 de `architecture` tem sobre microsserviços, e se decide do mesmo jeito. Uma mesh
divide a plataforma de dados pelas fronteiras dos times, então funciona onde os times já estão divididos e custa onde
não estão; a lei de Conway atravessa os dois casos. Registre a decisão como a lição 20 de `architecture` registra
qualquer outra, com as alternativas e as medições: os três números de dezembro desta lição são exatamente a evidência
de que um registro de decisão de arquitetura precisa.
:::

::: track *
Seja qual for a escolha, registre a decisão por escrito, com aquilo com que foi comparada e com as medições. Os três
números de dezembro desta lição são o tipo de evidência que encerra uma discussão assim: mostram quanto custam marts
independentes, em centavos, em vez de afirmar.
:::

A modelagem fica onde está em tudo isso. **Toda arquitetura desta lição termina em fatos e dimensões** que alguém
precisa projetar com um grão, chaves conformadas e histórico, e esse projeto é o que as lições 2 a 6 ensinaram. A
arquitetura decide quem o constrói e onde ele mora. A lição 12 trata da parte de que todas precisam e que a maioria
pula: escrever o que cada coluna significa.

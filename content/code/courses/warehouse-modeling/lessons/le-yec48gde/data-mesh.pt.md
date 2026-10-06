---
title: Data mesh
version: 1
---

Tudo até aqui supõe que um time constrói o warehouse. Numa empresa do tamanho da Ponto Final, isso é verdade e faz
sentido. Numa empresa com cinquenta times de produto, cada um com seus sistemas, o time central de dados vira a fila
em que toda pergunta espera: ele precisa entender cada origem, e as pessoas que entendem cada origem estão em outros
times, ocupadas com outro trabalho.

**Data mesh** é uma proposta para essa empresa. Zhamak Dehghani a apresentou em 2019, num artigo no site de Martin
Fowler, e depois num livro, *Data Mesh* (O'Reilly, 2022). Ela se apoia em quatro princípios:

- **Propriedade por domínio.** O time que toca uma parte do negócio é dono dos dados que essa parte produz, inclusive
  dos dados analíticos. O time de pedidos publica os pedidos; ninguém mais adiante os reconstrói a partir de uma
  extração.
- **Dados como produto.** O que um domínio publica é tratado como um produto com usuários: documentado, confiável,
  versionado, com alguém que responde por ele. A próxima seção trata do que isso significa na prática.
- **Uma plataforma de autosserviço.** Armazenamento, pipelines, catálogo, controle de acesso e monitoramento são
  oferecidos por um time de plataforma, para que cada domínio publique um produto de dados sem virar ele mesmo um
  time de infraestrutura de dados.
- **Governança computacional federada.** As regras que todo produto precisa seguir, como nomes, dimensões conformadas
  e classificação de dados pessoais, são combinadas em conjunto e **impostas por código na plataforma**, não por uma
  reunião de revisão.

Posta ao lado deste curso, a mesh é menos uma ruptura do que parece. A matriz de barramento da seção anterior é
governança federada numa página: as dimensões compartilhadas são a parte com que todos concordam, e cada linha pode
ter um time diferente como dono. O que a mesh muda é **quem constrói cada linha**: o domínio, em vez de um time
central que precisa aprender cada domínio, um após o outro.

O que ela não muda é a modelagem. Um domínio que publica vendas ainda precisa declarar um grão, escolher suas
dimensões e guardar o histórico de um cliente; a mesh desloca esse trabalho, não o elimina. O quarto princípio existe
porque, sem ele, cinquenta times produziriam cinquenta marts independentes, e a seção 4 mostrou aonde isso leva.

---
title: Escolher, e o que não depende da escolha
version: 1
---

Cinco jeitos de construir a mesma coisa já apareceram: o SDK do provedor com um driver de banco (aula
9), LangChain e LlamaIndex (aula 10), Haystack e RAGFlow (esta aula). A comparação que importa não é
qual recupera melhor. Medida com o mesmo teste, toda biblioteca deste curso ficou a poucas perguntas
do índice da aula 5 depois que as configurações foram escolhidas para o acervo, porque o resultado
pertence às configurações e as configurações pertencem ao acervo. As diferenças estão no que cada uma
facilita, no que torna visível e no que deixa para a equipe cuidar.

| | o que é | mais forte em | o que conferir primeiro |
| --- | --- | --- | --- |
| SDK e driver | umas cem linhas suas | toda decisão à vista, nada entre você e a requisição | que você escreveu as partes que as aulas 4 a 8 mediram |
| LangChain | uma biblioteca de peças ligadas em cadeias | conectores para quase qualquer armazenamento e provedor | tamanho do divisor, entrada do cliente de embeddings, ids, o sentido de uma nota |
| LlamaIndex | uma biblioteca construída em torno de um índice | técnicas de recuperação prontas: janelas, junção, motores de citação | para onde os clientes apontam, o prompt padrão |
| Haystack | uma biblioteca de componentes tipados num grafo declarado | pipelines conferidos ao serem montados e guardados como arquivos | a política de duplicatas, ids que incluem metadados |
| RAGFlow | uma aplicação de servidor com interface web | documentos difíceis, pessoas que não são desenvolvedoras | onde o acervo passa a morar, quem pode ver o quê |

Três perguntas costumam decidir, nesta ordem.

**Quem constrói e muda?** Um pipeline dentro de um produto, mudado pelos desenvolvedores dele, atrás
das permissões dele, é código: o SDK, ou uma das três bibliotecas. Uma base de conhecimento que um
time de atendimento alimenta e consulta por conta própria é uma aplicação, e escrever uma do zero para
não implantar o RAGFlow é um projeto à parte.

**Quais são os documentos?** Markdown e HTML precisam de um divisor e de algum cuidado. Contratos
escaneados e PDFs com tabelas precisam de um leitor, e é aí que uma aplicação construída em torno da
leitura paga os servidores, ou que uma equipe acrescenta uma etapa de leitura antes da biblioteca que
escolheu.

**Quanto pode ficar escondido?** As citações da aula 7, os filtros da aula 6 e os ids da aula 5 são
as partes que tornam uma resposta conferível. Qualquer ferramenta serve onde elas estão visíveis e são
definidas pela equipe, e nenhuma serve onde elas são padrões que ninguém leu.

## O que não depende da escolha

Seja qual for, isto continua igual, e é o resto deste curso:

- o conjunto de teste da aula 8, rodado de fora da ferramenta, antes e depois de toda mudança;
- o que entra no prompt e em que ordem, que a aula 12 mede;
- o histórico da conversa e o que é lembrado entre um turno e outro, aula 13;
- quem pode recuperar qual documento, aula 14, que é uma propriedade dos dados e nunca do padrão de
  um framework;
- o que é resumido e o que é mantido, aula 15;
- manter o texto de uma tarefa fora de outra, e texto de fora fora das instruções, aula 16;
- e quanto custa cada consulta, aula 17.

As aulas 12 a 16 são escritas com o SDK puro e o banco, para que nada esconda o que elas medem. Cada
uma pode ser construída dentro de qualquer uma das ferramentas acima, e o teste é como você saberia
que foi construída direito.

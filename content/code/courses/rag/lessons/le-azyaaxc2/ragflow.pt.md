---
title: RAGFlow, um pipeline que se instala
version: 2
---

As três bibliotecas até aqui são código que uma equipe importa. **O RAGFlow é uma aplicação que uma
equipe roda.** É um motor de recuperação de código aberto sob a licença Apache 2.0, mantido pela
InfiniFlow, e vem como um conjunto de servidores: uma interface web onde as pessoas sobem documentos
e conversam com eles, uma API para programas, e o armazenamento por trás dos dois. Este curso não o
roda, e o motivo faz parte da aula. O README dele em outubro de 2026 recomenda começar com 4 núcleos
de CPU, 16 GB de memória e 50 GB de disco, com Docker. A pilha que ele sobe inclui um motor de
busca (Elasticsearch, ou o Infinity, da própria InfiniFlow), MySQL, MinIO para os arquivos, e uma fila
de mensagens e um cache ao lado. É o dobro da memória da máquina virtual que a aula 1 recomenda, e mais maquinário do que
uma equipe acrescenta sem decidir.

O que segue é o que o projeto diz que faz, e o que cada afirmação quer dizer diante das decisões que
este curso tomou à mão. Tudo aqui muda mais depressa que o resto do curso; confira com a documentação
atual antes de depender de qualquer parte.

## Em torno do que ele é construído

**Ler documentos difíceis.** A parte do RAGFlow chamada DeepDoc faz análise de layout, OCR e
reconhecimento de tabelas. É o problema que este curso pôde deixar de lado, porque os documentos da
Marginalia são Markdown que um programa lê linha por linha. Um acervo real costuma ser PDFs em duas
colunas, contratos escaneados e planilhas coladas como imagem, e o texto que um leitor tira disso é o
texto com que todo passo seguinte trabalha. Uma tabela lida como uma sequência de células, ou uma nota
de rodapé lida no meio de um parágrafo, não tem conserto em nenhum tamanho de pedaço.

**Cortar por modelo.** Em vez de um divisor com um tamanho, um conjunto de dados no RAGFlow é
configurado com um modelo para o seu tipo de documento, entre eles artigos, livros, leis, pares de
pergunta e resposta, e tabelas. Cada modelo guarda o que a aula 4 teve de descobrir: uma lei é cortada
pelos artigos, uma tabela pelas linhas, uma lista de perguntas e respostas pelos pares. É o "seguir a
estrutura do próprio documento" da aula 4, decidido por tipo de documento por pessoas que olharam
muitos deles.

**Pedaços que uma pessoa pode ver e corrigir.** A interface mostra como cada documento foi cortado e
deixa uma pessoa editar um pedaço, acrescentar palavras-chave a ele ou desligá-lo. A aula 5 só mudava
o índice rodando de novo um programa sobre os arquivos de origem; aqui uma pessoa muda o índice
diretamente. Isso conserta um pedaço ruim em um minuto, e também quer dizer que o índice deixa de ser
derivado só dos documentos, de modo que a próxima leitura daquele documento precisa manter a edição ou
perdê-la.

**Respostas com as referências.** Uma resposta no chat mostra em quais pedaços se apoiou, e quem lê
pode abri-los. É a citação da aula 7, embutida na tela.

## O que muda para a equipe

Tudo o que as aulas anteriores deste curso disseram continua valendo, e parte disso muda de lugar:

- **O acervo mora em outro sistema.** Documentos, pedaços e vetores ficam no armazenamento do
  RAGFlow, e não no banco da equipe. A pergunta da aula 14, quais documentos esta pessoa pode ver, tem
  de ser respondida dentro do próprio modelo de usuários e conjuntos de dados do RAGFlow, e um pedido
  de exclusão tem de chegar até ele.
- **O teste continua sendo da equipe.** A API do RAGFlow responde perguntas, então o `eval.jsonl` da
  aula 8 pode rodar contra ela de fora, do mesmo jeito que o `frameworks.py` mediu duas bibliotecas.
  Nada num produto com tela torna a recuperação dele certa para os seus documentos.
- **Uma atualização é uma implantação.** Atualizar uma biblioteca muda um arquivo de travas;
  atualizar uma aplicação muda um serviço em execução, o formato do armazenamento e possivelmente a
  leitura dos documentos, ou seja, todo pedaço. Rode o teste depois dela como depois de qualquer outra
  coisa.

O RAGFlow serve a uma equipe cujos documentos são a parte difícil, PDFs, escaneados e tabelas, e
cujos usuários não são desenvolvedores: um time de atendimento que precisa subir um manual e
fazer perguntas a ele hoje à tarde. Serve menos onde o pipeline é parte de um produto, atrás das
permissões do produto e dentro do banco dele, que é o caso que este curso vem construindo.

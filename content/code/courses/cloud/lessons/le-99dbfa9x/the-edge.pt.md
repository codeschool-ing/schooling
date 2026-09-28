---
title: A borda não é uma região
version: 1
---

Redes de distribuição de conteúdo anunciam centenas de locais, e a conclusão fácil é que um provedor
com centenas de locais tem centenas de lugares para rodar a sua aplicação. **Um local de borda não é
uma região.** É um site pequeno, muitas vezes um rack de máquinas dentro do datacenter de outra pessoa
ou de um ponto de troca de tráfego, posto perto de onde os usuários estão. Ele faz duas coisas bem:
guarda cópias de conteúdo e roda pedaços pequenos de código. Ele não guarda o seu banco de dados, e
não oferece o catálogo de serviços que uma região oferece.

Esses sites têm vários nomes: pontos de presença, edge locations, network locations. A rede de
distribuição de conteúdo da AWS é o CloudFront, e o valor `GLOBAL` no `ip-ranges.json`, contado antes
nesta lição, trazia 118 blocos marcados `CLOUDFRONT`: endereços que não pertencem a nenhuma região em
particular, porque respondem de muitos lugares ao mesmo tempo.

## Para que a borda serve

**Um cache perto do usuário transforma uma viagem longa numa curta**, para tudo o que é igual para
todo mundo. Uma imagem, uma folha de estilo, um script, um trecho de vídeo, uma página que não muda
por usuário. O primeiro pedido de um arquivo num local de borda volta à **origem**, a região onde a
sua aplicação roda de fato, e a borda guarda a resposta. Todo pedido seguinte de usuários perto
daquele local é respondido pela cópia, a uma viagem curta, até a cópia expirar.

Ponha um número nisso com o piso. Um usuário em São Paulo carregando um site cuja origem está na
Virgínia espera pelo menos 76,6 ms por arquivo que o navegador precisa buscar na origem, sem cache. Se
houver um local de borda em São Paulo, as imagens e os scripts voltam da mesma cidade, e só o que é
pessoal daquele usuário faz a viagem longa.

**A borda também roda código.** A lição 8 apresentou os Cloudflare Workers, funções que rodam nos
locais da rede da Cloudflare em vez de numa região. Eles são bons em trabalho que não precisa de dados
de longe: redirecionar por país, verificar um token assinado, reescrever um cabeçalho, escolher que
versão de uma página servir. O pedido do usuário é tratado a uma distância curta do usuário, e nada
cruza o continente.

## O que fica na região

**O seu sistema de registro fica numa região**: o banco de dados, a fila, os arquivos que são a
verdade do próprio negócio. Eles precisam do que uma região tem e um local de borda não tem: zonas para
sobreviver à falha de um prédio, armazenamento durável, um lugar onde a promessa de residência de
dados da lição 2 pode ser cumprida. Plataformas de borda vendem armazenamento próprio, e se algum
serve é pergunta para os cursos de fornecedor; o ponto desta lição é que a borda é onde ficam cópias e
código pequeno, não onde fica a verdade.

Essa divisão tem uma armadilha, e é a armadilha da seção sobre idas e voltas. Código na borda que
precisa do banco tem que voltar à região para buscá-lo. Suponha que uma função de borda em Fortaleza
trate um pedido consultando um banco na Virgínia cinco vezes, uma consulta após a outra: **o usuário
economizou uma viagem curta e a função gastou cinco longas.** Medida de ponta a ponta, essa página é
mais lenta do que se o pedido tivesse ido direto a um servidor ao lado do banco, que teria feito as
suas cinco consultas por alguns metros de cabo.

Então a regra da borda é a regra da lição inteira, aplicada mais uma vez: deixe juntas as partes que
conversam muito. Conteúdo estático e código que não precisa de nada de longe pertencem à borda. Código
que conversa com o banco muitas vezes pertence ao lado do banco, na região, e o trabalho da borda para
esses pedidos é repassá-los depressa.

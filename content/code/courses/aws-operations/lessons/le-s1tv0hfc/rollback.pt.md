---
title: Reverter, e a única coisa que isso não desfaz
version: 1
---

Um rollback no blue/green leva o listener de produção de volta ao target group azul, e acontece de
três jeitos: **um alarme do grupo entra em `ALARM`**, o deploy falha sozinho (um hook relata falha, o
verde nunca fica saudável), ou **uma pessoa o interrompe** com `stop-deployment
--auto-rollback-enabled`. Em todos os casos o tráfego volta para tarefas que atendiam alguns minutos
antes e nunca pararam. Nada disso foi executado aqui; o moto não roda deploy nenhum.

Essa rapidez é real, e cobre menos do que as pessoas supõem. **Um rollback move tráfego. Ele não move
dados.** O que o 1.4.1 gravou enquanto atendia continua gravado, e o 1.4.0 precisa conseguir ler.

## O banco de dados é a parte difícil

O caso comum é uma mudança de esquema. O release 1.4.1 renomeia a coluna `customer_name` para `name`
no mesmo deploy que passa a usá-la. O canário sai, o alarme dispara, o tráfego volta para o 1.4.0, e
o 1.4.0 pede `customer_name`, que não existe mais. **O rollback funcionou e o serviço está fora**,
agora nas duas versões.

A saída é nunca liberar uma mudança que a versão anterior não sobreviva. Uma renomeação vira três
releases, no padrão chamado **expand and contract**:

1. **expandir**: acrescentar a coluna nova e gravar nas duas; o código antigo ignora a coluna nova;
2. **migrar**: copiar os valores antigos e passar as leituras para a coluna nova;
3. **contrair**: quando nenhuma versão em execução ler a coluna antiga, removê-la.

Em cada passo, a versão anterior ainda consegue rodar contra o banco como ele está, então cada passo
pode ser revertido. A mesma regra vale para mensagens numa fila, arquivos num bucket e o formato de
uma resposta de API: **um release precisa aceitar o que o release anterior produz, e produzir o que o
release anterior aceita**.

## A configuração faz parte da versão

Um rollback restaura a task definition antiga, que nomeia a imagem antiga, e é por isso que a lição 2
deixou as tags imutáveis. Ele não restaura um parâmetro do Parameter Store, o valor novo de um
segredo nem uma feature flag que alguém trocou na mesma hora. **O que muda com um release deve viajar
dentro dele**, na task definition, ou ser mudado num passo separado que possa ser revertido sozinho.

## Depois de um rollback

O rollback encerra a primeira fase do incidente e começa a segunda: descobrir o que deu errado
enquanto a versão antiga carrega o tráfego. O registro do próprio deploy guarda qual alarme o
interrompeu e em que fatia, e esse registro é a primeira linha da linha do tempo que a lição 13
monta.

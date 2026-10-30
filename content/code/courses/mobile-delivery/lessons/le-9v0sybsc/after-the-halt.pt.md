---
title: O que uma interrupção faz, e o que ela não faz
version: 1
---

**Interromper uma liberação impede que a versão ruim chegue a mais alguém. Ela não faz nada por
quem já a tem.** Na simulação, 1011 instalações ficam com a 1.5.0 depois da interrupção, e cada
uma continua quebrando até que uma versão que não quebra chegue a ela. A interrupção é o primeiro
passo de um incidente, e não o fim dele.

## A sequência, da interrupção à correção

1. **Interrompa** o rollout no Google Play, **pause** o phased release na App Store.
2. **Ache a causa** nos relatórios de crash, agrupados por versão e por aparelho. A lição 13 lê as
   pilhas de chamadas; a lição 14 trata dos travamentos que não são crashes.
3. **Gere a 1.5.1** com a correção, ou com o código da 1.4.0, e um version code maior.
4. **Libere a 1.5.1 depressa**: uma revisão acelerada do lado da Apple, lição 6, e uma liberação que
   pode andar rápido porque é o remédio. A primeira etapa dela vai para quem tem a 1.5.0.
5. **Retome a liberação com a 1.5.1**, e não com a 1.5.0.

## As pessoas que já estão na versão ruim

No Google Play, um release interrompido continua instalado onde está. Na App Store, quem atualizou à
mão durante o phased release também o tem. **Nada nas duas lojas entra num celular e troca uma
versão.** O que chega a elas é a próxima atualização, que só chega quando o celular atualiza, e
muitos celulares só atualizam apps no Wi-Fi e na tomada, ou nem atualizam sozinhos.

É por isso que a lição 19 existe. Uma **chave remota**, lida pelo app na abertura, pode desligar o
recurso quebrado nos 1011 celulares em minutos, se ela foi construída antes de a 1.5.0 sair. Uma tela
de **atualização forçada** pode pedir a quem está na 1.5.0 que atualize quando a 1.5.1 estiver no ar.
Nenhuma das duas pode ser acrescentada depois à versão que já está quebrada.

## A regra que fica

**Todo release que chega à produção é liberado em etapas, todos, inclusive os pequenos.** O bug da
1.5.0 estava numa mudança que alguém chamou de trivial. Uma liberação que fosse direto a 100% o teria
posto em vinte mil celulares até a noite; a escalonada o pôs em 1011, e parou.

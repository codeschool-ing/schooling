---
title: Pacote: por que os dados vão picados
---

Nada atravessa a rede inteiro. Um vídeo de 2 GB é cortado em milhares de **pacotes**, cada um com um pedaço do conteúdo e um cabeçalho dizendo de onde veio e para onde vai.

A razão é de convivência: se um arquivo grande viajasse em bloco, ele ocuparia o caminho até terminar e todo o resto esperaria. Picado, os pacotes de várias conversas se intercalam, e uma transferência longa não impede uma curta de passar.

A outra razão é a falha. Um pacote perdido custa reenviar alguns kilobytes; um arquivo perdido custa reenviar o arquivo. E como cada pacote sabe seu destino, cada um pode tomar um caminho diferente — se um trecho da rede cai no meio da transmissão, os seguintes desviam sem que a conversa recomece.

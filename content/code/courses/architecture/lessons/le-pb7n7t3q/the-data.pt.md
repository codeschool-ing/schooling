---
title: Os dados são a parte difícil
version: 1
---

O serviço de estoque do laboratório começou com os mesmos números do monólito porque os dois guardam doze
pacotes em memória. Um de verdade não escapa tão fácil. O estoque mora no banco do monólito, os outros
módulos do monólito podem lê-lo com um join, e no momento em que o serviço novo recebe escritas, há dois
lugares achando que são donos do número de pacotes de café.

Mover os dados é a parte de uma migração strangler que mais demora, e há uma sequência padrão para isso,
cada passo reversível:

1. **Tornar o módulo o único caminho de entrada**, ainda dentro do monólito. Todo outro módulo que lê as
   tabelas de estoque diretamente é mudado para chamar a interface do módulo de estoque. O monólito
   modular da aula 2 é o ponto de partida que deixa esse passo curto. Fowler chama a técnica de pôr uma
   interface na frente de alguma coisa antes de substituí-la de **branch by abstraction**.
2. **Dar ao serviço novo uma cópia**, mantida atualizada a partir do banco do monólito por captura de
   mudanças (*change data capture*; o Debezium lendo o log de escrita antecipada é a ferramenta de
   costume) ou por eventos de um outbox, da aula 7. O serviço responde leituras da sua cópia; o monólito
   ainda recebe as escritas.
3. **Mover as leituras** pela fachada, uma parte de cada vez, como o laboratório fez. A cópia é uma cópia
   da aula 9, então uma leitura logo depois de uma escrita pode estar velha por um instante.
4. **Mover as escritas**, que é o passo que muda quem é dono dos dados. Daqui em diante o serviço novo é
   o dono e as tabelas do monólito são a cópia, mantida em dia na outra direção enquanto alguma coisa no
   monólito ainda as ler.
5. **Parar a cópia e apagar as tabelas antigas**, quando nada as ler.

O que todo passo evita é **escrever nos dois bancos a partir da aplicação**, a escrita dupla: duas
escritas sem transação em volta, que a aula 7 mostrou que um dia vão dar certo de um lado e falhar do
outro, em silêncio.

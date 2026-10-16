---
title: Como o trabalho é feito, para que se possa confiar nele
version: 1
---

As lições técnicas deste curso tratam do que mudar num servidor. Esta seção trata de como, porque a
mesma mudança feita sem cuidado e feita bem diferem exatamente do jeito que importa às três da
manhã. Seis hábitos atravessam o resto do curso; cada um é barato, e cada um é algo que o curso faz
na sua frente em vez de só contar.

**Leia o log primeiro.** Antes de reiniciar qualquer coisa, antes de procurar na internet, leia as
últimas linhas do log do servidor. O PostgreSQL diz o que está errado em frases simples mais vezes
do que as pessoas esperam, e a lição 3 já mostrou onde encontrá-lo.

**Meça antes e depois.** Uma mudança feita "para melhorar o desempenho" sem um número antes e um
número depois é um palpite com consequências. Quando uma lição muda um ajuste, ela mostra a medição
dos dois lados, e a medição é o que você guarda.

**Mude por arquivos, não pela memória.** Um ajuste digitado numa sessão e esquecido é um servidor
que ninguém consegue refazer. A lição 5 mostra onde uma mudança deve ficar, e a lição 23 põe os
arquivos sob controle de versão para que a configuração do servidor tenha histórico como qualquer
código.

**Ensaie numa cópia.** Qualquer coisa que não se desfaz em um minuto — um upgrade, uma mudança de
esquema grande, uma configuração que exige reinício — é feita antes num lugar onde não importa. A
lição 20 cria um segundo cluster só para ensaiar um upgrade nele.

**Diga o que vai fazer.** Um reinício, uma migração e uma manutenção longa caem, cada um, na aplicação
de outra pessoa. Avisar quem depende do servidor, antes e depois, custa uma mensagem e economiza um
incidente.

**Anote o que fez.** A hora, o comando, o que ele imprimiu. Durante um incidente essa é a diferença
entre uma explicação e uma reconstrução, e a lição 24 transforma isso num documento.

## Por que estes, e não esperteza

Nenhum dos seis exige talento, e é por isso que estão aqui. Um administrador de banco de dados recebe
a confiança do único sistema que uma empresa não refaz com facilidade, e essa confiança vem mais de
ser previsível do que de ser esperto: a mudança foi avisada, medida, reversível e anotada. O
conhecimento técnico profundo do resto do curso deixa você capaz de fazer o trabalho; esses hábitos
tornam seguro deixar você fazê-lo.

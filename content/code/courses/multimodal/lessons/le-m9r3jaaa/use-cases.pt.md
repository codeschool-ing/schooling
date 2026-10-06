---
title: Onde ela se paga num produto
version: 1
---

A forma útil de organizar casos de uso multimodais não é por setor, e sim por **direção**: o que entra e o que sai. Cada direção tem uma família de produtos, um motivo que paga o custo e um jeito característico de falhar.

| direção | produtos que a usam | o que paga o custo | como falha |
|---|---|---|---|
| imagem → texto | ler notas fiscais e recibos, conferir uma foto enviada pelo cliente, texto alternativo para um catálogo | uma pessoa digitava o que a imagem diz | um dígito mal lido que parece plausível |
| áudio → texto | transcrição de ligações, atas de reunião, busca por voz, legendas | ninguém consegue buscar ou passar os olhos numa gravação | um nome ou um número ouvido como outra coisa |
| vídeo → texto | busca dentro de vídeos, resumos, moderação | uma pessoa teria de assistir tudo | o que aconteceu entre duas imagens amostradas |
| texto → imagem | ilustração, banners, protótipos de produto | precisa-se de uma imagem mais rápido do que alguém desenha | texto dentro da imagem, mãos, contagem, semelhança com pessoas |
| texto → áudio | menus telefônicos, leitura em voz alta, audiolivros, agentes de voz | senão alguém teria de estar na linha | números e nomes lidos errado, demora antes de falar |
| áudio → áudio | tradução ao vivo, assistentes de voz | a conversa precisa manter o ritmo | tudo acima, sem transcrição para conferir |

Duas colunas merecem uma segunda olhada.

**"O que paga o custo" é sempre o tempo de uma pessoa.** Cada linha substitui alguém olhando, ouvindo, digitando ou falando. Esse também é o teste para saber se um caso de uso é real: se ninguém ia fazer o trabalho à mão, automatizá-lo é um custo sem economia por trás. Uma loja que recebe quatro notas fiscais por mês não precisa de um modelo de visão; uma que recebe quatrocentas talvez precise.

**"Como falha" quase nunca é um travamento.** É um valor errado que se lê como certo. Por isso, daqui em diante, toda aula põe a saída de um modelo ao lado da verdade conhecida e conta a diferença. O laboratório consegue isso porque a mídia dele foi feita a partir de um roteiro. Um produto real faz isso com uma amostra conferida à mão, e a conta é a mesma.

## Os casos de uso que este curso deixa de fora

Algumas direções ficam de fora de propósito. Imagens médicas, rostos usados para identificar pessoas e qualquer coisa que decida sobre alguém pela voz ou pela aparência carregam um peso legal e ético além do que um curso intermediário consegue tratar com honestidade, e no Brasil dado biométrico é dado pessoal sensível pela LGPD. Robótica e modelos que agem numa tela olhando para ela também ficam de fora. O que fica é o conjunto de tarefas que uma equipe pequena de produto constrói toda semana.

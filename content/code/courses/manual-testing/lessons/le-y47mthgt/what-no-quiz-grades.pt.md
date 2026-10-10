---
title: O que nenhum quiz daqui consegue corrigir
version: 1
---

As perguntas no fim desta aula conseguem conferir muita coisa. Podem perguntar se *alguns* é uma
palavra vaga, se falta uma pré-condição, se um passo esconde duas ações, e podem corrigir a
resposta. **Elas não conseguem conferir se um caso que você escreveu pode ser executado por um
estranho**, e essa é a habilidade de que esta aula trata. Nada neste curso consegue corrigi-la, e
esta seção diz isso com todas as letras em vez de escondê-lo atrás de perguntas sobre desenho de
casos.

O motivo está na definição. Um caso passa no teste do estranho quando um estranho o executa e não
precisa perguntar nada. O único instrumento que mede isso é um estranho. Uma pergunta tem gabarito,
escrito de antemão, e o seu caso não existia quando o gabarito foi escrito. Uma máquina lendo o seu
caso poderia achar *alguns* e *correto*, do jeito que a tabela da seção 03 faz. Não poderia dizer
que *a conta de sempre* é clara para você e para mais ninguém, porque ela não sabe o que você sabe.

Então a verificação fica por sua conta. Leva uma hora e uma outra pessoa, e é a hora mais útil desta
aula.

## Entregue a alguém

**Escreva os casos.** Pegue dois cenários que a aula 2 não cobriu e escreva um caso para cada, na
forma do TC-BOOK-04: um estudante que reserva dois ingressos para Hamlet paga meia (R5), e cancelar
um pedido reservado devolve os lugares dele (R6). Deduza cada resultado esperado dos requisitos
antes de executar qualquer coisa. Depois execute cada um você mesmo, lendo na página, como fez a
seção 05.

**Encontre um estranho.** Alguém que nunca viu o boxoffice: um amigo, alguém que mora com você, um
colega de outro time. Não precisa saber nada de teste, e é melhor que não saiba, porque um testador
preenche lacunas por hábito. Uma chamada de vídeo com a sua tela compartilhada funciona tão bem
quanto uma cadeira ao seu lado.

**Entregue o caso e mais nada.** Reinicie o boxoffice para a pré-condição valer, abra o navegador no
seu computador ou no dele, e passe o caso. Não explique para que serve, não resuma, e não mostre como
o formulário funciona.

**Depois fique calado.** Esta é a parte difícil. Quando ele hesitar, quando perguntar, quando fizer
algo que você não quis dizer, anote e não responda. Se ele empacar, diga para fazer o que ele acha
que o caso quer dizer, e anote isso também. Cada resposta que você dá em voz alta é um buraco no
caso que você acabou de esconder de si mesmo.

**Compare.** Quando ele terminar, peça o veredito dele, passou ou falhou, e compare com o seu.
Depois compare o que ele fez com o que você quis dizer: o espetáculo que ele escolheu, o número que
digitou, onde procurou o resultado.

## O que fazer com o que você anotou

**Toda pergunta que ele fez é um defeito do caso**, e também todo lugar onde ele fez algo diferente
do que você quis dizer, mesmo que o veredito tenha saído igual. Corrija-os no caso, nunca numa
explicação. Depois entregue o caso corrigido a um estranho **diferente**, porque o primeiro já sabe
as respostas e não consegue mais achar os buracos.

Dois casos sem nenhuma pergunta de um estranho que nunca tinha visto o boxoffice é a linha de
chegada. A maioria das primeiras tentativas recebe três ou quatro perguntas cada, e as perguntas se
repetem: a mesma palavra vaga, o mesmo estado faltando. Essa repetição é a parte útil. É uma lista
dos seus próprios hábitos, e o próximo caso que você escrever vai ser lido com essa lista em mente.

## Quando não há ninguém para quem entregar

Há uma verificação mais fraca para os dias em que não há ninguém por perto: **a leitura a frio**.
Guarde o caso por três ou quatro dias, tempo bastante para esquecer os detalhes. Depois reinicie o
boxoffice, feche os requisitos e execute o caso fazendo exatamente o que cada linha diz e nada que
ela não diga. Onde você precisar parar e pensar no que quis dizer, o estranho teria perguntado.

Ela é mais fraca porque você não consegue esquecer tudo o que sabe, e as palavras que só são claras
para você são justamente as que continuam claras. Ainda assim é muito melhor do que reler o caso
logo depois de escrevê-lo, o que não confere nada: naquele momento toda palavra quer dizer o que
você quis dizer.

## Por que esta aula pesa tanto

A trilha `qa` é julgada por essa habilidade mais do que por qualquer outra. Um relatório de
defeito, o assunto da aula 15, é um caso que outra pessoa precisa executar para ver a falha. Um
teste de aceitação, a aula 12, é um caso que o cliente executa. E os cursos de automação que vêm
depois deste transformam casos em programas, onde o estranho é um script que não pode perguntar nem
adivinhar. Um caso que sobrevive a uma pessoa que nunca viu a aplicação é um caso que pode virar
programa, ir para as mãos de um cliente ou ser anexado a um relatório. **O quiz abaixo corrige se
você reconhece os defeitos. O estranho corrige se você consegue evitá-los**, e só a nota do estranho
conta.

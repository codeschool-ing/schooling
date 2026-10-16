---
title: Palavras que fazem o estranho perguntar
version: 1
---

A maior parte das perguntas da seção 02 veio de um punhado de palavras. *Alguns*, *um membro*,
*correto*, *bem-sucedida*: cada uma é curta, cada uma soa natural, e **cada uma é uma promessa de
que o leitor já sabe o que quem escreveu quis dizer**. Quem escreveu sabe, então a palavra parece
acabada de onde ele está. O estranho não sabe, e a palavra vira uma pergunta ou um chute.

As palavras são previsíveis o bastante para serem procuradas. Um caso pronto é um caso que foi lido
uma vez só para encontrá-las.

## As palavras, e o que as substitui

| palavra no caso | o estranho pergunta | o que escrever no lugar |
|---|---|---|
| alguns, uns, vários | quantos? | `3` |
| um espetáculo, qualquer espetáculo | qual? | The Little Prince |
| um membro, um usuário, a conta de teste | que conta, em que estado? | `member@example.org`, confirmada |
| válido, inválido | segundo que regra? | nome `Ana Lima`, que o R2 permite |
| correto, certo, adequado | segundo o quê? | R$ 81,00 |
| conferir, verificar, garantir | conferir o quê, onde? | a linha de The Little Prince mostra 197 em Seats left |
| funciona, bem-sucedido, OK | como isso aparece? | um pedido fica reservado, no estado reserved |
| um erro, uma mensagem adequada | que frase, dizendo o quê? | uma frase dizendo que o e-mail já tem conta |
| etc., e assim por diante | o que mais? | liste o resto, ou apague a palavra |
| como sempre, do jeito normal | o sempre de quem? | os próprios passos |

Toda substituição da terceira coluna é algo que o estranho encontra numa tela ou digita num campo.
Esse é o teste de uma substituição: **ela tem de ser um valor ou uma observação, nunca outra palavra
que precise de explicação.** *Preço correto* trocado por *o total certo* mudou a pergunta de lugar e
a manteve.

## Resultados esperados dizem onde olhar

As palavras vagas fazem mais estrago no resultado esperado, porque é ali que o veredito é decidido.
*A página deve estar correta* pede que o estranho saiba o que é correto. *A reserva está
confirmada* pede que ele saiba onde uma confirmação apareceria, e no boxoffice isso pode ser uma
mensagem na página Order ou um e-mail na caixa de saída.

**Um resultado esperado observável cita um lugar e uma coisa que deve estar lá.** A página Order, e
as palavras `State: reserved`. A página Shows, e o número em Seats left. A caixa de saída, e um
e-mail endereçado a `ana@example.org`. Um estranho que recebe um lugar e uma coisa não tem nada a
interpretar: está lá ou não está.

Quando um resultado é um número, ele é escrito do jeito que a aplicação o escreve. O boxoffice
mostra `R$ 81,00`, com vírgula antes dos centavos, e um caso que diz *81.00* entregou ao estranho
mais uma coisa para traduzir.

## Passos dizem o que fazer, uma coisa cada

Um passo que junta ações esconde onde o conjunto deu errado. *Preencha o formulário e envie* são
quatro ações no formulário de reserva do boxoffice, e quando o resultado vem errado o estranho não
consegue dizer qual das quatro foi o problema. **Uma ação por passo**, numerada: digite isto,
escolha aquilo, clique naquilo outro.

Os controles são citados pelo que o estranho vê neles. O botão do boxoffice diz Book, então o passo
diz *clique em Book*. O campo do número de ingressos mostra as palavras Tickets (1 to 6), então o
passo diz *o campo que mostra Tickets (1 to 6)*. Citar o controle pelas palavras dele, e não pela
posição, mantém o caso verdadeiro quando a página é rearrumada.

## O erro oposto

Quando pedem para eliminar toda pergunta, alguns autores vão para o outro lado, e isso também
reprova no teste.

**Escrever o que o estranho já sabe** enterra os passos que importam. *Mova o mouse até a barra de
endereço, clique nela, digite o endereço, aperte Enter* são quatro passos de que o estranho não
precisava, e quando ele chega ao passo que importa já está lendo na diagonal. O estranho da seção 02
sabe usar um navegador, então *abra `http://127.0.0.1:8000/book`* é o passo inteiro.

**Escrever aquilo de que o caso não depende** faz ele falhar por motivos que não são defeitos.
*Clique no botão azul Book, no canto inferior esquerdo do formulário* quebra no dia em que o botão
ficar verde ou for para a direita, enquanto a reserva funciona perfeitamente. *Clique em Book* diz
tudo de que o caso precisa.

A linha entre os dois é a descrição do estranho. Tudo o que ele não teria como saber entra; tudo o
que ele já sabe, ou de que o veredito não depende, fica de fora. Por isso a seção 02 descreveu o
estranho antes de escrever uma palavra de caso: **um nível de detalhe só é certo ou errado para um
leitor em particular.**

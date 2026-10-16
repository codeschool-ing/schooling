---
title: As partes de um caso de teste
version: 1
---

Um caso de teste costuma ser escrito como lembrete para quem o escreveu: *testar a reserva*,
*conferir o desconto*. Isso é uma anotação sobre o que fazer em seguida, e não tem veredito
nenhum. Dois testadores que a seguem fazem duas coisas diferentes, e nenhum dos dois consegue dizer
depois se passou. **Um caso de teste é o conjunto de condições, entradas, ações e resultados
esperados necessários para conferir uma coisa**, escrito de modo que quem o executa chegue ao
mesmo veredito de quem o escreveu.

O veredito é a razão de ser das partes. Um caso passa quando o que aconteceu bate com o que ele
disse que aconteceria, e falha quando não bate. Todo o resto do caso existe para que a comparação
seja justa: que ele comece do lugar certo, use os valores certos e olhe para a coisa certa.

## Os campos

Times e ferramentas dão nomes diferentes aos campos, e a aula 18 mostra quatro ferramentas, cada
uma com seu formulário. Por baixo, quase todo formulário traz os mesmos sete campos, e mais dois
que só são preenchidos quando o caso roda:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 326\" role=\"img\" data-fig=\"l02-case-anatomy\" aria-label=\"Um caso de teste desenhado como um formulário de nove linhas. Sete são escritas antes da execução: id, título, requisito, pré-condição, dados de teste, passos e resultado esperado, e dessas, pré-condição, passos e resultado esperado estão em destaque. Duas são preenchidas quando o caso roda: resultado obtido e status.\"><rect x=\"20.0\" y=\"20.0\" width=\"480.0\" height=\"26.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32.0\" y=\"33.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">id</text><text x=\"180.0\" y=\"33.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">TC-BOOK-01</text><rect x=\"20.0\" y=\"50.0\" width=\"480.0\" height=\"26.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32.0\" y=\"63.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">título</text><text x=\"180.0\" y=\"63.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o que o caso confere, numa linha</text><rect x=\"20.0\" y=\"80.0\" width=\"480.0\" height=\"26.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32.0\" y=\"93.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">requisito</text><text x=\"180.0\" y=\"93.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">R4, R5</text><rect x=\"20.0\" y=\"110.0\" width=\"480.0\" height=\"26.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"32.0\" y=\"123.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">pré-condição</text><text x=\"180.0\" y=\"123.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o estado antes do passo 1</text><rect x=\"20.0\" y=\"140.0\" width=\"480.0\" height=\"26.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32.0\" y=\"153.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">dados de teste</text><text x=\"180.0\" y=\"153.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">os valores digitados e escolhidos</text><rect x=\"20.0\" y=\"170.0\" width=\"480.0\" height=\"26.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"32.0\" y=\"183.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">passos</text><text x=\"180.0\" y=\"183.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma ação cada, numerados</text><rect x=\"20.0\" y=\"200.0\" width=\"480.0\" height=\"26.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"32.0\" y=\"213.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">resultado esperado</text><text x=\"180.0\" y=\"213.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">deduzido do requisito</text><rect x=\"20.0\" y=\"244.0\" width=\"480.0\" height=\"26.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"32.0\" y=\"257.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">resultado obtido</text><text x=\"180.0\" y=\"257.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o que de fato aconteceu</text><rect x=\"20.0\" y=\"274.0\" width=\"480.0\" height=\"26.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"32.0\" y=\"287.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">status</text><text x=\"180.0\" y=\"287.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">passou, falhou, bloqueado, não executado</text><path d=\"M516.0 20.0 L524.0 20.0 L524.0 226.0 L516.0 226.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"534.0\" y=\"116.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">escrito antes da execução,</text><text x=\"534.0\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">com a aplicação parada</text><path d=\"M516.0 244.0 L524.0 244.0 L524.0 300.0 L516.0 300.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"534.0\" y=\"265.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">preenchido quando</text><text x=\"534.0\" y=\"279.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o caso roda</text></svg>", "caption": "Os campos de um caso de teste. As três linhas em destaque carregam o peso; as duas últimas ficam vazias até alguém executar o caso.", "same": ["id", "status"]}
```

Eis um dos casos do boxoffice, com todos os campos preenchidos:

| campo | TC-BOOK-01 |
|---|---|
| id | TC-BOOK-01 |
| título | Um membro confirmado que reserva dois ingressos para Hamlet paga 10% menos |
| requisito | R4, R5 |
| pré-condição | O boxoffice 1.0 está rodando. Hamlet tem 80 lugares livres. A conta `member@example.org` existe e está confirmada. Uma inicialização limpa garante as duas coisas. |
| dados de teste | e-mail `member@example.org`; espetáculo Hamlet; 2 ingressos; Student desmarcado |
| passos | 1. Abra `http://127.0.0.1:8000/book`. 2. Digite o e-mail no campo E-mail. 3. Escolha Hamlet em Show. 4. Digite `2` no campo de ingressos. 5. Clique em Book. |
| resultado esperado | Um pedido fica reservado, com 2 ingressos para Hamlet e 10% de desconto, R$ 144,00 no total, no estado reserved. A página Shows mostra 78 lugares livres para Hamlet. |

**O id** é o nome do caso para tudo que se refere a ele, e a seção 06 desta aula explica por que
ele nunca é uma posição numa lista. **O título** diz numa linha o que o caso confere, para que
alguém percorrendo uma lista de duzentos o encontre. **O requisito** aponta a linha da
especificação que o caso confere, e é isso que transforma o caso em evidência sobre algo que o
teatro pediu.

## Pré-condição, passo, resultado esperado

Três campos carregam o peso, e são os três do título desta aula.

**Uma pré-condição é o que já precisa ser verdade antes do primeiro passo.** Ela descreve estado,
não ação: que versão está rodando, que contas existem, quantos lugares um espetáculo ainda tem. A
conta de membro aparece ali porque o desconto depende dela. Uma conta confirmada tem 10% de
desconto e uma não confirmada não tem, então os mesmos cinco passos dão dois totais diferentes,
dependendo de algo que os passos nem tocam. Uma pré-condição também não é um passo disfarçado.
*Inicie a aplicação* é uma ação; *o boxoffice 1.0 está rodando* é o estado que essa ação produz, e
deixa o testador pular a ação quando o estado já vale.

**Um passo é uma ação do testador**, numerada, na ordem em que é feita. Abrir uma página, digitar
um valor, clicar num botão. Um passo que esconde duas ações, *preencha o formulário e envie*,
esconde o lugar onde a segunda deu errado. A aula 3 trata de escrever passos que outra pessoa
consiga seguir sem perguntar.

**Um resultado esperado é o que a aplicação deve fazer, deduzido do requisito antes de o caso
rodar.** No TC-BOOK-01 ele sai de duas linhas. O R4 diz que um membro pode reservar de 1 a 6
ingressos, então dois ingressos dão um pedido reservado. O R5 diz que um ingresso custa o preço do
espetáculo e que um membro tem 10% de desconto. Hamlet custa R$ 80,00, então dois ingressos são
R$ 160,00, e 10% a menos dá R$ 144,00. Nada disso precisou da aplicação rodando.

Escrito depois, um resultado esperado copia o que quer que a tela tenha dito, e um caso que espera
o que aconteceu nunca falha. **Por isso o resultado esperado é escrito primeiro, a partir do
requisito, e a tela só é consultada quando o caso roda.**

## O que o caso deixa de fora

O TC-BOOK-01 não diz nada sobre a cor do botão Book, o número do pedido ou se a página carrega
rápido. Nada disso é o que este caso confere. Um caso que confere uma coisa dá um veredito que
significa uma coisa: quando o TC-BOOK-01 falha, alguém sabe que deve olhar a reserva e o desconto
de membro, e nada mais. Um caso que também conferisse o layout, o e-mail e a velocidade falharia
por qualquer um de quatro motivos, e seu veredito começaria uma conversa em vez de encerrá-la.

O número do pedido fica de fora por outro motivo, que a seção 04 da aula 3 retoma: ele depende de
quantos pedidos foram feitos antes de o caso começar.

## Preenchido na execução

**O resultado obtido** é o que de fato aconteceu, anotado quando difere do esperado e guardado como
evidência quando importa, uma captura de tela ou uma transcrição. **O status** é o veredito:
passou, falhou, bloqueado ou não executado. A seção 05 desta aula roda os primeiros casos e
preenche os dois.

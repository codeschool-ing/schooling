---
title: A anatomia de um relato de defeito
version: 1
---

Um relato de defeito costuma ser escrito como recado a um colega: *"a reserva quebra quando você
digita letras, dá uma olhada?"* Para quem escreveu, faz todo sentido, porque essa pessoa lembra do
resto. **Um relato é escrito para alguém que não estava lá**: um desenvolvedor na semana que vem,
um testador de outro time, ou você mesmo daqui a três meses, já sem os detalhes. Tudo o que esse
leitor precisa para ver a falha de novo, e para julgar o quanto ela importa, tem de estar na
página, porque a única pessoa que poderia responder às perguntas dele é justamente quem ele está
tentando não interromper.

É o mesmo teste que a aula 3 aplicou a um caso, virado ao contrário. Um caso diz *faça isto e você
deve ver aquilo*. Um relato diz *eu fiz isto, devia ter visto aquilo e vi outra coisa*. Os campos
abaixo são o que essa frase precisa quando é desmontada.

## Os campos

| campo | o que guarda | a pergunta que responde |
|---|---|---|
| **título** | o que falha, onde e em que condição, numa linha | dá para achar de novo numa busca, e distinguir dos vizinhos? |
| **ambiente** | a versão testada, o sistema, o navegador ou cliente, o que foi preparado para o teste | o leitor está olhando para a mesma coisa que você? |
| **pré-condições** | o estado antes do primeiro passo: dados, contas, um início do zero | de onde o leitor parte? |
| **passos** | ações numeradas, uma coisa cada, com os valores exatos digitados | o que você fez? |
| **resultado esperado** | o que devia ter acontecido, e o requisito que diz isso | por que isto é defeito e não gosto pessoal? |
| **resultado obtido** | o que aconteceu, palavra por palavra quando há palavras | o que exatamente está errado? |
| **evidência** | a transcrição, uma linha de log, uma captura de tela | o leitor consegue ver sem rodar nada? |
| **severidade** | quanto estrago o defeito faz | quão grave é? |
| **prioridade** | quando ele deve ser corrigido | em que ordem ele é corrigido? |

As ferramentas de acompanhamento acrescentam campos próprios, um identificador, quem relatou, uma
data, um componente, e a aula 17 mostra como os nove acima se encaixam em quatro delas. Os nove são
a parte que nenhuma ferramenta preenche por você.

Dois deles merecem uma frase cada antes do exemplo. **O título é o que a maioria das pessoas vai
ler do seu relato**: é a linha numa lista de quarenta, o assunto de uma notificação, o texto que
alguém busca antes de abrir um duplicado. "Erro na página de reserva" combina com todo defeito que
a página vier a ter. "Reservar com uma quantidade que não é número inteiro responde 500 com um
traceback do Python" combina com um só. **O resultado esperado cita o requisito**, porque sem ele o
relato é a sua opinião contra a do desenvolvedor, e com ele é o requisito contra o programa.

## Um relato inteiro

A aula 4 descobriu que o boxoffice 1.0 responde a uma palavra no campo de ingressos com uma página
de erro. A versão 1.1 mudou a regra da quantidade e deixou essa linha como estava, então o defeito
continua lá, e a aula 14 acrescentou mais um motivo para se importar: a página mostra o código e os
caminhos de arquivo do programa a quem digitou a palavra. Este é o relato que a Ana escreve, contra
a 1.1:

| campo | |
|---|---|
| título | Reservar com uma quantidade que não é número inteiro responde 500 com um traceback do Python |
| ambiente | boxoffice 1.1 (`/health` responde `ok boxoffice 1.1`), Python 3.13.16, Ubuntu 24.04; reproduzido com curl 8.5.0 e no Chromium |
| pré-condições | boxoffice recém-iniciado, então a conta semeada `member@example.org` existe e nada está reservado |
| passos | 1. Abra `http://127.0.0.1:8000/book?show=S2`. 2. Em E-mail, digite `member@example.org`. 3. Deixe o espetáculo em Hamlet. 4. Na caixa de ingressos, digite `two`. 5. Clique em Book. |
| reprodução em uma linha | `curl -s -o /dev/null -w '%{http_code}\n' -d 'email=member@example.org&show=S2&quantity=two' http://127.0.0.1:8000/book` imprime `500` |
| resultado esperado | o formulário de reserva de novo, com uma frase dizendo que os ingressos devem ser um número de 1 a 6, como recebe a quantidade `7` (R4, R7: entrada errada é respondida com uma frase, nunca com uma página de erro) |
| resultado obtido | status 500; a página é um traceback do Python que termina em `ValueError: invalid literal for int() with base 10: 'two'`, com o caminho do arquivo e os números de linha do programa, e nada da página do teatro em volta |
| reprodutibilidade | sempre; também com a quantidade vazia e com `2.5` |
| evidência | a transcrição e a linha de log do servidor, seção 05 desta aula |
| severidade | maior |
| prioridade | a triagem define, aula 16 |
| encontrado em | 1.0, pela aula 4; ainda presente na 1.1 |

Nada aqui é opinião até a severidade, e mesmo ela tem uma escala por trás, que a seção 04 desta
aula apresenta. Nada aqui chuta a causa, também. O traceback aponta uma linha de código, e o
desenvolvedor vai lê-la lá; um relato que diz *"a chamada int() precisa de um try/except"* começou a
consertar um programa que não é de quem escreveu, e erra tanto quanto acerta.

## O que um relato deixa de fora

**Um defeito por relato.** O traceback e o *"cannot be useed"* com erro de grafia que a aula 11
encontrou são dois defeitos, corrigidos por linhas diferentes, em dias diferentes, talvez por
pessoas diferentes. Num relato só, um deles é corrigido, o relato é fechado e o outro é esquecido
junto.

**Nada de adjetivos sobre o programa ou as pessoas.** *"A reserva está completamente quebrada de
novo"* erra duas vezes: a reserva funciona para qualquer número inteiro, e *de novo* acusa alguém
sem um fato por trás. Quem lê um relato é a pessoa cujo trabalho ele descreve, e um relato escrito
como acusação é lido como acusação e discutido em vez de resolvido.

**Nada de história.** A ordem em que você notou as coisas, o que você queria testar naquela manhã,
o que achou que podia ser: nada disso ajuda alguém a reproduzir a falha, e tudo isso empurra os
passos mais para baixo na página.

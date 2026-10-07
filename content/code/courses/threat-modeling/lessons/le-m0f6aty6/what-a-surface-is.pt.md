---
title: O que é uma superfície de ataque
version: 1
---

Um modelo de ameaças pergunta o que pode dar errado. Uma superfície de ataque faz antes uma pergunta
mais estreita: **por onde qualquer coisa de fora consegue entrar, e por onde qualquer coisa nossa
sai?** Toda ameaça da aula 3 chegou por um desses lugares. Um mapa deles é a lista de onde olhar, e o
tamanho dele é uma das poucas propriedades de segurança de um projeto que dá para contar.

A ideia ganhou forma com Michael Howard, na Microsoft, no começo dos anos 2000, e depois com
Pratyusa Manadhata e Jeannette Wing, na Carnegie Mellon, que definiram a superfície de ataque de um
sistema como três conjuntos:

| | o que é | no portal |
|---|---|---|
| **pontos de entrada e de saída** | os métodos pelos quais dados entram no sistema ou saem dele | o formulário de login, o upload, o handler do webhook, as páginas, a chamada do lembrete |
| **canais** | os jeitos como alguém de fora se conecta a esses pontos | HTTPS a partir da internet, HTTPS a partir dos fornecedores, a rede da clínica |
| **itens de dado não confiável** | os dados que alguém de fora consegue ler ou escrever por eles | os PDFs enviados, os campos do agendamento, o corpo do webhook |

Num diagrama de fluxo de dados, os três já estão desenhados. **Um ponto de entrada é um fluxo que
cruza uma fronteira para dentro do que você roda; um ponto de saída é um fluxo que cruza para
fora.** É por isso que o mapa pode ser calculado a partir do modelo da aula 2, que é o que esta aula
faz.

### Superfície não é risco

Uma superfície maior significa mais lugares para olhar, não mais risco em cada um. Uma página só de
leitura com o horário das clínicas faz parte da superfície e quase ninguém se importa com ela. O
webhook é um ponto de entrada e decide se um agendamento está pago. Então o mapa vem com duas
perguntas por entrada: **quem chega até ela sem credencial, e o que ela consegue mudar?** As
respostas ordenam as entradas, e a segunda parte desta aula encolhe as do topo.

### As partes que ninguém desenha

A superfície também é tudo o que roda com a confiança do seu sistema: as bibliotecas que o portal
importa, os serviços que ele chama, as ferramentas que o constroem e o publicam. Nenhuma aparece como
círculo no DFD, e cada uma é um jeito de o erro de outra pessoa virar problema da Vereda. A seção
sobre dependências as desenha.

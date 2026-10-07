---
title: Quem decide o ritmo
version: 1
---

Um pipeline extrai do sistema de outra pessoa, e **o tipo de sistema decide o que a extração pode
pedir**. A Ponto Final tem os quatro tipos que um pipeline encontra:

| origem | no laboratório | o que você recebe | quem decide o ritmo |
|---|---|---|---|
| **um banco de dados** | o PostgreSQL da loja | qualquer coisa que o SQL saiba perguntar, a qualquer momento | você, dentro do que a origem aguenta |
| **uma API** | a API de preços das editoras | o que os seus criadores escolheram expor, uma página por vez | a API, pelo seu limite de taxa |
| **um arquivo** | o arquivo de estoque da distribuidora | o que foi escrito, quando foi deixado | quem escreve o arquivo |
| **eventos** | o log de cliques do site | tudo o que aconteceu, uma vez ou mais, mais ou menos em ordem | o mundo |

Leia a última coluna de cima para baixo e o controle do pipeline vai sumindo. Com um banco a Ana
escolhe o que ler, quando e quanto. Com uma API ela escolhe dentro de limites que outra pessoa
definiu. Com um arquivo ela espera que ele chegue e pega o que ele traz. Com eventos ela nem escolhe
quando: eles acontecem.

**Cada origem tem uma falha que as outras não têm**, e essa falha é o assunto desta lição:

- um banco lido em dois comandos pode descrever dois momentos diferentes;
- uma API responde com uma página, uma recusa, ou nada;
- um arquivo pode chegar escrito pela metade, ou escrito diferente de ontem;
- um evento pode chegar duas vezes, ou depois de eventos que aconteceram mais tarde.

Nenhuma delas aparece como erro. A leitura rasgada devolve números, o meio arquivo carrega, o evento
duplicado conta. **Esse é o formato do problema no curso inteiro: as falhas perigosas são as que dão
certo.** As seções abaixo produzem cada uma no laboratório, de propósito, para que você já as tenha
visto antes que aconteçam com você.

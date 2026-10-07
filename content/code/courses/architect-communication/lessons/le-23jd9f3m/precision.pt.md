---
title: Precisão: a palavra que pode ser conferida
version: 1
---

**Uma frase precisa é uma que o leitor poderia conferir, e uma frase vaga é uma em que ele precisa
confiar.** Engenheiros são precisos no código porque o compilador exige. Na prosa nada exige, então
as mesmas pessoas escrevem "logo", "lento" e "alguns clientes" e deixam o leitor adivinhar qual era
o número.

O palpite raramente é o número que você tinha em mente. "A migração está quase pronta" quer dizer
dois dias para quem escreveu e duas semanas para quem já ouviu isso antes. Os dois saem da conversa
achando que concordaram.

## Troque o adjetivo pela medida

| vago | preciso |
|---|---|
| logo | até quinta-feira, 19 de março |
| lento | a página de pedidos leva 2,4 s no percentil 95, contra uma meta de 800 ms |
| alguns clientes | cerca de 180 checkouts com falha toda sexta à noite |
| custo significativo | R$ 4.000 por mês em banco de dados, mais seis semanas-engenheiro uma única vez |
| risco alto | se acontecer numa sexta à noite, o checkout para para todo mundo até alguém intervir |
| estamos trabalhando nisso | Bruna está testando a correção em staging; a próxima atualização é às 16:00 |

A coluna da direita é mais longa, e tudo bem. **A precisão gasta palavras onde elas carregam
informação e as economiza onde não carregavam**, que é o assunto da próxima seção.

Nem toda frase precisa de um número. "A correção é simples" é aceitável quando a frase seguinte
mostra a correção. O que importa é que uma afirmação da qual o leitor possa duvidar chegue junto com
aquilo que resolveria a dúvida.

## Preciso sobre o que você não sabe

A incerteza é um fato como qualquer outro e pode ser dita com precisão. "Pode demorar um pouco"
esconde a incerteza. "Entre duas e quatro semanas; o intervalo diminui quando tivermos testado a
migração numa cópia da produção, o que faremos na segunda" diz qual é a incerteza, por que ela existe
e quando vai encolher. A aula 4 constrói um método inteiro sobre isso.

A falha oposta é a **falsa precisão**: "a migração vai levar 13,5 dias" quando a resposta honesta é
um intervalo. Um número com mais dígitos do que a estimativa merece é lido como uma confiança que
você não tem, e o leitor faz planos em cima dele.

## Um nome para cada coisa

A prosa de engenharia tem um hábito que as redações da escola ensinam de propósito: evitar a
repetição trocando a palavra. O banco de pedidos vira "o banco principal", depois "o Postgres",
depois "o primário", depois "o armazenamento central". Um leitor que não conhece o sistema agora acredita que
existem quatro deles.

**Escolha um nome, defina-o na primeira vez e use-o todas as vezes.** Se dois nomes forem mesmo
necessários, diga isso: "o banco de pedidos (o primário PostgreSQL em que o checkout escreve)". É a
versão em prosa de uma regra que esta plataforma aplica aos próprios dados: uma coisa é chamada por
um nome estável, e um segundo nome é uma segunda coisa.

## Palavras que parecem precisas e não são

Algumas palavras têm cara de medida e não carregam nada:

- **"Boa prática"**, que não nomeia nenhuma prática nem fonte. Diga qual prática e por que ela serve
  aqui.
- **"Escalável", "robusto", "moderno"**, que são direções, não propriedades. Escalável até que
  carga, robusto contra que falha, moderno comparado com o quê?
- **"Só"** e **"simplesmente"**, como em "a gente só precisa pôr um cache", que dizem ao leitor que a
  parte difícil não merece menção. Em geral merece.
- **"Obviamente"**, que ou é verdade, e portanto é desnecessário, ou é falso, e portanto ofende o
  leitor que não achou aquilo óbvio.

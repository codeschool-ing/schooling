---
title: Perguntar à pessoa, e guardar as duas até ela responder
version: 1
---

**Quando o mesmo campo mudou dos dois lados, o app mostra à pessoa os dois valores e a deixa
escolher, e até ela escolher nenhum valor é jogado fora.** Essa frase tem duas metades e a segunda
importa mais. Uma tela de conflito que aparece uma vez e esquece as duas versões quando é fechada é a
última escrita vence com um diálogo na frente.

## Quando perguntar

Pergunte só quando a mescla não consegue decidir, e só quando o campo merece a atenção da pessoa.

| situação | o que o app faz |
|---|---|
| campos diferentes mudaram | mescla, não diz nada |
| o mesmo campo mudou para o mesmo valor | mescla, não diz nada |
| o mesmo campo mudou, e o campo é uma configuração | fica o valor do servidor, não diz nada; a regra da aula 13 é a certa ali |
| o mesmo campo mudou, e é algo que a pessoa criou | guarda os dois, e pergunta |

Perguntar demais tem um custo que não aparece num teste. Uma pessoa que vê uma tela de conflito dia
sim, dia não aprende a tocar no botão que a encerra mais rápido, e daí em diante a tela é uma versão
mais lenta da última escrita vence.

## O que a tela mostra

A pessoa precisa do bastante para reconhecer o próprio trabalho. Para o caso do planner da seção
anterior:

- **o que está em conflito, nas palavras dela**: "Violão, quarta-feira, 21 de outubro: quanto
  tempo?";
- **cada valor com onde e quando foi feito**: "30 minutos, no seu celular, 10:05" e "25 minutos, no
  seu tablet, 10:20" — as horas em que as edições foram feitas, registradas por cada aparelho, que é
  o único uso honesto do relógio do aparelho neste assunto inteiro;
- **uma escolha que inclui nenhum dos dois**: escolher 30, escolher 25, ou digitar um terceiro valor.

O que ela escolher é uma edição comum da versão mais nova: o aparelho manda com o número de versão
atual do servidor, exatamente como qualquer outra escrita.

## Onde a segunda versão espera

O valor perdedor fica no aparelho que o tem, numa tabela própria, até ser resolvido: uma linha por
conflito, com o id do registro, o campo, os dois valores, as duas horas e a versão do servidor
contra a qual foram comparados. Ela sobrevive ao app ser fechado, e a sincronização segue para todas
as outras linhas enquanto isso. **Um conflito nunca deve travar a caixa de saída da aula 8**: uma
sessão em disputa não é motivo para as próximas vinte esperarem.

Nenhuma plataforma desenha essa tela por você. O `NSFileVersion` da Apple informa versões
conflitantes de um documento guardado no iCloud Drive, e deixa a decisão para o app; o Android e o
React Native não oferecem nada parecido, então a tabela e a tela são suas nas três.

A aula 15 pega o outro caminho: tipos de dado desenhados para que edições concorrentes sempre se
mesclem, e a pergunta nunca precise ser feita.

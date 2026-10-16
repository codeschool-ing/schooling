---
title: Entre o forte e o eventual
version: 1
---

**"Consistente" não é uma chave de duas posições; é uma escada de promessas, e a maioria dos sistemas
reais fica num degrau entre o alto e o chão.** A imagem errada é um interruptor marcado *forte* e
*eventual*. Ela esconde os degraus que mais importam para quem usa um aplicativo, que são promessas
sobre o que **um** leitor vê, e não sobre o sistema inteiro.

## Quatro degraus que vale reconhecer

Da promessa mais forte, no alto, para a mais fraca, embaixo. As duas do meio não ficam uma acima da
outra; cada uma impede uma surpresa diferente.

| modelo | a promessa | na Roda Livre, ele impede |
|---|---|---|
| **forte** (linearizável) | toda leitura vê a última escrita concluída, como se houvesse uma cópia só | um leitor ver 7 na Rua XV depois que outro leitor ouviu 5 |
| **ler as próprias escritas** | depois que você escreve, as suas leituras veem essa escrita; as de outras pessoas talvez ainda não | ana devolver uma bicicleta e o aplicativo ainda mostrar a viagem dela como aberta |
| **leituras monotônicas** | depois de ver um valor, você nunca mais vê um mais antigo | o mapa mostrar 5, depois 6, depois 5 de novo, conforme cada atualização cai numa cópia diferente |
| **eventual** | se as escritas param, todas as cópias acabam com o mesmo valor | nada sobre o que alguém lê nesse meio-tempo, nem quanto tempo isso dura |

Os dois do meio se chamam **garantias de sessão**, porque são promessas a uma sessão — um celular,
uma conexão — e não a todo mundo. Eles saem bem mais baratos que a consistência forte. Um sistema
consegue dar "ler as próprias escritas" mandando as leituras de uma pessoa para a cópia que recebeu
a escrita dela, ou fazendo uma leitura esperar até a sua cópia ter alcançado essa escrita. Ninguém
mais precisa esperar.

## Eventual promete menos do que parece

"Eventualmente consistente" costuma ser ouvido como "consistente, um instante depois". Diz menos que
isso. Promete que as cópias **convergem se as escritas pararem**; não diz quando, e não diz nada sobre
o que um leitor vê no caminho. A leitura velha da aula 9, de uma réplica que ainda não tinha
alcançado o líder, era a consistência eventual funcionando como especificado.

O que torna agradável de usar um sistema eventualmente consistente costuma ser as garantias de
sessão postas por cima dele. **Uma cliente não percebe que duas cópias discordam; ela percebe quando
uma ação dela parece ter sido desfeita.** É essa a falha que "ler as próprias escritas" impede, e a
razão de ser o primeiro degrau que um time de produto pede.

## Para onde isto vai

Esses quatro bastam para reconhecer as palavras na documentação de um banco e perguntar qual delas
uma operação dá. Há mais degraus — a consistência *causal*, em que um efeito nunca é visto antes da
sua causa, é o próximo que as pessoas encontram — e escolher entre eles para um sistema real é
terreno de `nosql-operations` e de `architecture`.

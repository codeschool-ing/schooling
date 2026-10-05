---
title: Palavras não bastam
version: 1
---

Uma cliente digita *how do I get my money back* ("como recebo meu dinheiro de volta") na central de
ajuda da Marginalia, uma livraria online. A central tem a resposta. É o artigo chamado **When your
refund arrives** ("quando seu reembolso chega"), e em nenhum lugar do título ou do corpo aparecem as
palavras *money back*.

O jeito óbvio de buscar é procurar as palavras que a cliente digitou. Aqui isso é um `grep` sobre os
40 artigos de `data/help.jsonl`:

```
ana@lab:~/emb$ grep -i "money back" data/help.jsonl
{"id": "h18", "category": "returns", "lang": "en", "updated": "2026-01-08", "title": "Returning a gift", "body": "The person who received the gift can return it with the gift receipt and gets store credit for the price paid, without the buyer being told. To get the money back on the original card instead, the buyer has to start the return."}
ana@lab:~/emb$ grep -ci "refund" data/help.jsonl
8
```

**O único artigo que casa é o errado.** Ele fala de devolver um presente, e casou porque a última
frase dele por acaso diz *money back*. Os oito artigos que mencionam reembolso (*refund*) ficaram
invisíveis para a busca, porque a cliente disse *money back* e os artigos dizem *refund*.

## Duas pessoas, dois vocabulários

Esse é o caso comum, não um caso de azar. Quem escreve um artigo de ajuda e quem busca nele
descrevem a mesma coisa com palavras diferentes:

| a cliente digita | o artigo diz |
|---|---|
| money back (dinheiro de volta) | refund (reembolso) |
| the box never showed up (a caixa nunca apareceu) | a parcel marked as delivered that never arrived (um pacote marcado como entregue que nunca chegou) |
| I can't remember my login (não lembro meu login) | resetting your password (redefinir sua senha) |
| make the letters bigger (aumentar as letras) | change the typeface and the size (mudar a fonte e o tamanho) |

Os buscadores lutam contra isso há décadas com truques: listas de sinônimos mantidas à mão, cortar
as palavras até o radical para que *refunds* case com *refund*, correção ortográfica. Cada truque
ajuda um pouco, e cada um é mais uma lista que alguém precisa manter. Nenhum deles sabe que *the box
never showed up* e *never arrived* descrevem o mesmo acontecimento, porque nenhum deles trabalha com
o que as palavras significam.

## O que precisaria mudar

Para achar o artigo do reembolso, a busca teria de comparar o **significado** da pergunta com o
significado de cada artigo, e ordenar os artigos pela proximidade entre os dois. Isso pede duas
coisas que uma lista de palavras não tem:

1. um jeito de transformar qualquer texto em algo comparável, sejam quais forem as palavras;
2. uma noção de *perto* que coloque *money back* perto de *refund* e longe de *delivery times*.

Um **embedding** dá as duas. Ele transforma um texto numa lista de números, um vetor, escolhida de
modo que textos com significados parecidos recebam vetores parecidos. Comparar significados passa a
ser comparar listas de números, coisa que um computador faz muito rápido.

O resto desta aula calcula um embedding, olha o que há dentro dele e mede a proximidade entre alguns
textos. A aula 3 volta à pergunta da cliente e monta a busca que a responde.

---
title: Custo esperado: probabilidade vezes custo de troca
version: 1
---

Um custo de troca é quanto sair custaria **se** você sair. A maioria dos aprisionamentos nunca é
posta à prova: o banco continua funcionando, o fornecedor continua razoável, e o custo de troca
nunca é pago. Então o número a comparar não é o custo de troca em si. É o custo de troca ponderado
pela probabilidade da troca:

> custo esperado = probabilidade de trocar × custo de troca

Nos mesmos três anos que as aulas 8 e 9 usaram, para que os números caibam numa planilha só.

## As duas probabilidades da Coreto

Uma probabilidade de troca é um julgamento, e um julgamento só vale ser escrito com os motivos ao
lado.

**O banco de documentos: 10% em três anos.** Ele funciona, não exige operação, o provedor é
estável, e nada no roadmap do Catálogo pede algo que ele não faça. Os 10% são a chance de uma
dessas coisas mudar: um aumento de preço, um produto que o provedor descontinua, uma necessidade
que aparece. O Davi pediu ao líder do Catálogo que dissesse o que os faria sair, e a resposta foi
"um aumento de preço que a gente não consiga absorver".

**O gateway de pagamento: 35% em três anos.** Pagamentos tem motivos vivos para olhar em volta. As
tarifas do gateway são renegociadas todo ano, e cada negociação termina com a pergunta sobre trocar
ou não. E produto quer Pix parcelado, que o gateway atual ainda não oferece; se não oferecer a
tempo, a Coreto vai ter de ir para um que ofereça. O Mateus pôs um pouco mais de uma chance em três,
e ninguém na sala defendeu menos.

## A planilha

Na sua planilha, como montada na aula 1, acrescente uma aba para os dois aprisionamentos:

| | A | B | C | D |
|---|---|---|---|---|
| 1 | Aprisionamento | Custo de troca | Probabilidade | Custo esperado |
| 2 | Banco de documentos gerenciado | 210000 | 10% | |
| 3 | Gateway de pagamento | 135000 | 35% | |

Em D2 e D3, o custo esperado:

```localised
D2   =B2*C2      21000
D3   =B3*C3      47250
```

**Digite a probabilidade com o sinal de porcentagem.** A seção de problemas da aula 1 fez exatamente
este produto dar errado de propósito: R$ 210.000 multiplicados por uma célula com `10` em vez de
`10%` deram 2.100.000, cem vezes a resposta certa, sem erro nenhum na tela. A defesa é a mesma:
confira uma linha à mão. R$ 210.000 × 10% são R$ 21.000; se D2 mostrar outra coisa, olhe C2.

## Lendo a planilha

**A ordem se inverte.** Pelo custo de troca, o banco é o aprisionamento maior, R$ 210.000 contra
R$ 135.000. Pelo custo esperado, o gateway é mais que o dobro do banco: R$ 47.250 contra R$ 21.000.
Um time preocupado com o maior custo de troca gastaria seu esforço no aprisionamento errado, porque
o aprisionamento com mais chance de ser posto à prova é o gateway.

É para isso que serve a multiplicação. Um custo grande que você provavelmente nunca vai pagar pode
importar menos que um menor que você provavelmente vai, e o custo esperado põe os dois na mesma
escala.

## O que um custo esperado é, e o que não é

A Coreto nunca vai pagar R$ 21.000 para sair do banco. Vai pagar nada, se ficar, ou cerca de
R$ 210.000, se sair. **O custo esperado é um peso para comparar decisões, não a previsão de uma
fatura.** Ao longo de muitos aprisionamentos julgados com honestidade, os custos esperados somam
mais ou menos o que as trocas custam no total; em cada um isolado, o resultado é tudo ou nada.

Daí vêm dois cuidados.

**Olhe o tamanho do custo, além do custo esperado.** Se uma troca custaria mais do que a empresa
conseguiria levantar num ano, uma probabilidade pequena não a torna pequena. Nenhum dos dois casos da
Coreto é tão grande — R$ 210.000 é menos que o ano de um engenheiro, a R$ 264.000 —, mas um
aprisionamento capaz de afundar a empresa merece mais do que uma multiplicação.

**A probabilidade é o número fraco, então diga quão fraco.** Ninguém sabe se a chance do gateway é
exatamente 35%. A pergunta útil é quanto a probabilidade teria de se mover para mudar a decisão, e
isso exige o terceiro número: quanto custaria evitar o aprisionamento. A próxima seção o acrescenta.

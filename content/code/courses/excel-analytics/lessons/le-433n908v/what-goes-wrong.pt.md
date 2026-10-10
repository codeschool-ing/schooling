---
title: Quando as referências quebram
version: 1
---

**Uma referência pode quebrar de três jeitos, e só um deles mostra um erro.** Uma célula para a qual
ela apontava é excluída, e ela diz `#REF!`. Uma fórmula aponta para si mesma, e o Excel reclama uma
vez e depois mostra um número que não quer dizer nada. Ou um número é digitado onde devia haver uma
referência, e nada diz coisa nenhuma. O terceiro é o que custa dinheiro.

## `#REF!`: a célula sumiu

Com J2:J109 guardando `=H2/$L$2` e suas cópias, clique com o botão direito na letra da coluna **L** e
escolha **Excluir**. Toda participação da coluna J vira `#REF!`, e a fórmula de J2 passa a ser
`=H2/#REF!`. O Excel não perdeu o endereço por acaso: a célula que ele citava não existe mais, e não
há nada que ele pudesse pôr ali que fosse verdade. Um nome acompanha as suas células do mesmo jeito,
então se o `TotalRevenue` da seção anterior apontava para L2, o Gerenciador de Nomes agora mostra que
ele também se refere a um `#REF!`.

Tecle **Ctrl+Z** na hora e tudo volta. Depois que o arquivo é salvo e fechado, não há mais como
desfazer, e o único conserto é escrever a referência de novo.

Excluir linhas dentro de um intervalo é outro acontecimento, e mais silencioso. Exclua a linha 50 de
`Sales`, a venda S1049, e o total em L2 passa de `=SOMA(H2:H109)` para `=SOMA(H2:H108)`: o intervalo
encolheu para caber nas linhas que sobraram, e o total cai para **50450**. Nenhum erro, porque nada
quebrou. Uma venda sumiu, e isso pode ser o que você queria, ou não. Desfaça esta também.

## Referência circular: a fórmula conta a si mesma

Ponha um total no pé da coluna que ele soma, em H110:

```localised
=SOMA(H2:H110)
```

O intervalo inclui H110, então o valor da célula depende do próprio valor. O Excel avisa com uma
mensagem da primeira vez, a célula mostra 0, e a barra de status, no pé da janela, mostra
**Referências Circulares** com o endereço da célula. **Fórmulas › Verificação de Erros ›
Referências Circulares** lista todas as células presas numa. O mesmo acontece com `=SOMA(H:H)`
escrita em qualquer lugar da coluna H, que é o jeito mais comum de isso aparecer.

A cura é a regra da aula 1, seção 06: **total mora fora dos dados.** Numa célula ao lado, como L2,
ou depois de um espaço, ou em outra planilha. Apague H110.

O Excel tem uma opção que deixa fórmulas circulares recalcularem em ciclo, **Habilitar cálculo
iterativo**, para o modelo raro que precisa de uma. Uma fórmula que conta o próprio total não é esse
modelo, e a opção esconderia o aviso que acabou de ajudar você.

## Um número onde devia haver uma fórmula

Esta não tem sintoma nenhum, e por isso vale encená-la de propósito. Clique em H50, a venda S1049,
que mostra 1044: 9 sacos de `SUL1K` a R$ 116. Digite `1044` por cima e tecle Enter. Nada muda na
tela, e o total continua 51.494. A célula agora guarda um número em vez de uma fórmula, e essa
diferença é invisível.

Agora suponha que o pedido seja corrigido: eram 10 sacos, não 9. Digite `10` em E50. Com a fórmula,
H50 viraria 1160 e o total, **51610**. Com o número digitado, H50 fica em 1044 e o total fica em
**51494**, faltando R$ 116, e todo relatório feito em cima dele herda o buraco.

Números fixos chegam de dois jeitos. **Um valor colado por cima de uma fórmula**, como acima, em
geral por alguém que copiou uma coluna e usou **Colar Valores** no lugar errado. E **uma constante
enterrada numa fórmula**, como `=ARRED(F2*0,9;0)` escrita em seis células em vez de uma referência a
uma célula com o desconto: quando o desconto muda, alguém precisa achar as seis, e a que escapar dá
um preço antigo sem erro nenhum.

Dois comandos acham esses números:

- **Fórmulas › Mostrar Fórmulas** mostra cada fórmula no lugar do resultado. Numa coluna de cópias
  de `=E2*F2`, um `1044` solto salta aos olhos. Clique de novo para voltar.
- **Página Inicial › Localizar e Selecionar › Ir para Especial**, e depois **Constantes**, seleciona
  toda célula da seleção que guarda um valor digitado em vez de uma fórmula. Selecione H2:H109
  antes; numa coluna Revenue saudável, ele não acha nada.

Ponha de volta `=E50*F50` em H50 e o 9 em E50, e confira que o total voltou a 51.494.

## Antes da aula 3

Fique com a coluna H, `Revenue`; o resto do curso usa essa coluna. As outras coisas que esta aula
criou não serão usadas de novo: limpe J1:J109 e L1:L2 em `Sales`, limpe I1:K7 em `Products` e apague
`TotalRevenue`, `Revenue` e `Discount` no Gerenciador de Nomes. A aula 3 começa as próprias colunas
auxiliares em J. Depois salve.

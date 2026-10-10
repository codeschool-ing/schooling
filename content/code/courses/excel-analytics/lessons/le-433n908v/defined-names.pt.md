---
title: Nomes para intervalos e constantes
version: 1
---

**Um nome definido é uma referência absoluta com uma palavra onde estava o endereço.** `=H2/$L$2`
está certa e não diz nada a quem abrir o arquivo no mês que vem; `=H2/TotalRevenue` é a mesma
fórmula, e diz pelo que está dividindo. Um nome também é absoluto por natureza: aponta para as
mesmas células a partir de qualquer linha, então a fórmula que usa um nome pode ser preenchida em
qualquer lugar sem cifrão.

## Três jeitos de criar um

**Pela Caixa de Nome**, a caixa na ponta esquerda da barra de fórmulas que normalmente mostra o
endereço da célula selecionada. Clique em L2 de `Sales`, clique na Caixa de Nome, digite
`TotalRevenue` e tecle Enter. L2 agora tem um nome, e escolhê-lo na lista da Caixa de Nome seleciona
a célula de qualquer lugar da pasta de trabalho.

**Por Fórmulas › Definir Nome**, que abre uma caixa de diálogo com os campos **Nome** e **Refere-se
a**. Selecione H2:H109 antes e o segundo campo já vem preenchido; dê o nome `Revenue`. **Refere-se
a** mostra `=Sales!$H$2:$H$109`: a planilha, depois o intervalo, com os dois cifrões.

**Para um valor que não mora em célula nenhuma.** Na mesma caixa de diálogo, dê o nome `Discount` e
em **Refere-se a** digite `=0,1`. Nenhuma célula guarda esse valor; a pasta de trabalho guarda.

Depois use os nomes. Troque J2 por esta fórmula e preencha para baixo; as participações são as
mesmas de antes:

```localised
=H2/TotalRevenue
```

Em qualquer lugar de `Sales`, esta responde **51494**, o mesmo total de `=SOMA(H2:H109)`:

```localised
=SOMA(Revenue)
```

E em `Products`, numa célula vazia da linha 2, o preço do `SUL250` com 10% de desconto, **37**, sem
nenhuma taxa digitada na fórmula:

```localised
=ARRED(F2*(1-Discount);0)
```

## O Gerenciador de Nomes

**Fórmulas › Gerenciador de Nomes** (Ctrl+F3 no Windows) lista todos os nomes da pasta de trabalho
com o valor, aquilo a que se refere e o **escopo**. É onde você corrige um nome que aponta para o
intervalo errado e apaga um que ninguém usa. O escopo de um nome é a **pasta de trabalho**, a menos
que você escolha uma planilha ao criá-lo; um nome com escopo de planilha só é conhecido naquela
planilha, o que deixa duas planilhas terem cada uma o seu `Rate`. Deixe na pasta de trabalho até ter
um motivo.

O Excel recusa alguns nomes, e as regras são curtas:

- o primeiro caractere é uma letra, um sublinhado ou uma barra invertida, e **não há espaços**:
  `TotalRevenue` ou `Total_Revenue`, nunca `Total Revenue`;
- um nome não pode parecer um endereço de célula. `Q1`, para o primeiro trimestre, é recusado,
  porque Q1 é uma célula, e `TAX2025` também, porque a coluna TAX existe numa planilha de 16.384
  colunas;
- `C` e `R` sozinhos também são recusados, porque o Excel os usa para a coluna e a linha atuais num
  outro jeito de escrever referências;
- maiúsculas e minúsculas não contam: `revenue` e `Revenue` são o mesmo nome.

## O que um nome custa

Um nome esconde para onde aponta, e isso é ao mesmo tempo a utilidade e o preço dele. Dois hábitos
mantêm o preço baixo.

**Uma constante numa célula é visível; uma constante num nome, não.** `Discount` fica no
Gerenciador de Nomes, onde ninguém olha, e um colega que quer saber por que a grade usa 10% precisa
saber que deve abri-lo. Uma célula com rótulo, `Discount` numa célula e `10%` na seguinte, é vista e
alterada por qualquer pessoa. Use um nome para um valor que não deve mudar à toa, e uma célula para
um que deve ser visto.

**Um nome é um intervalo fixo.** `Revenue` quer dizer H2:H109. No dia em que a 109ª venda da Café
Serra entrar na linha 110, `=SOMA(Revenue)` vai deixá-la de fora, sem erro nenhum. Inserir uma
linha dentro do intervalo amplia o nome; acrescentar uma abaixo dele, não. A aula 7 transforma
`Sales` numa tabela do Excel, que dá nome a toda coluna e cresce com os dados, e essa é a ferramenta
melhor para um intervalo que cresce. Os nomes continuam sendo a ferramenta certa para uma célula só
e para uma constante.

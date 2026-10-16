---
title: Links, cabeçalhos congelados e uma planilha que não quebra por acidente
version: 1
---

**Uma pasta de trabalho que outra pessoa vai abrir precisa de um caminho que não dependa de ela
conhecer as guias.** A `cafe-serra.xlsx` agora tem seis planilhas, e uma delas está oculta. Quem
montou sabe onde está cada coisa. A dona, que abre o arquivo uma vez por mês, vê uma fileira de
guias no pé da janela, talvez cortada, e precisa adivinhar.

## Uma planilha de sumário

Acrescente uma planilha chamada `Contents` e arraste a guia dela para a frente, para que seja a
primeira. Dê a ela uma linha por planilha que o leitor possa querer: um link e uma frase dizendo o
que há lá.

```localised
=HIPERLINK("#Dashboard!A1"; "Dashboard")
=HIPERLINK("#Sales!A1"; "Sales")
```

O `#` quer dizer *um lugar nesta pasta de trabalho*, e o que vem depois é um endereço comum. Clicar
na célula leva até ele. O segundo argumento é o texto que a célula mostra. **Inserir › Link**, com
**Colocar neste Documento**, faz o mesmo salto sem fórmula, se você preferir uma caixa de diálogo.

Depois dê a cada planilha o caminho de volta: um link para `#Contents!A1` no mesmo canto de todas,
para que o leitor nunca precise das guias.

Uma coisa que esses links não fazem é acompanhar uma planilha renomeada. O endereço é texto entre
aspas, e o Excel não reescreve texto quando uma planilha muda de nome, então `#Sales!A1` continua
apontando para uma planilha que não existe mais e o link para de funcionar. **Renomeie as planilhas
antes de escrever os links**, ou confira cada link depois de renomear.

## Cabeçalhos que ficam no lugar

Nas planilhas de dados, os cabeçalhos das colunas somem depois de uma tela de linhas, e quem lê a
linha 80 de `Sales` precisa lembrar qual coluna é `Bags` e qual é `Price`. **Exibir › Congelar
Painéis › Congelar Linha Superior** mantém a linha 1 parada enquanto o resto rola. Em `Customers`,
onde a primeira coluna dá nome à linha, **Congelar Painéis** com **B2** selecionada mantém a linha
de cabeçalho e a coluna A.

O painel não precisa disso, porque cabe numa tela, que é a regra da seção anterior.

## Escondendo a engrenagem

Clique com o botão direito na guia `Calc` e escolha **Ocultar**. O leitor não precisa de quatro
tabelas dinâmicas, e uma planilha que ninguém vê é uma planilha que ninguém edita por engano.
Oculta não é protegida, porém: **Reexibir**, no mesmo menu, a traz de volta, e o próximo passo
trata disso.

## Protegendo o painel de um clique perdido

Um painel com uma célula viva sob o mouse quebra fácil. Um clique e um dígito digitado sobrescrevem
uma fórmula `INFODADOSTABELADINÂMICA` (`GETPIVOTDATA` no Excel em inglês) com um número, e daí em
diante o cartão mostra esse número, diga a segmentação o que disser. A proteção de planilha impede
isso, mas feita na ordem óbvia ela também trava a segmentação.

Antes de proteger, clique com o botão direito na segmentação, escolha **Tamanho e Propriedades** e,
em **Propriedades**, desmarque **Bloqueado**. Faça o mesmo na linha do tempo. Depois, **Revisão ›
Proteger Planilha**, e na lista marque **Usar Tabela Dinâmica e Gráfico Dinâmico** (*Use PivotTable
& PivotChart*), além dos dois tipos de seleção de células. Clique na segmentação em seguida para
ver se ela ainda filtra, porque um painel protegido cujos controles não se mexem parece igualzinho a
um painel sem dados.

**A proteção barra acidentes, não pessoas.** A senha de uma planilha é fácil de remover e não
segura ninguém que queira mudá-la. Pior: todas as linhas de `Sales` e `Customers` estão no arquivo,
ocultas ou não, legíveis por quem tiver o arquivo. Se a pasta de trabalho precisa ser ilegível sem
senha, isso é **Arquivo › Informações › Proteger Pasta de Trabalho › Criptografar com Senha**, e é
outra coisa. A próxima seção trata de quem deveria ter o arquivo.

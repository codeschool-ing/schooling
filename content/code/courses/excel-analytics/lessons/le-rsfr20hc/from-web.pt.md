---
title: Uma página ou um arquivo na web, também descritos em vez de executados
version: 1
---

**Da Web baixa o que estiver num endereço e lê as tabelas que houver ali, e o endereço pertence a
outra pessoa, que pode mudar a página amanhã.** É a fonte mais cômoda desta aula e a menos confiável.

**Esta seção também não foi executada.** Uma consulta a uma página viva daria outra resposta no dia em
que você lesse isto, e o computador do curso não tem Excel para rodá-la. O que segue é o que as caixas
de diálogo pedem e como o resultado quebra.

## Dois tipos de endereço

**Um endereço que termina num arquivo**, um `.csv` ou um `.xlsx` publicado num site, se comporta
exatamente como a seção 03 desta aula: o Power Query baixa o arquivo, e as mesmas escolhas de
delimitador, codificação e localidade valem. Portais de dados abertos do governo, institutos de
estatística e bancos centrais publicam boa parte dos seus dados assim, e esse é o caso confiável,
porque um arquivo publicado costuma manter as colunas de uma edição para a outra.

**Um endereço que é uma página** é o outro caso. O Power Query lê o HTML da página e procura tabelas
nele, o que é cômodo e frágil na mesma medida.

## As caixas de diálogo

**Dados › Obter Dados › De Outras Fontes › Da Web**, que também tem um botão próprio na guia
**Dados** na maioria das versões. A caixa pede a **URL**; **Avançado** deixa montá-la por partes e
acrescentar cabeçalhos, o que só é preciso quando a documentação de um site pede.

Depois vem o **acesso**: para uma página pública, **Anônimo**. Um site que exige login raramente vale a
pena ler assim, e uma página atrás do login de outra pessoa em geral não é sua para baixar.

Então o **Navegador**, que para uma página lista toda tabela que encontrou, chamadas `Table 1`,
`Table 2` e assim por diante, mais `Document`, a página inteira. **Exibição da Web** (Web View) mostra a
própria página, o que ajuda a ver qual das tabelas numeradas é a que você quer. Se os dados da página
não forem uma tabela de verdade, **Adicionar Tabela Usando Exemplos** deixa você digitar os primeiros
valores das colunas que quer, e o Power Query procura o padrão.

## Como ela quebra

Uma página é feita para pessoas lerem, e o dono a rearruma quando quiser. Três coisas acontecem, da
menos à mais perigosa:

- **A página muda de lugar ou some.** A atualização falha, e o erro nomeia o endereço. Chato, e
  inofensivo: você vê na hora.
- **Uma coluna é renomeada.** A etapa que nomeava a coluna antiga falha com um erro dizendo que a
  coluna não foi encontrada, que a seção 07 da aula 14 mostra como ler e corrigir.
- **Uma tabela é acrescentada acima da sua.** `Table 2` agora é outra tabela, as colunas podem até ter
  tipos plausíveis, e a consulta **atualiza sem erro**, sobre os dados errados. Nada avisa; um total
  que mudou de um dia para o outro é o único sintoma.

Esse último é o motivo para preferir um arquivo publicado a uma página e, quando só houver a página,
conferir um número conhecido depois de cada atualização, como a seção 05 da aula 1 conferiu a colagem.

## Níveis de privacidade

Na primeira vez que uma consulta combina uma fonte da web com um dos seus arquivos, o Excel pode pedir
que você defina um **nível de privacidade** para cada fonte: **Público**, **Organizacional** ou
**Privado**. A pergunta existe porque combinar duas fontes pode mandar valores de uma para a outra: um
filtro montado a partir de uma coluna do seu arquivo privado poderia acabar dentro do endereço de uma
requisição a um site público. Marque os seus arquivos como Privado e um site público como Público, e o
Excel mantém os dois separados.

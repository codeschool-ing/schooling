---
title: O que a lei chama de anônimo
version: 1
---

A LGPD dá à anonimização uma definição em duas metades, e as duas importam para um time de dados.

O **artigo 5º, III** define dado anonimizado como o dado relativo a um titular *que não possa ser
identificado, considerando a utilização de meios técnicos razoáveis e disponíveis na ocasião de seu
tratamento*. O **artigo 5º, XI** define anonimização como a utilização desses meios *por meio dos
quais um dado perde a possibilidade de associação, direta ou indireta, a um indivíduo*.

O **artigo 12** tira a consequência: dado anonimizado **não é dado pessoal** para os fins da lei — *a
não ser* que o processo de anonimização seja revertido usando exclusivamente meios próprios, *ou*
que possa ser revertido com esforços razoáveis. O que conta como razoável, diz o primeiro parágrafo
dele, deve considerar fatores objetivos, como custo e tempo necessários para reverter, de acordo com
as tecnologias disponíveis.

Três coisas decorrem disso, e cada uma tem uma seção desta aula por trás.

**Anonimato é uma propriedade que se mede, não um rótulo que se aplica.** "Meios razoáveis e
disponíveis na ocasião" é um teste do que alguém conseguiria de fato fazer. Os pseudônimos MD5 da
seção 8 falham nele em um segundo; a divulgação por data de nascimento, sexo e CEP falha para 5.988
de 6.012 pessoas. Um time que afirma que um conjunto de dados é anônimo deveria conseguir mostrar a
medição.

**Pode deixar de ser verdade.** "Na ocasião do tratamento" quer dizer que um conjunto anônimo hoje
pode virar dado pessoal quando for publicado outro com que ele possa ser juntado, ou quando
computação mais barata tornar razoável uma reversão antiga. Divulgações são reexaminadas, não
certificadas uma vez.

**Pseudonimizado não é anonimizado.** A definição do artigo 13, §4º — a associação se perde *senão
pelo uso de informação adicional mantida separadamente pelo controlador* — descreve exatamente o
dado de que a Ipê tem a chave. O artigo 12, §2º acrescenta que dados usados para formar o perfil
comportamental de uma pessoa identificada também podem ser considerados dado pessoal, que é onde fica
uma exportação analítica de um pseudônimo e de todas as compras.

## O que isso quer dizer na prática

| o que o time tem | o que a lei vê | o que continua valendo |
|---|---|---|
| dado mascarado ou tokenizado | dado pessoal | tudo |
| dado pseudonimizado, chave com a Ipê | dado pessoal | tudo; menor risco é um argumento numa avaliação de risco (aula 7) |
| contagens com células pequenas suprimidas, medidas | muito provavelmente anônimo | nada para as contagens publicadas, enquanto a medição se sustentar |
| linhas "anônimas" que ninguém mediu | dado pessoal até prova em contrário | tudo, mais uma afirmação falsa num aviso de privacidade |

O padrão seguro é o contrário da última linha: **trate tudo como dado pessoal até uma medição dizer
que não é**, e guarde a medição junto com a divulgação.

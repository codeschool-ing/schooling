---
title: "Residência de dados: onde os bytes estão é um fato jurídico"
version: 1
---

Uma região é um lugar, e um lugar tem leis. **Residência de dados** é a pergunta simples de onde um dado
está fisicamente — em que país ficam os discos dele, e os backups, e as cópias — e ela importa porque a
resposta decide quais regras se aplicam. Para dados pessoais de pessoas no Brasil, a regra a ler
primeiro é a LGPD, a Lei Geral de Proteção de Dados (Lei 13.709, de 2018).

## O que a LGPD não diz

A ideia errada é comum e repetida com confiança: *a LGPD exige que os dados pessoais de brasileiros
fiquem armazenados no Brasil*. **Ela não exige.** Não há nela uma exigência geral de localização. O
que ela regula é a *transferência internacional* de dados pessoais, no seu Capítulo V, e o art. 33
começa dizendo que essa transferência só é permitida nos casos que lista. Parafraseando, são eles:

- para países ou organismos internacionais que proporcionem grau de proteção adequado ao da LGPD, o
  que a autoridade nacional, a ANPD, avalia;
- quando o controlador oferece e comprova garantias de que os princípios da lei e os direitos do
  titular serão respeitados, nas formas que o artigo cita: cláusulas contratuais específicas para uma
  transferência, cláusulas-padrão contratuais, normas corporativas globais, e selos, certificados e
  códigos de conduta;
- quando o titular deu consentimento específico e em destaque para a transferência, informado antes
  de que ela é internacional;
- quando ela é necessária para cumprir uma obrigação legal, executar um contrato com o titular ou
  exercer direitos em processo;
- e um grupo de casos mais estreitos: cooperação jurídica internacional entre órgãos de inteligência,
  investigação e persecução; proteção da vida ou da incolumidade física do titular ou de outra pessoa;
  autorização da ANPD; compromisso assumido em acordo de cooperação internacional; e execução de
  política pública.

A ANPD publicou depois um regulamento de transferência internacional, com o texto das cláusulas-padrão
contratuais, na Resolução CD/ANPD nº 19, de 2024. Então **uma transferência para o exterior é lícita
quando cabe num desses casos**, e o trabalho é mostrar em qual. Se um arranjo específico é uma
transferência, e qual caso o cobre, é pergunta para quem responde pela conformidade da organização,
com a lei e o regulamento abertos. Esta aula não responde por você, e a página de marketing de um
provedor também não.

Regras de setor podem acrescentar o que a LGPD não traz. O setor financeiro, por exemplo, tem regras
do seu regulador sobre contratar serviços de nuvem, inclusive no exterior. Onde existe uma exigência
sobre local, ela está em regras assim, e é preciso lê-las no texto delas.

## A região é a alavanca

O que a nuvem dá é um jeito limpo de agir sobre a resposta. **A região que você escolhe é onde o dado
em repouso fica.** Dados pessoais guardados em `sa-east-1` ficam em São Paulo, e para essa cópia a
pergunta da transferência nem aparece.

O erro é parar na cópia principal. Toda cópia é um local:

- um backup replicado para uma segunda região, por segurança;
- logs mandados para um serviço de monitoramento cujos servidores ficam em outro país;
- um engenheiro de suporte no exterior que abre o cadastro de um cliente para corrigir um bug;
- uma rede de distribuição de conteúdo guardando em cache, num ponto distante, uma página com o nome de
  alguém.

Cada uma dessas pode pôr dados pessoais em outro país sem que o banco em si saia do lugar. Um mapa de
para onde os dados vão é o primeiro documento de que a pergunta de conformidade precisa, e é um
documento de engenharia.

Residência tem preço, e a tabela mostra qual. A mesma `t3.medium` custa 0,06720 USD por hora em
`sa-east-1` e 0,04160 em `us-east-1`; armazenamento S3 Standard custa 0,04050 por GB-mês contra
0,02300. Manter dados no Brasil é uma escolha com uma linha na conta, e saber o que a lei de fato
exige é como uma equipe evita pagar por uma obrigação que não existe, ou ignorar uma que existe.
Residência também não é soberania: a seção sobre nuvens soberanas mostrou que onde o dado fica e
quais tribunais o alcançam são perguntas separadas. A aula 9 vai mais fundo em regiões e em como
escolher uma.

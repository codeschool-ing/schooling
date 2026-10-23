---
title: VirusTotal, começando pelo hash
version: 1
---

**O VirusTotal passa um arquivo por várias dezenas de motores de antivírus e outras ferramentas, e
guarda os resultados para todo mundo que procurar o mesmo arquivo depois.** Ele não foi acessado neste
curso, porque o laboratório não tem internet; tudo nesta seção vem da documentação do próprio
VirusTotal, e nenhuma saída é mostrada porque nenhuma foi produzida.

## Busque, não envie

A caixa de busca de virustotal.com aceita um hash além de um arquivo. Buscar o SHA-256 da seção
anterior pergunta "alguém já enviou exatamente este arquivo?" sem mandar o arquivo. Duas respostas são
possíveis:

- **Existe um relatório.** Ele mostra quantos motores apontam o arquivo, quando foi visto pela primeira
  e pela última vez, os nomes com que foi enviado e o que a comunidade disse sobre ele. Nada seu foi
  compartilhado.
- **Nada é encontrado.** O arquivo é novo para o VirusTotal. Isso não é sinal de que é seguro: um
  arquivo escrito para um alvo só, que é o que um ataque direcionado manda, é novo por definição. É o
  ponto em que a ordem da primeira seção decide se este arquivo pode ser enviado.

A mesma consulta pode ser feita por script pela API pública, versão 3, com uma chave pessoal. Esta é a
forma documentada; ela não foi executada aqui:

```sh
curl -s -H "x-apikey: $VT_API_KEY" \
  https://www.virustotal.com/api/v3/files/1f40c2b362d01d064dcc53f20fc9b0a3e624469b810c9c5e7493e02d9be70cce
```

A chave gratuita tem uma cota diária pequena e os termos dela proíbem uso comercial, e é por isso que
empresas que fazem isso todo dia pagam uma licença.

## Lendo a proporção

O número que as pessoas citam é a **taxa de detecção**, tantos motores de tantos. É fácil lê-lo errado
nos dois sentidos:

| leitura | por que engana |
|---|---|
| "0 detecções, então é seguro" | motores detectam o que já viram; um arquivo novo ou direcionado começa em zero |
| "3 de 70, então provavelmente está tudo bem" | os poucos motores podem ser os primeiros a reconhecer uma família nova |
| "2 de 70 no nosso próprio instalador, então é malware" | motores heurísticos apontam empacotadores e instaladores; a aula 7 chamou isso de falso positivo |
| "a taxa era 0 semana passada" | taxas sobem conforme os motores aprendem o arquivo; um relatório é uma foto com data |

**A taxa é evidência, não veredito.** O que torna um relatório útil é o resto dele: os nomes que outras
pessoas deram ao arquivo, quando ele apareceu pela primeira vez, os domínios que ele contata e se os
motores que o apontam concordam sobre o que ele é.

## A linha da privacidade, mais uma vez

Os termos do VirusTotal dizem que o conteúdo enviado pelo serviço público é compartilhado com a
comunidade de segurança, incluindo clientes premium que podem baixar o arquivo. **Um arquivo que é do
escritório ou traz dados de cliente nunca é enviado para lá**, por maior que seja a pressa. Um serviço
pago de análise privada, ou a análise local da aula 12, é para onde um arquivo assim vai.

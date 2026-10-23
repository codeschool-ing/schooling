---
title: urlscan, para um link em vez de um arquivo
version: 1
---

**O urlscan.io abre um endereço web num navegador dele e registra tudo o que aconteceu**: a página como
foi desenhada, cada requisição que ela fez, os domínios e endereços para onde elas foram, os
certificados e os scripts que rodaram. Ele não foi acessado neste curso; esta seção vem da documentação
do urlscan, sem saída mostrada.

A pergunta que ele responde é a que um link levanta: para onde isto leva de fato, e o que a página faz,
sem ninguém do escritório abri-la. Uma página de phishing imitando um banco, um link que redireciona três
vezes antes de chegar, uma página que carrega scripts de um domínio que a aula 14 bloquearia: cada uma
aparece no relatório como algo que dá para ler.

## Busque primeiro, de novo

Como o VirusTotal, o urlscan guarda o que recebe, e outra pessoa pode já ter varrido o mesmo endereço.
A página de busca aceita um domínio, um endereço ou uma URL, e devolve varreduras anteriores com as
datas. **Uma varredura de ontem do mesmo link** responde à maior parte do que uma nova responderia, e não
envia nada.

## Visibilidade

Uma varredura nova tem uma visibilidade, escolhida no envio:

| visibilidade | quem vê o resultado |
|---|---|
| pública | qualquer um, listada na página inicial e na busca |
| não listada | qualquer um com o link, mais os clientes pagantes de segurança do urlscan |
| privada | só a conta que enviou |

**Pública é o padrão para uso anônimo**, e é a opção que vaza. Um link para o compartilhamento de
documentos de um cliente, um link de redefinição de senha ou uma página com o nome de alguém no
endereço, varrido em público, agora pode ser lido por estranhos, e varrê-lo pode até consumir um token
de uso único de que o cliente precisava. Links assim não são varridos de jeito nenhum; um link de um
estranho pode ser, de preferência não listado ou privado.

## O que ler no relatório

- **O endereço final** depois de cada redirecionamento, e se o domínio dele bate com o que o link
  dizia.
- **Os domínios contatados**, que vão para a lista da aula 14 se forem hostis.
- **A captura de tela**, que mostra o que uma pessoa teria visto sem ninguém ser essa pessoa.
- **A idade da página e o certificado**: um certificado emitido ontem para um domínio registrado ontem
  é a forma de um site de phishing, e a última seção desta aula trata da metade do domínio.

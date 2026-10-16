---
title: Entre zonas, regiões e sub-redes
version: 1
---

**Dentro da AWS, para onde os bytes vão decide se eles custam alguma coisa.** Ler o S3 de uma máquina
na mesma região não paga transferência, e só as requisições são cobradas. Atravessar a fronteira de
uma zona entre duas máquinas suas custa um pouco em cada direção. Sair da região custa quase tanto
quanto ir para a internet. E uma peça de rede que muitas contas têm, o NAT gateway, cobra por todo byte
que carrega, mesmo quando o destino é o S3 ali do lado.

As linhas, da tabela:

```
  between zones, each direction                         0.01000  GB
  to us-east-1                                          0.13800  GB
```

## Zonas e regiões

**O S3 é um serviço regional, então lê-lo de qualquer zona de São Paulo não paga transferência.** A
tarifa de zona é para tráfego entre recursos seus em zonas diferentes: um banco de dados numa zona
replicando para o standby em outra, que a lição 7 encontra com o Multi-AZ, ou um cluster com nós em
duas zonas. Cada GB é cobrado ao sair de uma zona e de novo ao entrar na outra, então 500 GB por mês de
replicação dão 500 × 0,01000 × 2 = 10,00.

**Copiar para outra região é cobrado como uma pequena internet.** O jurídico da Quitanda pediu uma vez
uma cópia do lago de 5 TB em us-east-1, para um parceiro que trabalha lá. São 5.120 GB × 0,13800 =
706,56 pela cópia, uma vez, e toda mudança replicada depois paga a mesma tarifa. É também por isso que
a lição 1 mantém os dados em São Paulo: os dados de uma empresa brasileira em geral precisam ficar, e
movê-los é uma linha na conta além de uma questão jurídica.

## O NAT gateway, e o endpoint que o substitui

Máquinas numa sub-rede privada chegam à internet por um NAT gateway, que a lição 17 de
`aws-foundations` monta. Sem mais nada configurado, elas também chegam ao S3 por ele, porque o
endereço do S3 é público. **Um NAT gateway cobra por todo GB que processa**, em qualquer direção, e a
tabela de preços deste curso não lê a oferta em que esse preço mora. A tabela do curso `cloud` lê: a
lição 10 de `cloud`, em "Lendo a lista pública de preços", imprime um NAT gateway em São Paulo a
0,0930 por GB processado, além de 0,0930 por hora por existir.

A esse preço, um job noturno numa sub-rede privada que lê 2 TB por mês do lago paga
2.048 × 0,0930 = 190,46 por mês só em processamento do NAT, por tráfego que nunca saiu de São Paulo.

**Um gateway endpoint para o S3 não custa nada e tira essa cobrança**, como explica a lição 19 de
`aws-foundations`: uma entrada na tabela de rotas da sub-rede que manda os endereços do S3 para o S3 por
dentro, passando ao largo do NAT gateway. Os 190,46 viram 0,00, e a política de bucket da lição 4 pode
então exigir `aws:SourceVpce`, para que o bucket só seja lido por esse caminho. É a mudança mais barata
desta lição e uma das mais esquecidas, porque nada quebra sem ela; a conta só fica maior.

Nada dessa rede existe no moto, que não tem zonas a atravessar nem gateway a pagar. Os números são as
listas de preços multiplicadas por contagens.

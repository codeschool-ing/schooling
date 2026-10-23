---
title: Uma década do mesmo erro
version: 1
---

**O jeito mais comum de dados vazarem da nuvem não envolve ataque nenhum. Alguém deixa um bucket de
armazenamento legível por todos, outra pessoa o encontra, e os dados são baixados com uma requisição
comum que o bucket responde como foi projetado.** Nada foi invadido. A segurança do provedor se
manteve. A configuração fez o que dizia.

A imagem errada é a de um vazamento como alguém derrotando uma defesa. Aqui a defesa foi desligada
pelo próprio dono, quase sempre por um motivo que fazia sentido no dia: um arquivo para compartilhar
com um fornecedor, um site para servir, um teste que precisava funcionar até as cinco da tarde. É por
isso que aconteceu por tanto tempo, em empresas com equipe de segurança, e por isso o título desta
aula o chama de erro da década.

## Quatro que foram publicados

Em 2017 a empresa de segurança UpGuard publicou uma série de relatórios sobre buckets do Amazon S3
expostos que os pesquisadores dela haviam encontrado. Quatro deles, como a UpGuard e a imprensa os
relataram na época:

| quando | dados de quem | o que havia |
|---|---|---|
| junho de 2017 | Deep Root Analytics, empresa de dados que trabalhava para o Comitê Nacional Republicano dos EUA | registros de cerca de 198 milhões de eleitores americanos |
| junho de 2017 | Booz Allen Hamilton, prestadora da Agência Nacional de Inteligência Geoespacial dos EUA | arquivos que incluíam credenciais de sistemas do governo |
| julho de 2017 | Verizon, por meio da NICE Systems, fornecedora que cuidava da central de atendimento | registros de clientes: a UpGuard estimou 14 milhões, a Verizon cerca de 6 milhões |
| outubro de 2017 | Accenture | quatro buckets com chaves, senhas e dados internos |

**Três dos quatro eram o bucket de um fornecedor guardando dados de um cliente.** Essa é a forma que
vale guardar. A empresa cujo nome estava na manchete não criou o bucket, e o programa de segurança
dela nunca o viu. A aula 10 volta a essa forma com armazenamentos que as pessoas abrem por conta
própria.

Em cada caso os pesquisadores acharam o bucket porque ele lhes respondeu, e avisaram o dono, que é o
jeito responsável de fazer. Não precisaram de vulnerabilidade, de senha nem de habilidade além de
saber o endereço. **Tudo o que um pesquisador acha desse jeito, alguém sem boas intenções acha do
mesmo jeito**, e ninguém publica relatório sobre as cópias que levou.

## Como o provedor respondeu

A correção não veio de mais um aviso num documento. Veio, ao longo de seis anos, de mudar o que é o
padrão:

| quando | o que a AWS mudou, pelos anúncios dela |
|---|---|
| novembro de 2018 | **S3 Block Public Access**: quatro chaves, por bucket e por conta, que recusam ou ignoram concessões públicas, digam o que disserem as políticas e as ACLs |
| janeiro de 2023 | todo objeto novo cifrado em repouso por padrão, com chaves gerenciadas pelo S3 |
| abril de 2023 | todo bucket novo criado com Block Public Access ligado e ACLs desativadas |

Desde abril de 2023 um bucket novo exige **dois passos deliberados** para ficar público: desligar a
proteção e depois escrever a concessão. O `put-bucket-policy` da aula 1 teria sido recusado numa
conta real exatamente por isso.

Isso não aposenta o assunto. Buckets criados antes de 2023 mantêm as configurações que tinham. Uma
proteção pode ser desligada por quem tiver permissão, e na pressa alguém sempre tem. O mesmo erro
existe com outros nomes em todo provedor, o que a aula 5 compara. E o armazenamento da próxima aula
fica totalmente fora dessas proteções. **O resto desta aula é o mecanismo, para que você ache os que
ainda estão abertos.**

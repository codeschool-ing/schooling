---
title: A LGPD e o dado que sai do país
version: 1
---

**Pela LGPD, mandar dado pessoal para outro país só é permitido em uma das hipóteses que o artigo 33
lista. Uma nuvem deixa esse envio a uma configuração de distância, então a pergunta deixa de ser se a
clínica exporta dados de propósito e passa a ser se ela consegue achar cada cópia que saiu sem
ninguém decidir.** Esta seção lê a lei no nível de que um engenheiro precisa; o parecer jurídico é do
advogado da clínica e do encarregado de dados que a lei exige.

## Quem é quem

No vocabulário da LGPD, a clínica é a **controladora**: decide por que e como os dados dos pacientes
são tratados. A AWS é **operadora**: trata os dados em nome da clínica, por contrato. A linha da aula 2
reaparece aqui em forma jurídica. A AWS responde por operar a infraestrutura como o contrato diz; a
clínica responde pelo que escolheu pôr onde.

## O que o artigo 33 permite

O artigo 33 abre com a regra — a transferência internacional *somente* é permitida nos casos que ele
lista — e depois os lista. Os que uma empresa encontra com mais frequência:

| hipótese | o que quer dizer na prática |
|---|---|
| um país com grau de proteção **adequado** | um país que a ANPD, a autoridade nacional de proteção de dados, reconheceu como adequado (o artigo 34 diz como ela avalia) |
| **garantias contratuais** | cláusulas-padrão contratuais, cláusulas específicas, normas corporativas globais, ou selos e certificados, que a controladora tem de oferecer e conseguir comprovar |
| **consentimento específico e em destaque** | o paciente concordou com aquela transferência, avisado à parte e com clareza de que ela vai para fora |
| **obrigação legal**, **contrato** com o paciente ou exercício de direitos | a transferência é necessária para uma dessas coisas, como o artigo 7 já permite para o tratamento |

O artigo lista outras hipóteses também, para cooperação entre autoridades, proteção da vida e
políticas públicas. Nenhuma delas é a que uma clínica usa quando escolhe uma região de backup.

**A ANPD publicou o regulamento de transferência internacional em agosto de 2024**, com o texto das
cláusulas-padrão contratuais e doze meses para os contratos existentes as adotarem. Um contrato com
um provedor de nuvem é exatamente o tipo que ele trata, e é por isso que os termos de tratamento de
dados do provedor são um documento que o encarregado da clínica deveria ter lido antes do primeiro
bucket ser criado.

## O que torna isso urgente numa nuvem

On-premises, o dado sai do país quando alguém despacha um disco ou abre um link para um data center
estrangeiro: um evento com uma ordem de compra por trás. Na nuvem, ele sai quando alguém digita outra
região:

- o caio cria um bucket de backup em `us-east-1` porque um post de blog disse que era a região mais
  barata;
- um serviço que a clínica quer só existe em algumas regiões, e o console muda para uma delas sem
  avisar;
- um plano de recuperação de desastre copia tudo para uma segunda região, e **a AWS e o Google Cloud
  têm cada um uma única região no Brasil**, as duas em São Paulo, então uma segunda região quer dizer
  um segundo país. O Azure tem duas no Brasil, Brazil South e Brazil Southeast. **Tirado das listas
  de regiões dos provedores, não executado.**

O último é o caso difícil, porque não é erro. A aula 9 do curso `cloud` defendeu sobreviver à perda
de uma região; a residência defende ficar em um país. A clínica resolve decidindo, e não à deriva:
espalhar pelas zonas de disponibilidade de `sa-east-1` e aceitar o risco menor de perder a região
inteira, ou replicar fora com uma hipótese legal registrada e o encarregado concordando por escrito.

**As duas respostas são defensáveis. O que não se defende é uma cópia na Virgínia que ninguém sabe
explicar.** A próxima seção acha essas cópias.

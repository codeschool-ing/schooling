---
title: De onde vêm as exigências
version: 1
---

As exigências chegam a uma organização de quatro tipos de fonte, e elas diferem em quão opcionais são:

| fonte | exemplo para a loja | a loja pode dizer não? |
|---|---|---|
| **lei** | a LGPD: proteger dados pessoais e comunicar incidentes graves (aula 17) | não |
| **regulação setorial** | para um banco, as regras de segurança cibernética do Banco Central; a loja não tem nenhuma | não, se estiver no setor |
| **contrato** | o provedor de pagamento com cartão exige que os lojistas sigam o **PCI DSS**, a norma de segurança do setor de cartões | só desistindo de pagamento com cartão |
| **norma voluntária** | a ISO 27001 (aula 14), escolhida porque um cliente grande pediu | sim, mas o cliente pode então escolher outro |

A linha do contrato costuma ser a primeira que um pequeno negócio encontra. O **PCI DSS** (*Payment Card
Industry Data Security Standard*) é escrito pelo conselho de normas das bandeiras de cartão e imposto a
todo negócio que guarda, processa ou transmite dados de cartão, pelo contrato com quem processa os
pagamentos dele. A loja evitou quase tudo do jeito que a aula 3 descreveu: mandando os clientes para a
página do provedor de pagamento, para que números de cartão nunca toquem o servidor da loja. As
exigências que sobraram para a loja encolheram para um questionário curto de autoavaliação. Isso é
evitar risco e delimitar o escopo da conformidade ao mesmo tempo.

### Da exigência ao controle, à evidência

Uma exigência raramente diz exatamente o que fazer. Ela enuncia um **objetivo**, e a organização decide
como cumpri-lo:

1. **a exigência**: "os dados pessoais devem ser protegidos por medidas técnicas e administrativas
   adequadas" (o artigo 46 da LGPD, na aula 17);
2. **uma política**: a regra da própria loja, "o acesso a dados de clientes é concedido por papel e
   revisto a cada seis meses";
3. **um procedimento**: quem faz a revisão, com qual lista, e para onde vai o resultado;
4. **evidência**: a revisão assinada de março passado, e a de setembro.

A cadeia importa porque o auditor a percorre de trás para a frente. Ele começa pela exigência, pede a
política, pergunta como ela é cumprida e depois pede para **ver** que foi cumprida. Uma política sem
evidência é uma promessa; um procedimento que ninguém segue é ficção.

### Um controle, muitas exigências

O mesmo controle em geral satisfaz várias exigências ao mesmo tempo. Uma revisão de acesso responde ao
dever de segurança da LGPD, a uma exigência do PCI DSS e a um controle da ISO 27001. Organizações que
mantêm um **mapeamento de controles**, uma tabela de cada controle para cada exigência que ele satisfaz,
fazem o trabalho uma vez e o mostram muitas vezes. A aula 13 de `threat-modeling` monta um mapeamento
assim entre ISO 27001, NIST CSF e SOC 2.

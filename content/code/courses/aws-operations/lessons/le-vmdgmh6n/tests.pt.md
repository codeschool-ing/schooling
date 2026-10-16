---
title: Testes de infraestrutura, rodados antes de qualquer coisa existir
version: 1
---

Um programa pode ser testado, e o template que ele escreve também. O módulo `assertions` do CDK monta o
template na memória e o confere, sem conta, sem moto e sem rede. **As decisões das seções anteriores
viram testes**, então uma edição posterior que desfaça uma delas falha no build em vez de chegar à
AWS. O Node.js tem um executor de testes embutido; o arquivo é `app.test.js`, ao lado do app:

```javascript
// app.test.js
const { test } = require("node:test");
const { App } = require("aws-cdk-lib");
const { Template, Match } = require("aws-cdk-lib/assertions");
const { ShopBase } = require("./app");

const template = Template.fromStack(new ShopBase(new App(), "Test"));

test("the uploads bucket refuses plain HTTP", () => {
  template.hasResourceProperties("AWS::S3::BucketPolicy", {
    PolicyDocument: {
      Statement: Match.arrayWith([
        Match.objectLike({
          Effect: "Deny",
          Condition: { Bool: { "aws:SecureTransport": "false" } },
        }),
      ]),
    },
  });
});

test("the uploads bucket survives the stack", () => {
  template.hasResource("AWS::S3::Bucket", {
    DeletionPolicy: "Retain",
    UpdateReplacePolicy: "Retain",
  });
});

test("one alarm, and it notifies somebody", () => {
  template.resourceCountIs("AWS::CloudWatch::Alarm", 1);
  template.hasResourceProperties("AWS::CloudWatch::Alarm", {
    AlarmActions: Match.anyValue(),
  });
});
```

`Template.fromStack` sintetiza a stack do jeito que o `cdk synth` faz. `hasResourceProperties` passa
quando **algum** recurso daquele tipo tem propriedades contendo as que foram dadas; `Match.objectLike`
e `Match.arrayWith` deixam o resto do objeto e do array conter qualquer outra coisa. `hasResource`
confere os atributos do próprio recurso, onde moram as políticas de exclusão. `resourceCountIs` conta.
O executor imprime o relatório em TAP, um formato de texto simples que outras ferramentas leem, e o
`grep` guarda as linhas que dizem qual teste passou.

```
ana@laptop:~/aws/cdk$ node --test 2>&1 | grep -E '^(ok|not ok|# (pass|fail))'
ok 1 - the uploads bucket refuses plain HTTP
ok 2 - the uploads bucket survives the stack
ok 3 - one alarm, and it notifies somebody
# pass 3
# fail 0
```

Agora desfaça a decisão que o primeiro teste protege, como alguém arrumando o arquivo poderia fazer:

```
ana@laptop:~/aws/cdk$ sed -i 's/enforceSSL: true/enforceSSL: false/' app.js
ana@laptop:~/aws/cdk$ node --test 2>&1 | grep -E '^(ok|not ok|# (pass|fail))|^  error:|Template has'
not ok 1 - the uploads bucket refuses plain HTTP
  error: |-
    Template has 0 resources with type AWS::S3::BucketPolicy.
ok 2 - the uploads bucket survives the stack
ok 3 - one alarm, and it notifies somebody
# pass 2
# fail 1
```

**O teste nomeia a decisão que se perdeu**, "the uploads bucket refuses plain HTTP", e o motivo,
nenhuma política de bucket no template. Ponha a linha de volta antes de seguir.

## O que testar

Testes assim valem a pena para **decisões**, não para cada propriedade:

- uma proteção fácil de remover e cara de perder: criptografia, uma política que recusa HTTP sem TLS,
  um bucket mantido quando a stack vai embora;
- uma contagem que não deve mudar por acidente: um alarme por serviço, nenhum bucket público;
- uma relação: o alarme avisa o tópico que o plantão lê.

O outro tipo, o **teste de snapshot**, compara o template inteiro com uma cópia guardada antes e falha
em qualquer diferença. Ele pega tudo e não explica nada, e depois da terceira atualização da biblioteca
que muda um hash nele, as pessoas atualizam o snapshot sem ler. Use-o, se usar, ao lado dos testes
finos, nunca no lugar deles.

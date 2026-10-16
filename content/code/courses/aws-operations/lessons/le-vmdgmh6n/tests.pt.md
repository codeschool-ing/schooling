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

```
ana@laptop:~/aws/cdk$ node --test --test-reporter=spec
✔ the uploads bucket refuses plain HTTP (2.833395ms)
✔ the uploads bucket survives the stack (0.385392ms)
✔ one alarm, and it notifies somebody (0.311572ms)
ℹ tests 3
ℹ suites 0
ℹ pass 3
ℹ fail 0
ℹ cancelled 0
ℹ skipped 0
ℹ todo 0
ℹ duration_ms 1750.102685
```

Agora desfaça a decisão que o primeiro teste protege, como alguém arrumando o arquivo poderia fazer:

```
ana@laptop:~/aws/cdk$ sed -i 's/enforceSSL: true/enforceSSL: false/' app.js
ana@laptop:~/aws/cdk$ node --test --test-reporter=spec 2>&1 | head -18
✖ the uploads bucket refuses plain HTTP (2.431477ms)
✔ the uploads bucket survives the stack (0.560651ms)
✔ one alarm, and it notifies somebody (0.23853ms)
ℹ tests 3
ℹ suites 0
ℹ pass 2
ℹ fail 1
ℹ cancelled 0
ℹ skipped 0
ℹ todo 0
ℹ duration_ms 1207.331431

✖ failing tests:

test at app.test.js:9:1
✖ the uploads bucket refuses plain HTTP (2.431477ms)
  Error [AssertionError]: Template has 0 resources with type AWS::S3::BucketPolicy.
  No matches found
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

---
title: Vigiando o vencimento, com um script que roda em qualquer lugar
version: 1
---

**Um vencimento que ninguém vigia é descoberto pelo build que falha, então a solução é ter algo
que vigie.** As páginas do App Store Connect mostram a data de cada certificado, e ninguém as abre
numa terça-feira qualquer. Um programa curto que lê certificados e reclama com um mês de
antecedência pode rodar toda noite no pipeline, e não precisa de Mac: um certificado é um arquivo
X.509 padrão, e o Node lê um sem instalar nada.

## Certificados para ler

Os certificados da Apple são exportados do Keychain do Mac como arquivos `.cer`, e uma linha de
`openssl x509 -inform der -in file.cer -out file.pem` transforma cada um no formato de texto que o
script lê. *Esse passo precisa dos seus certificados de verdade e não foi rodado para este curso.*
Para ter o que ler aqui, crie três certificados seus com o OpenSSL, cada um com o nome de um tipo
que a Apple emite e cada um vencendo num dia diferente. **Eles são substitutos, assinados por
ninguém além deles mesmos, e a Apple não aceitaria nenhum**; só as datas importam:

```
ana@dev:~/planner/certs$ openssl req -x509 -newkey rsa:2048 -nodes -keyout dev.key -out apple-development.pem -days 200 -subj "/CN=Apple Development: Ana Souza (stand-in)" 2>/dev/null
ana@dev:~/planner/certs$ openssl req -x509 -newkey rsa:2048 -nodes -keyout dist.key -out apple-distribution.pem -days 21 -subj "/CN=Apple Distribution: Study Planner (stand-in)" 2>/dev/null
ana@dev:~/planner/certs$ openssl req -x509 -newkey rsa:2048 -nodes -keyout push.key -out apple-push.pem -days 380 -subj "/CN=Apple Push Services: com.example.planner (stand-in)" 2>/dev/null
ana@dev:~/planner/certs$ ls
apple-development.pem
apple-distribution.pem
apple-push.pem
dev.key
dist.key
push.key
```

## O script

Salve isto como `expiry.ts` em `~/planner`:

```schooling-example
{"language": "typescript", "file": "expiry.ts", "parts": [{"code": "// expiry.ts: which certificates in a folder expire within a month of a date?\nimport { X509Certificate } from \"node:crypto\";\nimport { readdirSync, readFileSync } from \"node:fs\";\nimport { join } from \"node:path\";", "note": "O próprio módulo `crypto` do Node lê certificados X.509; nada é instalado."}, {"code": "const folder = process.argv[2] ?? \"certs\";\nconst on = process.argv[3] ? new Date(`${process.argv[3]}T12:00:00Z`) : new Date();\nconst warnDays = 30;\nconst day = 24 * 60 * 60 * 1000;\nlet trouble = 0;", "note": "A pasta, e o dia sobre o qual perguntar. Sem data, ele pergunta sobre agora. Meio-dia UTC impede que uma data escorregue para o dia anterior em qualquer fuso."}, {"code": "for (const name of readdirSync(folder).filter((f) => f.endsWith(\".pem\")).sort()) {\n  const cert = new X509Certificate(readFileSync(join(folder, name)));\n  const cn = cert.subject.split(\"\\n\").find((l) => l.startsWith(\"CN=\"))?.slice(3) ?? name;", "note": "Todo arquivo `.pem`, em ordem de nome para a saída ser a mesma a cada execução. A linha `CN=` do subject é o nome que a Apple escreve, como *Apple Distribution: Study Planner*."}, {"code": "  const left = Math.floor((cert.validToDate.getTime() - on.getTime()) / day);\n  const state = left < 0 ? \"EXPIRED\" : left < warnDays ? \"RENEW\" : \"ok\";\n  if (state !== \"ok\") trouble++;\n  console.log(`${state.padEnd(7)} ${String(left).padStart(5)} days  ${cert.validToDate.toISOString().slice(0, 10)}  ${cn}`);\n}", "note": "Dias inteiros restantes, arredondados para baixo. Menos de 30 é hora de renovar; abaixo de 0 já venceu."}, {"code": "process.exitCode = trouble ? 1 : 0;", "note": "O status de saída é a parte que um pipeline lê: 1 quando algo precisa de atenção."}]}
```

A data é um argumento pelo mesmo motivo que a semana do planner é em outras lições desta trilha:
um programa que lê o relógio responde diferente a cada dia, e a pergunta "o que vence antes do
lançamento em junho?" precisa de uma data que não é hoje. Sem ela, ele pergunta sobre agora, e a
segunda execução pergunta sobre 1º de junho de 2027:

```
ana@dev:~/planner$ node expiry.ts certs; echo "exit status $?"
ok        199 days  2027-05-18  Apple Development: Ana Souza (stand-in)
RENEW      20 days  2026-11-20  Apple Distribution: Study Planner (stand-in)
ok        379 days  2027-11-14  Apple Push Services: com.example.planner (stand-in)
exit status 1
ana@dev:~/planner$ node expiry.ts certs 2027-06-01
EXPIRED   -14 days  2027-05-18  Apple Development: Ana Souza (stand-in)
EXPIRED  -193 days  2026-11-20  Apple Distribution: Study Planner (stand-in)
ok        166 days  2027-11-14  Apple Push Services: com.example.planner (stand-in)
```

O `echo` depois da primeira execução imprime o status de saída. **O 1 é a parte útil**: um passo de
pipeline falha quando um comando sai com qualquer coisa diferente de 0, então um job noturno
rodando `node expiry.ts certs` fica vermelho um mês antes de o build de release ficar, que é todo o
ponto. A lição 10 o acrescenta ao pipeline.

## O que o script não enxerga

- **Perfis de provisionamento.** Um perfil é uma lista de propriedades assinada, não um
  certificado, e a data dele fica lá dentro como `ExpirationDate`. Num Mac,
  `security cms -D -i profile.mobileprovision` a imprime como texto. *Não rodado para este curso.*
- **A assinatura do programa.** Ela vence na data dela, um ano depois da inscrição, e tira os apps
  da loja; a Apple manda lembretes ao dono da conta, o que é mais um motivo para a lição 3 dizer
  quem deveria ser essa pessoa.
- **Chaves que não vencem.** A chave `.p8` que o App Store Connect emite para a API dele, e a das
  notificações push, não têm data de vencimento. Elas são revogadas, não renovadas.

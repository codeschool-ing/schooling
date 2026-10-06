---
title: Validade: as datas, e o relógio que as lê
version: 1
---

**Um certificado só é válido entre as datas `Not Before` e `Not After`, e um cliente o recusa fora
delas, por mais correto que todo o resto esteja.** A expiração é o motivo mais comum de um site que
funcionava de repente parar de funcionar, e é totalmente previsível: a data está impressa no
certificado desde o dia em que ele foi emitido.

## Três certificados, três datas de fim

```
ana@lab:~/lab$ for c in portal agenda files; do printf "%-7s " $c; openssl x509 -in pki/$c.pem -noout -enddate; done
portal  notAfter=Nov 17 00:00:00 2026 GMT
agenda  notAfter=Apr 10 00:00:00 2026 GMT
files   notAfter=Aug 20 00:00:00 2026 GMT
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Um calendário de janeiro a dezembro de 2026 com o presente do laboratório, 15 de junho, marcado. agenda.vereda.example foi de 10 de janeiro a 10 de abril e expirou. files.vereda.example vai de 1º de fevereiro a 20 de agosto, mas foi revogado em 20 de maio. portal.vereda.example vai de 1º de maio a 17 de novembro e é válido agora, com 154 dias restantes.\"><polyline points=\"160.0,26 160.0,190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></polyline><text x=\"163.0\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">jan</text><polyline points=\"293.1506849315068,26 293.1506849315068,190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></polyline><text x=\"296.1506849315068\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">abr</text><polyline points=\"427.7808219178082,26 427.7808219178082,190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></polyline><text x=\"430.7808219178082\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">jul</text><polyline points=\"563.8904109589041,26 563.8904109589041,190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></polyline><text x=\"566.8904109589041\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">out</text><text x=\"20\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">agenda.pem</text><rect x=\"173.31506849315068\" y=\"40\" width=\"133.15068493150685\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"179.31506849315068\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">expirado</text><text x=\"20\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">files.pem</text><rect x=\"205.86301369863014\" y=\"86\" width=\"295.8904109589041\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><text x=\"211.86301369863014\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">revogado em 20/5</text><text x=\"20\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">portal.pem</text><rect x=\"337.5342465753425\" y=\"132\" width=\"295.89041095890406\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"412.1095890410959\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">válido, faltam 154 dias</text><polyline points=\"365.64383561643837,86 365.64383561643837,114\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2.5\"></polyline><polyline points=\"404.1095890410959,30 404.1095890410959,200\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"2\"></polyline><text x=\"404.1095890410959\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">agora: 15 de junho de 2026</text></svg>", "caption": "Três certificados contra um instante: expirado, revogado, válido."}
```

O presente do laboratório é 15 de junho de 2026. O certificado do servidor da agenda terminou em 10
de abril, e conferi-lo agora diz isso:

```
ana@lab:~/lab$ openssl verify -attime 1781535600 -CAfile pki/root.pem -untrusted pki/issuing1.pem pki/agenda.pem
C = BR, O = Vereda Fisioterapia, CN = agenda.vereda.example
error 10 at 0 depth lookup: certificate has expired
error pki/agenda.pem: verification failed
```

O mesmo certificado, conferido como se fosse 1º de março, quando estava dentro das datas, passa:

```
ana@lab:~/lab$ openssl verify -attime $(date -d "2026-03-01 12:00 -03" +%s) -CAfile pki/root.pem -untrusted pki/issuing1.pem pki/agenda.pem
pki/agenda.pem: OK
```

Nada no certificado mudou entre os dois comandos. Só o relógio mudou. Vale lembrar disso quando uma
verificação falha numa máquina e passa em outra: um servidor com o relógio errado, muitas vezes uma
máquina virtual restaurada de um snapshot antigo ou um dispositivo que perdeu a bateria, recusa
certificados válidos e pode aceitar expirados.

## Quanto falta

O certificado do portal está bem hoje. Quão bem:

```
ana@lab:~/lab$ echo $(( ($(date -d "$(openssl x509 -in pki/portal.pem -noout -enddate | cut -d= -f2)" +%s) - 1781535600) / 86400 )) days left on portal.pem
154 days left on portal.pem
```

154 dias. Um monitoramento deveria calcular exatamente isso para todo certificado pelo qual uma
equipe responde, inclusive os internos, e alertar bem antes do zero: trinta dias é comum, o que
deixa tempo para perceber uma renovação que falhou em silêncio. Com a vida máxima caindo para 100 e
depois 47 dias (aula 8), a renovação deixa de ser uma tarefa anual de que alguém se lembra e vira um
job que roda sozinho, pelo ACME, e é vigiado.

## Expiração é uma propriedade de segurança, não burocracia

É tentador tratar a expiração como um incômodo e emitir certificados internos para dez anos. As
datas existem porque nada mais limita um erro: uma chave privada que vazou sem ninguém perceber, um
certificado emitido para um nome que alguém não controla mais, um algoritmo que enfraqueceu. A
revogação, duas seções adiante, deveria cuidar disso e muitas vezes não cuida. **A data `Not After`
é o único limite que todo cliente aplica**, então uma data mais curta é uma garantia mais forte.

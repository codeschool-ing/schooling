---
title: "A raiz de composição: um lugar que sabe de tudo"
version: 1
---

**Se nenhuma classe constrói os próprios colaboradores, alguma coisa precisa construir todos eles,
e a raiz de composição é essa coisa: um lugar, o mais perto possível do ponto de entrada do
programa, onde cada classe concreta é escolhida e cada objeto é ligado aos vizinhos.** Num script ela
é o `main`. Numa aplicação web é o código que roda uma vez na inicialização. Em todo o resto do
programa, os objetos recebem e nunca constroem.

A primeira reação costuma ser que isso muda o problema de lugar em vez de resolvê-lo. Muda, sim, e
mudar de lugar é o objetivo. Quando a construção está espalhada, a decisão "e-mail ou mensagem de
texto" é tomada dentro de qualquer classe que por acaso precisou de um notificador, e mudá-la
significa achar essa classe. Quando a construção está reunida, toda decisão desse tipo fica num
arquivo só, e o resto do programa é escrito como se não soubesse a resposta.

## Um main que só liga as peças

O `main.py` importa a tarefa de `overdue.py`, acrescenta as implementações reais que uma instalação
usaria e não faz mais nada.

```schooling-example
{"language": "python", "file": "main.py", "parts": [
 {"code": "# main.py\nimport os\nimport sys\nfrom datetime import date\n\nfrom overdue import FixedClock, ListedLoans, Loan, OverdueNotices", "note": "A raiz de composição importa classes concretas de todo lado. É o único arquivo que tem permissão para isso."},
 {"code": "\n\nclass EmailNotifier:\n    def __init__(self, sender: str):\n        self._sender = sender\n\n    def send(self, member: str, text: str) -> None:\n        print(f\"e-mail from {self._sender} to {member}: {text}\")\n\n\nclass SmsNotifier:\n    def send(self, member: str, text: str) -> None:\n        print(f\"SMS to {member}: {text}\")\n\n\nclass SystemClock:\n    def today(self) -> date:\n        return date.today()", "note": "Dois notificadores e um relógio que lê o calendário do computador. Um `EmailNotifier` de verdade conversaria com um servidor de e-mail; estes imprimem, para o programa rodar em qualquer lugar."},
 {"code": "\n\ndef build(channel: str) -> OverdueNotices:\n    loans = ListedLoans([\n        Loan(\"Bia\", \"Dom Casmurro\", date(2026, 3, 16)),\n        Loan(\"Duda\", \"Central do Brasil\", date(2026, 3, 11)),\n    ])\n    notifiers = {\"email\": EmailNotifier(\"desk@library.example.org\"),\n                 \"sms\": SmsNotifier()}\n    fixed = os.environ.get(\"LIBRARY_TODAY\")\n    clock = FixedClock(date.fromisoformat(fixed)) if fixed else SystemClock()\n    return OverdueNotices(loans, notifiers[channel], clock)", "note": "`build` é a ligação das peças, e se lê como uma lista de decisões. A configuração é lida aqui, dos argumentos e do ambiente, e em nenhum lugar mais fundo."},
 {"code": "\n\ndef main(argv: list[str]) -> None:\n    notices = build(argv[1] if len(argv) > 1 else \"email\")\n    print(\"sent:\", notices.send_all())\n\n\nif __name__ == \"__main__\":\n    main(sys.argv)", "note": "O ponto de entrada constrói uma vez e depois roda. Nada depois que `build` retorna cria um colaborador."}
]}
```

`LIBRARY_TODAY` deixa um operador repetir um dia passado, e deixa esta lição imprimir a mesma saída
toda vez. Sem ela, a tarefa usa a data real.

```
ana@laptop:~/patterns/injection$ LIBRARY_TODAY=2026-03-20 python3 main.py
e-mail from desk@library.example.org to Bia: 'Dom Casmurro' is 4 days late, fine 200 cents
e-mail from desk@library.example.org to Duda: 'Central do Brasil' is 9 days late, fine 450 cents
sent: 2
ana@laptop:~/patterns/injection$ LIBRARY_TODAY=2026-03-20 python3 main.py sms
SMS to Bia: 'Dom Casmurro' is 4 days late, fine 200 cents
SMS to Duda: 'Central do Brasil' is 9 days late, fine 450 cents
sent: 2
```

Trocar todos os avisos de e-mail para mensagem de texto custou uma palavra na linha de comando e não
mexeu em nenhuma classe. `OverdueNotices` é, byte a byte, o arquivo de duas seções atrás.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l05-root\" aria-label=\"Um diagrama de classes do programa de avisos de atraso. OverdueNotices, no alto, guarda três colaboradores, desenhados como linhas com um losango cheio do lado dele: um LoanStore, um Notifier e um Clock, cada um deles um protocolo. Abaixo, cinco classes concretas implementam os protocolos: ListedLoans implementa LoanStore; EmailNotifier e SmsNotifier implementam Notifier; SystemClock e FixedClock implementam Clock. Uma fronteira tracejada envolve as cinco classes concretas e tem o rótulo main.py, a raiz de composição: o único arquivo que as nomeia.\"><rect x=\"270.0\" y=\"14.0\" width=\"180.0\" height=\"96.5\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"25.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">OverdueNotices</text><path d=\"M270.0 36.5 L450.0 36.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"278.0\" y=\"47.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">loans</text><text x=\"278.0\" y=\"62.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">notifier</text><text x=\"278.0\" y=\"76.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">clock</text><path d=\"M270.0 88.0 L450.0 88.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"278.0\" y=\"99.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">send_all()</text><text x=\"462.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">pede três protocolos</text><text x=\"462.0\" y=\"55.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">e não constrói nenhum</text><rect x=\"40.0\" y=\"150.0\" width=\"180.0\" height=\"59.5\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"130.0\" y=\"161.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">«protocol»</text><text x=\"130.0\" y=\"175.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">LoanStore</text><path d=\"M40.0 187.0 L220.0 187.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"48.0\" y=\"198.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">open_loans()</text><rect x=\"270.0\" y=\"150.0\" width=\"180.0\" height=\"59.5\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"161.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">«protocol»</text><text x=\"360.0\" y=\"175.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Notifier</text><path d=\"M270.0 187.0 L450.0 187.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"278.0\" y=\"198.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">send()</text><rect x=\"500.0\" y=\"150.0\" width=\"180.0\" height=\"59.5\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"161.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">«protocol»</text><text x=\"590.0\" y=\"175.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Clock</text><path d=\"M500.0 187.0 L680.0 187.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"508.0\" y=\"198.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">today()</text><path d=\"M300.0 110.5 L300.0 130.0 L130.0 130.0 L130.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M300.0 110.5 L294.5 119.5 L300.0 128.5 L305.5 119.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--paper-dim)\"></path><path d=\"M360.0 110.5 L360.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M360.0 110.5 L354.5 119.5 L360.0 128.5 L365.5 119.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--paper-dim)\"></path><path d=\"M420.0 110.5 L420.0 130.0 L590.0 130.0 L590.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M420.0 110.5 L414.5 119.5 L420.0 128.5 L425.5 119.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--paper-dim)\"></path><rect x=\"20.0\" y=\"228.0\" width=\"680.0\" height=\"92.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><rect x=\"70.0\" y=\"250.0\" width=\"120.0\" height=\"21.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"130.0\" y=\"260.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">ListedLoans</text><path d=\"M130.0 250.0 L130.0 238.0 L130.0 238.0 L130.0 209.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M130.0 209.5 L137.0 221.5 L123.0 221.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"var(--panel)\"></path><rect x=\"245.0\" y=\"250.0\" width=\"110.0\" height=\"21.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"300.0\" y=\"260.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">EmailNotifier</text><path d=\"M300.0 250.0 L300.0 238.0 L360.0 238.0 L360.0 209.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M360.0 209.5 L367.0 221.5 L353.0 221.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"var(--panel)\"></path><rect x=\"365.0\" y=\"250.0\" width=\"110.0\" height=\"21.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"420.0\" y=\"260.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">SmsNotifier</text><path d=\"M420.0 250.0 L420.0 238.0 L360.0 238.0 L360.0 209.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M360.0 209.5 L367.0 221.5 L353.0 221.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"var(--panel)\"></path><rect x=\"490.0\" y=\"250.0\" width=\"95.0\" height=\"21.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"537.5\" y=\"260.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">SystemClock</text><path d=\"M537.5 250.0 L537.5 238.0 L590.0 238.0 L590.0 209.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M590.0 209.5 L597.0 221.5 L583.0 221.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"var(--panel)\"></path><rect x=\"595.0\" y=\"250.0\" width=\"95.0\" height=\"21.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"642.5\" y=\"260.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">FixedClock</text><path d=\"M642.5 250.0 L642.5 238.0 L590.0 238.0 L590.0 209.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M590.0 209.5 L597.0 221.5 L583.0 221.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"var(--panel)\"></path><text x=\"360.0\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--amber)\">main.py, a raiz de composição: o único arquivo que nomeia estas classes</text></svg>", "caption": "O trabalho depende de três protocolos. Que classes ficam por trás deles é decidido num arquivo só."}
```

## Regras que a mantêm uma raiz

**Só a raiz de composição pode nomear uma classe concreta da qual outro objeto depende.** Uma classe
lá no fundo do programa que escreve `SmsNotifier()` reabriu o problema que esta seção fechou, por
mais conveniente que tenha sido naquele dia.

Construa tudo antes de qualquer coisa rodar. Se a ligação falhar, porque falta uma configuração ou
um arquivo não abre, ela deve falhar na inicialização, com o programa ainda sem ter feito nada, e
não no primeiro empréstimo atrasado às três da manhã.

Mantenha a raiz sem graça. Ela decide e conecta; não guarda regra nenhuma sobre multas ou
empréstimos. Uma raiz que começa a calcular coisas é uma classe que ganhou um segundo trabalho, e a
lógica dela não pode ser testada sem montar o programa inteiro.

## Até que tamanho ela cresce

No programa desta lição, `build` tem nove linhas. Um serviço com quarenta classes tem uma raiz de
umas cem linhas, e isso ainda está bem: ela é longa como um sumário é longo, sem nada escondido.
Projetos em Go são conhecidos por fazer exatamente isso, um `main.go` que constrói cada dependência
à mão e a passa adiante, e muitos serviços grandes em Go não têm outro mecanismo.

Quando a própria ligação começa a ficar repetitiva — o mesmo repositório entregue a vinte classes,
objetos que precisam ser criados uma vez por requisição web e jogados fora depois dela — um
contêiner pode assumir a parte mecânica. A próxima seção constrói um, e é honesta sobre quão
raramente o Python precisa disso.

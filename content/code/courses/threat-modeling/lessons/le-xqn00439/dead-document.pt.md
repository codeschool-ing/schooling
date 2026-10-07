---
title: Como um modelo morre
version: 1
---

Um modelo de ameaças costuma ser escrito uma vez, com cuidado, no começo de um projeto, e depois
arquivado. Um ano depois ele descreve um sistema que não existe mais, e continua sendo o documento
que alguém manda a um auditor. Ninguém decidiu deixá-lo morrer. Ele morreu uma mudança não
registrada de cada vez.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l15-drift\" aria-label=\"O sistema e o seu modelo se afastando. Em cima, o que acontece com o sistema: funcionalidades saem, um fornecedor muda a API, uma integração nova entra, pessoas entram e saem. Embaixo, mudanças no modelo. Um modelo atualizado uma vez só, no começo, descreve um sistema cada vez mais longe do real a cada evento lá em cima. Um modelo vivo muda sempre que um desses eventos muda o que ele desenha.\"><text x=\"20.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">sistema</text><text x=\"20.0\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">modelo morto</text><text x=\"20.0\" y=\"200.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">modelo vivo</text><path d=\"M130.0 40.0 L700.0 40.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M130.0 130.0 L700.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M130.0 200.0 L700.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><circle cx=\"170.0\" cy=\"40.0\" r=\"6\" fill=\"var(--paper)\"></circle><circle cx=\"260.0\" cy=\"40.0\" r=\"6\" fill=\"var(--paper)\"></circle><circle cx=\"330.0\" cy=\"40.0\" r=\"6\" fill=\"var(--paper)\"></circle><circle cx=\"430.0\" cy=\"40.0\" r=\"6\" fill=\"var(--paper)\"></circle><circle cx=\"520.0\" cy=\"40.0\" r=\"6\" fill=\"var(--paper)\"></circle><circle cx=\"610.0\" cy=\"40.0\" r=\"6\" fill=\"var(--paper)\"></circle><circle cx=\"680.0\" cy=\"40.0\" r=\"6\" fill=\"var(--paper)\"></circle><circle cx=\"170.0\" cy=\"130.0\" r=\"6\" fill=\"var(--amber)\"></circle><circle cx=\"170.0\" cy=\"200.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><circle cx=\"260.0\" cy=\"200.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><circle cx=\"430.0\" cy=\"200.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><circle cx=\"520.0\" cy=\"200.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><circle cx=\"680.0\" cy=\"200.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><path d=\"M170 112 L700 64\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"560.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">a distância cresce a cada mudança</text><text x=\"415.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">nem toda mudança mexe no modelo: só as que mudam o que ele desenha</text></svg>", "caption": "Ninguém decide deixar um modelo morrer. Ele morre uma mudança não registrada de cada vez."}
```

### Os sinais

Um modelo morto é fácil de reconhecer quando se sabe onde olhar, e todo sinal é algo que um programa
ou um git log consegue mostrar:

- **A última mudança dele é mais antiga que a do sistema.** O portal saiu duas vezes em setembro; se
  o `threats.csv` tivesse mudado pela última vez em março, o modelo estaria descrevendo um portal
  mais antigo.
- **As ameaças nomeiam coisas que sumiram,** ou o sistema tem coisas que as ameaças nunca nomeiam.
  Uma ameaça num elemento que ninguém acha no diagrama, ou uma integração nova sem ameaça nenhuma.
- **As datas de revisão passaram sem ninguém perceber.** O RA-002 foi revisto sete dias atrasado, em
  9 de outubro, e só porque a aula 12 por acaso rodou o `acceptances.py` no dia 7.
- **Os problemas foram achados por outra pessoa.** Na aula 13, o relatório SOC 2 do gateway levantou
  duas perguntas que o modelo da Vereda nunca tinha feito. Agora elas são as ameaças T18 e T19:

```
(.venv) ana@vm:~/tm/portal-model$ tail -2 threats.csv
T18,Payment gateway,S,Anybody who obtains the gateway API key from the portal's configuration can create charges and refunds in Vereda's name.
T19,Payment gateway,E,A former employee who still has a login to the gateway's dashboard can see patients' payments and refund them.
```

Nenhuma das duas é exótica. As duas foram achadas de fora, lendo o relatório de um fornecedor contra
uma fronteira de confiança, o que é bom de ter feito e um jeito fraco de depender para achar coisas.

### Por que acontece

Três motivos, e nenhum é preguiça.

**O modelo está separado do trabalho.** Ele mora num documento que ninguém abre enquanto constrói,
então uma mudança no sistema nunca passa por ele. Toda aula deste curso manteve o modelo no git ao
lado do código por esse motivo, e isso é necessário, não suficiente.

**Ninguém é dono do gatilho.** Todo mundo concorda que o modelo deve ser atualizado "quando o projeto
mudar". Ninguém é a pessoa que percebe que um projeto mudou, então ninguém o atualiza.

**Atualizá-lo é caro.** Um modelo refeito do zero toda vez é trabalho de dois dias. Uma equipe que
enfrenta isso a cada sprint para de fazer, o que é uma decisão razoável sobre a premissa errada.
**Uma mudança no sistema pede uma mudança no modelo do mesmo tamanho**, e o resto desta aula é como
mantê-la tão pequena assim.

### Relendo a renovação do RA-002

A revisão atrasada do RA-002 produziu um registro novo em vez de uma edição, como a aula 12 pediu:

```
(.venv) ana@vm:~/tm/portal-model$ head -9 decisions/RA-003-cancellation-record-renewed.md
---
id: RA-003
threat: T06
decision: accept
owner: daniel
decided: 2026-10-09
review by: 2026-12-15
supersedes: RA-002
---
```

E o `acceptances.py`, escrito na aula 12, continua relatando o antigo:

```
(.venv) ana@vm:~/tm/portal-model$ python3 acceptances.py 2026-10-09
        threat decision  owner   review by   status
DR-001  T03    mitigate  daniel  2027-09-30  ok
RA-001  T14    accept    daniel  2027-04-01  ok
RA-002  T06    accept    daniel  2026-10-02  OVERDUE by 7 days
RA-003  T06    accept    daniel  2026-12-15  ok
```

O registro diz que substitui o RA-002, e a ferramenta não conhece o campo. É o jeito pequeno e comum
de modelos morrerem: uma convenção é acrescentada e ninguém avisa o programa que lê os arquivos. A
checagem mais adiante nesta aula lê o `supersedes`.

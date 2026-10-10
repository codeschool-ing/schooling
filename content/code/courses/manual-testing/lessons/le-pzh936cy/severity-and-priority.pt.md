---
title: Severidade e prioridade
version: 1
---

A maioria dos testadores novos trata severidade e prioridade como um número escrito duas vezes: um
defeito grave é corrigido primeiro, um pequeno depois. **São duas perguntas diferentes, feitas por
pessoas diferentes.** Severidade é quanto estrago o defeito faz, e quem testa consegue medi-la no
produto. Prioridade é quando ele será corrigido, e isso depende de coisas que quem testa muitas
vezes não vê: a data da versão, o que mais está esperando, quem está prestes a usar qual página. Na
maior parte do tempo as duas concordam. Os casos em que não concordam são o motivo de existirem os
dois campos.

## Severidade: quanto estrago

Uma escala só serve se dois testadores põem o mesmo defeito no mesmo degrau, então cada degrau é
escrito como um teste que alguém consegue aplicar. Esta é uma escala comum de quatro degraus, a que
os critérios de saída da aula 1 usaram:

| severidade | o teste |
|---|---|
| **crítica** | dinheiro ou dados são perdidos ou cobrados indevidamente, ou o caminho principal para para todo mundo, e não há como contornar |
| **maior** | um requisito falha de um jeito que os usuários encontram, mas há como contornar, ou só alguns usuários encontram |
| **menor** | o requisito é cumprido no essencial e o produto fica mais difícil de usar do que devia |
| **trivial** | cosmético: uma palavra, uma cor, um alinhamento, sem efeito no que alguém consegue fazer |

Passe por ela os defeitos conhecidos do boxoffice 1.1. O desconto de estudante que a aula 10
encontrou é o mais claro:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=2&student=on' http://127.0.0.1:8000/book | grep -A1 'ticket(s)'
<p>Hamlet, 2 ticket(s), 10% off:
<strong>R$ 144,00</strong></p>
```

O R5 diz que estudantes pagam metade, então dois ingressos de Hamlet a R$ 80,00 deviam custar
R$ 80,00 no total. A página cobra R$ 144,00. Todo estudante que reserva paga a mais, em todo
pedido, e não há nada que possa fazer: **crítica**. O reembolso de pedido usado da aula 5 também é
crítico, pelo mesmo teste: o dinheiro volta por um lugar em que alguém sentou, e os lugares voltam
à venda.

O traceback da seção 02 é **maior**. A página de reserva falha e mostra as entranhas do programa a
quem digitou a palavra, mas um cliente que digita um algarismo reserva normalmente. A tabela de
espetáculos que a aula 7 encontrou com 760 pixels de largura é **menor**: no celular o cliente rola
para o lado e ainda reserva. *"An order that is used cannot be useed"*, da aula 11, é **trivial**:
uma frase com erro de grafia numa recusa que está, ela mesma, correta.

**Severidade é sobre o estrago, não sobre como o defeito foi achado ou quão difícil foi achá-lo.**
Um defeito que levou dois dias de exploração para aparecer pode ser trivial, e um que qualquer
pessoa encontra no primeiro minuto pode ser crítico.

## Prioridade: quando

Prioridade é uma ordem no tempo, geralmente escrita de P1 a P3 ou P4: corrigir antes do próximo
build, corrigir nesta versão, corrigir quando der. **Ela normalmente é definida na triagem, por
quem é dono do produto**, com quem testa e alguém do desenvolvimento na sala. A aula 16 é essa
reunião. Quem testa pode propor uma prioridade no relato; o campo é seu para sugerir e de outra
pessoa para decidir, porque os fatos que o movem raramente estão nas mãos de quem testa.

Esta é de novo a lista do boxoffice, com as prioridades que o gerente do teatro dá a cada um:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 300\" role=\"img\" data-fig=\"l15-severity-priority\" aria-label=\"Uma grade com a severidade ao longo da base, trivial, menor, maior e crítica, e a prioridade subindo pela lateral, P3 embaixo até P1 no alto. A, o desconto de estudante ignorado, e B, o pedido usado reembolsado, ficam em crítica e P1. C, o traceback com uma palavra, fica em maior e P2. D, a tabela de espetáculos com 760 pixels de largura, fica em menor e P1. E, cannot be useed, fica em trivial e P3.\"><rect x=\"110.0\" y=\"24.0\" width=\"86.0\" height=\"60.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"202.0\" y=\"24.0\" width=\"86.0\" height=\"60.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"294.0\" y=\"24.0\" width=\"86.0\" height=\"60.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"386.0\" y=\"24.0\" width=\"86.0\" height=\"60.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"110.0\" y=\"90.0\" width=\"86.0\" height=\"60.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"202.0\" y=\"90.0\" width=\"86.0\" height=\"60.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"294.0\" y=\"90.0\" width=\"86.0\" height=\"60.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"386.0\" y=\"90.0\" width=\"86.0\" height=\"60.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"110.0\" y=\"156.0\" width=\"86.0\" height=\"60.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"202.0\" y=\"156.0\" width=\"86.0\" height=\"60.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"294.0\" y=\"156.0\" width=\"86.0\" height=\"60.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"386.0\" y=\"156.0\" width=\"86.0\" height=\"60.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"98.0\" y=\"47.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">P1</text><text x=\"98.0\" y=\"62.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">próximo build</text><text x=\"98.0\" y=\"113.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">P2</text><text x=\"98.0\" y=\"128.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">nesta versão</text><text x=\"98.0\" y=\"179.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">P3</text><text x=\"98.0\" y=\"194.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">quando der</text><text x=\"153.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">trivial</text><text x=\"245.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">menor</text><text x=\"337.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">maior</text><text x=\"429.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">crítica</text><text x=\"291.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">severidade: quanto estrago</text><text x=\"14.0\" y=\"12.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">prioridade: quando</text><circle cx=\"413.0\" cy=\"54.0\" r=\"12\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><text x=\"413.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">A</text><circle cx=\"445.0\" cy=\"54.0\" r=\"12\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><text x=\"445.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">B</text><circle cx=\"337.0\" cy=\"120.0\" r=\"12\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><text x=\"337.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">C</text><circle cx=\"245.0\" cy=\"54.0\" r=\"12\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"245.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">D</text><circle cx=\"153.0\" cy=\"186.0\" r=\"12\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><text x=\"153.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">E</text><text x=\"502.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">A</text><text x=\"520.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">desconto de estudante ignorado</text><text x=\"502.0\" y=\"66.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">B</text><text x=\"520.0\" y=\"66.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pedido usado reembolsado</text><text x=\"502.0\" y=\"92.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">C</text><text x=\"520.0\" y=\"92.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">traceback com uma palavra</text><text x=\"502.0\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">D</text><text x=\"520.0\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">tabela com 760 px de largura</text><text x=\"502.0\" y=\"144.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">E</text><text x=\"520.0\" y=\"144.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">&quot;cannot be useed&quot;</text></svg>", "caption": "Cinco defeitos do boxoffice 1.1, avaliados duas vezes. Quem testa mede a coluna; a triagem decide a linha. D é o que surpreende: menor, e primeiro da fila.", "same": ["\"cannot be useed\"", "trivial"]}
```

Três dos cinco ficam onde você esperaria. Os outros dois mostram o que a prioridade sabe e a
severidade não.

**A tabela de espetáculos é menor e P1.** O gerente diz que a maior parte dos ingressos é vendida
pelo celular, e a propaganda da temporada, que leva direto à página de espetáculos, começa na
semana que vem. Nada no defeito mudou; mudou o custo de deixá-lo.

**O traceback é maior e só P2.** Ele tem contorno e poucos clientes o encontram, então espera atrás
de dois defeitos que tiram dinheiro de todo mundo. O ponto da aula 14 continua de pé, e é o
argumento que quem testa leva à triagem para subi-lo: uma página de erro que mostra código também é
informação entregue a um estranho.

A combinação que a figura não tem é a que mais surpreende: **crítica e prioridade baixa**. Uma
queda numa funcionalidade que ninguém alcança ainda, como a página de reserva de uma temporada que
só entra à venda no ano que vem, é crítica pela escala e pode esperar, porque nenhum cliente a
encontra antes de ser corrigida.

## Acertando os campos

**Não aumente a severidade para chamar atenção.** Um relato marcado como crítico que é claramente
menor ensina a triagem a ler suas severidades com desconto, e o próximo crítico que você abrir é
lido do mesmo jeito. Se você acha que algo merece ser corrigido antes, isso é um argumento sobre
prioridade, e o lugar dele é uma frase no relato dizendo por quê.

**A severidade não muda depois da triagem, a não ser que os fatos mudem.** A prioridade muda o
tempo todo: um prazo anda, um cliente reclama, uma correção em outro lugar barateia esta. A
severidade se move quando se aprende algo novo sobre o estrago, por exemplo que o traceback também
aparece numa página que todo cliente usa.

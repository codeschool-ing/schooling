---
title: Aprender agindo
version: 1
---

Um teste A/B aprende e depois age: divide os visitantes por igual até o fim, depois lança o vencedor.
Todo visitante mandado para a página pior durante o teste é um custo pago pelo conhecimento. **Um
bandido de várias alavancas** (*multi-armed bandit*), a forma mais simples de aprendizado por reforço,
mistura as duas coisas: desloca visitantes para a página que está indo melhor enquanto o teste ainda
roda.

```schooling-example
{"language": "python", "file": "bandit.py", "parts": [{"code": "import numpy as np\n\nrng = np.random.default_rng(16)\nrates = {\"old\": 0.042, \"new\": 0.046}\nvisitors = 50400", "note": "Duas páginas de checkout cujas taxas verdadeiras de conversão a simulação conhece e as estratégias não, e os mesmos 50.400 visitantes do teste da aula 10."}, {"code": "def run(choose):\n    shown = {\"old\": 0, \"new\": 0}\n    won = {\"old\": 0, \"new\": 0}\n    for n in range(visitors):\n        page = choose(n, shown, won)\n        shown[page] += 1\n        won[page] += rng.random() < rates[page]\n    return shown, sum(won.values())", "note": "Um visitante por vez: uma estratégia escolhe uma página, o visitante converte ou não, e a estratégia vê o resultado."}, {"code": "def ab_test(n, shown, won):\n    return \"new\" if n % 2 else \"old\"\n\n\ndef epsilon_greedy(n, shown, won, epsilon=0.1):\n    if rng.random() < epsilon or min(shown.values()) == 0:\n        return \"new\" if rng.random() < 0.5 else \"old\"\n    return max(shown, key=lambda p: won[p] / shown[p])", "note": "O teste A/B alterna e ignora os resultados. O epsilon-guloso mostra uma página ao acaso uma vez em dez, para seguir aprendendo, e no resto mostra a página que está convertendo melhor até ali."}, {"code": "for name, choose in ((\"A/B test, 50/50\", ab_test), (\"epsilon-greedy\", epsilon_greedy)):\n    shown, orders = run(choose)\n    cost = shown[\"old\"] * (rates[\"new\"] - rates[\"old\"])\n    print(f\"{name:16} new page shown to {shown['new'] / visitors:5.1%}, {orders:,} orders, \"\n          f\"about {cost:.0f} expected orders lost to the old page\")", "note": "O custo de cada estratégia são os visitantes que ela mandou para a página pior, vezes a diferença entre as taxas."}], "output": "A/B test, 50/50  new page shown to 50.0%, 2,133 orders, about 101 expected orders lost to the old page\nepsilon-greedy   new page shown to 66.7%, 2,335 orders, about 67 expected orders lost to the old page"}
```

**O bandido mostrou a página nova a 66,7% dos visitantes e perdeu cerca de 67 pedidos esperados para a
página antiga; a divisão igual perdeu cerca de 101.** Deslocar tráfego para o vencedor enquanto aprende
sai mais barato, e a diferença cresce com a distância entre as páginas e com a duração do teste.

Não é de graça, e o custo é aquele de que as aulas de A/B falavam. A estimativa do bandido para a
página antiga se apoia em bem menos visitantes, então **a medida dele da diferença é menos precisa**,
e as escolhas dele dependem dos primeiros resultados, que a aula 11 mostrou serem ruidosos: uma página
que começa com azar recebe menos visitantes e menos chances de se recuperar. Nesta rodada ele mostrou
a página nova a só dois visitantes em três, bem abaixo dos nove em dez que a regra dele alcançaria
quando tivesse certeza: com taxas de conversão tão próximas, as duas páginas trocam de lugar aos olhos
dele por muito tempo.

**A troca é aprender contra ganhar.** Quando a pergunta é "qual página, para decidir e seguir em
frente", um teste A/B responde de forma limpa e o resultado dele merece confiança. Quando a pergunta é
"mostre a melhor de várias manchetes pelos próximos dois dias e depois esqueça", um bandido ganha mais.
O aprendizado por reforço em escala completa, escolhendo sequências de ações em condições que mudam,
está muito além deste curso; a troca é a parte que uma analista de BI encontra.

---
title: O piso de toda ida e volta
version: 1
---

A imagem habitual de uma conexão lenta é a de um cano estreito: falta largura de banda, e um link
maior resolveria. Largura de banda é quanto chega por segundo quando os dados já estão fluindo.
**Latência é quanto tempo uma coisa leva para ir e voltar**, e ela tem um piso que nenhuma compra
move, porque o sinal precisa cobrir a distância.

Numa fibra óptica o sinal é luz, e a luz no vidro é mais lenta que no vácuo: cerca de dois terços,
perto de 200.000 km por segundo. Isso dá **200 km por milissegundo**, e é o número em que esta seção
inteira se apoia. Um pedido a um servidor a 2.000 km não pode ter resposta em menos de 20 ms, porque a
luz precisa de 10 ms para cada lado.

O programa abaixo calcula esse piso de São Paulo até três lugares. É aritmética sobre coordenadas
escritas nele; ele não envia nenhum pacote e não mede nada:

```schooling-example
{"language": "python", "file": "floor.py", "parts": [{"code": "from math import radians, sin, cos, asin, sqrt"}, {"code": "EARTH_KM = 6371          # mean radius of the Earth\nFIBRE_KM_PER_MS = 200    # light in glass: about two thirds of c", "note": "**Duas constantes carregam o argumento inteiro.** O raio médio da Terra transforma graus em quilômetros. A luz no vácuo percorre cerca de 300.000 km por segundo; no vidro de uma fibra óptica ela desacelera para uns dois terços disso, perto de 200.000 km por segundo, ou seja, 200 km a cada milissegundo."}, {"code": "PLACES = {               # latitude, longitude in degrees\n    'Sao Paulo': (-23.55, -46.63),\n    'Fortaleza': (-3.72, -38.54),\n    'Ashburn':   (39.04, -77.49),\n    'Frankfurt': (50.11, 8.68),\n}", "note": "Os quatro lugares, escritos no programa para você conferir em qualquer mapa. Ashburn faz as vezes da `us-east-1`, que a lista do CLI chama de US East (N. Virginia), e Frankfurt, da `eu-central-1`. Os pontos são cidades, não datacenters: os provedores não publicam onde ficam os prédios."}, {"code": "def great_circle_km(a, b):\n    lat1, lon1, lat2, lon2 = map(radians, (*a, *b))\n    h = sin((lat2 - lat1) / 2) ** 2 + cos(lat1) * cos(lat2) * sin((lon2 - lon1) / 2) ** 2\n    return 2 * EARTH_KM * asin(sqrt(h))", "note": "A fórmula de haversine: o comprimento do caminho mais curto sobre a superfície de uma esfera entre dois pontos. É a linha reta que um cabo seguiria se o fundo do mar, a costa e os países no meio deixassem."}, {"code": "for dest in ('Fortaleza', 'Ashburn', 'Frankfurt'):\n    km = great_circle_km(PLACES['Sao Paulo'], PLACES[dest])\n    rtt_ms = 2 * km / FIBRE_KM_PER_MS\n    print(f'Sao Paulo -> {dest:<10} {km:6.0f} km   round trip >= {rtt_ms:5.1f} ms')", "note": "**A ida e volta é a distância duas vezes**, ida e retorno, dividida pela velocidade na fibra. É o menor tempo que qualquer pedido pode levar para chegar à outra ponta e trazer uma resposta, antes que um único roteador, fila ou servidor tenha feito qualquer coisa."}], "output": "Sao Paulo -> Fortaleza    2370 km   round trip >=  23.7 ms\nSao Paulo -> Ashburn      7664 km   round trip >=  76.6 ms\nSao Paulo -> Frankfurt    9829 km   round trip >=  98.3 ms"}
```

**O piso de São Paulo até o norte da Virgínia é de 76,6 ms.** Até Fortaleza, que ainda é Brasil, é de
23,7 ms, e até Frankfurt, de 98,3 ms. Divida dois deles e a forma aparece: 76,6 / 23,7 dá 3,2, então
toda ida e volta até a Virgínia custa pelo menos três vezes mais tempo que uma até Fortaleza.

## Por que os números reais são maiores

**Toda ida e volta real é mais longa que esse piso**, por motivos que só somam:

- Cabos não seguem grandes círculos. Eles correm ao longo da costa, sob trechos específicos do mar, e
  entram nas cidades onde chegam. Muitos dos cabos submarinos que saem do Brasil chegam perto de
  Fortaleza, então o tráfego de São Paulo para a América do Norte por esses cabos sobe a costa
  primeiro, um caminho mais longo que a linha reta que o programa mediu.
- Cada roteador no caminho lê o pacote e o põe numa fila atrás de outros antes de encaminhá-lo. Um
  roteador sozinho acrescenta pouco; um caminho por uma dúzia deles, alguns ocupados, soma.
- O próprio servidor leva tempo para responder, e o sistema operacional de cada ponta também.

Então o número que o programa imprimiu é um limite, e uma medição real daria acima dele. Quanto acima
é algo que você descobre medindo o seu próprio caminho com `ping` e `traceroute`, as ferramentas do
curso `networks`. Este curso não mede por você, porque um número medido de uma máquina num dia seria
apresentado como um fato sobre o caminho de todo mundo. **Nada nesta seção foi medido numa rede.**

## Para que o piso serve

Um limite que você não consegue bater ainda é o número mais útil aqui, por dois motivos.

**Ele diz quais projetos não podem funcionar.** Se um usuário em São Paulo precisa de uma resposta em
menos de 50 ms, um servidor na Virgínia está descartado antes de qualquer benchmark: 76,6 ms já
estouram o orçamento com uma rede perfeita e um servidor instantâneo. Nenhum ajuste ou largura de
banda muda isso; só mudar o servidor de lugar muda.

**Ele cresce com o número de viagens.** Uma ida e volta de 76,6 ms é difícil de notar. A próxima seção
pega uma página que espera vinte delas, uma após a outra, e o piso vira mais de um segundo de espera
que o usuário vê a cada carregamento.

Uma regra prática sai direto da constante, e vale guardar: **um milissegundo de ida e volta para cada
100 km de distância em linha reta.** São Paulo a Fortaleza são 2.370 km, então pelo menos 23,7 ms. A
regra é a mesma divisão que o programa faz, feita de cabeça, e é por isso que a escolha de região nas
próximas seções é uma pergunta de geografia antes de ser uma pergunta sobre qualquer outra coisa.

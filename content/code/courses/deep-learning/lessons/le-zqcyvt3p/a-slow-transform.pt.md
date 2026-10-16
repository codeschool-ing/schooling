---
title: Uma transformação que custa trabalho de verdade
version: 1
---

Ler um dígito não custa nada, porque ele já é uma linha de números na memória. **Um pipeline de
imagens de verdade paga por cada imagem que lê**: o arquivo é decodificado de JPEG ou PNG, recortado
e redimensionado, espelhado ou girado ao acaso, transformado em tensor e normalizado. Tudo isso roda
no processador, uma vez por imagem por época, antes que a rede veja um único pixel.

Para sentir esse custo nos dígitos, esta aula lhes dá uma transformação que faz um trabalho
comparável. Salve como `~/dl/warp.py`:

```schooling-example
{
  "language": "python",
  "file": "warp.py",
  "parts": [
    {
      "code": "\"\"\"warp: a transform that costs real work for every image read, as decoding and augmenting a photograph does.\"\"\"\nimport torch\nimport torch.nn.functional as F",
      "note": "Tudo aqui é aritmética comum de tensores, do `torch.nn.functional`: nenhuma biblioteca de transformações de imagem, e nada de dormir para fingir um custo."
    },
    {
      "code": "class Warp:\n    \"\"\"Turn a flat 8x8 digit into a 32x32 image, bent by a smooth random field, with noise added.\"\"\"\n\n    def __init__(self, size=32, work=128, strength=0.08, noise=0.05):\n        self.size, self.work, self.strength, self.noise = size, work, strength, noise\n        self.base = F.affine_grid(torch.eye(2, 3)[None], [1, 1, work, work], align_corners=False)\n\n    def __call__(self, img):\n        w = self.work\n        big = F.interpolate(img.reshape(1, 1, 8, 8), size=(w, w), mode=\"bicubic\", align_corners=False)\n        field = F.interpolate(2 * torch.rand(1, 2, 4, 4) - 1, size=(w, w), mode=\"bicubic\", align_corners=False)\n        bent = F.grid_sample(big, self.base + self.strength * field.permute(0, 2, 3, 1),\n                             mode=\"bicubic\", align_corners=False)\n        small = F.interpolate(bent, size=(self.size, self.size), mode=\"bilinear\", antialias=True, align_corners=False)\n        return small[0] + self.noise * torch.randn(1, self.size, self.size)",
      "note": "Quatro passos para cada imagem. Ampliar o dígito 8x8 para 128x128 por interpolação bicúbica; fazer um campo aleatório suave a partir de números aleatórios 4x4; mover cada pixel ao longo desse campo com o `grid_sample`, que entorta os traços como duas pessoas escrevem um mesmo dígito de jeitos diferentes; reduzir o resultado para 32x32 com antialiasing e somar um pouco de ruído. Trabalhar em 128 e reduzir é o que um pipeline de verdade faz com uma foto grande, e é daí que vem o custo."
    }
  ]
}
```

O entortamento é uma versão da distorção elástica que Patrice Simard e colegas usaram em dígitos
manuscritos em 2003: um campo aleatório suave move cada pixel um pouco, e os traços saem do jeito
que outra pessoa poderia ter escrito o mesmo dígito. É um aumento de dados, e a aula 7 disse por que
o aumento ajuda; **aqui ele é uma carga de trabalho**. Nada nele dorme ou espera: cada microssegundo
que ele leva é aritmética.

Agora meça. Salve como `~/dl/slow.py`:

```schooling-example
{
  "language": "python",
  "file": "slow.py",
  "parts": [
    {
      "code": "\"\"\"slow: what the warp costs per image against a plain read, and what it makes of digit 0.\"\"\"\nimport time\n\nimport torch\n\nfrom dset import Digits\nfrom warp import Warp\n\ntorch.manual_seed(0)\nplain, warped = Digits(\"train\"), Digits(\"train\", transform=Warp())\nfor name, ds in ((\"plain\", plain), (\"warped\", warped)):\n    start = time.perf_counter()\n    for i in range(len(ds)):\n        ds[i]\n    per = (time.perf_counter() - start) / len(ds)\n    print(f\"{name:6s} {per * 1e6:7.1f} microseconds an image, {per * len(ds):.3f} s for all {len(ds)}\")",
      "note": "Cada item do conjunto de treino lido uma vez, com e sem a transformação, cronometrado com `time.perf_counter`. Ler um item simples é indexar dois tensores que já estão na memória."
    },
    {
      "code": "img, label = warped[0]\nprint(\"item 0:\", tuple(img.shape), \" label\", label.item(), \" read again, same image:\", torch.equal(img, warped[0][0]))",
      "note": "O mesmo índice lido duas vezes. A transformação roda a cada leitura e sorteia números aleatórios novos toda vez."
    },
    {
      "code": "RAMP = \" .:-=+*#%█\"\n\n\ndef rows(picture):\n    \"\"\"A 32x32 picture as 16 lines of characters, two pixel rows to a line.\"\"\"\n    shades = picture.reshape(16, 2, 32).mean(dim=1).clamp(0, 1)\n    return [\"\".join(RAMP[int(v * 9.99)] for v in row) for row in shades]",
      "note": "Uma figura no terminal: cada brilho de 0 a 1 vira um de dez caracteres, de um espaço até um bloco cheio. Duas linhas de pixels dividem uma linha de texto porque um caractere tem quase o dobro de altura que de largura."
    },
    {
      "code": "original = plain[0][0].reshape(8, 8).repeat_interleave(4, dim=0).repeat_interleave(4, dim=1)\npanels = [rows(original), rows(warped[0][0][0]), rows(warped[0][0][0])]\nfor line in zip(*panels):\n    print(\"  \".join(line))",
      "note": "Três painéis lado a lado: o dígito 8x8 original com cada pixel repetido quatro vezes, depois duas leituras do mesmo item entortado."
    }
  ]
}
```

```
ana@vm:~/dl$ python slow.py
plain      3.5 microseconds an image, 0.004 s for all 1077
warped  1747.1 microseconds an image, 1.882 s for all 1077
item 0: (1, 32, 32)  label 6  read again, same image: False
            %%%%====                         :=##%#**=:.                        -*##+-:.            
            %%%%====                      . :=+%%%%*=-..                      .-+*#%#+-:.           
        ====%%%%....                      .-=+#%%%+=:                       ..:+*%%%+=:             
        ====%%%%....                     .:=+%##++:.                       .:=+*###*=:.             
        %%%%----                         -=*#**=-:.                        .=*#**+=-:.              
        %%%%----                         -#%%*=.                           :*%█%+-.                 
        ████....                        .-#█%*-.                           -*%█#=.                  
        ████....                         -+██#+:....::..                  :=%██#=:....   ....       
    ....████****########....            .-*██%#*=++*+*++=-::             .=+%██%*+-===*+**+=-:.     
    ....████****########....           . -+%██%%**+***##**+=-:.          .+*%██%#*++**#####**==-. . 
    ....████****----++++####            .-+*████#+=---=+*###*+=:.       .:=*%███%#*===-++**##**+-:. 
    ....████****----++++####             :=*███%#+-::-=+###%%#+=:         :+#███%#*=:.-=+##%%█#*+-. 
        %%%%****::::%%%%****             :=+#%##*+---=**#%%█%#*-.         .-**%%%%*=-:-*#%%█%█%*+-. 
        %%%%****::::%%%%****             ..:-=+*####*##%%#%##+=-.         ..::=++##***########**=-. 
            ####████****....                 .-=#████%%***++=-::.               -+%████%#*+====::.  
            ####████****....                   ..::--=+++=:::.                  ..:-----=----.      
```

**Ler uma imagem simples levou 3,5 microssegundos; ler uma entortada levou 1747,1**, umas
quinhentas vezes mais. No conjunto de treino isso dá 0,004 segundo contra 1,882 segundo por
passada, e é pago de novo a cada época, porque a transformação roda dentro do `__getitem__`. São
tempos de uma máquina num momento, e os seus vão ser outros: o que se transfere é a proporção, uma
transformação custando centenas de vezes o que a leitura em si custa.

A figura mostra por que ela precisa rodar toda vez. O primeiro painel é o item 0 como está guardado,
um 6 em blocos de 8 por 8. Os outros dois são o mesmo item lido duas vezes, **e não são a mesma
imagem**: `read again, same image: False`. Cada leitura sorteia um campo novo e um ruído novo, então
a cada época a rede vê um 6 um pouco diferente. Calcular os entortamentos uma vez e guardá-los
deixaria a leitura de graça e transformaria o aumento de dados em 1.077 imagens fixas.

As duas próximas seções perguntam o que esse custo faz com o treino, e o que dá para fazer a
respeito.

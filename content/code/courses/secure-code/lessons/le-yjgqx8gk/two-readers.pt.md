---
title: Dois leitores para cada falha
version: 1
---

Quando algo quebra, duas pessoas diferentes precisam saber, e precisam de coisas diferentes. **Quem
enviou a requisição precisa saber que falhou e o que fazer a seguir. A equipe precisa saber
exatamente por quê.** O erro mais comum é dar o mesmo texto aos dois leitores, e aí ou a equipe
recebe de menos ou o estranho recebe demais.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l15-two\" aria-label=\"Uma falha, escrita para dois leitores. À esquerda, a página de erro, lida por quem enviou a requisição, que pode ser qualquer um: diz que algo deu errado do lado do portal e dá uma referência curta. À direita, o log, lido só pela equipe: traz a mesma referência, a hora, o caminho que falhou e o traceback completo. A referência é a única coisa que os dois compartilham, e é o que permite à equipe achar a falha que um paciente relata.\"><defs><marker id=\"l15-two-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"170\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">a página de erro</text><text x=\"170\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">lida por quem enviou a requisição</text><rect x=\"20\" y=\"56\" width=\"300\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"40\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">something went wrong on our side</text><text x=\"40\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">reference: …</text><text x=\"535\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">o log</text><text x=\"535\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">lido só pela equipe</text><rect x=\"370\" y=\"56\" width=\"330\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"386\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ref=…  path='/patients/…'</text><text x=\"386\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Traceback (most recent call last):</text><text x=\"386\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">  … KeyError: 'marta'</text><path d=\"M170 166 L170 200 L535 200 L535 166\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-two-ah-paper-dim)\" marker-start=\"url(#l15-two-ah-paper-dim)\"></path><text x=\"352\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">a referência liga os dois</text></svg>", "caption": "A página diz à pessoa o que aconteceu; o log diz à equipe por quê. Só a referência aparece nos dois."}
```

### A página de erro é pública

Quem envia uma requisição lê a resposta, e pode ser um paciente, um script ou alguém mapeando o portal
de fora. Uma página de erro com traceback, comando SQL, caminho de arquivo ou versão de biblioteca
conta a todos eles como a aplicação é construída. Cada fato é pequeno. Juntos, poupam a alguém horas
de adivinhação, um tempo que quem defende preferiria que eles gastassem.

Então a página diz o que aconteceu com palavras que um paciente consegue usar, e dá uma
**referência**: um código curto e aleatório que não significa nada lá fora, e que a equipe consegue
buscar.

### O log é privado, e mesmo assim não é um cofre

O log é onde o detalhe pertence: a referência, a hora, o caminho, o traceback, os identificadores
necessários para achar o registro que quebrou. **Ele é lido por menos gente que a página, e por mais
gente do que alguém lembra**: todos com acesso ao serviço de logs, aos backups dele e a qualquer lugar
para onde uma linha de log é copiada quando alguém a cola num chamado. A aula 16 listou uma linha de
log entre os lugares de onde um segredo vaza. Então o log traz o que a equipe precisa para consertar
as coisas, e nada que faria mal ler.

### Os dois são escritos de propósito

Nem a página nem a linha de log devem ser o que o framework produz por padrão. A própria página 500 do
Flask é um bom padrão, dizendo *Internal Server Error* e mais nada; o problema começa quando alguém a
troca por algo mais útil para si mesmo, que foi exatamente o que aconteceu no portal, e a próxima
seção mostra.

---
title: Uma semana da rotina
version: 1
---

"Responsabilidade compartilhada pela segurança" é a frase que toda palestra de DevSecOps contém, e
ela não diz nada até virar um conjunto de hábitos que alguém pudesse observar. Esta seção acompanha
um time pequeno durante uma semana, com o pipeline que este curso monta, e dá nome a cada hábito
quando ele aparece. As aulas 2 a 20 tratam deles um por um.

### Segunda: uma mudança, e um build que quebra

Uma desenvolvedora acrescenta um filtro à busca do linkbox e escreve o SQL juntando o texto do
usuário à consulta. Antes do push, ela roda no laptop os estágios rápidos do pipeline, o mesmo
script que o servidor roda, e o estágio de análise estática para naquela linha, citando a regra e o
motivo. Ela muda a consulta para receber um parâmetro, acrescenta um teste com um apóstrofo no texto
da busca e faz o push. O ciclo inteiro levou dez minutos e ninguém mais se envolveu.

**Hábito: as mesmas checagens rodam no laptop e no servidor.** A aula 2 monta isso, e a aula 3
escreve a análise estática que ela rodou.

### Terça: um achado que ninguém consegue corrigir

O estágio de análise de composição aponta um aviso de segurança numa biblioteca que o serviço usa.
Ainda não existe versão corrigida. Quebrar todo build até os mantenedores publicarem uma pararia
todo o trabalho por um problema que ninguém no time consegue resolver, então o pipeline reporta um
alerta e o build passa. O security champion do time, um desenvolvedor que dedica algumas horas por
semana a isso, lê o aviso: ele depende de um recurso que o linkbox não usa. Ele registra isso, com
uma data para olhar de novo.

**Hábito: uma checagem quebra o build só pelo que quem o quebrou consegue corrigir.** A aula 7 é o
argumento inteiro, e as outras aulas do curso se apoiam nela.

### Quarta: um segredo num commit

Alguém cola um token num arquivo de teste para experimentar algo e faz commit. O commit nunca sai
do laptop: um hook varre o que está no stage e o recusa. Se tivesse sido enviado, o primeiro estágio
do servidor o recusaria de novo, e a resposta começaria por **revogar o token, não por apagar a
linha**, porque um segredo enviado já foi copiado para todo lugar onde o repositório foi clonado.

**Hábito: segredos são pegos antes de serem compartilhados, e tratados como queimados quando foram.**
Aula 6.

### Quinta: a execução noturna

Durante a noite, o pipeline reconstruiu a imagem do zero, sem cache. Um pacote da imagem base tinha
ganhado uma correção no dia anterior, e a reconstrução a incorporou sem ninguém editar uma linha. A
varredura dinâmica da cópia de staging também rodou à noite, porque leva minutos que os pushes do
dia não deveriam esperar.

**Hábito: checagens lentas rodam com agenda, para as rápidas poderem rodar em todo push.** Aulas 2, 4
e 8.

### Sexta: o que a semana contou

O champion olha quatro números: quantos achados foram abertos e fechados, há quanto tempo os
abertos estão abertos, quais repositórios e imagens foram varridos, e quantas exceções expiram na
semana seguinte. Nenhum deles é meta, e a aula 20 explica por que transformar um deles em meta o
estraga.

**Hábito: o programa é medido pela rapidez com que os achados fecham, não por quantos são achados.**

### A vida de um achado

Todo achado daquela semana passou pelos mesmos estados, fosse qual fosse a ferramenta que o
levantou:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"sp-l01-life\" aria-label=\"Os estados por que passa um achado. Uma checagem o levanta; uma pessoa faz a triagem para um de três desfechos: corrigido, e depois verificado pela mesma checagem passando; em exceção até uma data, com um motivo, e levantado de novo quando a data passa; ou falso positivo, e a checagem é ajustada para parar de levantá-lo.\"><defs><marker id=\"sp-l01-life-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l01-life-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"115\" width=\"130\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">levantado</text><text x=\"85.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">por uma checagem</text><rect x=\"200\" y=\"115\" width=\"170\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"285.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">triado</text><text x=\"285.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">por uma pessoa, por escrito</text><rect x=\"430\" y=\"20\" width=\"130\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"495.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">corrigido</text><text x=\"495.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">na própria mudança</text><rect x=\"590\" y=\"20\" width=\"115\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"647.5\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">verificado</text><text x=\"647.5\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a checagem passa</text><rect x=\"430\" y=\"115\" width=\"190\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"525.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">em exceção</text><text x=\"525.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">até uma data, com motivo</text><rect x=\"430\" y=\"210\" width=\"190\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"525.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">falso positivo</text><text x=\"525.0\" y=\"247.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a checagem é ajustada</text><path d=\"M150 143 L198 143\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l01-life-ah-paper-dim)\"></path><path d=\"M370 130 L400 130 L400 48 L428 48\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l01-life-ah-paper-dim)\"></path><path d=\"M370 143 L428 143\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l01-life-ah-paper-dim)\"></path><path d=\"M370 156 L400 156 L400 238 L428 238\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l01-life-ah-paper-dim)\"></path><path d=\"M560 48 L588 48\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l01-life-ah-paper-dim)\"></path><path d=\"M620 143 L660 143 L660 100 L85 100 L85 113\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sp-l01-life-ah-amber)\"></path><text x=\"560\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">a data passa</text></svg>", "caption": "Três saídas da triagem, e uma delas volta sozinha."}
```

O estado que mais importa é o do meio. **A triagem é uma decisão de uma pessoa, por escrito**: o
achado é real e é corrigido, ou é real e fica em exceção até uma data, com um motivo, ou não é real
e a checagem é ajustada para parar de dizer isso. Um achado que não está em estado nenhum, levantado
e nunca respondido, é como um pipeline ensina um time a ignorá-lo.

### Quem faz o quê

| papel | o que muda na semana |
|---|---|
| desenvolvedor | corrige o que o pipeline acha na própria mudança, antes do merge; roda as checagens rápidas no laptop |
| security champion | um por time, em tempo parcial: faz a triagem do que não é óbvio, mantém as exceções honestas, leva ao time de segurança o que precisa dele |
| engenheiro de segurança | escolhe e ajusta as checagens, escreve as regras próprias, decide os casos difíceis, mede o programa |
| plantão | trata os achados que chegam de fora do pipeline: um aviso novo sobre algo que já está rodando |

Nenhum desses papéis é novo. O que é novo é que **o pipeline é onde eles se encontram**, e o código
do pipeline é onde os acordos entre eles ficam escritos.

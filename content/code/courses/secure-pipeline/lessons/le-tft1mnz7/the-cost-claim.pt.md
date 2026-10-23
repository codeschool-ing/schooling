---
title: O custo de um achado tardio, e o número que todo mundo cita
version: 1
---

Todo argumento a favor do shift left acaba no mesmo gráfico. Uma barra para cada fase de um projeto:
um defeito custa 1 unidade para corrigir no design, 6,5 na implementação, 15 nos testes e **100
depois do release**, atribuído ao "IBM Systems Sciences Institute". Ele está em slides de
fornecedores e em livros didáticos, e é citado como medição.

**Ninguém que foi procurar achou o estudo por trás dele.** A trilha termina em apostilas de um
instituto de treinamento da IBM do começo dos anos 1980, citadas de segunda mão por livros
posteriores. Nenhum artigo com os projetos, os dados ou o método apareceu. *The Leprechauns of
Software Engineering*, de Laurent Bossavit, é o relato mais conhecido dessa busca, e trata o gráfico
como o que ele é: um número repetido tantas vezes que parece um achado.

### O que os dados antigos de fato diziam

Há dados reais por perto, e eles são mais estreitos que o gráfico. *Software Engineering Economics*
(1981), de Barry Boehm, reuniu o custo de corrigir defeitos em grandes projetos dos anos 1970. Eles
eram construídos em fases longas e sequenciais, então um requisito mal entendido no começo podia ser
descoberto anos depois, num sistema já entregue. Em 2001, Boehm e Victor Basili puseram "muitas vezes
100 vezes mais caro" no topo da lista de fatos sobre redução de defeitos que publicaram na *IEEE
Computer*. O mesmo item dizia que, em sistemas pequenos e não críticos, a razão ficava **mais perto
de 5 para 1**.

A versão honesta, então, é esta. Em projetos grandes com fases longas, defeitos tardios custam bem
mais que os precoces. Os estudos antigos viram razões de dezenas a cem. Onde o sistema era pequeno, a
diferença era pequena já naquela época. **Ninguém mediu achados de segurança num pipeline de um
serviço como o linkbox**, e um slide que aplica 100x a ele está enfeitando um argumento com um número
que não tem.

### O argumento sem o número

O shift left não precisa do gráfico. Precisa de quatro coisas que valem para o linkbox hoje, e cada
uma pode ser conferida em vez de acreditada:

| o que cresce com o tempo | por quê |
|---|---|
| **o contexto a reconstruir** | o autor de uma mudança sabe por que cada linha está ali por algumas horas; uma semana depois ele a lê como qualquer outra pessoa |
| **o código construído em cima** | outras mudanças passam a depender da que tem a falha, então a correção mexe em mais do que a linha errada |
| **as cópias** | depois do push a imagem está no registry, nos servidores e em caches; a correção tem de chegar a cada cópia |
| **o tempo de exposição** | uma falha em produção fica aberta a quem a encontrar, enquanto estiver lá |

Nenhuma delas precisa de multiplicador para convencer, e nenhuma diz o tamanho da diferença. Essa
parte é uma medição que o seu próprio time pode fazer: **quanto tempo, em minutos, do push de uma
mudança até ler o resultado**, e quanto tempo, em dias, de um achado levantado até ele ser corrigido.
Esta aula mede o primeiro no linkbox, e a aula 20 mede o segundo.

### Por que isso importa num curso de segurança

Um programa de segurança vive de confiança. Pede-se aos desenvolvedores que aceitem um pipeline mais
lento e um build que quebra por motivos que eles não escolheram. Eles aceitam porque acreditam em
quem pede. **Um número que desmorona quando alguém confere gasta essa confiança.** O desenvolvedor
que procura os 100x e acha apostilas que ninguém consegue ler vai se perguntar o que mais no slide era
enfeite. Cite o que você mediu; onde não há medição, dê os motivos e diga que são motivos.

É a mesma disciplina que este curso mantém nas próprias transcrições. Cada contagem citada, dos
achados do Bandit na aula 3 às vulnerabilidades de uma imagem na aula 8, foi impressa por uma
ferramenta numa máquina como a sua, e você pode fazer a ferramenta imprimir de novo.

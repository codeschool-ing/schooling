---
title: Evidência
version: 1
---

Os passos dizem ao leitor como ver a falha. **A evidência deixa que ele a veja sem rodar nada**, e
isso importa mais vezes do que parece: o desenvolvedor está lendo no celular entre duas reuniões, o
dono do produto na triagem não tem uma cópia da aplicação, o defeito só acontece na sua máquina. Um
relato com boa evidência pode ser julgado antes que alguém o reproduza, e um relato sem nenhuma
espera até alguém ter tempo.

Três tipos de evidência cobrem quase todo defeito de uma aplicação web, e o defeito da seção 02
desta aula tem os três.

## A transcrição

O que a aplicação devolveu, como texto, com o comando que pediu. A seção 03 já a tem: o comando
curl e o traceback que ele imprimiu. **Texto é a melhor evidência que existe**, porque o leitor pode
buscá-lo, copiar uma linha para o próprio terminal e comparar caractere por caractere com o que ele
obtém. A linha que importa é a última:

```
ValueError: invalid literal for int() with base 10: 'two'
```

Cole essa linha no relato como texto, dentro de um bloco de código se a ferramenta tiver um. Uma
captura de tela da mesma linha não pode ser buscada nem copiada, e no celular não se lê. O
traceback inteiro também vai no relato, abaixo dela, porque o desenvolvedor vai querer os números de
linha.

## A linha de log do servidor

O navegador e o curl mostram o que o cliente viu. O terminal do servidor mostra o que o servidor
achou que fez, e os dois podem discordar, por isso um relato traz os dois quando pode. No terminal
onde o boxoffice está rodando, a requisição da seção 03 acrescentou esta linha:

```
127.0.0.1 - - [10/Oct/2026 04:13:43] "POST /book HTTP/1.1" 500 -
```

Ela diz quem pediu (`127.0.0.1`, esta máquina), quando, o que foi pedido (`POST /book`) e o que foi
respondido (`500`). A hora entre colchetes é o relógio do seu computador, então a sua vai ser
outra; cite como você a vê. **Uma linha de log amarra o relato a um momento**, e num servidor de
teste compartilhado, onde um desenvolvedor pode abrir o log completo, esse momento é como ele acha a
sua requisição no meio das de todo mundo.

O log do boxoffice é curto porque o programa é pequeno. Um servidor de verdade escreve mais em volta
de uma falha, muitas vezes o traceback inteiro, e a regra é a mesma: cite as linhas que pertencem à
sua requisição, e diga onde está o resto do log, em vez de anexar uma tarde inteira dele.

## A captura de tela

Uma captura de tela é a evidência do que só se vê: um layout, uma cor, uma página que aparece
errada. Para este defeito ela acrescenta um fato que o texto não tem. No navegador o traceback é a
página inteira, sem título na aba, sem nenhum dos links do teatro e sem rodapé, então o cliente não
vê caminho de volta além do botão do próprio navegador.

Uma boa captura mostra a barra de endereço, para o leitor saber que página era, e o mínimo possível
além disso. **Recorte na janela, não na área de trabalho inteira**, e marque com um retângulo a
parte que importa se a imagem estiver carregada. Se o defeito é uma sequência, por exemplo um botão
que pisca, uma gravação curta da tela substitui a captura; uma gravação de algo que uma captura
mostraria é um minuto do tempo de alguém para achar um quadro.

## O que a evidência não pode carregar

A evidência sai da sua máquina e vai morar numa ferramenta que muita gente lê. Antes de anexar
qualquer coisa, olhe para ela como um estranho olharia.

**Senhas, tokens e dados de outras pessoas saem.** A conta semeada do boxoffice e a senha dela são
dados de teste, e o curso as imprime de propósito. O nome, o e-mail ou o número de cartão de um
cliente real numa captura é um vazamento com o seu nome nele, e a aula 20 trata de criar dados de
teste que nunca precisaram ser escondidos. Borre ou substitua, e diga no relato que fez isso.

**Um defeito de segurança vai para quem precisa dele, não para todo mundo.** O traceback é um
exemplo pequeno do tipo que a aula 14 descreveu: ele mostra caminhos de arquivo e código a quem o
provoca. Numa ferramenta que a empresa inteira lê, ou numa pública, um relato de como fazer uma
página vazar as próprias entranhas é informação para um atacante também. A maioria das ferramentas
consegue restringir quem vê um item, e a maioria das organizações diz para onde vão os relatos de
segurança; siga isso, e mantenha a reprodução exata mesmo assim, porque quem vai corrigir precisa
dela tanto quanto qualquer um.

**A evidência combina com o relato.** Uma transcrição da 1.0 anexada a um relato contra a 1.1, ou
uma captura de uma conta diferente da que os passos citam, faz o leitor duvidar de todo o resto da
página. Quando a versão muda, rode de novo e troque a evidência.

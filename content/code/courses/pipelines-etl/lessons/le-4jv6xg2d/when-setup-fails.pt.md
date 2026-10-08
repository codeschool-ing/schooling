---
title: Quando a montagem falha
version: 1
---

O `setup.sh` para no primeiro erro em vez de seguir em frente, então **a última linha que ele
imprimiu é a linha que quebrou.** Leia essa antes de qualquer outra coisa. Rodá-lo de novo é sempre
seguro: ele mantém o que está feito e continua de onde parou. Cinco falhas explicam quase todos os
casos:

- **Uma linha terminando em `is required: apt-get install …`, ou `there is no user ana`.** Falta
  algo da primeira seção desta lição. Instale o que ela cita, ou crie o usuário, e rode a montagem
  de novo.
- **`/home/ana/pontofinal/shop.sh is missing`**, ou o mesmo para outro arquivo. A montagem procura
  os arquivos ao lado dela, então os quatro ficam em `~/pontofinal`, com exatamente esses nomes.
- **O `pip` não alcança o índice de pacotes.** O erro fala de timeout, de certificado ou de proxy. O
  Airflow é instalado contra um arquivo de restrições baixado do GitHub, então a máquina precisa
  alcançar tanto `pypi.org` quanto `raw.githubusercontent.com`. Tente um `pip install requests` à
  mão na máquina virtual: quando ele funcionar, a montagem funciona.
- **`Text file busy` ou `Permission denied` em `/opt/etl`.** Algo de uma tentativa anterior ainda
  está rodando. `sudo shop down` para tudo o que o `shop` iniciou, e aí a montagem consegue
  substituir os arquivos.
- **`No space left on device`.** Os ambientes virtuais precisam de 1,3 GB de uma vez, e o cache de
  downloads do pip de outro tanto enquanto trabalha. Dê um disco maior à máquina virtual, ou apague
  `/root/.cache/pip` depois da primeira execução bem-sucedida.

**Uma falha não imprime erro nenhum: um arquivo copiado com uma linha faltando.** O gerador roda
mesmo assim, e sorteia outra loja. A linha dele na saída da montagem é a conferência, `customers
5079, orders 17012, lines 26620 at 2026-02-28; 31 days of changes`. Se a sua for diferente, copie o
arquivo de novo, apague `/var/lib/etl-data` para a montagem sorteá-lo outra vez, rode a montagem e
depois `sudo shop reset`.

Dois hábitos facilitam o resto do curso. **Rode `sudo shop reset` sempre que uma lição pedir**: ele
devolve a loja à noite de 28 de fevereiro, esvazia o warehouse e faz o Airflow esquecer tudo, para
os seus números voltarem a bater com os da lição. E **nunca conserte o laboratório editando o banco
da loja à mão**: os pipelines deste curso o leem, e uma linha que você mudou pelas costas do `shop`
é uma linha que faz a sua saída discordar da página por motivos que ninguém encontra.

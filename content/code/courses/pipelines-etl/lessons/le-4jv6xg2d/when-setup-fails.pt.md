---
title: Quando a montagem falha
version: 1
---

O `lab.sh` para no primeiro erro em vez de seguir em frente, então **a última linha que ele
imprimiu é a linha que quebrou.** Leia essa antes de qualquer outra coisa. Quatro falhas explicam
quase todos os casos:

- **`PostgreSQL 16 is required: apt-get install postgresql-16`.** O script não achou o `initdb`.
  Instale o pacote e rode `lab.sh up` de novo; ele pula o que já está feito e continua de onde
  parou.
- **O `pip` não alcança o índice de pacotes.** O erro fala de timeout, de certificado ou de proxy. O
  Airflow é instalado contra um arquivo de restrições baixado do GitHub, então a máquina precisa
  alcançar tanto `pypi.org` quanto `raw.githubusercontent.com`. Tente um `pip install requests` à
  mão na máquina virtual: quando ele funcionar, o script funciona.
- **`Text file busy` ou `Permission denied` em `/opt/etl`.** Algo de uma tentativa anterior ainda
  está rodando. `sudo bash ~/lab/lab.sh down` para tudo o que o laboratório iniciou, e aí o `up`
  consegue substituir os arquivos.
- **`No space left on device`.** Os ambientes virtuais precisam de 1,3 GB de uma vez, e o cache de
  downloads do pip de outro tanto enquanto trabalha. Dê um disco maior à máquina virtual, ou apague
  `/root/.cache/pip` depois da primeira execução bem-sucedida.

Dois hábitos facilitam o resto do curso. **Rode `lab.sh reset` sempre que uma lição pedir**: ele
devolve a loja à noite de 28 de fevereiro, esvazia o warehouse e faz o Airflow esquecer tudo, para
os seus números voltarem a bater com os da lição. E **nunca conserte o laboratório editando o banco
da loja à mão**: os pipelines deste curso o leem, e uma linha que você mudou sem o laboratório saber
é uma linha que faz a sua saída discordar da página por motivos que ninguém encontra.

Se falhar algo que não está nesta lista, o script é curto o bastante para ler. Ache a função de
onde veio a última linha e rode os comandos dela um de cada vez.

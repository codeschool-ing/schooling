---
title: Para que serve um backup
version: 1
---

Um **backup** é uma cópia dos dados, guardada separada do original, que pode ser usada para trazer os
dados de volta depois de perdidos ou danificados. Cada palavra dessa definição pesa, e os erros comuns
derrubam uma de cada vez.

**Separada** exclui muita coisa que as pessoas chamam de backup:

| o que as pessoas têm | por que não é backup |
|---|---|
| um segundo disco no mesmo servidor, espelhado (RAID 1) | uma exclusão, uma corrupção ou um ransomware acontecem nos dois discos ao mesmo tempo |
| uma pasta sincronizada com a nuvem | a sincronização copia fielmente a exclusão, ou os arquivos cifrados, em segundos |
| uma réplica do banco em outro servidor | a réplica aplica toda mudança, inclusive `DELETE FROM orders` |
| uma cópia no mesmo servidor, em outra pasta | o que destruir o servidor destrói a cópia |

As quatro têm valor, e as quatro protegem a **disponibilidade contra falha de hardware**: um disco morre,
o outro continua servindo. Nenhuma protege contra as três coisas para as quais um backup existe: **erros**
(alguém apagou a pasta errada), **corrupção** (um defeito ou um disco falhando danificou os dados em
silêncio) e **ataques** (um ransomware cifrou tudo o que alcançou). Contra essas, uma cópia que espelha
toda mudança é uma segunda vítima.

**Pode ser usada para trazer os dados de volta** é a parte que mais se supõe e menos se confere. Um
backup que não restaura, ou que restaura a coisa errada, não é um backup; é um arquivo tranquilizador.
Duas seções adiante, o próprio backup da loja se revela exatamente isso.

### Versões, não só cópias

Um backup só protege contra um dano percebido tarde se guarda **versões antigas**. Se o backup se
sobrescreve toda noite e um arquivo foi corrompido há uma semana, toda cópia agora é do arquivo
corrompido. Então backups são guardados com uma **retenção**: as últimas sete noites, os últimos quatro
domingos, os últimos doze fins de mês, por exemplo. O ransomware que cifra arquivos em silêncio por um
tempo antes de se anunciar é o motivo de a retenção importar.

### Resiliência

**Resiliência** é a propriedade mais ampla a que o backup pertence: a capacidade de continuar
funcionando durante uma falha e de se recuperar depois. Ela tem duas metades, e a disponibilidade da
aula 1 precisa das duas:

- **continuar no ar**: redundância, um segundo disco, um segundo servidor, uma segunda conexão de
  internet, para que uma falha não pare a loja;
- **voltar**: backups e um plano praticado para restaurá-los, para as falhas que a redundância não
  absorve.

A redundância é rápida e copia tudo, inclusive o dano. Backups são lentos e guardam o passado. Uma loja
resiliente tem os dois, e sabe qual pegar.

"""Lesson 10: the parts of a presigned URL."""
from figures import Fig, T, figure


@figure('l10-presigned', 10)
def presigned():
    f = Fig('l10-presigned', 720, 360, T(
        'The parts of the presigned URL the lab printed, one per row. The address names the bucket '
        'and the object. X-Amz-Algorithm says how it was signed. X-Amz-Credential names the access '
        'key that signed it, with the date, the region and the service: on AWS this is the key id, '
        'which says whose key is handing the file out. X-Amz-Date is when it was signed and '
        'X-Amz-Expires how many seconds it lasts from then. X-Amz-SignedHeaders lists what else the '
        'signature covers. X-Amz-Signature is computed from the secret key over everything above it, '
        'so changing any part breaks it.',
        'As partes da URL pré-assinada que o laboratório imprimiu, uma por linha. O endereço nomeia o '
        'bucket e o objeto. X-Amz-Algorithm diz como foi assinada. X-Amz-Credential nomeia a chave de '
        'acesso que a assinou, com a data, a região e o serviço: na AWS é o id da chave, que diz de quem '
        'é a chave que está entregando o arquivo. X-Amz-Date é quando foi assinada e X-Amz-Expires '
        'quantos segundos ela dura a partir daí. X-Amz-SignedHeaders lista o que mais a assinatura '
        'cobre. X-Amz-Signature é calculada com a chave secreta sobre tudo acima dela, então mudar '
        'qualquer parte a invalida.'))
    rows = [
        ('localhost:4567/clinic-results/maria-souza/…', T('which object', 'qual objeto'), '--paper-dim'),
        ('X-Amz-Algorithm=AWS4-HMAC-SHA256', T('how it was signed', 'como foi assinada'), '--paper-dim'),
        ('X-Amz-Credential=test/20261023/sa-east-1/s3', T('whose key signed it', 'de quem é a chave que assinou'), '--amber'),
        ('X-Amz-Date=20261023T…', T('when it was signed', 'quando foi assinada'), '--paper-dim'),
        ('X-Amz-Expires=900', T('seconds it lasts from then', 'segundos que dura a partir daí'), '--amber'),
        ('X-Amz-SignedHeaders=host', T('what else is covered', 'o que mais é coberto'), '--paper-dim'),
    ]
    y = 22
    for code, what, col in rows:
        f.rect(30, y, 380, 36, stroke='--wire', fill='--scan')
        f.text(44, y + 18, code, size=10, anchor='start', mono=True)
        f.text(430, y + 18, what, size=10.5, anchor='start', fill=col if col == '--amber' else '--paper')
        y += 44
    top, bottom = 22, y - 8
    f.path(f'M418 {top} L424 {top} L424 {bottom} L418 {bottom}', stroke='--phosphor', width=1.4)
    f.rect(30, y + 6, 380, 36, stroke='--phosphor', fill='--panel', width=1.4)
    f.text(44, y + 24, 'X-Amz-Signature=…', size=10, anchor='start', mono=True)
    f.text(430, y + 16, T('computed from the secret key', 'calculada com a chave secreta'), size=10.5,
           anchor='start', fill='--phosphor')
    f.text(430, y + 33, T('over every row above', 'sobre todas as linhas acima'), size=10.5,
           anchor='start', fill='--phosphor')
    f.arrow([(424, y + 4), (424, bottom + 2)], stroke='--phosphor', start=False)
    return f, T('Everything a defender can learn from a link is in it: the key that signed it, and when '
                'it stops working. Nothing about it is stored in the bucket.',
                'Tudo o que quem defende pode saber de um link está nele: a chave que o assinou e quando '
                'ele para de funcionar. Nada dele fica guardado no bucket.')

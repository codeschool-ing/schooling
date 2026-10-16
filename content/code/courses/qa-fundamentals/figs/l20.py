# lesson 20

@figure('l20-matrix', 20)
def l20_matrix(lang):
    t = {
        'en': dict(x='likelihood', y='impact', lv=['low', 'medium', 'high'],
                   areas={'price rule': (3, 3), 'coupons': (3, 2), 'orders': (2, 3), 'refunds': (2, 2),
                          'seat map': (1, 2), 'nightly report': (1, 1)},
                   start='start here',
                   label='A three by three risk matrix, likelihood across from low to high, impact up from low to high. '
                         'Price rule sits at high likelihood and high impact, marked start here. Orders: medium '
                         'likelihood, high impact. Coupons: high likelihood, medium impact. Refunds: medium and medium. '
                         'Seat map: low likelihood, medium impact. Nightly report: low and low.',
                   cap='Cine Aurora’s six areas before usage and history were added. The top right gets the most hours.'),
        'pt': dict(x='probabilidade', y='impacto', lv=['baixa', 'média', 'alta'],
                   areas={'regra de preço': (3, 3), 'cupons': (3, 2), 'pedidos': (2, 3), 'reembolsos': (2, 2),
                          'mapa de assentos': (1, 2), 'relatório noturno': (1, 1)},
                   start='comece aqui',
                   label='Uma matriz de risco de três por três, probabilidade na horizontal de baixa a alta, impacto na '
                         'vertical de baixo a alto. A regra de preço fica em probabilidade alta e impacto alto, marcada '
                         'comece aqui. Pedidos: probabilidade média, impacto alto. Cupons: probabilidade alta, impacto '
                         'médio. Reembolsos: médio e médio. Mapa de assentos: probabilidade baixa, impacto médio. '
                         'Relatório noturno: baixo e baixo.',
                   cap='As seis áreas do Cine Aurora antes de entrarem uso e histórico. O canto de cima à direita fica com '
                       'mais horas.'),
    }[lang]
    f = Fig('l20-matrix', 560, 300, t['label'])
    x0, y0, cw, ch = 90, 20, 150, 76
    for i in range(3):
        for j in range(3):
            hot = i + j >= 4
            f.rect(x0 + i * cw, y0 + (2 - j) * ch, cw, ch, stroke='--wire',
                   fill='--panel' if hot else '--ink', rx=0)
    for k, lv in enumerate(t['lv']):
        f.text(x0 + k * cw + cw / 2, y0 + 3 * ch + 14, lv, size=9, fill='--paper-dim')
        f.text(x0 - 8, y0 + (2 - k) * ch + ch / 2, lv, size=9, anchor='end', fill='--paper-dim')
    f.text(x0 + 1.5 * cw, y0 + 3 * ch + 34, t['x'], size=10, weight='600')
    f.text(x0 - 60, y0 + 6, t['y'], size=10, weight='600', anchor='start')
    seen = {}
    for name, (l, im) in t['areas'].items():
        n = seen.get((l, im), 0)
        seen[(l, im)] = n + 1
        cx = x0 + (l - 1) * cw + cw / 2
        cy = y0 + (3 - im) * ch + ch / 2 + n * 18
        hot = (l, im) == (3, 3)
        box(f, cx - 62, cy - 12, 124, 24, [name], size=9, weights=['600'] if hot else None,
            stroke='--amber' if hot else '--wire', fills=['--amber' if hot else '--paper'])
    f.text(x0 + 2.5 * cw, y0 + 14, t['start'], size=9, fill='--amber', weight='600')
    return f, t['cap']


@figure('l20-hours', 20)
def l20_hours(lang):
    t = {
        'en': dict(rows=[('price rule', 5), ('orders', 3), ('refunds', 2.5), ('coupons', 2.5), ('seat map', 2),
                         ('nightly report', 1)], unit='hours',
                   label='Sixteen hours of testing split across six areas, as horizontal bars: price rule 5 hours, '
                         'orders 3, refunds 2.5, coupons 2.5, seat map 2, nightly report 1.',
                   cap='The same sixteen hours an even split would give, spent where the damage would be greatest.'),
        'pt': dict(rows=[('regra de preço', 5), ('pedidos', 3), ('reembolsos', 2.5), ('cupons', 2.5),
                         ('mapa de assentos', 2), ('relatório noturno', 1)], unit='horas',
                   label='Dezesseis horas de teste divididas entre seis áreas, como barras horizontais: regra de preço 5 '
                         'horas, pedidos 3, reembolsos 2,5, cupons 2,5, mapa de assentos 2, relatório noturno 1.',
                   cap='As mesmas dezesseis horas de uma divisão igual, gastas onde o estrago seria maior.'),
    }[lang]
    f = Fig('l20-hours', 560, 220, t['label'])
    x0, scale = 140, 70
    for i, (name, h) in enumerate(t['rows']):
        y = 16 + i * 32
        f.text(x0 - 10, y + 11, name, size=9.5, anchor='end')
        f.rect(x0, y, h * scale, 22, stroke='--phosphor' if i == 0 else '--wire',
               fill='--phosphor-dim' if i == 0 else '--panel', rx=2)
        f.text(x0 + h * scale + 8, y + 11, num(lang, h, 1 if h % 1 else 0), size=9.5, anchor='start',
               fill='--paper-dim')
    f.text(x0, 210, t['unit'], size=9, anchor='start', fill='--paper-dim')
    return f, t['cap']

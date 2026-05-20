const cargoLabels = {
  'Gerente':              'Gerente',
  'Mecanico':             'Mecânico',
  'Auxiliar':             'Auxiliar',
  'Atendente':            'Atendente',
  'Lavador':              'Lavador',
  'Funileiro':            'Funileiro',
  'Eletricista':          'Eletricista',
  'Pintor':               'Pintor',
  'TecnicoArCondicionado':'Técnico AC',
};

String cargoLabel(String cargo) => cargoLabels[cargo] ?? cargo;

String tipoRemuneracaoLabel(String tipo, {int? porcentagem}) =>
    switch (tipo) {
      'Porcentagem' =>
        porcentagem != null ? '$porcentagem% comissão' : 'Comissão',
      'Fixo'  => 'Fixo mensal',
      'Socio' => 'Gerente',
      _       => tipo,
    };

String tipoRemuneracaoLabelLong(String tipo, {int? porcentagem}) =>
    switch (tipo) {
      'Porcentagem' =>
        porcentagem != null ? '$porcentagem% sobre OS' : 'Comissão sobre OS',
      'Fixo'  => 'Salário fixo',
      'Socio' => 'Gerente',
      _       => tipo,
    };

String tipoRemuneracaoPagamentoDesc(String tipo, {int? porcentagem}) =>
    switch (tipo) {
      'Porcentagem' => '${porcentagem ?? 0}% de comissão por OS',
      'Fixo'        => 'Salário fixo mensal',
      'Socio'       => 'Gerente',
      _             => tipo,
    };

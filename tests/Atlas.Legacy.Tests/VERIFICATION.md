# Evidência de caracterização

Data: 2026-09-26. Compilador: Delphi Win32 37.0, com recompilação `dcc32 -B AtlasLegacyTests.dpr`.

- Execução normal: nove casos passaram em ambos os caminhos; código de saída zero.
- Ensaio negativo: substituição temporária de `>` por `>=` na rejeição de `TProgressiveDiscountPolicy`; a suíte falhou em `eligibility boundary`, com código de saída 1.
- Restauração: a comparação original foi restabelecida, o projeto recompilado e os nove casos passaram novamente.

O ensaio negativo não permanece no fonte. Não houve execução de Form, rede ou banco nesta suíte. O caso negativo conhecido preserva uma anomalia apenas para documentar a diferença entre extração e correção. Os valores esperados são explícitos; o cálculo monetário compartilhado não fornece oráculos independentes de arredondamento.

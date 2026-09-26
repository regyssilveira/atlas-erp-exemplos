# Build, testes e bloqueio de pacote

Data: 2026-09-26. Compilador explicitamente selecionado: Delphi Win32 37.0.

| Execução | Resultado observado |
|---|---|
| baseline-20260926 | três suítes recompiladas; 15 testes de domínio, quatro FireDAC e nove casos de caracterização aprovados; pacote criado |
| negative-20260926 | comparação da política temporariamente alterada de `>` para `>=`; falha em `eligibility boundary`; processo saiu com código 1 |
| inspeção da execução negativa | `build/negative-20260926/package` não existe; logs preservados; nenhum pacote aprovado |
| restored-20260926 | comparação original restaurada; três suítes recompiladas e aprovadas; novo pacote criado |

O script não reutiliza diretório existente. A mutação não permanece no fonte. O manifesto inclui caminho e versão de arquivo do compilador, resultados e digests dos arquivos empacotados. Logs locais completos ficam nos diretórios ignorados `build/`. Este registro descreve uma execução, não promete que todo ambiente Delphi oferece a mesma configuração.

Limites: compilação direta dos DPRs, não MSBuild; pacote de testes, não ERP; SQLite em memória não prova bancos de produção; nenhuma cobertura, assinatura, análise estática, SBOM ou distribuição remota foi executada. O ensaio negativo prova o bloqueio diante daquela falha específica.

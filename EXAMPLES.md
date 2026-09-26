# Matriz dos exemplos

Esta matriz informa o que cada recorte do Atlas demonstra, qual evidência executável existe e o que permanece fora da garantia. Os exemplos acompanham o livro **Engenharia de ERP com Delphi** e não constituem um ERP pronto para produção.

| Cap. | Problema | Unidade ou suíte | Evidência atual | Limite declarado |
|---:|---|---|---|---|
| 1 | regra escondida no evento da tela | `Atlas.Sales.FinalizeSale` | fluxo inicial compilável | ponto de partida deliberadamente acoplado |
| 2 | separar interface, aplicação, domínio e infraestrutura | `Atlas.Sales.Application.FinalizeSale`; hosts | composição compilável | não fornece container ou framework arquitetural |
| 3 | dependências entre módulos | `Atlas.Architecture.DependencyRules` | teste de direções permitidas | não analisa automaticamente todos os fontes |
| 4 | transação e persistência real | `Atlas.Persistence.FireDAC.Store`; suíte FireDAC | commit, rollback, versão e idempotência em SQLite | não prova isolamento dos SGBDs de produção |
| 5 | regra comercial explícita | `Atlas.Sales.Rules.Discount` | decisões aceitas e rejeitadas | política didática, sem catálogo comercial completo |
| 5 | proteger a extração de uma decisão antiga | `Atlas.Legacy.Discount`; `AtlasLegacyTests` | nove casos nos caminhos anterior e extraído; mutação de fronteira detectada | recorte sem Form real; anomalia conhecida não aprovada; arredondamento compartilhado |
| 6 | movimento e vigência | `Atlas.Inventory.Domain.Movement`; `Atlas.Commercial.Domain.EffectivePrice` | saldo por movimentos e intervalo efetivo | não implementa banco temporal completo |
| 7 | concorrência e repetição | `Atlas.Consistency.OptimisticLock`; `Idempotency` | conflito de versão e replay | concorrência é simulada em memória |
| 8 | contexto e precedência | `Atlas.Shared.Context`; `Atlas.Configuration.PolicyResolver` | regra mais específica prevalece | não cobre autenticação nem isolamento físico |
| 9 | reserva e disponibilidade | `Atlas.Inventory.Domain.Position` | reserva, confirmação e saldo | não cobre logística, lote ou custo integral |
| 10 | baixa parcial e duplicidade | `Atlas.Finance.Domain.Receivable` | saldo e chave externa | não cobre contabilidade ou conciliação bancária completa |
| 11 | processo fiscal e histórico da decisão | `Atlas.Fiscal.Domain.Document`; `TaxSnapshot` | resultado desconhecido e snapshot versionado | não calcula tributos nem produz documento eletrônico |
| 12 | leitura e desempenho | exemplos SQL do livro; suíte FireDAC | consulta sobre schema descartável | não publica benchmark universal |
| 13 | falhas externas | `Atlas.Integration.Resilience` | retry e circuit breaker mínimos | não executa rede ou provedor real |
| 14 | job recuperável | `Atlas.Processing.JobQueue` | estados, tentativas e deduplicação | fila em memória, sem lease persistente |
| 15 | autorização e auditoria | `Atlas.Security.Authorization` | negação por padrão e correlação | não fornece IAM, armazenamento imutável ou observabilidade completa |
| 16 | histórico de migrations | `Atlas.Database.Migrations` | versão e conflito de checksum | não executa DDL nem backfill |
| 17 | limites verificáveis | suíte de domínio e regras arquiteturais | 15 testes autocontidos | não substitui testes do produto e de sua infraestrutura |

## Como interpretar a matriz

“Evidência atual” significa que o comportamento foi compilado e exercitado pela suíte indicada. “Limite declarado” identifica uma propriedade que o exemplo não prova. A ausência de uma implementação completa é intencional quando ela exigiria escolher SGBD, broker, provedor fiscal, modelo de segurança ou regra empresarial que pertence ao produto do leitor.

Use [EXPERIMENTS.md](EXPERIMENTS.md) para transformar os limites mais importantes em ensaios no ambiente real da software house.

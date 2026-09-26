# Atlas ERP — exemplos em Delphi

Código didático do livro **Engenharia de ERP com Delphi: Arquitetura para sistemas empresariais que precisam crescer e durar**, de Régys Borges da Silveira.

O repositório acompanha a evolução arquitetural do Atlas ERP e contém exemplos executáveis de domínio, consistência, integrações, processamento assíncrono, segurança, auditoria, migrations e regras de dependência. Os exemplos tornam decisões verificáveis; não constituem um ERP pronto para produção.

## Requisitos

- Delphi 13 Florence ou versão compatível;
- compilador Win32 para o projeto de testes.

## Executar os testes

O repositório possui três suítes:

- `tests/Atlas.Domain.Tests/AtlasDomainTests.dpr`: 15 testes autocontidos de domínio, sem banco ou rede;
- `tests/Atlas.Persistence.FireDAC.Tests/AtlasPersistenceFireDACTests.dpr`: quatro testes de integração com FireDAC e SQLite em memória.
- `tests/Atlas.Legacy.Tests/AtlasLegacyTests.dpr`: nove casos de caracterização executados no caminho anterior e na regra extraída. Inclui uma anomalia conhecida, cuja preservação não significa aprovação funcional.

O recorte legado isola uma decisão que poderia estar num evento. Não automatiza uma Form real nem demonstra que o ERP inteiro foi caracterizado. Os dois caminhos usam o mesmo tipo monetário; por isso, não constituem verificações independentes do arredondamento. Casos com expectativas explícitas evitam depender apenas da comparação entre implementações.

Abra cada projeto no RAD Studio ou execute `dcc32` a partir da pasta em que o respectivo `.dpr` se encontra. Os caminhos das units são relativos ao diretório do projeto.

## Recorte da integração FireDAC

A suíte FireDAC cria um schema descartável e verifica transação, rollback, commit, atualização otimista por versão e registro persistido de idempotência. SQLite foi escolhido para manter o teste reproduzível sem instalar ou configurar um servidor.

Esse recorte não comprova concorrência entre duas conexões nem a semântica de isolamento, locking e DDL de Firebird, PostgreSQL ou SQL Server. Esses comportamentos precisam de suítes próprias contra o SGBD adotado pelo produto, conforme advertido no livro.

## O que cada exemplo prova

A matriz [EXAMPLES.md](EXAMPLES.md) relaciona os 17 capítulos às units, aos testes e aos limites declarados. Os roteiros em [EXPERIMENTS.md](EXPERIMENTS.md) mostram como exercitar concorrência real, recuperação de worker, retomada de migration, convivência de políticas fiscais e autorização por múltiplos canais no ambiente do produto.

## Recorte fiscal da reforma tributária

`TTaxDecisionSnapshot` conserva a identidade da operação, da política, do catálogo e das entradas usadas em uma decisão fiscal. O teste demonstra que uma política posterior não deve reinterpretar silenciosamente um resultado histórico.

O exemplo não calcula IBS, CBS, Imposto Seletivo ou qualquer outro tributo. Não contém alíquotas, classificação fiscal, leiaute de documento ou orientação tributária. Cada produto precisa implementar e homologar essas regras com especialistas e com a documentação oficial vigente.

## Licença

Licenciado sob a [Apache License 2.0](LICENSE). Consulte também o arquivo [NOTICE](NOTICE).

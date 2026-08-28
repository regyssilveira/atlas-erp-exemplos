# Atlas ERP — exemplos em Delphi

Código didático do livro **Engenharia de ERP com Delphi: Arquitetura para sistemas empresariais que precisam crescer e durar**, de Régys Borges da Silveira.

O repositório acompanha a evolução arquitetural do Atlas ERP e contém exemplos executáveis de domínio, consistência, integrações, processamento assíncrono, segurança, auditoria, migrations e regras de dependência. Os exemplos tornam decisões verificáveis; não constituem um ERP pronto para produção.

## Requisitos

- Delphi 13 Florence ou versão compatível;
- compilador Win32 para o projeto de testes.

## Executar os testes

O repositório possui duas suítes:

- `tests/Atlas.Domain.Tests/AtlasDomainTests.dpr`: 14 testes autocontidos de domínio, sem banco ou rede;
- `tests/Atlas.Persistence.FireDAC.Tests/AtlasPersistenceFireDACTests.dpr`: quatro testes de integração com FireDAC e SQLite em memória.

Abra cada projeto no RAD Studio ou execute `dcc32` a partir da pasta em que o respectivo `.dpr` se encontra. Os caminhos das units são relativos ao diretório do projeto.

## Recorte da integração FireDAC

A suíte FireDAC cria um schema descartável e verifica transação, rollback, commit, atualização otimista por versão e registro persistido de idempotência. SQLite foi escolhido para manter o teste reproduzível sem instalar ou configurar um servidor.

Esse recorte não comprova concorrência entre duas conexões nem a semântica de isolamento, locking e DDL de Firebird, PostgreSQL ou SQL Server. Esses comportamentos precisam de suítes próprias contra o SGBD adotado pelo produto, conforme advertido no livro.

## Licença

Licenciado sob a [Apache License 2.0](LICENSE). Consulte também o arquivo [NOTICE](NOTICE).

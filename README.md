# Atlas ERP — exemplos em Delphi

Código didático do livro **Engenharia de ERP com Delphi: Arquitetura para sistemas empresariais que precisam crescer e durar**, de Régys Borges da Silveira.

O repositório acompanha a evolução arquitetural do Atlas ERP e contém exemplos executáveis de domínio, consistência, integrações, processamento assíncrono, segurança e auditoria. Os exemplos tornam decisões verificáveis; não constituem um ERP pronto para produção.

## Requisitos

- Delphi 13 Florence ou versão compatível;
- compilador Win32 para o projeto de testes.

## Executar os testes

Abra `tests/Atlas.Domain.Tests/AtlasDomainTests.dpr` no RAD Studio ou compile pela linha de comando com `dcc32`. O executável roda testes autocontidos, sem banco ou rede reais.

## Licença

Licenciado sob a [Apache License 2.0](LICENSE). Consulte também o arquivo [NOTICE](NOTICE).

# Roteiros de experimentos

Os roteiros abaixo complementam os exemplos sem fornecer infraestrutura universal. Cada equipe deve adaptá-los ao SGBD, ao provedor e aos contratos do próprio produto.

## 1. Duas sessões disputam a mesma venda

**Objetivo:** verificar a proteção contra atualização perdida.

**Preparação:** criar a venda 8457 com versão conhecida e abrir duas conexões independentes.

**Execução:** ambas leem a mesma versão; a primeira confirma a alteração; a segunda tenta confirmar com a versão antiga.

**Resultado esperado:** apenas uma atualização produz efeito. A segunda recebe conflito identificável e pode recarregar o estado. A prova deve observar o resultado por uma terceira conexão depois dos commits.

**Não prova:** que todas as operações do ERP usam a mesma proteção ou que o nível de isolamento escolhido serve a outros cenários.

## 2. Worker interrompido na janela incerta

**Objetivo:** verificar recuperação sem duplicação empresarial.

**Preparação:** persistir `FISCAL-8457` com identidade estável e efeito externo consultável ou idempotente.

**Execução:** reservar o trabalho, produzir o efeito e interromper o worker antes de registrar conclusão. Depois do vencimento do lease, iniciar outro worker.

**Resultado esperado:** o segundo worker consulta ou repete com a mesma identidade, reconhece o efeito anterior e conclui uma única intenção. A resposta tardia do lease antigo não sobrescreve o estado atual.

**Não prova:** exatamente uma execução física; o protocolo busca um único efeito empresarial observável.

## 3. Migration interrompida e retomada

**Objetivo:** verificar ledger, pós-condições e recuperação.

**Preparação:** copiar três bancos representativos: schema anterior, schema atual e estado parcialmente alterado.

**Execução:** interromper a migration depois de criar uma estrutura e antes de registrar conclusão; reiniciar o executor.

**Resultado esperado:** a retomada inspeciona a pós-condição, não repete cegamente DDL e produz relatório coerente entre estrutura, checksum e ledger. Estado ambíguo bloqueia com procedimento assistido.

**Não prova:** rollback universal de DDL ou reparo automático de customizações desconhecidas.

## 4. Política fiscal nova com snapshot antigo

**Objetivo:** confirmar que uma atualização não reinterpreta o passado.

**Preparação:** calcular a venda 8457 com política `rtc-sale-v3`, guardar catálogo, entradas e fingerprints e deixar o documento aguardando consulta.

**Execução:** instalar `rtc-sale-v4` e retomar o processo fiscal.

**Resultado esperado:** o worker consulta o documento usando a identidade e o snapshot v3. Somente operações ainda recalculáveis adotam v4 por transição explícita.

**Não prova:** correção tributária das políticas; os resultados precisam de homologação funcional e fontes oficiais vigentes.

## 5. A mesma autorização por três entradas

**Objetivo:** verificar que a política não depende da interface.

**Preparação:** conceder `sale.cancel` ao gerente na empresa 10 e filial 2, com venda 8457 no estado permitido.

**Execução:** emitir o comando pela VCL, por uma API de teste e por um job. Repetir na filial 3 e com versão antiga da venda.

**Resultado esperado:** os três canais tomam a mesma decisão para o mesmo contexto; filial ou versão incompatível é negada; auditoria conserva ator, canal, política e correlação `corr-20260825-01`.

**Não prova:** segurança integral do transporte, autenticação ou retenção da auditoria.

program AtlasDomainTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.DateUtils,
  Atlas.Shared.Money in '..\..\src\Atlas.Shared\Atlas.Shared.Money.pas',
  Atlas.Sales.Rules.Discount in '..\..\src\Atlas.Sales.Rules\Atlas.Sales.Rules.Discount.pas',
  Atlas.Inventory.Domain.Movement in '..\..\src\Atlas.Inventory.Domain\Atlas.Inventory.Domain.Movement.pas',
  Atlas.Commercial.Domain.EffectivePrice in '..\..\src\Atlas.Commercial.Domain\Atlas.Commercial.Domain.EffectivePrice.pas',
  Atlas.Consistency.OptimisticLock in '..\..\src\Atlas.Consistency\Atlas.Consistency.OptimisticLock.pas',
  Atlas.Consistency.Idempotency in '..\..\src\Atlas.Consistency\Atlas.Consistency.Idempotency.pas',
  Atlas.Configuration.PolicyResolver in '..\..\src\Atlas.Configuration\Atlas.Configuration.PolicyResolver.pas',
  Atlas.Inventory.Domain.Position in '..\..\src\Atlas.Inventory.Domain\Atlas.Inventory.Domain.Position.pas',
  Atlas.Finance.Domain.Receivable in '..\..\src\Atlas.Finance.Domain\Atlas.Finance.Domain.Receivable.pas',
  Atlas.Fiscal.Domain.Document in '..\..\src\Atlas.Fiscal.Domain\Atlas.Fiscal.Domain.Document.pas',
  Atlas.Integration.Resilience in '..\..\src\Atlas.Integration\Atlas.Integration.Resilience.pas',
  Atlas.Processing.JobQueue in '..\..\src\Atlas.Processing\Atlas.Processing.JobQueue.pas',
  Atlas.Security.Authorization in '..\..\src\Atlas.Security\Atlas.Security.Authorization.pas',
  Atlas.Database.Migrations in '..\..\src\Atlas.Database\Atlas.Database.Migrations.pas',
  Atlas.Architecture.DependencyRules in '..\..\src\Atlas.Architecture\Atlas.Architecture.DependencyRules.pas';

procedure Check(const ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
end;

procedure TestDiscountPolicy;
var
  Policy: TProgressiveDiscountPolicy;
  Decision: TDiscountDecision;
begin
  Policy := TProgressiveDiscountPolicy.Create(
    TMoney.Create(1000), 0.10, TMoney.Create(150));
  try
    Decision := Policy.Decide(TMoney.Create(1200), TMoney.Create(100));
    Check(Decision.Accepted, 'O desconto deveria ser aceito.');
    Check(Decision.Discount.Amount = 100, 'O desconto aceito está incorreto.');

    Decision := Policy.Decide(TMoney.Create(1200), TMoney.Create(130));
    Check(not Decision.Accepted, 'O desconto acima de 10% deveria ser rejeitado.');
  finally
    Policy.Free;
  end;
end;

procedure TestMovementBalance;
var
  Ledger: TStockLedger;
begin
  Ledger := TStockLedger.Create;
  try
    Ledger.Post(TStockMovement.Create(1, 42, 2, 10, smEntry,
      'PURCHASE-100', EncodeDate(2026, 8, 20)));
    Ledger.Post(TStockMovement.Create(2, 42, 2, 3, smExit,
      'SALE-8457', EncodeDate(2026, 8, 21)));
    Check(Abs(Ledger.Balance(42, 2) - 7) < 0.0001,
      'O saldo deveria ser explicado como 10 - 3 = 7.');
  finally
    Ledger.Free;
  end;
end;

procedure TestEffectivePrice;
var
  Price: TEffectivePrice;
begin
  Price := TEffectivePrice.Create(42, TMoney.Create(89.90),
    EncodeDate(2026, 8, 1), EncodeDate(2026, 9, 1));
  Check(Price.IsEffectiveOn(EncodeDate(2026, 8, 15)),
    'O preço deveria estar vigente em agosto.');
  Check(not Price.IsEffectiveOn(EncodeDate(2026, 9, 1)),
    'O limite final da vigência é exclusivo.');
end;

procedure TestOptimisticConflict;
var
  Store: TVersionedSaleStore;
  FirstReader: TSaleSnapshot;
  SecondReader: TSaleSnapshot;
  CurrentVersion: Integer;
begin
  Store := TVersionedSaleStore.Create(8457);
  try
    FirstReader := Store.Load;
    SecondReader := Store.Load;
    Check(Store.TryFinalize(FirstReader.Version, CurrentVersion),
      'A primeira atualização deveria ser aceita.');
    Check(not Store.TryFinalize(SecondReader.Version, CurrentVersion),
      'A atualização com versão antiga deveria ser rejeitada.');
    Check(CurrentVersion = 2, 'A versão corrente deveria ser 2.');
  finally
    Store.Free;
  end;
end;

procedure TestIdempotency;
var
  Registry: TIdempotencyRegistry;
  StoredResult: string;
begin
  Registry := TIdempotencyRegistry.Create;
  try
    Check(Registry.Register('FINALIZE-8457', 'sale=8457', 'accepted',
      StoredResult) = ioExecuted, 'A primeira intenção deveria executar.');
    Check(Registry.Register('FINALIZE-8457', 'sale=8457', 'ignored',
      StoredResult) = ioReplayed, 'A repetição deveria reutilizar o resultado.');
    Check(StoredResult = 'accepted', 'O resultado original deveria ser preservado.');
    Check(Registry.Register('FINALIZE-8457', 'sale=9999', 'ignored',
      StoredResult) = ioConflict, 'A mesma chave com outra intenção deveria conflitar.');
  finally
    Registry.Free;
  end;
end;

procedure TestPolicyPrecedence;
var
  Resolver: TDiscountPolicyResolver;
  Rule: TPolicyRule;
  Context: TPolicyContext;
  Rate: Double;
begin
  Resolver := TDiscountPolicyResolver.Create;
  try
    Rule := Default(TPolicyRule);
    Rule.DiscountRate := 0.05;
    Resolver.Add(Rule);

    Rule := Default(TPolicyRule);
    Rule.CompanyId := 10;
    Rule.DiscountRate := 0.08;
    Resolver.Add(Rule);

    Rule := Default(TPolicyRule);
    Rule.CompanyId := 10;
    Rule.BranchId := 2;
    Rule.OperationName := 'FinalizeSale';
    Rule.DiscountRate := 0.10;
    Resolver.Add(Rule);

    Context.CompanyId := 10;
    Context.BranchId := 2;
    Context.UserId := 37;
    Context.OperationName := 'FinalizeSale';
    Check(Resolver.Resolve(Context, Rate), 'Uma política deveria ser encontrada.');
    Check(Abs(Rate - 0.10) < 0.0001,
      'A política mais específica deveria prevalecer.');
  finally
    Resolver.Free;
  end;
end;

procedure TestStockReservation;
var
  Position: TStockPosition;
begin
  Position := TStockPosition.Create(10);
  try
    Check(Position.TryReserve(5001, 3), 'A reserva deveria ser aceita.');
    Check(Abs(Position.Available - 7) < 0.0001,
      'Disponível deveria considerar a reserva.');
    Position.Confirm(5001);
    Check(Abs(Position.OnHand - 7) < 0.0001,
      'A confirmação deveria reduzir o saldo físico.');
  finally
    Position.Free;
  end;
end;

procedure TestPartialAndDuplicatePayment;
var
  Receivable: TReceivable;
begin
  Receivable := TReceivable.Create(TMoney.Create(100));
  try
    Check(Receivable.ApplyPayment('PIX-E2E-001', TMoney.Create(40)),
      'O primeiro pagamento deveria ser aplicado.');
    Check(not Receivable.ApplyPayment('PIX-E2E-001', TMoney.Create(40)),
      'O mesmo pagamento não deveria ser aplicado duas vezes.');
    Check(Receivable.Status = rsPartiallyPaid,
      'O título deveria estar parcialmente pago.');
    Check(Receivable.Outstanding.Amount = 60,
      'O saldo restante deveria ser 60.');
  finally
    Receivable.Free;
  end;
end;

procedure TestUnknownFiscalResult;
var
  Document: TFiscalDocument;
begin
  Document := TFiscalDocument.Create('NFE-KEY-8457');
  try
    Document.Queue;
    Document.StartTransmission;
    Document.MarkResultUnknown;
    Check(Document.Status = fdsResultUnknown,
      'Timeout deveria produzir resultado desconhecido.');
    Document.ConfirmAuthorization('PROTOCOL-123');
    Check(Document.Status = fdsAuthorized,
      'A consulta posterior deveria confirmar autorização.');
  finally
    Document.Free;
  end;
end;

procedure TestIntegrationResilience;
var
  Breaker: TCircuitBreaker;
  Policy: TRetryPolicy;
  Failure: TIntegrationResult;
begin
  Breaker := TCircuitBreaker.Create(2);
  try
    Policy := TRetryPolicy.Create(3);
    Failure := TIntegrationResult.Failed(ifTransient, 'gateway indisponível');
    Check(Policy.ShouldRetry(1, Failure),
      'Falha transitória deveria admitir nova tentativa.');
    Breaker.RecordResult(Failure);
    Breaker.RecordResult(Failure);
    Check(not Breaker.CanExecute, 'Circuito deveria abrir após duas falhas.');
    Breaker.AllowProbe;
    Breaker.RecordResult(TIntegrationResult.Accepted('ok'));
    Check(Breaker.State = csClosed, 'Sucesso de prova deveria fechar o circuito.');
  finally
    Breaker.Free;
  end;
end;

procedure TestRecoverableJob;
var
  Queue: TJobQueue;
  Job: TJob;
begin
  Queue := TJobQueue.Create;
  try
    Job := Queue.Enqueue('FISCAL-8457', '{sale:8457}', 2);
    Check(Queue.Enqueue('FISCAL-8457', 'duplicado', 2) = Job,
      'A identidade do job deveria impedir duplicidade.');
    Job.Start;
    Job.Fail('timeout');
    Check(Job.State = jsWaitingRetry, 'Primeira falha deveria aguardar retry.');
    Job.Start;
    Job.Fail('serviço indisponível');
    Check(Job.State = jsDeadLetter,
      'Tentativas esgotadas deveriam levar à dead letter.');
  finally
    Queue.Free;
  end;
end;

procedure TestAuthorizationAndAudit;
var
  Policy: TAuthorizationPolicy;
  Trail: TAuditTrail;
  Entry: TAuditEntry;
begin
  Policy := TAuthorizationPolicy.Create;
  Trail := TAuditTrail.Create;
  try
    Policy.Grant('manager', 'sale.cancel');
    Check(Policy.IsAllowed('manager', 'sale.cancel'),
      'Permissão concedida deveria autorizar.');
    Check(not Policy.IsAllowed('operator', 'sale.cancel'),
      'A ausência de regra deveria negar por padrão.');
    Entry.ActorId := 'user-37';
    Entry.Action := 'sale.cancel';
    Entry.EntityId := 'sale-8457';
    Entry.CorrelationId := 'corr-20260825-01';
    Entry.Detail := 'cancelamento autorizado';
    Trail.Append(Entry);
    Check((Trail.Count = 1) and
      (Trail.Last.CorrelationId = 'corr-20260825-01'),
      'Auditoria deveria preservar a correlação.');
  finally
    Trail.Free;
    Policy.Free;
  end;
end;

procedure TestMigrationLedger;
var
  Ledger: TMigrationLedger;
  Migration: TMigration;
  ChecksumConflictDetected: Boolean;
begin
  Ledger := TMigrationLedger.Create;
  try
    Migration := TMigration.Create(14, 'add_outbox', 'sha256:original');
    Check(Ledger.NeedsApply(Migration), 'Migration nova deveria estar pendente.');
    Ledger.RegisterApplied(Migration);
    Check(not Ledger.NeedsApply(Migration),
      'Migration registrada não deveria executar novamente.');
    ChecksumConflictDetected := False;
    try
      Ledger.NeedsApply(TMigration.Create(14, 'add_outbox', 'sha256:alterado'));
    except
      on E: EInvalidOpException do
        ChecksumConflictDetected := True;
    end;
    Check(ChecksumConflictDetected,
      'Alterar migration aplicada deveria produzir conflito.');
  finally
    Ledger.Free;
  end;
end;

procedure TestArchitectureDependencies;
begin
  Check(not TDependencyRules.Allows(lyDomain, lyInfrastructure),
    'Domínio não deve depender da infraestrutura.');
  Check(TDependencyRules.Allows(lyInfrastructure, lyApplication),
    'Infraestrutura pode implementar portas da aplicação.');
  Check(TDependencyRules.Allows(lyHost, lyInfrastructure),
    'Host pode compor implementações concretas.');
end;

begin
  TestDiscountPolicy;
  TestMovementBalance;
  TestEffectivePrice;
  TestOptimisticConflict;
  TestIdempotency;
  TestPolicyPrecedence;
  TestStockReservation;
  TestPartialAndDuplicatePayment;
  TestUnknownFiscalResult;
  TestIntegrationResilience;
  TestRecoverableJob;
  TestAuthorizationAndAudit;
  TestMigrationLedger;
  TestArchitectureDependencies;
  Writeln('14 testes de domínio executados com sucesso.');
end.

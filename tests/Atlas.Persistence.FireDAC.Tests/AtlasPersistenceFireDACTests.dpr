program AtlasPersistenceFireDACTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  FireDAC.Stan.Def,
  FireDAC.Stan.Async,
  FireDAC.DApt,
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef,
  FireDAC.Phys.SQLiteWrapper.Stat,
  Atlas.Persistence.FireDAC.Store in
    '..\..\src\Atlas.Persistence.FireDAC\Atlas.Persistence.FireDAC.Store.pas';

procedure Check(const ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
end;

procedure TestRollbackPreservesState;
var
  Store: TFireDACAtlasStore;
begin
  Store := TFireDACAtlasStore.Create;
  try
    Store.InitializeSchema;
    Store.SeedSale(8457);
    Store.BeginUnitOfWork;
    Check(Store.TryFinalize(8457, 1), 'A atualização deveria ocorrer.');
    Store.Rollback;
    Check(Store.LoadSaleStatus(8457) = 'Draft',
      'Rollback deveria restaurar o estado da venda.');
    Check(Store.LoadSaleVersion(8457) = 1,
      'Rollback deveria restaurar a versão.');
  finally
    Store.Free;
  end;
end;

procedure TestCommitPersistsState;
var
  Store: TFireDACAtlasStore;
begin
  Store := TFireDACAtlasStore.Create;
  try
    Store.InitializeSchema;
    Store.SeedSale(8457);
    Store.BeginUnitOfWork;
    Check(Store.TryFinalize(8457, 1), 'A atualização deveria ocorrer.');
    Store.Commit;
    Check(Store.LoadSaleStatus(8457) = 'Finalized',
      'Commit deveria preservar a finalização.');
    Check(Store.LoadSaleVersion(8457) = 2,
      'Commit deveria preservar a nova versão.');
  finally
    Store.Free;
  end;
end;

procedure TestOptimisticVersionInSQL;
var
  Store: TFireDACAtlasStore;
begin
  Store := TFireDACAtlasStore.Create;
  try
    Store.InitializeSchema;
    Store.SeedSale(8457);
    Check(Store.TryFinalize(8457, 1),
      'A primeira versão deveria ser aceita.');
    Check(not Store.TryFinalize(8457, 1),
      'A versão antiga deveria ser rejeitada pelo update condicional.');
  finally
    Store.Free;
  end;
end;

procedure TestPersistedIdempotency;
var
  Store: TFireDACAtlasStore;
  StoredResult: string;
begin
  Store := TFireDACAtlasStore.Create;
  try
    Store.InitializeSchema;
    Check(Store.RegisterIdempotency('FINALIZE-8457', 'sale=8457',
      'accepted', StoredResult) = iwInserted,
      'A primeira intenção deveria ser persistida.');
    Check(Store.RegisterIdempotency('FINALIZE-8457', 'sale=8457',
      'ignored', StoredResult) = iwReplayed,
      'A repetição deveria reutilizar o resultado persistido.');
    Check(StoredResult = 'accepted',
      'O resultado original deveria ser preservado.');
    Check(Store.RegisterIdempotency('FINALIZE-8457', 'sale=9999',
      'ignored', StoredResult) = iwConflict,
      'A mesma chave com outro fingerprint deveria conflitar.');
  finally
    Store.Free;
  end;
end;

begin
  TestRollbackPreservesState;
  TestCommitPersistsState;
  TestOptimisticVersionInSQL;
  TestPersistedIdempotency;
  Writeln('4 testes de integração FireDAC executados com sucesso.');
end.

unit Atlas.Persistence.FireDAC.Store;

interface

uses
  System.SysUtils,
  FireDAC.Comp.Client;

type
  TIdempotencyWrite = (iwInserted, iwReplayed, iwConflict);

  TFireDACAtlasStore = class
  private
    FConnection: TFDConnection;
    function NewQuery: TFDQuery;
  public
    constructor Create;
    destructor Destroy; override;
    procedure InitializeSchema;
    procedure BeginUnitOfWork;
    procedure Commit;
    procedure Rollback;
    procedure SeedSale(const ASaleId: Int64);
    function LoadSaleStatus(const ASaleId: Int64): string;
    function LoadSaleVersion(const ASaleId: Int64): Integer;
    function TryFinalize(const ASaleId: Int64;
      const AExpectedVersion: Integer): Boolean;
    function RegisterIdempotency(const AKey, AFingerprint,
      AResult: string; out AStoredResult: string): TIdempotencyWrite;
  end;

implementation

uses
  Data.DB,
  FireDAC.Stan.Param;

constructor TFireDACAtlasStore.Create;
begin
  inherited Create;
  FConnection := TFDConnection.Create(nil);
  FConnection.LoginPrompt := False;
  FConnection.Params.DriverID := 'SQLite';
  FConnection.Params.Database := ':memory:';
  FConnection.Connected := True;
end;

destructor TFireDACAtlasStore.Destroy;
begin
  FConnection.Free;
  inherited;
end;

function TFireDACAtlasStore.NewQuery: TFDQuery;
begin
  Result := TFDQuery.Create(nil);
  Result.Connection := FConnection;
end;

procedure TFireDACAtlasStore.InitializeSchema;
begin
  FConnection.ExecSQL(
    'create table Sale (' +
    '  Id integer not null primary key,' +
    '  Status varchar(20) not null,' +
    '  Version integer not null' +
    ')');
  FConnection.ExecSQL(
    'create table Idempotency (' +
    '  IdempotencyKey varchar(100) not null primary key,' +
    '  Fingerprint varchar(200) not null,' +
    '  StoredResult varchar(200) not null' +
    ')');
end;

procedure TFireDACAtlasStore.BeginUnitOfWork;
begin
  if FConnection.InTransaction then
    raise EInvalidOpException.Create('Já existe uma unidade de trabalho ativa.');
  FConnection.StartTransaction;
end;

procedure TFireDACAtlasStore.Commit;
begin
  if not FConnection.InTransaction then
    raise EInvalidOpException.Create('Não existe transação para confirmar.');
  FConnection.Commit;
end;

procedure TFireDACAtlasStore.Rollback;
begin
  if not FConnection.InTransaction then
    raise EInvalidOpException.Create('Não existe transação para desfazer.');
  FConnection.Rollback;
end;

procedure TFireDACAtlasStore.SeedSale(const ASaleId: Int64);
var
  Query: TFDQuery;
begin
  Query := NewQuery;
  try
    Query.SQL.Text :=
      'insert into Sale(Id, Status, Version) values (:Id, :Status, :Version)';
    Query.ParamByName('Id').AsLargeInt := ASaleId;
    Query.ParamByName('Status').AsString := 'Draft';
    Query.ParamByName('Version').AsInteger := 1;
    Query.ExecSQL;
  finally
    Query.Free;
  end;
end;

function TFireDACAtlasStore.LoadSaleStatus(const ASaleId: Int64): string;
var
  Query: TFDQuery;
begin
  Query := NewQuery;
  try
    Query.SQL.Text := 'select Status from Sale where Id = :Id';
    Query.ParamByName('Id').AsLargeInt := ASaleId;
    Query.Open;
    if Query.Eof then
      raise EArgumentException.CreateFmt('Venda %d não encontrada.', [ASaleId]);
    Result := Query.Fields[0].AsString;
  finally
    Query.Free;
  end;
end;

function TFireDACAtlasStore.LoadSaleVersion(const ASaleId: Int64): Integer;
var
  Query: TFDQuery;
begin
  Query := NewQuery;
  try
    Query.SQL.Text := 'select Version from Sale where Id = :Id';
    Query.ParamByName('Id').AsLargeInt := ASaleId;
    Query.Open;
    if Query.Eof then
      raise EArgumentException.CreateFmt('Venda %d não encontrada.', [ASaleId]);
    Result := Query.Fields[0].AsInteger;
  finally
    Query.Free;
  end;
end;

function TFireDACAtlasStore.TryFinalize(const ASaleId: Int64;
  const AExpectedVersion: Integer): Boolean;
var
  Query: TFDQuery;
begin
  Query := NewQuery;
  try
    Query.SQL.Text :=
      'update Sale set Status = :Status, Version = Version + 1 ' +
      'where Id = :Id and Version = :ExpectedVersion';
    Query.ParamByName('Status').AsString := 'Finalized';
    Query.ParamByName('Id').AsLargeInt := ASaleId;
    Query.ParamByName('ExpectedVersion').AsInteger := AExpectedVersion;
    Query.ExecSQL;
    Result := Query.RowsAffected = 1;
  finally
    Query.Free;
  end;
end;

function TFireDACAtlasStore.RegisterIdempotency(const AKey, AFingerprint,
  AResult: string; out AStoredResult: string): TIdempotencyWrite;
var
  Query: TFDQuery;
  ExistingFingerprint: string;
begin
  if AKey.Trim.IsEmpty then
    raise EArgumentException.Create('A chave de idempotência é obrigatória.');

  Query := NewQuery;
  try
    Query.SQL.Text :=
      'select Fingerprint, StoredResult from Idempotency ' +
      'where IdempotencyKey = :IdempotencyKey';
    Query.ParamByName('IdempotencyKey').AsString := AKey;
    Query.Open;
    if not Query.Eof then
    begin
      ExistingFingerprint := Query.FieldByName('Fingerprint').AsString;
      AStoredResult := Query.FieldByName('StoredResult').AsString;
      if ExistingFingerprint = AFingerprint then
        Exit(iwReplayed);
      Exit(iwConflict);
    end;
    Query.Close;
    Query.SQL.Text :=
      'insert into Idempotency(IdempotencyKey, Fingerprint, StoredResult) ' +
      'values (:IdempotencyKey, :Fingerprint, :StoredResult)';
    Query.ParamByName('IdempotencyKey').AsString := AKey;
    Query.ParamByName('Fingerprint').AsString := AFingerprint;
    Query.ParamByName('StoredResult').AsString := AResult;
    Query.ExecSQL;
    AStoredResult := AResult;
    Result := iwInserted;
  finally
    Query.Free;
  end;
end;

end.

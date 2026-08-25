unit Atlas.Consistency.Idempotency;

interface

uses
  System.SysUtils,
  System.Generics.Collections;

type
  TIdempotencyOutcome = (ioExecuted, ioReplayed, ioConflict);

  TIdempotencyEntry = record
    Fingerprint: string;
    StoredResult: string;
  end;

  TIdempotencyRegistry = class
  private
    FEntries: TDictionary<string, TIdempotencyEntry>;
  public
    constructor Create;
    destructor Destroy; override;
    function Register(const AKey, AFingerprint, AResult: string;
      out AStoredResult: string): TIdempotencyOutcome;
  end;

implementation

constructor TIdempotencyRegistry.Create;
begin
  inherited;
  FEntries := TDictionary<string, TIdempotencyEntry>.Create;
end;

destructor TIdempotencyRegistry.Destroy;
begin
  FEntries.Free;
  inherited;
end;

function TIdempotencyRegistry.Register(const AKey, AFingerprint,
  AResult: string; out AStoredResult: string): TIdempotencyOutcome;
var
  Entry: TIdempotencyEntry;
begin
  if AKey.Trim.IsEmpty then
    raise EArgumentException.Create('A chave de idempotência é obrigatória.');

  if FEntries.TryGetValue(AKey, Entry) then
  begin
    AStoredResult := Entry.StoredResult;
    if Entry.Fingerprint = AFingerprint then
      Exit(ioReplayed)
    else
      Exit(ioConflict);
  end;

  Entry.Fingerprint := AFingerprint;
  Entry.StoredResult := AResult;
  FEntries.Add(AKey, Entry);
  AStoredResult := AResult;
  Result := ioExecuted;
end;

end.

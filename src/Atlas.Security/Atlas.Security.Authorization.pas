unit Atlas.Security.Authorization;

interface

uses
  System.SysUtils,
  System.Generics.Collections;

type
  TAuthorizationPolicy = class
  private
    FGrants: TDictionary<string, Boolean>;
    function Key(const ARole, AAction: string): string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Grant(const ARole, AAction: string);
    function IsAllowed(const ARole, AAction: string): Boolean;
  end;

  TAuditEntry = record
    ActorId: string;
    Action: string;
    EntityId: string;
    CorrelationId: string;
    Detail: string;
  end;

  TAuditTrail = class
  private
    FEntries: TList<TAuditEntry>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Append(const AEntry: TAuditEntry);
    function Count: Integer;
    function Last: TAuditEntry;
  end;

implementation

constructor TAuthorizationPolicy.Create;
begin
  inherited Create;
  FGrants := TDictionary<string, Boolean>.Create;
end;

destructor TAuthorizationPolicy.Destroy;
begin
  FGrants.Free;
  inherited;
end;

function TAuthorizationPolicy.Key(const ARole, AAction: string): string;
begin
  Result := UpperCase(Trim(ARole)) + '|' + UpperCase(Trim(AAction));
end;

procedure TAuthorizationPolicy.Grant(const ARole, AAction: string);
begin
  FGrants.AddOrSetValue(Key(ARole, AAction), True);
end;

function TAuthorizationPolicy.IsAllowed(const ARole, AAction: string): Boolean;
begin
  Result := FGrants.ContainsKey(Key(ARole, AAction));
end;

constructor TAuditTrail.Create;
begin
  inherited Create;
  FEntries := TList<TAuditEntry>.Create;
end;

destructor TAuditTrail.Destroy;
begin
  FEntries.Free;
  inherited;
end;

procedure TAuditTrail.Append(const AEntry: TAuditEntry);
begin
  if (AEntry.ActorId = '') or (AEntry.Action = '') or
    (AEntry.CorrelationId = '') then
    raise EArgumentException.Create(
      'Auditoria exige ator, ação e correlação.');
  FEntries.Add(AEntry);
end;

function TAuditTrail.Count: Integer;
begin
  Result := FEntries.Count;
end;

function TAuditTrail.Last: TAuditEntry;
begin
  if FEntries.Count = 0 then
    raise EInvalidOpException.Create('Trilha de auditoria vazia.');
  Result := FEntries[FEntries.Count - 1];
end;

end.

unit Atlas.Database.Migrations;

interface

uses
  System.SysUtils,
  System.Generics.Collections;

type
  TMigration = record
    Version: Integer;
    Name: string;
    Checksum: string;
    class function Create(const AVersion: Integer; const AName,
      AChecksum: string): TMigration; static;
  end;

  TMigrationLedger = class
  private
    FApplied: TDictionary<Integer, string>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure RegisterApplied(const AMigration: TMigration);
    function NeedsApply(const AMigration: TMigration): Boolean;
  end;

implementation

class function TMigration.Create(const AVersion: Integer; const AName,
  AChecksum: string): TMigration;
begin
  if (AVersion < 1) or (Trim(AName) = '') or (Trim(AChecksum) = '') then
    raise EArgumentException.Create('Migration exige versão, nome e checksum.');
  Result.Version := AVersion;
  Result.Name := AName;
  Result.Checksum := AChecksum;
end;

constructor TMigrationLedger.Create;
begin
  inherited Create;
  FApplied := TDictionary<Integer, string>.Create;
end;

destructor TMigrationLedger.Destroy;
begin
  FApplied.Free;
  inherited;
end;

procedure TMigrationLedger.RegisterApplied(const AMigration: TMigration);
var
  ExistingChecksum: string;
begin
  if FApplied.TryGetValue(AMigration.Version, ExistingChecksum) then
  begin
    if ExistingChecksum <> AMigration.Checksum then
      raise EInvalidOpException.CreateFmt(
        'Migration %d foi alterada depois de aplicada.', [AMigration.Version]);
    Exit;
  end;
  FApplied.Add(AMigration.Version, AMigration.Checksum);
end;

function TMigrationLedger.NeedsApply(const AMigration: TMigration): Boolean;
var
  ExistingChecksum: string;
begin
  if not FApplied.TryGetValue(AMigration.Version, ExistingChecksum) then
    Exit(True);
  if ExistingChecksum <> AMigration.Checksum then
    raise EInvalidOpException.CreateFmt(
      'Checksum divergente na migration %d.', [AMigration.Version]);
  Result := False;
end;

end.

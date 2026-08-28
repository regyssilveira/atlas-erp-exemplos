unit Atlas.Fiscal.Domain.TaxSnapshot;

interface

uses
  System.SysUtils;

type
  TTaxDecisionSnapshot = class
  private
    FOperationId: string;
    FPolicyId: string;
    FCatalogVersion: string;
    FInputFingerprint: string;
    FResultFingerprint: string;
  public
    constructor Create(const AOperationId, APolicyId, ACatalogVersion,
      AInputFingerprint, AResultFingerprint: string);
    function MatchesInput(const AInputFingerprint: string): Boolean;
    function CanReproduceWith(const APolicyId,
      ACatalogVersion: string): Boolean;
    property OperationId: string read FOperationId;
    property PolicyId: string read FPolicyId;
    property CatalogVersion: string read FCatalogVersion;
    property InputFingerprint: string read FInputFingerprint;
    property ResultFingerprint: string read FResultFingerprint;
  end;

implementation

constructor TTaxDecisionSnapshot.Create(const AOperationId, APolicyId,
  ACatalogVersion, AInputFingerprint, AResultFingerprint: string);
begin
  inherited Create;
  if AOperationId.Trim.IsEmpty then
    raise EArgumentException.Create('OperationId é obrigatório.');
  if APolicyId.Trim.IsEmpty then
    raise EArgumentException.Create('PolicyId é obrigatório.');
  if ACatalogVersion.Trim.IsEmpty then
    raise EArgumentException.Create('CatalogVersion é obrigatória.');
  if AInputFingerprint.Trim.IsEmpty then
    raise EArgumentException.Create('InputFingerprint é obrigatório.');
  if AResultFingerprint.Trim.IsEmpty then
    raise EArgumentException.Create('ResultFingerprint é obrigatório.');

  FOperationId := AOperationId;
  FPolicyId := APolicyId;
  FCatalogVersion := ACatalogVersion;
  FInputFingerprint := AInputFingerprint;
  FResultFingerprint := AResultFingerprint;
end;

function TTaxDecisionSnapshot.MatchesInput(
  const AInputFingerprint: string): Boolean;
begin
  Result := SameText(FInputFingerprint, AInputFingerprint);
end;

function TTaxDecisionSnapshot.CanReproduceWith(const APolicyId,
  ACatalogVersion: string): Boolean;
begin
  Result := SameText(FPolicyId, APolicyId) and
    SameText(FCatalogVersion, ACatalogVersion);
end;

end.

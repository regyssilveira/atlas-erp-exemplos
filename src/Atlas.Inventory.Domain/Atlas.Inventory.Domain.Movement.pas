unit Atlas.Inventory.Domain.Movement;

interface

uses
  System.SysUtils,
  System.Generics.Collections;

type
  TStockMovementKind = (smEntry, smExit, smAdjustment);

  TStockMovement = record
  private
    FId: Int64;
    FProductId: Int64;
    FBranchId: Int64;
    FQuantity: Double;
    FKind: TStockMovementKind;
    FSource: string;
    FOccurredAt: TDateTime;
  public
    class function Create(const AId, AProductId, ABranchId: Int64;
      const AQuantity: Double; const AKind: TStockMovementKind;
      const ASource: string; const AOccurredAt: TDateTime): TStockMovement; static;
    function SignedQuantity: Double;
    property Id: Int64 read FId;
    property ProductId: Int64 read FProductId;
    property BranchId: Int64 read FBranchId;
    property Source: string read FSource;
    property OccurredAt: TDateTime read FOccurredAt;
  end;

  TStockLedger = class
  private
    FMovements: TList<TStockMovement>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Post(const AMovement: TStockMovement);
    function Balance(const AProductId, ABranchId: Int64): Double;
  end;

implementation

class function TStockMovement.Create(const AId, AProductId, ABranchId: Int64;
  const AQuantity: Double; const AKind: TStockMovementKind;
  const ASource: string; const AOccurredAt: TDateTime): TStockMovement;
begin
  if (AId <= 0) or (AProductId <= 0) or (ABranchId <= 0) then
    raise EArgumentOutOfRangeException.Create('Identificadores devem ser positivos.');
  if AQuantity <= 0 then
    raise EArgumentOutOfRangeException.Create('A quantidade deve ser positiva.');
  if ASource.Trim.IsEmpty then
    raise EArgumentException.Create('A origem do movimento é obrigatória.');
  if AOccurredAt <= 0 then
    raise EArgumentOutOfRangeException.Create('OccurredAt');

  Result.FId := AId;
  Result.FProductId := AProductId;
  Result.FBranchId := ABranchId;
  Result.FQuantity := AQuantity;
  Result.FKind := AKind;
  Result.FSource := ASource;
  Result.FOccurredAt := AOccurredAt;
end;

function TStockMovement.SignedQuantity: Double;
begin
  case FKind of
    smEntry: Result := FQuantity;
    smExit: Result := -FQuantity;
  else
    Result := FQuantity;
  end;
end;

constructor TStockLedger.Create;
begin
  inherited;
  FMovements := TList<TStockMovement>.Create;
end;

destructor TStockLedger.Destroy;
begin
  FMovements.Free;
  inherited;
end;

procedure TStockLedger.Post(const AMovement: TStockMovement);
begin
  FMovements.Add(AMovement);
end;

function TStockLedger.Balance(const AProductId, ABranchId: Int64): Double;
var
  Movement: TStockMovement;
begin
  Result := 0;
  for Movement in FMovements do
    if (Movement.ProductId = AProductId) and
       (Movement.BranchId = ABranchId) then
      Result := Result + Movement.SignedQuantity;
end;

end.

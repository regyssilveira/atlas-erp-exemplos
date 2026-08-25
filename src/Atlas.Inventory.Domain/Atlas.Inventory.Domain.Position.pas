unit Atlas.Inventory.Domain.Position;

interface

uses
  System.SysUtils,
  System.Generics.Collections;

type
  TStockPosition = class
  private
    FOnHand: Double;
    FReservations: TDictionary<Int64, Double>;
    function ReservedQuantity: Double;
  public
    constructor Create(const AInitialOnHand: Double);
    destructor Destroy; override;
    procedure Receive(const AQuantity: Double);
    function TryReserve(const AReservationId: Int64;
      const AQuantity: Double): Boolean;
    procedure Confirm(const AReservationId: Int64);
    procedure Release(const AReservationId: Int64);
    function Available: Double;
    property OnHand: Double read FOnHand;
  end;

implementation

constructor TStockPosition.Create(const AInitialOnHand: Double);
begin
  inherited Create;
  if AInitialOnHand < 0 then
    raise EArgumentOutOfRangeException.Create('AInitialOnHand');
  FOnHand := AInitialOnHand;
  FReservations := TDictionary<Int64, Double>.Create;
end;

destructor TStockPosition.Destroy;
begin
  FReservations.Free;
  inherited;
end;

procedure TStockPosition.Receive(const AQuantity: Double);
begin
  if AQuantity <= 0 then
    raise EArgumentOutOfRangeException.Create('AQuantity');
  FOnHand := FOnHand + AQuantity;
end;

function TStockPosition.ReservedQuantity: Double;
var
  Quantity: Double;
begin
  Result := 0;
  for Quantity in FReservations.Values do
    Result := Result + Quantity;
end;

function TStockPosition.Available: Double;
begin
  Result := FOnHand - ReservedQuantity;
end;

function TStockPosition.TryReserve(const AReservationId: Int64;
  const AQuantity: Double): Boolean;
begin
  if (AReservationId <= 0) or (AQuantity <= 0) then
    raise EArgumentOutOfRangeException.Create('Reserva inválida.');
  if FReservations.ContainsKey(AReservationId) then
    Exit(False);
  Result := AQuantity <= Available;
  if Result then
    FReservations.Add(AReservationId, AQuantity);
end;

procedure TStockPosition.Confirm(const AReservationId: Int64);
var
  Quantity: Double;
begin
  if not FReservations.TryGetValue(AReservationId, Quantity) then
    raise EInvalidOpException.Create('Reserva não encontrada.');
  FOnHand := FOnHand - Quantity;
  FReservations.Remove(AReservationId);
end;

procedure TStockPosition.Release(const AReservationId: Int64);
begin
  if not FReservations.ContainsKey(AReservationId) then
    raise EInvalidOpException.Create('Reserva não encontrada.');
  FReservations.Remove(AReservationId);
end;

end.

unit Atlas.Integration.Inventory.InMemory;

interface

uses
  Atlas.Sales.Contracts;

type
  TInventoryReservationAdapter = class(TInterfacedObject, IStockReservation)
  private
    FAvailableItemUnits: Integer;
  public
    constructor Create(const AAvailableItemUnits: Integer);
    function TryReserveForSale(const ASaleId, ACompanyId, ABranchId: Int64;
      const AItemCount: Integer; out AReason: string): Boolean;
  end;

implementation

constructor TInventoryReservationAdapter.Create(
  const AAvailableItemUnits: Integer);
begin
  inherited Create;
  FAvailableItemUnits := AAvailableItemUnits;
end;

function TInventoryReservationAdapter.TryReserveForSale(
  const ASaleId, ACompanyId, ABranchId: Int64;
  const AItemCount: Integer; out AReason: string): Boolean;
begin
  Result := AItemCount <= FAvailableItemUnits;
  if Result then
  begin
    Dec(FAvailableItemUnits, AItemCount);
    AReason := '';
  end
  else
    AReason := 'Estoque insuficiente para reservar os itens da venda.';
end;

end.

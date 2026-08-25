unit Atlas.Consistency.OptimisticLock;

interface

type
  TSaleSnapshot = record
    SaleId: Int64;
    Version: Integer;
    Finalized: Boolean;
  end;

  TVersionedSaleStore = class
  private
    FSaleId: Int64;
    FVersion: Integer;
    FFinalized: Boolean;
  public
    constructor Create(const ASaleId: Int64);
    function Load: TSaleSnapshot;
    function TryFinalize(const AExpectedVersion: Integer;
      out ACurrentVersion: Integer): Boolean;
  end;

implementation

constructor TVersionedSaleStore.Create(const ASaleId: Int64);
begin
  inherited Create;
  FSaleId := ASaleId;
  FVersion := 1;
  FFinalized := False;
end;

function TVersionedSaleStore.Load: TSaleSnapshot;
begin
  Result.SaleId := FSaleId;
  Result.Version := FVersion;
  Result.Finalized := FFinalized;
end;

function TVersionedSaleStore.TryFinalize(const AExpectedVersion: Integer;
  out ACurrentVersion: Integer): Boolean;
begin
  Result := (AExpectedVersion = FVersion) and not FFinalized;
  if Result then
  begin
    FFinalized := True;
    Inc(FVersion);
  end;
  ACurrentVersion := FVersion;
end;

end.

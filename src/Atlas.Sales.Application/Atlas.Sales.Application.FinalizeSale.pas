unit Atlas.Sales.Application.FinalizeSale;

interface

uses
  System.SysUtils,
  Atlas.Shared.Context,
  Atlas.Sales.Domain.Sale,
  Atlas.Sales.Contracts;

type
  TFinalizeSaleCommand = record
    SaleId: Int64;
    Context: TOperationContext;
  end;

  TFinalizeSaleResult = record
  private
    FSuccess: Boolean;
    FReason: string;
  public
    class function Accepted: TFinalizeSaleResult; static;
    class function Rejected(const AReason: string): TFinalizeSaleResult; static;
    property Success: Boolean read FSuccess;
    property Reason: string read FReason;
  end;

  TFinalizeSale = class
  private
    FSales: ISaleRepository;
    FStock: IStockReservation;
    FUnitOfWork: IUnitOfWork;
  public
    constructor Create(const ASales: ISaleRepository;
      const AStock: IStockReservation; const AUnitOfWork: IUnitOfWork);
    function Execute(const ACommand: TFinalizeSaleCommand): TFinalizeSaleResult;
  end;

implementation

class function TFinalizeSaleResult.Accepted: TFinalizeSaleResult;
begin
  Result.FSuccess := True;
  Result.FReason := '';
end;

class function TFinalizeSaleResult.Rejected(
  const AReason: string): TFinalizeSaleResult;
begin
  Result.FSuccess := False;
  Result.FReason := AReason;
end;

constructor TFinalizeSale.Create(const ASales: ISaleRepository;
  const AStock: IStockReservation; const AUnitOfWork: IUnitOfWork);
begin
  inherited Create;
  if not Assigned(ASales) then
    raise EArgumentNilException.Create('ASales');
  if not Assigned(AStock) then
    raise EArgumentNilException.Create('AStock');
  if not Assigned(AUnitOfWork) then
    raise EArgumentNilException.Create('AUnitOfWork');
  FSales := ASales;
  FStock := AStock;
  FUnitOfWork := AUnitOfWork;
end;

function TFinalizeSale.Execute(
  const ACommand: TFinalizeSaleCommand): TFinalizeSaleResult;
var
  Sale: TSale;
  RejectionReason: string;
begin
  Sale := FSales.FindById(ACommand.SaleId,
    ACommand.Context.CompanyId, ACommand.Context.BranchId);
  if not Assigned(Sale) then
    Exit(TFinalizeSaleResult.Rejected('Venda não encontrada no contexto informado.'));

  if not FStock.TryReserveForSale(Sale.Id, Sale.CompanyId, Sale.BranchId,
    Sale.ItemCount, RejectionReason) then
    Exit(TFinalizeSaleResult.Rejected(RejectionReason));

  FUnitOfWork.BeginWork;
  try
    Sale.Finalize;
    FSales.Save(Sale);
    FUnitOfWork.Commit;
  except
    FUnitOfWork.Rollback;
    raise;
  end;
  Result := TFinalizeSaleResult.Accepted;
end;

end.

program AtlasERPModular;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Atlas.Shared.Context in '..\Atlas.Shared\Atlas.Shared.Context.pas',
  Atlas.Sales.Domain.Sale in '..\Atlas.Sales.Domain\Atlas.Sales.Domain.Sale.pas',
  Atlas.Sales.Contracts in '..\Atlas.Sales.Contracts\Atlas.Sales.Contracts.pas',
  Atlas.Sales.Application.FinalizeSale in '..\Atlas.Sales.Application\Atlas.Sales.Application.FinalizeSale.pas',
  Atlas.Infrastructure.Memory in '..\Atlas.Infrastructure.Memory\Atlas.Infrastructure.Memory.pas',
  Atlas.Integration.Inventory.InMemory in '..\Atlas.Integration.Inventory\Atlas.Integration.Inventory.InMemory.pas';

var
  Sales: ISaleRepository;
  Stock: IStockReservation;
  UnitOfWork: IUnitOfWork;
  UseCase: TFinalizeSale;
  Command: TFinalizeSaleCommand;
  UseCaseResult: TFinalizeSaleResult;
begin
  Sales := TInMemorySaleRepository.Create(TSale.Create(8457, 10, 2, 3));
  Stock := TInventoryReservationAdapter.Create(20);
  UnitOfWork := TNoOpUnitOfWork.Create;
  UseCase := TFinalizeSale.Create(Sales, Stock, UnitOfWork);
  try
    Command.SaleId := 8457;
    Command.Context := TOperationContext.Create(10, 2, 37,
      'SALE-8457-ATTEMPT-2');
    UseCaseResult := UseCase.Execute(Command);
    if UseCaseResult.Success then
      Writeln('Venda finalizada pelo host modular.')
    else
      Writeln('Venda rejeitada: ', UseCaseResult.Reason);
  finally
    UseCase.Free;
  end;
end.

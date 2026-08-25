program AtlasERP;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Atlas.Sales.FinalizeSale in '..\Atlas.Sales\Atlas.Sales.FinalizeSale.pas';

var
  Sale: TSale;
  UseCase: TFinalizeSale;
  Command: TFinalizeSaleCommand;
  UseCaseResult: TFinalizeSaleResult;
begin
  Sale := TSale.Create(8457, 3);
  try
    UseCase := TFinalizeSale.Create(Sale);
    try
      Command.SaleId := Sale.Id;
      Command.CompanyId := 10;
      Command.BranchId := 2;
      Command.UserId := 37;
      Command.CorrelationId := 'SALE-8457-ATTEMPT-1';

      UseCaseResult := UseCase.Execute(Command);
      if UseCaseResult.Success then
        Writeln('Venda ', UseCaseResult.SaleId, ' finalizada.')
      else
        Writeln('Venda rejeitada: ', UseCaseResult.Reason);
    finally
      UseCase.Free;
    end;
  finally
    Sale.Free;
  end;
end.

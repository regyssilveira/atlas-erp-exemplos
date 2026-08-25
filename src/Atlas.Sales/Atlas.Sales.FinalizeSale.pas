unit Atlas.Sales.FinalizeSale;

interface

uses
  System.SysUtils;

type
  TSaleStatus = (ssOpen, ssFinalized);

  TSale = class
  private
    FId: Int64;
    FItemCount: Integer;
    FStatus: TSaleStatus;
  public
    constructor Create(const AId: Int64; const AItemCount: Integer);
    procedure MarkAsFinalized;
    property Id: Int64 read FId;
    property ItemCount: Integer read FItemCount;
    property Status: TSaleStatus read FStatus;
  end;

  TFinalizeSaleCommand = record
    SaleId: Int64;
    CompanyId: Int64;
    BranchId: Int64;
    UserId: Int64;
    CorrelationId: string;
  end;

  TFinalizeSaleResult = record
  private
    FSuccess: Boolean;
    FSaleId: Int64;
    FReason: string;
  public
    class function Rejected(const AReason: string): TFinalizeSaleResult; static;
    class function Succeeded(const ASaleId: Int64): TFinalizeSaleResult; static;
    property Success: Boolean read FSuccess;
    property SaleId: Int64 read FSaleId;
    property Reason: string read FReason;
  end;

  TFinalizeSale = class
  private
    FSale: TSale;
  public
    constructor Create(const ASale: TSale);
    function Execute(const Command: TFinalizeSaleCommand): TFinalizeSaleResult;
  end;

implementation

{ TSale }

constructor TSale.Create(const AId: Int64; const AItemCount: Integer);
begin
  inherited Create;
  if AId <= 0 then
    raise EArgumentOutOfRangeException.Create('A venda precisa de um identificador válido.');
  if AItemCount < 0 then
    raise EArgumentOutOfRangeException.Create('A quantidade de itens não pode ser negativa.');

  FId := AId;
  FItemCount := AItemCount;
  FStatus := ssOpen;
end;

procedure TSale.MarkAsFinalized;
begin
  if FStatus <> ssOpen then
    raise EInvalidOpException.Create('Somente uma venda aberta pode ser finalizada.');
  FStatus := ssFinalized;
end;

{ TFinalizeSaleResult }

class function TFinalizeSaleResult.Rejected(
  const AReason: string): TFinalizeSaleResult;
begin
  Result.FSuccess := False;
  Result.FSaleId := 0;
  Result.FReason := AReason;
end;

class function TFinalizeSaleResult.Succeeded(
  const ASaleId: Int64): TFinalizeSaleResult;
begin
  Result.FSuccess := True;
  Result.FSaleId := ASaleId;
  Result.FReason := '';
end;

{ TFinalizeSale }

constructor TFinalizeSale.Create(const ASale: TSale);
begin
  inherited Create;
  if not Assigned(ASale) then
    raise EArgumentNilException.Create('ASale');
  FSale := ASale;
end;

function TFinalizeSale.Execute(
  const Command: TFinalizeSaleCommand): TFinalizeSaleResult;
begin
  if Command.SaleId <> FSale.Id then
    Exit(TFinalizeSaleResult.Rejected('A venda informada não corresponde à venda carregada.'));

  if FSale.Status <> ssOpen then
    Exit(TFinalizeSaleResult.Rejected('A venda não está aberta.'));

  if FSale.ItemCount = 0 then
    Exit(TFinalizeSaleResult.Rejected('A venda não possui itens.'));

  FSale.MarkAsFinalized;
  Result := TFinalizeSaleResult.Succeeded(Command.SaleId);
end;

end.

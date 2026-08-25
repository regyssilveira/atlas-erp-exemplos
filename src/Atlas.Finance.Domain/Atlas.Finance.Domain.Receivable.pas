unit Atlas.Finance.Domain.Receivable;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Atlas.Shared.Money;

type
  TReceivableStatus = (rsOpen, rsPartiallyPaid, rsSettled);

  TReceivable = class
  private
    FOriginalAmount: TMoney;
    FPaidAmount: TMoney;
    FPaymentIds: TDictionary<string, Boolean>;
    function GetStatus: TReceivableStatus;
  public
    constructor Create(const AOriginalAmount: TMoney);
    destructor Destroy; override;
    function ApplyPayment(const APaymentId: string;
      const AAmount: TMoney): Boolean;
    function Outstanding: TMoney;
    property Status: TReceivableStatus read GetStatus;
  end;

implementation

constructor TReceivable.Create(const AOriginalAmount: TMoney);
begin
  inherited Create;
  if AOriginalAmount.Amount <= 0 then
    raise EArgumentOutOfRangeException.Create('AOriginalAmount');
  FOriginalAmount := AOriginalAmount;
  FPaidAmount := TMoney.Zero;
  FPaymentIds := TDictionary<string, Boolean>.Create;
end;

destructor TReceivable.Destroy;
begin
  FPaymentIds.Free;
  inherited;
end;

function TReceivable.ApplyPayment(const APaymentId: string;
  const AAmount: TMoney): Boolean;
begin
  if APaymentId.Trim.IsEmpty then
    raise EArgumentException.Create('PaymentId é obrigatório.');
  if AAmount.Amount <= 0 then
    raise EArgumentOutOfRangeException.Create('AAmount');
  if FPaymentIds.ContainsKey(APaymentId) then
    Exit(False);
  if AAmount.Amount > Outstanding.Amount then
    raise EInvalidOpException.Create('O pagamento supera o saldo do título.');

  FPaidAmount := FPaidAmount.Add(AAmount);
  FPaymentIds.Add(APaymentId, True);
  Result := True;
end;

function TReceivable.Outstanding: TMoney;
begin
  Result := FOriginalAmount.Subtract(FPaidAmount);
end;

function TReceivable.GetStatus: TReceivableStatus;
begin
  if FPaidAmount.Amount = 0 then
    Result := rsOpen
  else if Outstanding.Amount = 0 then
    Result := rsSettled
  else
    Result := rsPartiallyPaid;
end;

end.

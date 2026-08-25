unit Atlas.Sales.Rules.Discount;

interface

uses
  System.SysUtils,
  Atlas.Shared.Money;

type
  TDiscountDecision = record
  private
    FAccepted: Boolean;
    FDiscount: TMoney;
    FReason: string;
  public
    class function Accept(const ADiscount: TMoney): TDiscountDecision; static;
    class function Reject(const AReason: string): TDiscountDecision; static;
    property Accepted: Boolean read FAccepted;
    property Discount: TMoney read FDiscount;
    property Reason: string read FReason;
  end;

  TProgressiveDiscountPolicy = class
  private
    FMinimumTotal: TMoney;
    FRate: Double;
    FMaximumDiscount: TMoney;
  public
    constructor Create(const AMinimumTotal: TMoney; const ARate: Double;
      const AMaximumDiscount: TMoney);
    function Decide(const ASaleTotal, ARequestedDiscount: TMoney): TDiscountDecision;
  end;

implementation

class function TDiscountDecision.Accept(
  const ADiscount: TMoney): TDiscountDecision;
begin
  Result.FAccepted := True;
  Result.FDiscount := ADiscount;
  Result.FReason := '';
end;

class function TDiscountDecision.Reject(
  const AReason: string): TDiscountDecision;
begin
  Result.FAccepted := False;
  Result.FDiscount := TMoney.Zero;
  Result.FReason := AReason;
end;

constructor TProgressiveDiscountPolicy.Create(const AMinimumTotal: TMoney;
  const ARate: Double; const AMaximumDiscount: TMoney);
begin
  inherited Create;
  if (ARate < 0) or (ARate > 1) then
    raise EArgumentOutOfRangeException.Create('ARate');
  FMinimumTotal := AMinimumTotal;
  FRate := ARate;
  FMaximumDiscount := AMaximumDiscount;
end;

function TProgressiveDiscountPolicy.Decide(
  const ASaleTotal, ARequestedDiscount: TMoney): TDiscountDecision;
var
  AllowedDiscount: TMoney;
begin
  if ASaleTotal.Amount < FMinimumTotal.Amount then
    Exit(TDiscountDecision.Reject('O total não atinge o mínimo da política.'));

  AllowedDiscount := ASaleTotal.Percentage(FRate);
  if AllowedDiscount.Amount > FMaximumDiscount.Amount then
    AllowedDiscount := FMaximumDiscount;

  if ARequestedDiscount.Amount > AllowedDiscount.Amount then
    Exit(TDiscountDecision.Reject('O desconto solicitado excede o limite permitido.'));

  Result := TDiscountDecision.Accept(ARequestedDiscount);
end;

end.

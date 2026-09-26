unit Atlas.Legacy.Discount;

interface

uses
  Atlas.Shared.Money,
  Atlas.Sales.Rules.Discount;

type
  // A controlled slice of the old routine, not a complete Form or DataModule.
  TLegacyDiscountRoutine = class
  public
    function Accepts(const ATotal, ARequested, ACap: Currency): Boolean;
  end;

  TExtractedDiscountRoutine = class
  public
    function Accepts(const ATotal, ARequested, ACap: Currency): Boolean;
  end;

implementation

function TLegacyDiscountRoutine.Accepts(
  const ATotal, ARequested, ACap: Currency): Boolean;
var
  Allowed: Currency;
begin
  if ATotal < 1000 then
    Exit(False);
  Allowed := TMoney.Create(ATotal).Percentage(0.10).Amount;
  if Allowed > ACap then
    Allowed := ACap;
  Result := ARequested <= Allowed;
end;

function TExtractedDiscountRoutine.Accepts(
  const ATotal, ARequested, ACap: Currency): Boolean;
var
  Policy: TProgressiveDiscountPolicy;
begin
  Policy := TProgressiveDiscountPolicy.Create(
    TMoney.Create(1000), 0.10, TMoney.Create(ACap));
  try
    Result := Policy.Decide(
      TMoney.Create(ATotal), TMoney.Create(ARequested)).Accepted;
  finally
    Policy.Free;
  end;
end;

end.

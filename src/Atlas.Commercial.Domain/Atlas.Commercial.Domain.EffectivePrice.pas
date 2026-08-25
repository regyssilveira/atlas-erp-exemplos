unit Atlas.Commercial.Domain.EffectivePrice;

interface

uses
  System.SysUtils,
  Atlas.Shared.Money;

type
  TEffectivePrice = record
  private
    FProductId: Int64;
    FPrice: TMoney;
    FValidFrom: TDateTime;
    FValidUntil: TDateTime;
  public
    class function Create(const AProductId: Int64; const APrice: TMoney;
      const AValidFrom, AValidUntil: TDateTime): TEffectivePrice; static;
    function IsEffectiveOn(const ADate: TDateTime): Boolean;
    property Price: TMoney read FPrice;
  end;

implementation

class function TEffectivePrice.Create(const AProductId: Int64;
  const APrice: TMoney; const AValidFrom, AValidUntil: TDateTime): TEffectivePrice;
begin
  if AProductId <= 0 then
    raise EArgumentOutOfRangeException.Create('ProductId');
  if APrice.Amount < 0 then
    raise EArgumentOutOfRangeException.Create('Price');
  if AValidFrom <= 0 then
    raise EArgumentOutOfRangeException.Create('ValidFrom');
  if (AValidUntil > 0) and (AValidUntil <= AValidFrom) then
    raise EArgumentException.Create('O fim da vigência deve ser posterior ao início.');

  Result.FProductId := AProductId;
  Result.FPrice := APrice;
  Result.FValidFrom := AValidFrom;
  Result.FValidUntil := AValidUntil;
end;

function TEffectivePrice.IsEffectiveOn(const ADate: TDateTime): Boolean;
begin
  Result := (ADate >= FValidFrom) and
    ((FValidUntil = 0) or (ADate < FValidUntil));
end;

end.

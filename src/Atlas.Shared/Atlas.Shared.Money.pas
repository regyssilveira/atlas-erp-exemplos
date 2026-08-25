unit Atlas.Shared.Money;

interface

uses
  System.SysUtils,
  System.Math;

type
  TMoney = record
  private
    FAmount: Currency;
  public
    class function Create(const AAmount: Currency): TMoney; static;
    class function Zero: TMoney; static;
    function Add(const AOther: TMoney): TMoney;
    function Subtract(const AOther: TMoney): TMoney;
    function Percentage(const ARate: Double): TMoney;
    property Amount: Currency read FAmount;
  end;

implementation

class function TMoney.Create(const AAmount: Currency): TMoney;
begin
  Result.FAmount := AAmount;
end;

class function TMoney.Zero: TMoney;
begin
  Result.FAmount := 0;
end;

function TMoney.Add(const AOther: TMoney): TMoney;
begin
  Result := TMoney.Create(FAmount + AOther.FAmount);
end;

function TMoney.Subtract(const AOther: TMoney): TMoney;
begin
  Result := TMoney.Create(FAmount - AOther.FAmount);
end;

function TMoney.Percentage(const ARate: Double): TMoney;
begin
  if (ARate < 0) or (ARate > 1) then
    raise EArgumentOutOfRangeException.Create('ARate deve estar entre zero e um.');
  Result := TMoney.Create(SimpleRoundTo(FAmount * ARate, -2));
end;

end.

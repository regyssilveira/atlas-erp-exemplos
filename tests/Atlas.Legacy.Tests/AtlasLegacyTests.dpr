program AtlasLegacyTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Atlas.Shared.Money in '..\..\src\Atlas.Shared\Atlas.Shared.Money.pas',
  Atlas.Sales.Rules.Discount in '..\..\src\Atlas.Sales.Rules\Atlas.Sales.Rules.Discount.pas',
  Atlas.Legacy.Discount in '..\..\src\Atlas.Legacy\Atlas.Legacy.Discount.pas';

var
  OldPath: TLegacyDiscountRoutine;
  NewPath: TExtractedDiscountRoutine;
  Count: Integer;

procedure CheckCase(const AName: string;
  const ATotal, ARequested, ACap: Currency; const AExpected: Boolean);
var
  Before, After: Boolean;
begin
  Before := OldPath.Accepts(ATotal, ARequested, ACap);
  After := NewPath.Accepts(ATotal, ARequested, ACap);
  if (Before <> AExpected) or (After <> AExpected) then
    raise Exception.Create('Characterization failed: ' + AName);
  Inc(Count);
  Writeln('PASS: ', AName);
end;

begin
  OldPath := TLegacyDiscountRoutine.Create;
  NewPath := TExtractedDiscountRoutine.Create;
  try
    try
      CheckCase('below eligibility', 999.99, 0, 150, False);
      CheckCase('eligibility boundary', 1000, 100, 150, True);
      CheckCase('accepted discount', 1200, 100, 150, True);
      CheckCase('percentage boundary', 1200, 120, 150, True);
      CheckCase('above percentage', 1200, 120.01, 150, False);
      CheckCase('cap boundary', 2000, 150, 150, True);
      CheckCase('above cap', 2000, 150.01, 150, False);
      CheckCase('branch cap', 1200, 100, 90, False);
      // Known anomaly, preserved only to separate extraction from correction.
      CheckCase('known negative-input anomaly', 1200, -1, 150, True);
      Writeln(Count, ' characterization cases passed on both paths.');
    except
      on E: Exception do
      begin
        Writeln(E.ClassName, ': ', E.Message);
        ExitCode := 1;
      end;
    end;
  finally
    NewPath.Free;
    OldPath.Free;
  end;
end.

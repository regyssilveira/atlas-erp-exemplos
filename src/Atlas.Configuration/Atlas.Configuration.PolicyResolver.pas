unit Atlas.Configuration.PolicyResolver;

interface

uses
  System.SysUtils,
  System.Generics.Collections;

type
  TPolicyContext = record
    CompanyId: Int64;
    BranchId: Int64;
    UserId: Int64;
    OperationName: string;
  end;

  TPolicyRule = record
    CompanyId: Int64;
    BranchId: Int64;
    UserId: Int64;
    OperationName: string;
    DiscountRate: Double;
  end;

  TDiscountPolicyResolver = class
  private
    FRules: TList<TPolicyRule>;
    function Matches(const ARule: TPolicyRule;
      const AContext: TPolicyContext): Boolean;
    function Specificity(const ARule: TPolicyRule): Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const ARule: TPolicyRule);
    function Resolve(const AContext: TPolicyContext;
      out ADiscountRate: Double): Boolean;
  end;

implementation

constructor TDiscountPolicyResolver.Create;
begin
  inherited;
  FRules := TList<TPolicyRule>.Create;
end;

destructor TDiscountPolicyResolver.Destroy;
begin
  FRules.Free;
  inherited;
end;

procedure TDiscountPolicyResolver.Add(const ARule: TPolicyRule);
begin
  if (ARule.DiscountRate < 0) or (ARule.DiscountRate > 1) then
    raise EArgumentOutOfRangeException.Create('DiscountRate');
  FRules.Add(ARule);
end;

function TDiscountPolicyResolver.Matches(const ARule: TPolicyRule;
  const AContext: TPolicyContext): Boolean;
begin
  Result := ((ARule.CompanyId = 0) or
             (ARule.CompanyId = AContext.CompanyId)) and
            ((ARule.BranchId = 0) or
             (ARule.BranchId = AContext.BranchId)) and
            ((ARule.UserId = 0) or
             (ARule.UserId = AContext.UserId)) and
            (ARule.OperationName.IsEmpty or
             SameText(ARule.OperationName, AContext.OperationName));
end;

function TDiscountPolicyResolver.Specificity(
  const ARule: TPolicyRule): Integer;
begin
  Result := 0;
  if ARule.CompanyId <> 0 then Inc(Result, 1);
  if ARule.BranchId <> 0 then Inc(Result, 2);
  if ARule.UserId <> 0 then Inc(Result, 4);
  if not ARule.OperationName.IsEmpty then Inc(Result, 8);
end;

function TDiscountPolicyResolver.Resolve(const AContext: TPolicyContext;
  out ADiscountRate: Double): Boolean;
var
  Rule: TPolicyRule;
  Score: Integer;
  BestScore: Integer;
begin
  Result := False;
  BestScore := -1;
  ADiscountRate := 0;
  for Rule in FRules do
    if Matches(Rule, AContext) then
    begin
      Score := Specificity(Rule);
      if Score > BestScore then
      begin
        BestScore := Score;
        ADiscountRate := Rule.DiscountRate;
        Result := True;
      end;
    end;
end;

end.

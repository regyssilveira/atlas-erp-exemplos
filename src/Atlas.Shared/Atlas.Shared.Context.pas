unit Atlas.Shared.Context;

interface

uses
  System.SysUtils;

type
  TOperationContext = record
  private
    FCompanyId: Int64;
    FBranchId: Int64;
    FUserId: Int64;
    FCorrelationId: string;
  public
    class function Create(const ACompanyId, ABranchId, AUserId: Int64;
      const ACorrelationId: string): TOperationContext; static;
    property CompanyId: Int64 read FCompanyId;
    property BranchId: Int64 read FBranchId;
    property UserId: Int64 read FUserId;
    property CorrelationId: string read FCorrelationId;
  end;

implementation

class function TOperationContext.Create(
  const ACompanyId, ABranchId, AUserId: Int64;
  const ACorrelationId: string): TOperationContext;
begin
  if ACompanyId <= 0 then
    raise EArgumentOutOfRangeException.Create('CompanyId');
  if ABranchId <= 0 then
    raise EArgumentOutOfRangeException.Create('BranchId');
  if AUserId <= 0 then
    raise EArgumentOutOfRangeException.Create('UserId');
  if ACorrelationId.Trim.IsEmpty then
    raise EArgumentException.Create('CorrelationId é obrigatório.');

  Result.FCompanyId := ACompanyId;
  Result.FBranchId := ABranchId;
  Result.FUserId := AUserId;
  Result.FCorrelationId := ACorrelationId;
end;

end.

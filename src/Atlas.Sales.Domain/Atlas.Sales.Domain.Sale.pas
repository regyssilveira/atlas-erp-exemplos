unit Atlas.Sales.Domain.Sale;

interface

uses
  System.SysUtils;

type
  TSaleStatus = (ssOpen, ssFinalized);

  TSale = class
  private
    FId: Int64;
    FCompanyId: Int64;
    FBranchId: Int64;
    FItemCount: Integer;
    FStatus: TSaleStatus;
  public
    constructor Create(const AId, ACompanyId, ABranchId: Int64;
      const AItemCount: Integer);
    procedure Finalize;
    property Id: Int64 read FId;
    property CompanyId: Int64 read FCompanyId;
    property BranchId: Int64 read FBranchId;
    property ItemCount: Integer read FItemCount;
    property Status: TSaleStatus read FStatus;
  end;

implementation

constructor TSale.Create(const AId, ACompanyId, ABranchId: Int64;
  const AItemCount: Integer);
begin
  inherited Create;
  if AId <= 0 then
    raise EArgumentOutOfRangeException.Create('Id');
  if ACompanyId <= 0 then
    raise EArgumentOutOfRangeException.Create('CompanyId');
  if ABranchId <= 0 then
    raise EArgumentOutOfRangeException.Create('BranchId');
  if AItemCount < 0 then
    raise EArgumentOutOfRangeException.Create('ItemCount');

  FId := AId;
  FCompanyId := ACompanyId;
  FBranchId := ABranchId;
  FItemCount := AItemCount;
  FStatus := ssOpen;
end;

procedure TSale.Finalize;
begin
  if FStatus <> ssOpen then
    raise EInvalidOpException.Create('Somente vendas abertas podem ser finalizadas.');
  if FItemCount = 0 then
    raise EInvalidOpException.Create('A venda precisa possuir itens.');
  FStatus := ssFinalized;
end;

end.

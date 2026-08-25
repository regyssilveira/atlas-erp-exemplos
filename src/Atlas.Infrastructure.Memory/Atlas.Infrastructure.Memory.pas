unit Atlas.Infrastructure.Memory;

interface

uses
  System.SysUtils,
  Atlas.Sales.Domain.Sale,
  Atlas.Sales.Contracts;

type
  TInMemorySaleRepository = class(TInterfacedObject, ISaleRepository)
  private
    FSale: TSale;
  public
    constructor Create(const ASale: TSale);
    destructor Destroy; override;
    function FindById(const ASaleId, ACompanyId, ABranchId: Int64): TSale;
    procedure Save(const ASale: TSale);
  end;

  TNoOpUnitOfWork = class(TInterfacedObject, IUnitOfWork)
  private
    FActive: Boolean;
  public
    procedure BeginWork;
    procedure Commit;
    procedure Rollback;
  end;

implementation

constructor TInMemorySaleRepository.Create(const ASale: TSale);
begin
  inherited Create;
  if not Assigned(ASale) then
    raise EArgumentNilException.Create('ASale');
  FSale := ASale;
end;

destructor TInMemorySaleRepository.Destroy;
begin
  FSale.Free;
  inherited;
end;

function TInMemorySaleRepository.FindById(
  const ASaleId, ACompanyId, ABranchId: Int64): TSale;
begin
  if (FSale.Id = ASaleId) and (FSale.CompanyId = ACompanyId) and
     (FSale.BranchId = ABranchId) then
    Result := FSale
  else
    Result := nil;
end;

procedure TInMemorySaleRepository.Save(const ASale: TSale);
begin
  if ASale <> FSale then
    raise EInvalidOpException.Create('O repositório não conhece esta venda.');
end;

procedure TNoOpUnitOfWork.BeginWork;
begin
  if FActive then
    raise EInvalidOpException.Create('Já existe uma unidade de trabalho ativa.');
  FActive := True;
end;

procedure TNoOpUnitOfWork.Commit;
begin
  if not FActive then
    raise EInvalidOpException.Create('Não existe uma unidade de trabalho ativa.');
  FActive := False;
end;

procedure TNoOpUnitOfWork.Rollback;
begin
  FActive := False;
end;

end.

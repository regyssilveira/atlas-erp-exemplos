unit Atlas.Sales.Contracts;

interface

uses
  Atlas.Sales.Domain.Sale;

type
  ISaleRepository = interface
    ['{51405C46-E983-4AD9-A132-9F85291BD199}']
    function FindById(const ASaleId, ACompanyId, ABranchId: Int64): TSale;
    procedure Save(const ASale: TSale);
  end;

  IUnitOfWork = interface
    ['{45E473DD-1328-4B65-8913-AD6BC1F72098}']
    procedure BeginWork;
    procedure Commit;
    procedure Rollback;
  end;

  IStockReservation = interface
    ['{B858116A-DC2E-426A-86EC-1076F0E85B73}']
    function TryReserveForSale(const ASaleId, ACompanyId, ABranchId: Int64;
      const AItemCount: Integer; out AReason: string): Boolean;
  end;

implementation

end.

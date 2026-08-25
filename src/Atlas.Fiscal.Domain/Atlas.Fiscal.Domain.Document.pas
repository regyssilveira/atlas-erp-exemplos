unit Atlas.Fiscal.Domain.Document;

interface

uses
  System.SysUtils;

type
  TFiscalDocumentStatus = (fdsDraft, fdsQueued, fdsTransmitting,
    fdsResultUnknown, fdsAuthorized, fdsRejected);

  TFiscalDocument = class
  private
    FStatus: TFiscalDocumentStatus;
    FAccessKey: string;
    FProtocol: string;
    FReason: string;
  public
    constructor Create(const AAccessKey: string);
    procedure Queue;
    procedure StartTransmission;
    procedure MarkResultUnknown;
    procedure ConfirmAuthorization(const AProtocol: string);
    procedure ConfirmRejection(const AReason: string);
    property Status: TFiscalDocumentStatus read FStatus;
    property AccessKey: string read FAccessKey;
    property Protocol: string read FProtocol;
    property Reason: string read FReason;
  end;

implementation

constructor TFiscalDocument.Create(const AAccessKey: string);
begin
  inherited Create;
  if AAccessKey.Trim.IsEmpty then
    raise EArgumentException.Create('AccessKey é obrigatória.');
  FAccessKey := AAccessKey;
  FStatus := fdsDraft;
end;

procedure TFiscalDocument.Queue;
begin
  if FStatus <> fdsDraft then
    raise EInvalidOpException.Create('Somente documento em rascunho pode ser enfileirado.');
  FStatus := fdsQueued;
end;

procedure TFiscalDocument.StartTransmission;
begin
  if FStatus <> fdsQueued then
    raise EInvalidOpException.Create('Somente documento enfileirado pode ser transmitido.');
  FStatus := fdsTransmitting;
end;

procedure TFiscalDocument.MarkResultUnknown;
begin
  if FStatus <> fdsTransmitting then
    raise EInvalidOpException.Create('Resultado desconhecido exige transmissão em andamento.');
  FStatus := fdsResultUnknown;
end;

procedure TFiscalDocument.ConfirmAuthorization(const AProtocol: string);
begin
  if not (FStatus in [fdsTransmitting, fdsResultUnknown]) then
    raise EInvalidOpException.Create('O documento não aguarda resultado de autorização.');
  if AProtocol.Trim.IsEmpty then
    raise EArgumentException.Create('Protocol é obrigatório.');
  FProtocol := AProtocol;
  FStatus := fdsAuthorized;
end;

procedure TFiscalDocument.ConfirmRejection(const AReason: string);
begin
  if not (FStatus in [fdsTransmitting, fdsResultUnknown]) then
    raise EInvalidOpException.Create('O documento não aguarda resultado.');
  if AReason.Trim.IsEmpty then
    raise EArgumentException.Create('Reason é obrigatório.');
  FReason := AReason;
  FStatus := fdsRejected;
end;

end.

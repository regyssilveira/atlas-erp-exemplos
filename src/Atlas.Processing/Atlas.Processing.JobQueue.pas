unit Atlas.Processing.JobQueue;

interface

uses
  System.SysUtils,
  System.Generics.Collections;

type
  TJobState = (jsPending, jsProcessing, jsWaitingRetry, jsSucceeded,
    jsDeadLetter);

  TJob = class
  private
    FId: string;
    FPayload: string;
    FState: TJobState;
    FAttempts: Integer;
    FMaxAttempts: Integer;
    FLastError: string;
  public
    constructor Create(const AId, APayload: string; const AMaxAttempts: Integer);
    procedure Start;
    procedure Complete;
    procedure Fail(const AError: string);
    property Id: string read FId;
    property Payload: string read FPayload;
    property State: TJobState read FState;
    property Attempts: Integer read FAttempts;
    property LastError: string read FLastError;
  end;

  TJobQueue = class
  private
    FJobs: TObjectDictionary<string, TJob>;
  public
    constructor Create;
    destructor Destroy; override;
    function Enqueue(const AId, APayload: string;
      const AMaxAttempts: Integer): TJob;
    function Find(const AId: string): TJob;
  end;

implementation

constructor TJob.Create(const AId, APayload: string;
  const AMaxAttempts: Integer);
begin
  inherited Create;
  if (AId = '') or (AMaxAttempts < 1) then
    raise EArgumentException.Create('Job exige identidade e tentativas válidas.');
  FId := AId;
  FPayload := APayload;
  FMaxAttempts := AMaxAttempts;
  FState := jsPending;
end;

procedure TJob.Start;
begin
  if not (FState in [jsPending, jsWaitingRetry]) then
    raise EInvalidOpException.Create('Job não está disponível para execução.');
  Inc(FAttempts);
  FState := jsProcessing;
end;

procedure TJob.Complete;
begin
  if FState <> jsProcessing then
    raise EInvalidOpException.Create('Somente job em execução pode concluir.');
  FState := jsSucceeded;
end;

procedure TJob.Fail(const AError: string);
begin
  if FState <> jsProcessing then
    raise EInvalidOpException.Create('Somente job em execução pode falhar.');
  FLastError := AError;
  if FAttempts >= FMaxAttempts then
    FState := jsDeadLetter
  else
    FState := jsWaitingRetry;
end;

constructor TJobQueue.Create;
begin
  inherited Create;
  FJobs := TObjectDictionary<string, TJob>.Create([doOwnsValues]);
end;

destructor TJobQueue.Destroy;
begin
  FJobs.Free;
  inherited;
end;

function TJobQueue.Enqueue(const AId, APayload: string;
  const AMaxAttempts: Integer): TJob;
begin
  if FJobs.TryGetValue(AId, Result) then
    Exit;
  Result := TJob.Create(AId, APayload, AMaxAttempts);
  FJobs.Add(AId, Result);
end;

function TJobQueue.Find(const AId: string): TJob;
begin
  if not FJobs.TryGetValue(AId, Result) then
    Result := nil;
end;

end.

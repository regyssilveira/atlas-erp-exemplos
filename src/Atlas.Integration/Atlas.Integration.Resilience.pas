unit Atlas.Integration.Resilience;

interface

uses
  System.SysUtils;

type
  TIntegrationFailureKind = (ifNone, ifTransient, ifPermanent,
    ifResultUnknown);
  TCircuitState = (csClosed, csOpen, csHalfOpen);

  TIntegrationResult = record
    Success: Boolean;
    FailureKind: TIntegrationFailureKind;
    Detail: string;
    class function Accepted(const ADetail: string): TIntegrationResult; static;
    class function Failed(const AKind: TIntegrationFailureKind;
      const ADetail: string): TIntegrationResult; static;
  end;

  TRetryPolicy = record
  private
    FMaxAttempts: Integer;
  public
    class function Create(const AMaxAttempts: Integer): TRetryPolicy; static;
    function ShouldRetry(const AAttempt: Integer;
      const AResult: TIntegrationResult): Boolean;
  end;

  TCircuitBreaker = class
  private
    FFailureThreshold: Integer;
    FConsecutiveFailures: Integer;
    FState: TCircuitState;
  public
    constructor Create(const AFailureThreshold: Integer);
    function CanExecute: Boolean;
    procedure RecordResult(const AResult: TIntegrationResult);
    procedure AllowProbe;
    property State: TCircuitState read FState;
  end;

implementation

class function TIntegrationResult.Accepted(
  const ADetail: string): TIntegrationResult;
begin
  Result.Success := True;
  Result.FailureKind := ifNone;
  Result.Detail := ADetail;
end;

class function TIntegrationResult.Failed(const AKind: TIntegrationFailureKind;
  const ADetail: string): TIntegrationResult;
begin
  Result.Success := False;
  Result.FailureKind := AKind;
  Result.Detail := ADetail;
end;

class function TRetryPolicy.Create(const AMaxAttempts: Integer): TRetryPolicy;
begin
  if AMaxAttempts < 1 then
    raise EArgumentOutOfRangeException.Create('MaxAttempts deve ser positivo.');
  Result.FMaxAttempts := AMaxAttempts;
end;

function TRetryPolicy.ShouldRetry(const AAttempt: Integer;
  const AResult: TIntegrationResult): Boolean;
begin
  Result := (AAttempt < FMaxAttempts) and
    (AResult.FailureKind = ifTransient);
end;

constructor TCircuitBreaker.Create(const AFailureThreshold: Integer);
begin
  inherited Create;
  if AFailureThreshold < 1 then
    raise EArgumentOutOfRangeException.Create(
      'FailureThreshold deve ser positivo.');
  FFailureThreshold := AFailureThreshold;
  FState := csClosed;
end;

function TCircuitBreaker.CanExecute: Boolean;
begin
  Result := FState <> csOpen;
end;

procedure TCircuitBreaker.RecordResult(const AResult: TIntegrationResult);
begin
  if AResult.Success then
  begin
    FConsecutiveFailures := 0;
    FState := csClosed;
    Exit;
  end;

  if AResult.FailureKind <> ifTransient then
    Exit;

  Inc(FConsecutiveFailures);
  if FConsecutiveFailures >= FFailureThreshold then
    FState := csOpen;
end;

procedure TCircuitBreaker.AllowProbe;
begin
  if FState = csOpen then
    FState := csHalfOpen;
end;

end.

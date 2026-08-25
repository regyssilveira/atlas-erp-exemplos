unit Atlas.Architecture.DependencyRules;

interface

uses
  System.SysUtils;

type
  TLayer = (lyDomain, lyApplication, lyInfrastructure, lyHost);

  TDependencyRules = record
    class function Allows(const AFromLayer, AToLayer: TLayer): Boolean; static;
  end;

implementation

class function TDependencyRules.Allows(const AFromLayer,
  AToLayer: TLayer): Boolean;
begin
  case AFromLayer of
    lyDomain:
      Result := AToLayer = lyDomain;
    lyApplication:
      Result := AToLayer in [lyDomain, lyApplication];
    lyInfrastructure:
      Result := AToLayer in [lyDomain, lyApplication, lyInfrastructure];
    lyHost:
      Result := True;
  else
    Result := False;
  end;
end;

end.

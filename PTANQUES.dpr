program PTANQUES;

uses
  SvcMgr,
  UTANQUES in 'UTANQUES.pas' {ogcvtanques: TService},
  CRCs in '..\IgasDispensarios\CRCs.pas',
  uLkJSON in '..\IgasDispensarios\uLkJSON.pas',
  IdHashMessageDigest in '..\IgasDispensarios\IdHashMessageDigest.pas',
  IdHash in '..\IgasDispensarios\IdHash.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(Togcvtanques, ogcvtanques);
  Application.Run;
end.

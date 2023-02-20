program PCLIENTE;

uses
  Forms,
  UCLIENTE in 'UCLIENTE.pas' {Form1},
  CRCs in '..\..\IgasDispensarios\CRCs.pas',
  OG_Hasp in '..\..\IgasDispensarios\OG_Hasp.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

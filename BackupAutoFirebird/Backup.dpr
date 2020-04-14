program Backup;

uses
  Forms,
  Un_Principal in 'Un_Principal.pas' {F_Principal};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Backup';
  Application.CreateForm(TF_Principal, F_Principal);
  Application.Run;
end.

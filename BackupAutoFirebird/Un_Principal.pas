unit Un_Principal;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Spin, IniFiles, Buttons, Mask,
  AppEvnts, Registry, IBServices, JvToolEdit, JvExMask, JvComponentBase, JvTrayIcon;

type
  TF_Principal = class(TForm)
    GroupBox1: TGroupBox;
    CheckBox1: TCheckBox;
    SpinEdit1: TSpinEdit;
    SpinEdit2: TSpinEdit;
    Label2: TLabel;
    Label1: TLabel;
    Timer: TTimer;
    SpinEdit3: TSpinEdit;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    ApplicationEvents: TApplicationEvents;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    LbCopia: TLabel;
    IBBackupService: TIBBackupService;
    JvDirectoryEdit: TJvDirectoryEdit;
    JvFilenameEdit: TJvFilenameEdit;
    JvTrayIcon: TJvTrayIcon;
    Label7: TLabel;
    procedure TimerTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure RxTrayIcon1DblClick(Sender: TObject);
    procedure ApplicationEventsMinimize(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
  private
    { Private declarations }
    _data : TDateTime;
    vCopias, vHora , vMinu : Integer;
    vIP, vPort : String;
    vOrigem, vDestino : String;
    vUsuario, vSenha : String;
    vAuto : Boolean;
    procedure GravaRegistro(Raiz: HKEY; Chave, Valor, Endereco: string);
    procedure ApagaRegistro(Raiz: HKEY; Chave, Valor: string);
    procedure DoBackup;
    function CreateProcessSimple(cmd: string): boolean;
  public
    { Public declarations }
  end;

var
  F_Principal: TF_Principal;
  H : THandle;

implementation

{$R *.dfm}

procedure TF_Principal.TimerTimer(Sender: TObject);
var
   Present: TDateTime;
   Hour, Min, Sec, MSec: Word;
begin
   Present:= Now;
   DecodeTime(Present, Hour, Min, Sec, MSec);

   // ta na hora, executar backup
   if ( Hour = vHora ) and ( Min = vMinu ) and (_data <> date) then
   begin
      _data := date;
      DoBackup;
   end;
end;

procedure TF_Principal.FormCreate(Sender: TObject);
var
   IniFile : TIniFile;
begin
   IniFile:= TIniFile.Create ( ExtractFilePath(ParamStr(0)) + 'CONFIG.ini' );
   vHora   := IniFile.ReadInteger ('Sistema' , 'Hora'  , SpinEdit1.Value );
   vMinu   := IniFile.ReadInteger ('Sistema' , 'Minu'  , SpinEdit2.Value );
   vCopias := IniFile.ReadInteger ('Sistema' , 'Copias', SpinEdit2.Value );
   vAuto   := IniFile.ReadBool    ('Sistema' , 'Auto'  , CheckBox1.Checked );
   vOrigem := IniFile.ReadString  ('Sistema' , 'Origem', '');
   vDestino:= IniFile.ReadString  ('Sistema' , 'Destino','');
   vIP     := IniFile.ReadString  ('Sistema' , 'Servidor','127.0.0.1');
   vPort   := IniFile.ReadString  ('Sistema' , 'Porta'   ,'3050');
   vUsuario:= IniFile.ReadString  ('Sistema' , 'Usuario','SYSDBA');
   vSenha  := IniFile.ReadString  ('Sistema' , 'Senha'  ,'masterkey');

   IniFile.Destroy;
   SpinEdit1.Value      := vHora;
   SpinEdit2.Value      := vMinu;
   SpinEdit3.Value      := vCopias;
   CheckBox1.Checked    := vAuto;
   JvFilenameEdit.Text  := vOrigem;
   JvDirectoryEdit.Text := vDestino;

   Timer.Enabled        := vAuto;

   _data := date - 1;
end;

procedure TF_Principal.GravaRegistro(Raiz: HKEY; Chave, Valor, Endereco: string);
var Registro: TRegistry;
begin
  Registro := TRegistry.Create(KEY_WRITE); // Chama o construtor do objeto
  Registro.RootKey := Raiz;
  Registro.OpenKey(Chave, True); //Cria a chave
  Registro.WriteString(Valor, '"' + Endereco + '"'); //Grava o endereço da sua aplicação no Registro
  Registro.CloseKey; // Fecha a chave e o objeto
  Registro.Free;
end;

procedure TF_Principal.RxTrayIcon1DblClick(Sender: TObject);
begin
   show; {Mostra o form}
   WindowState := wsNormal;
   H := FindWindow(nil,'Backup'); { acha o ponteiro da aplicação no sistema}
   ShowWindow(h,SW_RESTORE); { mostra aplicação na barra de tarefas}
   JvTrayIcon.Active := false; {oculta ícone do tray icon}
end;

procedure TF_Principal.ApagaRegistro(Raiz: HKEY; Chave, Valor: string);
var  Registro: TRegistry;
begin
  Registro := TRegistry.Create(KEY_WRITE); // Chama o construtor do objeto
  Registro.RootKey := Raiz;
  Registro.OpenKey(Chave, True); //Cria a chave
  Registro.DeleteValue(Valor); //Grava o endereço da sua aplicação no Registro
  Registro.CloseKey; // Fecha a chave e o objeto
  Registro.Free;
end;

procedure TF_Principal.ApplicationEventsMinimize(Sender: TObject);
begin
   h := FindWindow(nil,'Backup'); { acha o ponteiro da aplicação no sistema}
   ShowWindow(h,SW_HIDE); { esconde a aplicação da barra de tarefas}
   JvTrayIcon.Active := true; { coloca ícone no tray icon}
   hide; { esconde o form }
end;

procedure TF_Principal.DoBackup;
var
   _ii : Integer;
begin
   LbCopia.Visible := True;
   Application.ProcessMessages;
   {
   DeleteFile(DirectoryEdit1.Text +'\logbkp.bak');
   CreateProcessSimple('gbak -user '+vUsuario+' -password '+vSenha+' -v -y '+ DirectoryEdit1.Text +'\logbkp.bak ' +
                          vIP+'/'+vPort+':'+FilenameEdit1.Text +' '+ DirectoryEdit1.Text +'\backup.bak');
   }
   IBBackupService.Active := False;
   IBBackupService.BackupFile.Clear;
   IBBackupService.Params.Clear;
   IBBackupService.Params.Add('user_name='+vUsuario);
   IBBackupService.Params.Add('password='+vSenha);
   IBBackupService.BackupFile.Add(JvDirectoryEdit.Text+'\backup.bak');
   IBBackupService.ServerName  := vIP+'/'+vPort;
   IBBackupService.DatabaseName:= JvFilenameEdit.Text;
    IBBackupService.Attach;
   IBBackupService.ServiceStart;
   while not(IBBackupService.Eof) do begin
     IBBackupService.GetNextLine;
     Application.ProcessMessages;
   end;
   IBBackupService.Active := False;

   if FileExists(JvDirectoryEdit.Text +'\backup.bak') then
   begin // criou o arquivo - somente faz as mudanças se o backup foi criado
      DeleteFile(JvDirectoryEdit.Text +'\backup.b'+IntToStr( SpinEdit3.Value )); // exclui o backup mais antigo
      DeleteFile(JvDirectoryEdit.Text +'\logbkp.b'+IntToStr( SpinEdit3.Value ));
      for _ii := SpinEdit3.Value -1 downto 1 do
      begin
         RenameFile(JvDirectoryEdit.Text +'\backup.b'+IntToStr(_ii), JvDirectoryEdit.Text +'\backup.b'+IntToStr(_ii+1));
         RenameFile(JvDirectoryEdit.Text +'\logbkp.b'+IntToStr(_ii), JvDirectoryEdit.Text +'\logbkp.b'+IntToStr(_ii+1));
      end;
      RenameFile(JvDirectoryEdit.Text +'\backup.bak', JvDirectoryEdit.Text +'\backup.b1');
      RenameFile(JvDirectoryEdit.Text +'\logbkp.bak', JvDirectoryEdit.Text +'\logbkp.b1');
   end;
   LbCopia.Visible := False;
end;

procedure TF_Principal.BitBtn2Click(Sender: TObject);
var
   IniFile : TIniFile;
begin
   vHora   := SpinEdit1.Value;
   vMinu   := SpinEdit2.Value;
   vCopias := SpinEdit3.Value;
   vAuto   := CheckBox1.Checked;
   vOrigem := JvFilenameEdit.Text;
   vDestino:= JvDirectoryEdit.Text;
   IniFile:= TIniFile.Create ( ExtractFilePath(ParamStr(0)) + 'CONFIG.ini' );
   IniFile.WriteInteger ('Sistema' , 'Hora'  , SpinEdit1.Value );
   IniFile.WriteInteger ('Sistema' , 'Minu'  , SpinEdit2.Value );
   IniFile.WriteInteger ('Sistema' , 'Copias', SpinEdit3.Value );
   IniFile.WriteBool    ('Sistema' , 'Auto'  , CheckBox1.Checked );
   IniFile.WriteString  ('Sistema' , 'Origem', JvFilenameEdit.Text);
   IniFile.WriteString  ('Sistema' , 'Destino',JvDirectoryEdit.Text);
   IniFile.Destroy;
   Timer.Enabled := True;

    h := FindWindow(nil,'Backup'); { acha o ponteiro da aplicação no sistema}
    ShowWindow(h,SW_HIDE); { esconde a aplicação da barra de tarefas}
    JvTrayIcon.Active := true; { coloca ícone no tray icon}
    hide; { esconde o form }
end;

procedure TF_Principal.CheckBox1Click(Sender: TObject);
begin
  if TCheckBox(Sender).Checked then begin
    GravaRegistro(HKEY_LOCAL_MACHINE, '\Software\Microsoft\Windows\CurrentVersion\Run',
      'IniciarPrograma', ExtractFilePath(Application.ExeName) + ExtractFileName(Application.ExeName));
  end
  else begin
    ApagaRegistro(HKEY_LOCAL_MACHINE, '\Software\Microsoft\Windows\CurrentVersion\Run',
      'IniciarPrograma');
  end;
end;

function TF_Principal.CreateProcessSimple(cmd: string): boolean;
var
  SUInfo: TStartupInfo;
  ProcInfo: TProcessInformation;
begin
  FillChar(SUInfo, SizeOf(SUInfo), #0);
  SUInfo.cb      := SizeOf(SUInfo);
  SUInfo.dwFlags := STARTF_USESHOWWINDOW;
  SUInfo.wShowWindow := SW_HIDE;

  Result := CreateProcess(nil,
                          PChar(cmd),
                          nil,
                          nil,
                          false,
                          CREATE_NEW_CONSOLE or
                          NORMAL_PRIORITY_CLASS,
                          nil,
                          nil,
                          SUInfo,
                          ProcInfo);

  if (Result) then
  begin
    WaitForSingleObject(ProcInfo.hProcess, INFINITE);

    CloseHandle(ProcInfo.hProcess);
    CloseHandle(ProcInfo.hThread);
  end;
end;

procedure TF_Principal.BitBtn1Click(Sender: TObject);
begin
   DoBackup;
end;

end.

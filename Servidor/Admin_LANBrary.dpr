program Admin_LANBrary;
{$APPTYPE GUI}
uses
  System.StartUpCopy,
  FMX.Forms,
  FMX.Skia,
  System.SysUtils,
  FMX.DialogService,
  System.UITypes,
  Web.WebReq,
  Winapi.Windows,
  IdHTTPWebBrokerBridge,
  UMain in 'UMain.pas' {frmMain},
  UMainFormEvents in 'Unidades\UMainFormEvents.pas',
  Estilos in 'Unidades\Estilos.pas',
  UAcciones_Inicio in 'Unidades\UAcciones_Inicio.pas',
  Generales in 'Unidades\Generales.pas',
  UAcciones_Pantallas in 'Unidades\UAcciones_Pantallas.pas',
  DBActions in 'Unidades\CapaDeDatos\DBActions.pas',
  uJSONTool in 'Unidades\uJSONTool.pas',
  UWebServer in 'Unidades\UWebServer.pas' {WebServer: TWebModule},
  UScripts in 'Unidades\CapaDeDatos\UScripts.pas' {Scripts: TDataModule},
  ECategoria in 'Unidades\Entidades\ECategoria.pas',
  ELibro in 'Unidades\Entidades\ELibro.pas',
  EUsuario in 'Unidades\Entidades\EUsuario.pas',
  DBActions_WS in 'Unidades\CapaDeDatos\DBActions_WS.pas',
  UAcciones_Usuarios in 'Unidades\UAcciones_Usuarios.pas',
  UAcciones_Configuraciones in 'Unidades\UAcciones_Configuraciones.pas',
  PasswordHashing in 'Unidades\PasswordHashing.pas';

{$R *.res}
var
  Mutex: Cardinal;
begin
  //ReportMemoryLeaksOnShutdown:= True;
  GlobalUseSkia := True;
  Mutex:= CreateMutex(nil, False, 'LANBrary');
  if GetLastError = ERROR_ALREADY_EXISTS then
  begin
    TDialogService.MessageDialog('Una instancia del panel de administración de ' +
    'LANBrary ya se está ejecutando.', TMsgDlgType.mtError,
    [TMsgDlgBtn.mbOK], TMsgDlgBtn.mbOK, 0, nil);
    Exit;
  end;

  if WebRequestHandler <> nil then
    WebRequestHandler.WebModuleClass := WebModuleClass;

  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TScripts, Scripts);
  Application.Run;
  CloseHandle(Mutex);
end.

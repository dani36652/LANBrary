unit UAcciones_Configuraciones;

interface
uses
  {$IFDEF ANDROID}
  Androidapi.JNI.Webkit, FMX.VirtualKeyboard,
  Androidapi.JNI.Print, Androidapi.JNI.Util,
  fmx.Platform.Android,
  Androidapi.jni,fmx.helpers.android, Androidapi.Jni.app,
  Androidapi.Jni.GraphicsContentViewText, Androidapi.JniBridge,
  Androidapi.JNI.Os, Androidapi.Jni.Telephony,
  Androidapi.JNI.JavaTypes,Androidapi.Helpers,
  Androidapi.JNI.Widget,System.Permissions,
  Androidapi.Jni.Provider,Androidapi.Jni.Net,
  fmx.TextLayout,AndroidAPI.JNI.Support,
 {$ENDIF}
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.TabControl,
  FMX.MediaLibrary, FMX.Objects, FMX.DialogService,
  FMX.Layouts, FMX.Controls.Presentation, FMX.Edit, FMX.StdCtrls;

type TAcciones_Configuraciones = class
  private
  public
    class procedure btnAtras_ConfiguracionesClick(Sender: TObject);
    class procedure CamposChangeTracking(Sender: TObject);
    class procedure btnGuardar_ConfiguracionesClick(Sender: TObject);
    class procedure edtURLServidor_ConfiguracionesKeyDown(Sender: TObject;
    var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
    class procedure edtPuertoServidor_ConfiguracionesKeyDown(Sender: TObject;
    var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
    class function LoadSettings: Boolean;
end;

implementation
uses
  Generales, UMain;

{ TAcciones_Configuraciones }

class procedure TAcciones_Configuraciones.btnAtras_ConfiguracionesClick(
  Sender: TObject);
begin
  frmMain.Pantallas.ActiveTab:= frmMain.Login;
  LoadSettings;
end;

class procedure TAcciones_Configuraciones.btnGuardar_ConfiguracionesClick(
  Sender: TObject);
var
  Mensaje: string;
  {$IFDEF ANDROID}
  Toast: JToast;
  {$ENDIF}
  StrURL: string;
begin
  Mensaje:= 'Se guardaron las configuraciones';

  StrURL:= frmMain.edtURLServidor_Configuraciones.Text.Trim;

  if (StrURL.EndsWith('/')) or (StrURL.EndsWith('\')) then
  begin
    StrURL:= StrURL.Remove(Length(StrURL));
    frmMain.edtURLServidor_Configuraciones.Text:= StrURL;
  end;

  EscribirConfigIni('SERVIDOR', 'URL', frmMain.edtURLServidor_Configuraciones.Text.Trim);
  EscribirConfigIni('SERVIDOR', 'PUERTO', frmMain.edtPuertoServidor_Configuraciones.Text.Trim);

  if (not frmMain.edtURLServidor_Configuraciones.Text.Trim.IsEmpty) and
  (not frmMain.edtPuertoServidor_Configuraciones.Text.Trim.IsEmpty) then
  begin
    URLServidor:= frmMain.edtURLServidor_Configuraciones.Text.Trim + ':' +
    frmMain.edtPuertoServidor_Configuraciones.Text.Trim;
  end else  URLServidor:= frmMain.edtURLServidor_Configuraciones.Text.Trim;

  REST.URL:= URLServidor;

  frmMain.Pantallas.ActiveTab:= frmMain.Login;
  {$IFDEF ANDROID}
  Toast:= TJToast.JavaClass.makeText(TAndroidHelper.Context,
  StrToJCharSequence(Mensaje), TJToast.JavaClass.LENGTH_SHORT);
  Toast.setGravity(TJGravity.JavaClass.CENTER, 0, 0);
  Toast.show;
  {$ENDIF}
  {$IFDEF MSWINDOWS}
  TDialogService.MessageDialog(Mensaje, TMsgDlgType.mtInformation,
  [TMsgDlgBtn.mbOK], TMsgDlgBtn.mbOK, 0, nil);
  {$ENDIF}
end;

class procedure TAcciones_Configuraciones.CamposChangeTracking(Sender: TObject);
begin
  frmMain.btnGuardar_Configuraciones.Enabled:=
  not frmMain.edtURLServidor_Configuraciones.Text.Trim.EndsWith('/') and
  not frmMain.edtURLServidor_Configuraciones.Text.Trim.EndsWith('\') and
  not frmMain.edtURLServidor_Configuraciones.Text.Trim.IsEmpty      and
  (frmMain.edtURLServidor_Configuraciones.Text.Contains('http://')  or
   frmMain.edtURLServidor_Configuraciones.Text.Contains('https://'));
end;

class procedure TAcciones_Configuraciones.edtPuertoServidor_ConfiguracionesKeyDown(
  Sender: TObject; var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
begin
  if Key = vkReturn then
  begin
    if frmMain.btnGuardar_Configuraciones.Enabled then
      frmMain.btnGuardar_ConfiguracionesClick(frmMain.btnGuardar_Configuraciones);
  end;
end;

class procedure TAcciones_Configuraciones.edtURLServidor_ConfiguracionesKeyDown(
  Sender: TObject; var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
begin
  if Key = vkReturn then
    MostrarTeclado(frmMain.edtPuertoServidor_Configuraciones);
end;

class function TAcciones_Configuraciones.LoadSettings: Boolean;
var
  URLServer: string;
  PuertoServer: string;
begin
  URLServer:= LeerConfigIni('SERVIDOR', 'URL');
  PuertoServer:= LeerConfigIni('SERVIDOR', 'PUERTO');
  frmMain.edtURLServidor_Configuraciones.Text:= URLServer;
  frmMain.edtPuertoServidor_Configuraciones.Text:= PuertoServer;

  if (not URLServer.Trim.IsEmpty) and (not PuertoServer.Trim.IsEmpty) then
    URLServidor:= URLServer + ':' + PuertoServer
  else
    URLServidor:= URLServer;

  REST.URL:= URLServidor;
  Result:= not URLServer.Trim.IsEmpty;
end;

end.

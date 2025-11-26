unit Generales;

interface

uses
  {$IFDEF ANDROID}
  Androidapi.JNI.Webkit, FMX.VirtualKeyboard,
  Androidapi.JNI.Print, Androidapi.JNI.Util,
  fmx.Platform.Android, Androidapi.Jni.Embarcadero,
  Androidapi.jni,fmx.helpers.android, Androidapi.Jni.app,
  Androidapi.Jni.GraphicsContentViewText, Androidapi.JniBridge,
  Androidapi.JNI.Os, Androidapi.Jni.Telephony,
  Androidapi.JNI.JavaTypes,Androidapi.Helpers,
  Androidapi.JNI.Widget,System.Permissions,
  FMX.DialogService,Androidapi.Jni.Provider,Androidapi.Jni.Net,
  fmx.TextLayout,AndroidAPI.JNI.Support, FMX.AddressBook.Android,
 {$ENDIF}
 System.Classes, FMX.Forms, FMX.Platform, System.Messaging, FMX.Objects, FMX.SKIA,
 FMX.Graphics,
 System.UIConsts, System.UITypes, FMX.Types, System.SyncObjs,
 IdGlobal, {$IFDEF MSWINDOWS} WinApi.Windows, Winapi.ShellApi, {$ENDIF} IdHTTP, System.NetEncoding,
 System.Types, System.StrUtils, FMX.Dialogs, IdStack, System.Hash,
 System.SysUtils;

procedure Sincronizar(const AProc:TProc);
procedure Encolar(const AProc: TProc);
procedure EscribirLog(const Mensaje: string; const Nivel: Integer = 1); //1 = Operaciones 2 = Excepciones
function GetLocalIPAddress: string;
procedure EscribirConfigIni(const Seccion, Identificador, Valor: string);
function LeerConfigIni(const Seccion, Identificador: string): string;
function FileToBase64String(const aFileName: string): string;
function MemoryStreamToBase64String(const aStream: TMemoryStream): string;
function Base64StringToMemoryStream(const Base64String: string): TMemoryStream;
procedure MostrarTeclado(const Control: TFmxObject);
{$IFDEF ANDROID}
procedure GoToAppPermissionsSettings;
function GetExternalStorageRoot: string;
{$ENDIF}
procedure ShowLoadingDialog;
procedure HideLoadingDialog;
procedure MessageDlg(const Title, Msg: string);
procedure SeccionCritica(const AProc: TProc);
function Base64ToBitmap(const Base64String: string): FMX.Graphics.TBitmap;
function StreamToBase64String(const Stream: TMemoryStream): string;
function EliminarArchivo(const AFileName: string; var Respuesta: string): Boolean;
{$IFDEF MSWINDOWS}
function getPDFThumbnail(FileName: string; aWidth,
aHeight: Single): TMemoryStream; external 'miniaturaPDF.dll' name 'getPDFThumbnail';
{$ENDIF}
{$IFDEF ANDROID}
function getPDFThumbnail(const AFileName: string; const aWidth,
aHeight: Integer): TMemoryStream;
{$ENDIF}
procedure UsuarioBloqueado;
procedure AbrirPDF(const AFileName: string);

type TGeneral_Actions = class
  private
  public
    class procedure BtnOkMsgDlgUsr_BloqueadoClick(Sender: TObject);
end;

implementation
uses
  System.IniFiles, FMX.TabControl, FMX.StdCtrls, FMX.Edit,
  FMX.Memo, System.IOUtils, System.DateUtils, UMain;

procedure Sincronizar(const AProc:TProc);
begin
  if CurrentThreadId <> MainThreadID then
  begin
    {$IFDEF ANDROID}
    CallInUIThreadAndWaitFinishing(
    procedure
    begin
      AProc;
    end);
    {$ENDIF}

    {$IFDEF MSWINDOWS}
    TThread.Synchronize(nil,
    procedure
    begin
      AProc;
    end);
    {$ENDIF}
  end else AProc;
end;

procedure Encolar(const AProc: TProc);
begin
  if CurrentThreadId <> MainThreadID then
  begin
    {$IFDEF ANDROID}
    CallInUIThread(
    procedure
    begin
      AProc;
    end);
    {$ENDIF}

    {$IFDEF MSWINDOWS}
    TThread.Synchronize(nil,
    procedure
    begin
      AProc;
    end);
    {$ENDIF}
  end else AProc;
end;

procedure EscribirLog(const Mensaje: string; const Nivel: Integer);
begin
  (*
    Con esto se evita el error IO32 por el acceso múltiple
    a este método.
  *)
  //1 = Operaciones 2 = Excepciones 3 = Error de conexión
  SeccionCritica(
  procedure
  var
    F: TextFile;
    FileName: string;
  begin
    try
      FileName:=
      {$IFDEF ANDROID}
      TPath.GetDocumentsPath
      {$ENDIF}
      {$IFDEF MSWINDOWS}
      ExtractFileDir(ParamStr(0))
      {$ENDIF} + PathDelim + 'Log.txt';

      AssignFile(F, FileName);
      if FileExists(FileName) then
        Append(F)
      else
        Rewrite(F);
      case Nivel of
        1: writeln(F, FormatDateTime('DD/MM/YYYY hh:nn ampm', Now) + ' - ' + Mensaje);
        2: writeln(F, FormatDateTime('DD/MM/YYYY hh:nn ampm', Now) + ' - Excepción: ' + Mensaje);
        3: Writeln(F, FormatDateTime('DD/MM/YYYY hh:nn ampm', Now) + ' - Error de conexión: ' + Mensaje);
      end;
      CloseFile(F);
    except
      CloseFile(F);
    end;
  end);
end;

function GetLocalIPAddress: string;
begin
  TIdStack.IncUsage;
  try
    try
      Result:= GStack.LocalAddress;
    except on E: exception do
      begin
        EscribirLog(E.ClassName + ': ' + E.Message, 2);
        Result:= string.Empty;
      end;
    end;
  finally
    TIdStack.DecUsage;
  end;
end;

procedure EscribirConfigIni(const Seccion, Identificador, Valor: string);
var
  IniFile: TIniFile;
  FileName: string;
begin
  FileName:=
  {$IFDEF ANDROID}
  TPath.GetDocumentsPath
  {$ENDIF}
  {$IFDEF MSWINDOWS}
  ExtractFileDir(ParamStr(0))
  {$ENDIF}
  + PathDelim + 'config.ini';
  IniFile:= TIniFile.Create(FileName);
  try
    try
      IniFile.WriteString(Seccion, Identificador, Valor);
      IniFile.UpdateFile;
    except on E: Exception do
      begin
        EscribirLog(E.ClassName + ': Error al inentar escribir en el archivo de configuración: ' +
        E.Message, 2);
      end;
    end;
  finally
    FreeAndNil(IniFile);
  end;
end;

function LeerConfigIni(const Seccion, Identificador: string): string;
var
  IniFile: TIniFile;
  FileName: string;
begin
  FileName:=
  {$IFDEF ANDROID}
  TPath.GetDocumentsPath
  {$ENDIF}
  {$IFDEF MSWINDOWS}
  ExtractFileDir(ParamStr(0))
  {$ENDIF}
  + PathDelim + 'config.ini';
  IniFile:= TIniFile.Create(FileName);
  try
    try
      Result:= IniFile.ReadString(Seccion, Identificador, '');
    except on E: Exception do
      begin
        EscribirLog(E.ClassName + ': Error al inentar leer en el archivo de configuración: ' +
        E.Message, 2);
        Result:= string.Empty;
      end;
    end;
  finally
    FreeAndNil(IniFile);
  end;
end;

function FileToBase64String(const aFileName: string): string;
var
  FileStream: TFileStream;
  Encoding: TNetEncoding;
  Buffer: TBytes;
begin
  {
    Función que convierte cualquier archivo a Base64
    pidiendo su ruta como parámetro
  }
  if not TFile.Exists(aFileName) then
    Exit(string.Empty);

  FileStream := TFileStream.Create(aFileName, fmOpenRead);
  Encoding := TNetEncoding.Base64;
  try
    try
      SetLength(Buffer, FileStream.Size);
      FileStream.ReadBuffer(Buffer[0], FileStream.Size);
      Result := Encoding.EncodeBytesToString(Buffer);
    except
      Result:= string.Empty;
    end;
  finally
    FreeAndNil(FileStream);
    SetLength(Buffer, 0); //Liberar en memoria (importante)
  end;
end;

function MemoryStreamToBase64String(const aStream: TMemoryStream): string;
var
  Encoding: TNetEncoding;
  Buffer: TBytes;
  FSize: Int64;
begin
  if not Assigned(aStream) then
    Exit(string.Empty);

  if aStream.Position <> 0 then
    aStream.Position:= 0; //Importante!

  FSize:= aStream.Size;

  if FSize > 0 then
  begin
    Encoding := TNetEncoding.Base64;
    try
      try
        SetLength(Buffer, FSize);
        aStream.ReadBuffer(Buffer[0], FSize);
        Result := Encoding.EncodeBytesToString(Buffer);
      except
        Result:= string.Empty;
      end;
    finally
      SetLength(Buffer, 0); //Liberar en memoria (importante)
    end;
  end else Result:= string.Empty;
end;

function StreamToBase64String(const Stream: TMemoryStream): string;
var
  Encoding: TNetEncoding;
  Buffer: TBytes;
  FSize: Int64;
begin
  if not Assigned(Stream) then
    Exit(string.Empty);

  if Stream.Position <> 0 then
    Stream.Position:= 0;

  FSize:= Stream.Size;
  if FSize > 0 then
  begin
    Encoding := TNetEncoding.Base64;
    try
      try
        SetLength(Buffer, FSize);
        Stream.ReadBuffer(Buffer[0], FSize);
        Result := Encoding.EncodeBytesToString(Buffer);
      except
        Result:= string.Empty;
      end;
    finally
      SetLength(Buffer, 0); //Liberar en memoria (importante)
    end;
  end else Result:= string.Empty;
end;

{$IFDEF ANDROID}
function getPDFThumbnail(const AFileName: string; const aWidth,
  aHeight: Integer): TMemoryStream;
var
  JavaFile: JFile;
  FileDescriptor: JParcelFileDescriptor;
  Renderer: JPdfRenderer;
  Page: JPdfRenderer_Page;
  JavaBitmap: JBitmap;
  Bitmap: TBitmap;
begin
  Result:= nil;

  JavaFile := TJFile.JavaClass.init(StringToJString(AFileName));
  FileDescriptor := TJParcelFileDescriptor.JavaClass.open(JavaFile,
  TJParcelFileDescriptor.JavaClass.MODE_READ_ONLY);
  Renderer := TJPdfRenderer.JavaClass.init(FileDescriptor);
  Page:= Renderer.openPage(0);
  JavaBitmap:= TJBitmap.JavaClass.createBitmap(aWidth,
  aHeight , TJBitmap_Config.JavaClass.ARGB_8888);
  Page.render(JavaBitmap, nil, nil,
  TJPdfRenderer_Page.JavaClass.RENDER_MODE_FOR_DISPLAY);
  try
    Bitmap:= TBitmap.Create;
    if JBitmapToBitmap(JavaBitmap, Bitmap) then
    begin
      Result:= TMemoryStream.Create;
      Bitmap.SaveToStream(Result);
      Result.Position:= 0;
    end;
  finally
    if Page <> nil then
      Page.close;

    if Renderer <> nil then
      Renderer.close;

    if FileDescriptor <> nil then
      FileDescriptor.close;

    if JavaBitmap <> nil then
      JavaBitmap.recycle;

    if Bitmap <> nil then
      FreeAndNil(Bitmap);
  end;
end;
{$ENDIF}

function EliminarArchivo(const AFileName: string; var Respuesta: string): Boolean;
begin
  Respuesta:= string.Empty;
  Result:= False;
  if TFile.Exists(AFileName) then
  begin
    try
      TFile.Delete(AFileName);
      Result:= True;
    except on E: Exception do
      begin
        EscribirLog('TAcciones_Descargas.EliminarLibro: ' + E.Message, 2);
        Respuesta:= E.ClassName + ': ' + E.Message;
      end;
    end;
  end
  else
    Respuesta:= 'El archivo especificado ya no existe en el almacenamiento.';
end;

function Base64StringToMemoryStream(const Base64String: string): TMemoryStream;
var
  Encoding: TNetEncoding;
  DecodedBytes: TBytes;
begin
  Result:= nil;

  {
    Esta función convierte una cadena en Base64 a un
    TMemoryStream
  }
  Encoding:= TNetEncoding.Base64;
  try
    try
      DecodedBytes:= Encoding.DecodeStringToBytes(Base64String);
      Result:= TMemoryStream.Create;
      Result.WriteBuffer(DecodedBytes[0], Length(DecodedBytes));
      Result.Position:= 0;
    except
    end;
  finally
    SetLength(DecodedBytes, 0);
  end;
end;

procedure MostrarTeclado(const Control: TFmxObject);
begin
  if Control.ClassType = TEdit then
  begin
    TEdit(Control).SetFocus;
    TEdit(Control).GoToTextEnd;
  end else

  if Control.ClassType = TMemo then
  begin
    TMemo(Control).SetFocus;
    TMemo(Control).GoToTextEnd;
  end;
end;

{$IFDEF ANDROID}
procedure GoToAppPermissionsSettings;
var
  Mensaje: string;
begin
  Mensaje:= 'Es necesaria la autorización de forma manual de los' +
  ' permisos requeridos. ¿Quiere hacerlo ahora mismo?';

  TDialogService.MessageDialog(Mensaje, TMsgDlgType.mtConfirmation,
  [TMsgDlgBtn.mbOK], TMsgDlgBtn.mbOK, 0,
  procedure(const AResult: TModalResult)
  var
    Intent: JIntent;
    Uri: Jnet_Uri;
  begin
    case AResult of
      mrOk:
      begin
        Uri := TJnet_Uri.JavaClass.fromParts(StringToJString('package'),
        TAndroidHelper.Context.getPackageName, nil);
        Intent := TJIntent.JavaClass.init(TJSettings.JavaClass.ACTION_APPLICATION_DETAILS_SETTINGS, Uri);
        Intent.addFlags(TJIntent.JavaClass.FLAG_ACTIVITY_NEW_TASK);
        TAndroidHelper.Context.startActivity(Intent);
      end;
    end;
  end);
end;

function GetExternalStorageRoot: string;
begin
  Result := JStringToString(
    TJEnvironment.JavaClass.getExternalStorageDirectory.getAbsolutePath);
end;
{$ENDIF}

procedure ShowLoadingDialog;
begin
  frmMain.IndicadorLoadingDlg.Animation.Enabled:= True;
  frmMain.LoadingDialog.Visible:= True;
  frmMain.LoadingDialog.BringToFront;
end;

procedure HideLoadingDialog;
begin
  frmMain.IndicadorLoadingDlg.Animation.Enabled:= False;
  frmMain.LoadingDialog.Visible:= False;
end;

procedure MessageDlg(const Title, Msg: string);
begin
  Encolar(
  procedure
  begin
    frmMain.TituloMessageDialog.Text:= Title.Trim.ToUpper;
    frmMain.MensajeMessageDialog.Text:= Msg;
    frmMain.MessageDialog.Visible:= True;
    frmMain.MessageDialog.BringToFront;
  end);
end;

procedure SeccionCritica(const AProc: TProc);
begin
  CriticalSection.Acquire;
  try
    if Assigned(AProc) then
      AProc;
  finally
    CriticalSection.Release;
  end;
end;

function Base64ToBitmap(const Base64String: string): FMX.Graphics.TBitmap;
var
  Buffer: TMemoryStream;
begin
  Result:= nil;

  Buffer:= Base64StringToMemoryStream(Base64String);
  if Buffer = nil then
    Exit;
  try
    try
      Result:= FMX.Graphics.TBitmap.Create;
      Result.LoadFromStream(Buffer);
    except
    end;
  finally
    FreeAndNil(Buffer);
  end;
end;

procedure UsuarioBloqueado;
begin
  TInterlocked.Exchange(ACCOUNT_IS_LOCKED, True);
  (*
    DRH 28/10/2025
    -Este procedimiento se disparará cuando el usuario
    quiera realizar una petición en alguno de los endpoints
    y se le haya bloqueado la cuenta.

    -Si se dispara en otro hilo que no sea el principal,
    entonces hay que aplicarle un Synchronize.
  *)
  Encolar(
  procedure
  begin
    frmMain.btnOkMessageDlg.OnClick:= TGeneral_Actions.BtnOkMsgDlgUsr_BloqueadoClick;
    frmMain.TituloMessageDialog.Text:= 'AVISO';
    frmMain.MensajeMessageDialog.Text:= 'Su cuenta ha sido bloqueada, se ' +
    'requiere contactar al administrador.';
    frmMain.MessageDialog.Visible:= True;
    frmMain.MessageDialog.BringToFront;
  end);
end;

procedure AbrirPDF(const AFileName: string);
{$IFDEF ANDROID}
var
  JavaFile: JFile;
  Uri: Jnet_Uri;
  Intent: JIntent;
{$ENDIF}
begin
  if TFile.Exists(AFileName) then
  begin
    {$IFDEF ANDROID}
    JavaFile:= TJFile.JavaClass.init(StringToJString(AFileName));
    Uri:= TAndroidHelper.JFileToJURI(JavaFile);
    Intent := TJIntent.Create;
    Intent.setAction(TJIntent.JavaClass.ACTION_VIEW);
    Intent.setDataAndType(Uri, StringToJString('application/pdf'));
    Intent.addFlags(TJIntent.JavaClass.FLAG_GRANT_READ_URI_PERMISSION);
    Intent.setFlags(TJIntent.JavaClass.FLAG_ACTIVITY_NO_HISTORY);
    TAndroidHelper.Context.startActivity(Intent);
    {$ENDIF}
    {$IFDEF MSWINDOWS}
    ShellExecute(0, 'open', PWideChar(AFileName), nil, nil, SW_SHOWNORMAL);
    {$ENDIF}
  end
  else
    MessageDlg('INFORMACIÓN', 'El archivo especificado que desea abrir ' +
    'no existe en la ruta especificada.');
end;

{ TGeneral_Actions }

class procedure TGeneral_Actions.BtnOkMsgDlgUsr_BloqueadoClick(Sender: TObject);
begin
  frmMain.MessageDialog.Visible:= False;

  if frmMain.Pantallas.ActiveTab <> frmMain.Login then
    frmMain.Pantallas.ActiveTab:= frmMain.Login;

  frmMain.btnOkMessageDlg.OnClick:= frmMain.btnOkMessageDlgClick;
  TInterlocked.Exchange(ACCOUNT_IS_LOCKED, False);
end;

end.


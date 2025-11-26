unit Generales;

interface

uses
  IdHashMessageDigest,
  System.Classes, FMX.Forms, FMX.Platform, System.Messaging, FMX.Objects,
  IdGlobal, WinApi.Windows, Winapi.ShellApi, TlHelp32, IdHTTP, System.NetEncoding,
  System.Types, System.StrUtils, FMX.Dialogs, IdStack, System.Hash, FMX.Grid,
  System.SysUtils, System.SyncObjs;

procedure Sincronizar(const AProc: TProc);
procedure Encolar(const AProc: TProc);
procedure SeccionCritica(const AProc: TProc);
//procedure SyncSemaforoWS(const AProc: TProc);
procedure EscribirLog(const Mensaje: string; const Nivel: Integer = 1); //1 = Operaciones 2 = Excepciones
procedure MessageDialog(const Titulo, Mensaje: string);
procedure AbrirURL(const aURL: string);
function GetLocalIPAddress: string;
procedure EscribirConfigIni(const Seccion, Identificador, Valor: string);
function LeerConfigIni(const Seccion, Identificador: string): string;
function FileToBase64String(const aFileName: string): string;
function Base64StringToMemoryStream(const Base64String: string): TMemoryStream;
function StreamToBase64String(const Stream: TStream): string;
procedure DesplazarStringGrid(const Grid: TStringGrid; const Pos: Integer = 1); //1= Inicio 2= Final 3 De acuerdo a la seleccion
procedure HideLoadingDialog;
procedure ShowLoadingDialog;
function CalcularHashMD5(const MS: TMemoryStream): string;

function getPDFThumbnail(FileName: string; aWidth, aHeight: Single): TMemoryStream; external 'miniaturaPDF.dll'
 name 'getPDFThumbnail';

implementation
uses
  System.IniFiles, FMX.TabControl, FMX.StdCtrls, FMX.Edit,
  FMX.Memo, System.IOUtils, System.DateUtils, UMain;

procedure Sincronizar(const AProc:TProc);
begin
  if CurrentThreadId <> MainThreadID then
  begin
    TThread.Synchronize(nil,
    procedure
    begin
      AProc;
    end);
  end else AProc;
end;

procedure Encolar(const AProc: TProc);
begin
  if CurrentThreadId <> MainThreadID then
  begin
    TThread.Queue(nil,
    procedure
    begin
      AProc;
    end);
  end else AProc;
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

//Solamente va a utilizarse en el WebServer.
(*procedure SyncSemaforo(const AProc: TProc);
begin
  Semaforo.Acquire;
  try
    if Assigned(AProc) then
      AProc;
  finally
    Semaforo.Release;
  end;
end;*)

procedure EscribirLog(const Mensaje: string; const Nivel: Integer);
begin
  (*
    Con esto se evita el error IO32 por el acceso múltiple
    a este método.
  *)
  //1 = Operaciones 2 = Excepciones
  SeccionCritica(
  procedure
  var
    F: TextFile;
    FileName: string;
  begin
    try
      FileName := TPath.Combine(ExtractFilePath(ParamStr(0)), 'Log.txt');
      AssignFile(F, FileName);
      if FileExists(FileName) then
        Append(F)
      else
        Rewrite(F);
      case Nivel of
        1: writeln(F, FormatDateTime('DD/MM/YYYY hh:nn ampm', Now) + ' - ' + Mensaje);
        2: writeln(F, FormatDateTime('DD/MM/YYYY hh:nn ampm', Now) + ' - Excepción: ' + Mensaje);
        else
          writeln(F, FormatDateTime('DD/MM/YYYY hh:nn ampm', Now) + ' - ' + Mensaje);
      end;
      CloseFile(F);
    except
      CloseFile(F);
    end;
  end);
end;

procedure MessageDialog(const Titulo, Mensaje: string);
begin
  //No hace falta sincronizar si se llama desde otro hilo que no es el principal
  Encolar(
  procedure
  begin
    frmMain.TituloMessageDlg.Text:= Titulo.ToUpper;
    frmMain.MensajeMsgDlg.Text:= Mensaje;
    frmMain.MessageDialog.Visible:= True;
    frmMain.MessageDialog.BringToFront;
  end);
end;

procedure AbrirURL(const aURL: string);
begin
  ShellExecute(0, nil, PChar(aURL), nil, nil, SW_SHOWNOACTIVATE);
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
  FileName:= ExtractFileDir(ParamStr(0)) + PathDelim + 'config.ini';
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
  FileName:= ExtractFileDir(ParamStr(0)) + PathDelim + 'config.ini';
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

function Base64StringToMemoryStream(const Base64String: string): TMemoryStream;
var
  Encoding: TNetEncoding;
  DecodedBytes: TBytes;
begin
  {
    Esta función convierte una cadena en Base64 a un
    TMemoryStream
  }

  if Base64String.IsEmpty then
  Exit(nil);

  Encoding:= TNetEncoding.Base64;
  try
    try
      DecodedBytes:= Encoding.DecodeStringToBytes(Base64String);
      Result:= TMemoryStream.Create;
      Result.WriteBuffer(DecodedBytes[0], Length(DecodedBytes));
      Result.Position:= 0; //Importante
    except
      Result:= nil;
    end;
  finally
    SetLength(DecodedBytes, 0);
  end;
end;

function StreamToBase64String(const Stream: TStream): string;
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

procedure DesplazarStringGrid(const Grid: TStringGrid;
  const Pos: Integer = 1); //1= Inicio 2= Final
begin
  if Grid = nil then
    Exit;

  if Grid.RowCount > 1 then
  begin
    case Pos of
      1:  Grid.ViewportPosition:= TPointF.Create(0, 0);

      2:  Grid.ViewportPosition:= TPointF.Create(0,
      Grid.RowCount * Grid.RowHeight);

      3: Grid.ViewportPosition:= TPointF.Create(0,
      (Grid.Selected + 1) * Grid.RowHeight);

      else
        Grid.ViewportPosition:= TPointF.Create(0, 0);
    end;
  end;
end;

procedure HideLoadingDialog;
begin
  frmMain.LoadingDialog.Visible:= False;
  frmMain.IndicadorLoadingDialog.Animation.Enabled:= False;
end;

procedure ShowLoadingDialog;
begin
  frmMain.IndicadorLoadingDialog.Animation.Enabled:= True;
  frmMain.LoadingDialog.Visible:= True;
  frmMain.LoadingDialog.BringToFront;
end;

function CalcularHashMD5(const MS: TMemoryStream): string;
var
  MD5: TIdHashMessageDigest5;
begin
  MS.Position := 0;
  MD5 := TIdHashMessageDigest5.Create;
  try
    Result := MD5.HashStreamAsHex(MS);
  finally
    if MD5 <> nil then
      FreeAndNil(MD5);
  end;
end;

end.


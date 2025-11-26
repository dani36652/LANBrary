unit UAcciones_Configuraciones;

interface
uses
  FMX.Platform.Win, FMX.Forms, FMX.Types,
  System.SysUtils, Winapi.Windows, Winapi.ShlObj, Winapi.ActiveX, FMX.Dialogs,
  FMX.DialogService, System.Classes, System.Types, System.SysConst,
  FMX.ComboEdit, System.StrUtils, FMX.Objects, FMX.StdCtrls,
  FMX.Colors, FMX.Controls, FMX.Edit, FMX.Platform, FMX.Utils,
  System.Generics.Collections, System.UIConsts, FMX.ListView.Appearances,
  FMX.ListView, System.UITypes, FMX.Grid;

type TAcciones_Configuraciones = class
  private
  public
    class procedure btnSelecRutaDesc_ConfigClick(Sender: TObject);
    class procedure LoadSettings;
end;

type TFolderPickerDialog = class (TComponent)
  strict protected
    FTitle: string;
    FFolderPath: string;
    FInitialDir: string;
  private

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Execute(const Handle: TWindowHandle): Boolean;
    property Title: string read FTitle write FTitle;
    property FolderPath: string read FFolderPath;
    property InitialDir: string read FInitialDir write FInitialDir;
end;

implementation
uses
  System.IOUtils, UMain, Generales;

{ TFolderPickerDialog }

constructor TFolderPickerDialog.Create(AOwner: TComponent);
begin
  inherited;
  FTitle:= 'Select folder';
  FFolderPath:= '';
  FInitialDir:= '';
end;

destructor TFolderPickerDialog.Destroy;
begin
  FTitle:= string.Empty;
  FFolderPath:= string.Empty;
  inherited;
end;

function TFolderPickerDialog.Execute(const Handle: TWindowHandle): Boolean;
var
  Dialog: IFileDialog;
  hr: HRESULT;
  ShellItem, FolderItem: IShellItem;
  pszFilePath: PWideChar;
  CoInit: Boolean;
  ParentWND: HWND;
begin
  Result := False;
  FFolderPath := '';
  pszFilePath := nil;
  ShellItem := nil;
  Dialog := nil;

  CoInit := Succeeded(CoInitializeEx(nil, COINIT_APARTMENTTHREADED or COINIT_DISABLE_OLE1DDE));
  try
    hr := CoCreateInstance(CLSID_FileOpenDialog, nil, CLSCTX_INPROC_SERVER, IID_IFileDialog, Dialog);
    if Succeeded(hr) and Assigned(Dialog) then
    begin
      Dialog.SetOptions(FOS_PICKFOLDERS or FOS_FORCEFILESYSTEM);
      Dialog.SetTitle(PWideChar(WideString(FTitle)));

      if not FInitialDir.IsEmpty then
      begin
        if Succeeded(SHCreateItemFromParsingName(PWideChar(WideString(
        FInitialDir)), nil, IID_IShellItem, FolderItem)) then
          Dialog.SetFolder(FolderItem);
      end;

      ParentWND:= FmxHandleToHWND(Handle);
      hr := Dialog.Show(ParentWND);
      if Succeeded(hr) then
      begin
        hr := Dialog.GetResult(ShellItem);
        if Succeeded(hr) and Assigned(ShellItem) then
        begin
          hr := ShellItem.GetDisplayName(SIGDN_FILESYSPATH, pszFilePath);
          if Succeeded(hr) and Assigned(pszFilePath) then
          begin
            FFolderPath := pszFilePath;
            CoTaskMemFree(pszFilePath);
            Result := True;
          end;
        end;
      end;
    end;
  finally
    ShellItem := nil;
    Dialog := nil;

    if CoInit then
      CoUninitialize;
  end;
end;

{ TAcciones_Configuraciones }

class procedure TAcciones_Configuraciones.btnSelecRutaDesc_ConfigClick(
  Sender: TObject);
var
  FolderPicker: TFolderPickerDialog;
begin
  FolderPicker:= TFolderPickerDialog.Create(nil);

  if not frmMain.edtRutaDescargas_Configuraciones.Text.Trim.IsEmpty then
    FolderPicker.InitialDir:= frmMain.edtRutaDescargas_Configuraciones.Text.Trim;

  FolderPicker.Title:= 'Carpeta de descargas';
  try
    if FolderPicker.Execute(frmMain.Handle) then
    begin
      frmMain.edtRutaDescargas_Configuraciones.Text:= FolderPicker.FolderPath;
      EscribirConfigIni('DOWNLOADS', 'PATH', FolderPicker.FolderPath);
    end
    else
      frmMain.edtRutaDescargas_Configuraciones.Text:=
      LeerConfigIni('DOWNLOADS', 'PATH');
  finally
    FreeAndNil(FolderPicker);
  end;
end;

class procedure TAcciones_Configuraciones.LoadSettings;
var
  DOWNLOADS_PATH: string;
begin
  DOWNLOADS_PATH:= LeerConfigIni('DOWNLOADS', 'PATH');

  if not DOWNLOADS_PATH.IsEmpty then
    frmMain.edtRutaDescargas_Configuraciones.Text:= DOWNLOADS_PATH
  else
  begin
    DOWNLOADS_PATH:= TPath.GetDownloadsPath;
    frmMain.edtRutaDescargas_Configuraciones.Text:= DOWNLOADS_PATH;
    EscribirConfigIni('DOWNLOADS', 'PATH', DOWNLOADS_PATH);
  end;
end;

end.

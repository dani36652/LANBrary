unit UMainFormEvents;

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
  FMX.DialogService,Androidapi.Jni.Provider,Androidapi.Jni.Net,
  fmx.TextLayout,AndroidAPI.JNI.Support,
 {$ENDIF}
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.TabControl,
  System.Math, FMX.ComboEdit, System.SyncObjs, FMX.ListView, FMX.SearchBox,
  FMX.Layouts, FMX.Objects, FMX.Controls.Presentation, FMX.Edit, FMX.StdCtrls;

type TMainFormEvents = class
  private
    {$IFDEF ANDROID}
    class procedure CalcContentBoundsProc(Sender: TObject; var ContentBounds: TRectF);
    class procedure RestorePosition;
    class procedure UpdateKBBounds;
    class procedure CBECategorias_PrincipalClick(Sender: TObject);
    class var
      FKBBounds: TRectF;
      FNeedOffset: Boolean;
    {$ENDIF}
    class procedure ComboEditClick(Sender: TObject);
    class procedure setTextFieldsSettings(Sender: TObject);
    class procedure CreateAndAssingSearchBoxes;
  public
    {$IFDEF ANDROID}
    class procedure PermisoAlmacenamientoRequestResult(Sender: TObject;
    const APermissions: TClassicStringDynArray;
    const AGrantResults: TClassicPermissionStatusDynArray);

    class function ReadyForDownloading: Boolean;
    class procedure CreateDirectories;
    {$ENDIF}
    class procedure FormCreate(Sender: TObject);
    class procedure FormDestroy(Sender: TObject);
    class procedure FormFocusChanged(Sender: TObject);
    class procedure FormVirtualKeyboardHidden(Sender: TObject;
    KeyboardVisible: Boolean; const Bounds: TRect);
    class procedure FormVirtualKeyboardShown(Sender: TObject;
    KeyboardVisible: Boolean; const Bounds: TRect);
    class procedure FormKeyDown(Sender: TObject; var Key: Word;
    var KeyChar: WideChar; Shift: TShiftState);
    class procedure btnOkMessageDlgClick(Sender: TObject);
    class procedure FormResize(Sender: TObject);
    class procedure FormShow(Sender: TObject);
end;

implementation
uses
  URest, EUsuario, System.IOUtils,
  Estilos, UMain,Generales, UAcciones_Registro, UAcciones_Configuraciones,
  UJSONTool, ULibros;

{ TMainFormEvents }

class procedure TMainFormEvents.btnOkMessageDlgClick(Sender: TObject);
begin
  frmMain.MessageDialog.Visible:= False;
end;

class procedure TMainFormEvents.FormCreate(Sender: TObject);
begin
  FLAG_SEARCHING_BOOKS:= False;
  SCROLLING_BOOKS:= False;
  ACCOUNT_IS_LOCKED:= False;
  FLAG_BOOK_DELETED:= False;
  {$IFDEF ANDROID}
  RutaPDFS:= string.Empty;
  RutaThumbnails:= string.Empty;
  {$ENDIF}
  {$IFDEF MSWINDOWS}
  RutaPDFS:= ExtractFileDir(ParamStr(0)) + PathDelim + 'Books';
  RutaThumbnails:= RutaPDFS + PathDelim + 'Thumbnails';

  if not TDirectory.Exists(RutaPDFS) then
    TDirectory.CreateDirectory(RutaPDFS);

  if not TDirectory.Exists(RutaThumbnails) then
    TDirectory.CreateDirectory(RutaThumbnails);
  {$ENDIF}
  TIPO_FOTO:= -1;
  Usuario:= Default(rUsuario);
  OPCION_SELECCIONADA:= -1;
  PaginaActual.Indx:= -1;
  PaginaActual.Ult_id:= string.Empty;
  PaginaActual.Ult_Fechahora:= string.Empty;
  PaginaActual.Ult_IdCategoria:= -1;
  SetLength(Paginas, 0);
  REST:= TREST.Create(nil);
  CriticalSection:= TCriticalSection.Create;

  {$IFDEF ANDROID}
  //Bandera para impedir el cierre de la app mientras corre un subproceso
  THREAD_IS_RUNNING:= False;
  CAMERA_PERMISSION:= JStringToString(TJManifest_permission.JavaClass.CAMERA);

  if TJBuild_VERSION.JavaClass.SDK_INT >= 33  then
  begin
    IMAGES_PERMISSION:= JStringToString(TJManifest_permission.JavaClass.READ_MEDIA_IMAGES);
    STORAGE_PERMISSION:= string.Empty;
  end;
  if TJBuild_VERSION.JavaClass.SDK_INT <= 32 then
  begin
    STORAGE_PERMISSION:= JStringToString(TJManifest_permission.JavaClass.READ_EXTERNAL_STORAGE);
    IMAGES_PERMISSION:= string.Empty;
  end;

  frmMain.ScrollForm.AniCalculations.TouchTracking:= [];
  frmMain.ScrollForm.OnCalcContentBounds:= CalcContentBoundsProc;
  {$ENDIF}
  setTextFieldsSettings(Sender); //DRH 14/11/2025

//////////////////////////////////////////////////////////////////////////////////////////////////////
  frmMain.MVOpcionesFotoPerfil.Height:= (TForm(Sender).Height / 3);
  frmMain.MVOpciones_ClasificacionLibros.Height:= (TForm(Sender).Height / 4);
  frmMain.MVOpciones_Principal.Width:= TForm(Sender).Width - 55;
  frmMain.LYFotoUsuario_Registro.Height:= frmMain.Height/ 4;
  frmMain.rectMarcoFotoUsuario_Registro.Width:= frmMain.LYFotoUsuario_Registro.Width / 3;
  frmMain.rectMarcoFotoUsuario_Registro.Height:= frmMain.LYFotoUsuario_Registro.Height;

  frmMain.rectToolbarMVOpciones.Height:= frmMain.Height / 4.2;
///////////////////////////////////////////////////////////////////////////////////////
  CreateAndAssingSearchBoxes; //DRH 22/10/2025
  setApplicationTheme(Sender as TForm);

  if TAcciones_Configuraciones.LoadSettings then
  begin
    frmMain.btnAtras_Configuraciones.Visible:= True;
    frmMain.Pantallas.ActiveTab:= frmMain.Login;
  end
  else
  begin
    frmMain.btnAtras_Configuraciones.Visible:= False;
    frmMain.Pantallas.ActiveTab:= frmMain.Configuraciones;
  end;
end;

class procedure TMainFormEvents.FormDestroy(Sender: TObject);
begin
  if Assigned(CriticalSection) then
    FreeAndNil(CriticalSection);

  if Assigned(REST) then
    FreeAndNil(REST);
end;

class procedure TMainFormEvents.FormFocusChanged(Sender: TObject);
begin
  {$IFDEF ANDROID}
  if Assigned(TForm(Sender).Focused) then
    UpdateKBBounds;
  {$ENDIF}
end;

{$IFDEF ANDROID}
class procedure TMainFormEvents.CalcContentBoundsProc(Sender: TObject;
  var ContentBounds: TRectF);
begin
  if FNeedOffset and (FKBBounds.Top > 0) then
  begin
    ContentBounds.Bottom := Max(ContentBounds.Bottom, 2 * frmMain.ClientHeight - FKBBounds.Top);
  end;
end;

class procedure TMainFormEvents.CBECategorias_PrincipalClick(Sender: TObject);
begin
  if not ReadyForDownloading then
    Exit;

    TComboEdit(Sender).DropDown;
end;

{$ENDIF}

class procedure TMainFormEvents.ComboEditClick(Sender: TObject);
begin
  if not Assigned(Sender) then
    Exit;

  if TComboEdit(Sender).Items.Count > 0 then
    TComboEdit(Sender).DropDown;
end;

class procedure TMainFormEvents.CreateAndAssingSearchBoxes;
var
  i: Integer;
  ListView: TListView;
begin
  {
    SearchBox para TListView de la pantalla "Descargas"
  }
  ListView:= frmMain.LVDescargas;
  SearchBox_Descargas:= TSearchBox.Create(frmMain);
  SearchBox_Descargas.Parent:= frmMain;
  SearchBox_Descargas.Visible:= False;
  ListView.SearchVisible:= True;
  for i:= 0 to ListView.ControlsCount - 1 do
  begin
    if ListView.Controls[i].ClassType = TSearchBox then
    begin
      SearchBox_Descargas.Model.SearchResponder:=
      TSearchBox(ListView.Controls[i]).Model.SearchResponder;
      Break;
    end;
  end;
  ListView.SearchVisible:= False;
  {=====================================================}
end;

class procedure TMainFormEvents.setTextFieldsSettings(Sender: TObject);
var
  i: Integer;
begin
  if not Assigned(Sender) then
    Exit;

  for i:= 0 to TForm(Sender).ComponentCount - 1 do
  begin
    if TForm(Sender).Components[i].ClassType = TComboEdit then
    {$IFDEF ANDROID}
    if TForm(Sender).Components[i].Name = 'CBECategorias_Principal' then
      TComboEdit(TForm(Sender).Components[i]).OnClick:= CBECategorias_PrincipalClick
    else
      TComboEdit(TForm(Sender).Components[i]).OnClick:= ComboEditClick;
    {$ENDIF}
    {$IFDEF MSWINDOWS}
    TComboEdit(TForm(Sender).Components[i]).OnClick:= ComboEditClick;
    {$ENDIF}
  end;
end;

class procedure TMainFormEvents.FormKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: WideChar; Shift: TShiftState);
begin
  if Key = vkHardwareBack then
  begin
    if THREAD_IS_RUNNING then
    begin
      Key:= 0;
    end
    else

    if frmMain.MessageDialog.IsVisible then
    begin
      Key:= 0;

      if not ACCOUNT_IS_LOCKED then
        frmMain.MessageDialog.Visible:= False;
    end
    else

    if frmMain.rectFondoCambiarClave.IsVisible then
    begin
      Key:= 0;
      frmMain.rectFondoCambiarClave.Visible:= False;
    end
    else

    if frmMain.MVOpciones_Principal.IsShowed then
    begin
      Key:= 0;
      frmMain.MVOpciones_Principal.HideMaster;
    end
    else

    if frmMain.MVOpcionesFotoPerfil.IsShowed then
    begin
      Key:= 0;
      frmMain.MVOpcionesFotoPerfil.HideMaster;
    end
    else

    if frmMain.MVOpciones_ClasificacionLibros.IsShowed then
    begin
      Key:= 0;
      frmMain.MVOpciones_ClasificacionLibros.HideMaster
    end
    else
    begin
      case frmMain.Pantallas.TabIndex of
        0:
        begin
          Key:= 0;
          frmMain.btnAtras_Configuraciones.OnClick(frmMain.btnAtras_Configuraciones);
        end;

        1:
        begin
          Key:= 0;
          frmMain.btnAtras_RegistroClick(frmMain.btnAtras_Registro);
        end;

        4:
        begin
          Key:= 0;
          frmMain.btnAtras_MiCuenta.OnClick(frmMain.btnAtras_MiCuenta);
        end;

        5:
        begin
          Key:= 0;
          frmMain.btnAtrasDescargas.OnClick(frmMain.btnAtrasDescargas);
        end;
      end;
    end;
  end;
end;

class procedure TMainFormEvents.FormResize(Sender: TObject);
begin

end;

class procedure TMainFormEvents.FormShow(Sender: TObject);
begin

end;

class procedure TMainFormEvents.FormVirtualKeyboardHidden(Sender: TObject;
  KeyboardVisible: Boolean; const Bounds: TRect);
begin
  {$IFDEF ANDROID}
  FKBBounds.Create(0, 0, 0, 0);
  FNeedOffset := False;
  RestorePosition;
  {$ENDIF}
end;

class procedure TMainFormEvents.FormVirtualKeyboardShown(Sender: TObject;
  KeyboardVisible: Boolean; const Bounds: TRect);
begin
  {$IFDEF ANDROID}
  FKBBounds := TRectF.Create(Bounds);
  FKBBounds.TopLeft := TForm(Sender).ScreenToClient(FKBBounds.TopLeft);
  FKBBounds.TopLeft.Y:= FKBBounds.TopLeft.Y - 5; //5 pixeles para tomar en cuenta el Caret position selector
  FKBBounds.BottomRight := TForm(Sender).ScreenToClient(FKBBounds.BottomRight);
  UpdateKBBounds;
  {$ENDIF}
end;

{$IFDEF ANDROID}
class procedure TMainFormEvents.PermisoAlmacenamientoRequestResult(
  Sender: TObject; const APermissions: TClassicStringDynArray;
  const AGrantResults: TClassicPermissionStatusDynArray);
begin
  if (Length(AGrantResults) = 2) and (AGrantResults[0] = TPermissionStatus.Granted)
  and (AGrantResults[1] = TPermissionStatus.Granted) then
    CreateDirectories
  else
    GoToAppPermissionsSettings;
end;

class function TMainFormEvents.ReadyForDownloading: Boolean;
var
  Intent: JIntent;
  Uri: Jnet_Uri;
  LECTURA_ALMACENAMIENTO,
  ESCRITURA_ALMACENAMIENTO: string;
begin
  if (not RutaPDFS.IsEmpty) and (not RutaThumbnails.IsEmpty) then
    Exit(True);

  ESCRITURA_ALMACENAMIENTO:= JStringToString(
  TJManifest_permission.JavaClass.WRITE_EXTERNAL_STORAGE);

  LECTURA_ALMACENAMIENTO:= JStringToString(
  TJManifest_permission.JavaClass.READ_EXTERNAL_STORAGE);

  if TJBuild_VERSION.JavaClass.SDK_INT >= 30 then //Android 11+
  begin
    case TJEnvironment.JavaClass.isExternalStorageManager of
      True:
      begin
        Result:= True;
        CreateDirectories;
      end;

      False:
      begin
        Result:= False;
        Intent:= TJIntent.Create;
        //Puede asignar una acción mediante su string
        //Intent.setAction(StringToJString('android.settings.MANAGE_APP_ALL_FILES_ACCESS_PERMISSION'));
        Intent.setAction(TJSettings.JavaClass.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION);
        Uri:= TJnet_Uri.JavaClass.parse(StringToJString(Concat('package:',
        JStringToString(TAndroidHelper.Context.getPackageName))));
        intent.setData(Uri);
        TAndroidHelper.Activity.startActivity(intent);
      end;
    end;
  end
  else //Android 10 e inferiores
  begin
    if not PermissionsService.IsEveryPermissionGranted([
    ESCRITURA_ALMACENAMIENTO, LECTURA_ALMACENAMIENTO]) then
    begin
      Result:= False;
      PermissionsService.RequestPermissions([
      ESCRITURA_ALMACENAMIENTO, LECTURA_ALMACENAMIENTO], PermisoAlmacenamientoRequestResult,
      nil);
    end
    else
    begin
      Result:= True;
      CreateDirectories;
    end;
  end;
end;

class procedure TMainFormEvents.CreateDirectories;
var
  ExtStorage_Path: string;
begin
  ExtStorage_Path:= GetExternalStorageRoot;
  RutaPDFS:= ExtStorage_Path + PathDelim + 'LANBrary' + PathDelim + 'Books';
  RutaThumbnails:= RutaPDFS + PathDelim + 'Thumbnails';

  if not TDirectory.Exists(RutaPDFS) then
    TDirectory.CreateDirectory(RutaPDFS);

  if not TDirectory.Exists(RutaThumbnails) then
    TDirectory.CreateDirectory(RutaThumbnails);
end;

class procedure TMainFormEvents.RestorePosition;
begin
  frmMain.ScrollForm.ViewportPosition := PointF(0, 0);
  frmMain.MainLayout.Align := TAlignLayout.Client;
  frmMain.ScrollForm.RealignContent;
end;

class procedure TMainFormEvents.UpdateKBBounds;
var
  LFocused : TControl;
  LFocusRect: TRectF;
begin
 // Evita que el teclado virtual se sobreponga a los objetos de entrada de texto
  if Assigned(frmMain.Focused) then
  begin
    LFocused := TControl(frmMain.Focused.GetObject);
    LFocusRect := LFocused.AbsoluteRect;
    LFocusRect.Offset(frmMain.ScrollForm.ViewportPosition);
    FNeedOffset:= False;
    if (LFocusRect.IntersectsWith(TRectF.Create(FKBBounds))) and
    (LFocusRect.Bottom > FKBBounds.Top) then
    begin
      FNeedOffset:= True;
      frmMain.MainLayout.Align := TAlignLayout.Horizontal;
      frmMain.ScrollForm.RealignContent;
      frmMain.ScrollForm.ViewportPosition :=
      PointF(frmMain.ScrollForm.ViewportPosition.X,
      (LFocusRect.Bottom - FKBBounds.Top) + 16);
    end
    else
      RestorePosition;
  end;
end;
{$ENDIF}

end.

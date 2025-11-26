unit UAcciones_Registro;

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

type TAcciones_Registro = class
  private
    class procedure ThreadOnTerminate(Sender: TObject);
    {$IFDEF ANDROID}
    class procedure TomarImagenDeCamara_RequestResult(Sender: TObject;
    const APermissions: TClassicStringDynArray;
    const AGrantResults: TClassicPermissionStatusDynArray);

    class procedure TomarImagenDeGaleria_RequestResult(Sender: TObject;
    const APermissions: TClassicStringDynArray;
    const AGrantResults: TClassicPermissionStatusDynArray);
    {$ENDIF}
    {$IFDEF MSWINDOWS}
    class procedure WinSeleccionarFotoDePerfil;
    {$ENDIF}
  public
    class procedure DatosChange(Sender: TObject);
    class procedure BtnSelecFotoUsr_RegistroClick(Sender: TObject);
    class procedure btnCerrarMVOpcionesFotoClick(Sender: TObject);
    class procedure btnHideAndShowClave_RegistroClick(Sender: TObject);
    class procedure setCamposRegistroToDefault;
    class procedure TomarFotoDeCamaraDidFinishTaking(Image: TBitmap);
    class procedure btnCamaraMVOpcionesFotoClick(Sender: TObject);
    class procedure btnEliminarFotoUsuarioMVOpcionesClick(Sender: TObject);
    class procedure btnAtras_RegistroClick(Sender: TObject);
    class procedure btnGaleriaMVOpcionesFotoClick(Sender: TObject);
    class procedure CamposKeyDown(Sender: TObject; var Key: Word;
    var KeyChar: WideChar; Shift: TShiftState);
    class procedure btnRegistrarse_RegistroClick(Sender: TObject);
    class procedure btnHideAndShowConfClave_RegistroClick(Sender: TObject);
end;

implementation
uses
  UMain, Generales, System.IOUtils, System.SyncObjs, UAcciones_MiCuenta,
  UJSONTool;

{ TAcciones_Registro }

class procedure TAcciones_Registro.btnAtras_RegistroClick(Sender: TObject);
begin
  try
    frmMain.Pantallas.ActiveTab:= frmMain.Login;
  finally
    setCamposRegistroToDefault;
  end;
end;

class procedure TAcciones_Registro.btnCamaraMVOpcionesFotoClick(
  Sender: TObject);

begin
  frmMain.MVOpcionesFotoPerfil.HideMaster;
  {$IFDEF ANDROID}
  PermissionsService.RequestPermissions([CAMERA_PERMISSION], TomarImagenDeCamara_RequestResult, nil);
  {$ENDIF}
  {$IFDEF MSWINDOWS}
  WinSeleccionarFotoDePerfil;
  {$ENDIF}
end;

class procedure TAcciones_Registro.btnCerrarMVOpcionesFotoClick(
  Sender: TObject);
begin
  frmMain.MVOpcionesFotoPerfil.HideMaster;
end;

class procedure TAcciones_Registro.btnEliminarFotoUsuarioMVOpcionesClick(
  Sender: TObject);
var
  Mensaje: string;
begin
  Mensaje:= '¿Eliminar foto de perfil?';

  TDialogService.MessageDialog(Mensaje, TMsgDlgType.mtConfirmation,
  [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbCancel], TMsgDlgBtn.mbYes, 0,
  procedure(const AResult: TModalResult)
  {$IFDEF ANDROID}
  var
    Toast: JToast;
  {$ENDIF}
  begin
    case AResult of
      mrYes:
      begin
        frmMain.MVOpcionesFotoPerfil.HideMaster;
        case TIPO_FOTO of
          1:
          begin
            frmMain.rectMarcoFotoUsuario_Registro.Width:= frmMain.LYFotoUsuario_Registro.Width / 3;
            frmMain.rectMarcoFotoUsuario_Registro.Fill.Color:= $FFEAEAEA;
            frmMain.imgFotoUsuario_Registro.Visible:= False;
            frmMain.imgFotoUsuario_Registro.Bitmap:= nil;
            frmMain.SVGFotoUsuarioDefault_Registro.Visible:= True;
            frmMain.btnEliminarFotoUsuarioMVOpciones.Visible:= False;

            {$IFDEF ANDROID}
            Toast:= TJToast.JavaClass.makeText(TAndroidHelper.Context,
            StrToJCharSequence('Se eliminó la foto de perfil'), TJToast.JavaClass.LENGTH_SHORT);
            Toast.setGravity(TJGravity.JavaClass.CENTER, 0, 0);
            Toast.show;
            {$ENDIF}
            {$IFDEF MSWINDOWS}
            TDialogService.MessageDialog('Se eliminó la foto de perfil', TMsgDlgType.mtInformation,
            [TMsgDlgBtn.mbOK], TMsgDlgBtn.mbOK, 0, nil);
            {$ENDIF}
            TIPO_FOTO:= -1;
          end;

          2: TAcciones_MiCuenta.EliminarFotoPerfil;
        end;
      end;
    end;
  end);
end;

class procedure TAcciones_Registro.btnGaleriaMVOpcionesFotoClick(
  Sender: TObject);
begin
  frmMain.MVOpcionesFotoPerfil.HideMaster;
  {$IFDEF ANDROID}
  if TJBuild_VERSION.JavaClass.SDK_INT >= 33 then
    PermissionsService.RequestPermissions([IMAGES_PERMISSION], TomarImagenDeGaleria_RequestResult, nil)
  else
    PermissionsService.RequestPermissions([STORAGE_PERMISSION], TomarImagenDeGaleria_RequestResult, nil);
  {$ENDIF}
end;

class procedure TAcciones_Registro.btnHideAndShowClave_RegistroClick(
  Sender: TObject);
begin
  frmMain.edtClave_Registro.Password:= not frmMain.edtClave_Registro.Password;
  frmMain.PasswordHidden_Registro.Visible:= frmMain.edtClave_Registro.Password;
  frmMain.PasswordShown_Registro.Visible:= not frmMain.edtClave_Registro.Password;
end;

class procedure TAcciones_Registro.btnHideAndShowConfClave_RegistroClick(
  Sender: TObject);
begin
  frmMain.edtConfirmarClave_Registro.Password:= not frmMain.edtConfirmarClave_Registro.Password;
  frmMain.PasswordHidden2_Registro.Visible:= frmMain.edtConfirmarClave_Registro.Password;
  frmMain.PasswordShown2_Registro.Visible:= not frmMain.edtConfirmarClave_Registro.Password;
end;

class procedure TAcciones_Registro.btnRegistrarse_RegistroClick(
  Sender: TObject);
var
  Thread: TThread;
begin
  ShowLoadingDialog;

  Thread:= TThread.CreateAnonymousThread(
  procedure
  var
    Nombre, ApellidoP, ApellidoM, Correo, Clave,
    Edad, Foto: string;
    MSFoto: TMemoryStream;
  begin
    TInterlocked.Exchange(THREAD_IS_RUNNING, True);

    Nombre:= frmMain.edtNombreUsr_Registro.Text.Trim;
    ApellidoP:= frmMain.edtApellidoP_Registro.Text.Trim;
    ApellidoM:= frmMain.edtApellidoM_Registro.Text.Trim;
    Correo:= frmMain.edtCorreo_Registro.Text.Trim;
    Clave:= frmMain.edtClave_Registro.Text;
    Edad:= frmMain.edtEdad_Registro.Text.Trim;

    if (frmMain.imgFotoUsuario_Registro.IsVisible) and
    (frmMain.imgFotoUsuario_Registro.Bitmap <> nil) then
    begin
      MSFoto:= TMemoryStream.Create;
      try
        frmMain.imgFotoUsuario_Registro.Bitmap.SaveToStream(MSFoto);
        MSFoto.Position:= 0; //Muy importante
        Foto:= MemoryStreamToBase64String(MSFoto);
      finally
        FreeAndNil(MSFoto);
      end;
    end else Foto:= string.Empty;

    case TJSONTool.RegistrarUsuario(Nombre, ApellidoP,ApellidoM,
    Correo, Clave, Edad, Foto) of

      200:
      begin
        Sincronizar(
        procedure
        begin
          frmMain.Pantallas.ActiveTab:= frmMain.Login;
          setCamposRegistroToDefault;
          MessageDlg('Información', 'Registrado exitosamente.');
        end);
      end;

      409:
      begin
        Sincronizar(
        procedure
        begin
          MessageDlg('Información', 'Ya existe un usuario registrado con el mismo correo electrónico.');
        end);
      end;

      500:
      begin
        Sincronizar(
        procedure
        begin
          MessageDlg('Error', 'No se pudo conectar con el servidor.');
        end);
      end;

      else
      begin
        Sincronizar(
        procedure
        begin
          MessageDlg('Información', 'No fue posible realizar el registro en este momento.');
        end);
      end;
    end;
  end);

  Thread.FreeOnTerminate:= True;
  Thread.OnTerminate:= ThreadOnTerminate;
  Thread.Start;
end;

class procedure TAcciones_Registro.BtnSelecFotoUsr_RegistroClick(
  Sender: TObject);
begin
  TIPO_FOTO:= 1;
  frmMain.MVOpcionesFotoPerfil.ShowMaster;
end;

class procedure TAcciones_Registro.CamposKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: WideChar; Shift: TShiftState);
begin
  if Key = vkReturn then
  begin
    if Sender = frmMain.edtNombreUsr_Registro then
      MostrarTeclado(frmMain.edtApellidoP_Registro)
    else
    if Sender = frmMain.edtApellidoP_Registro then
      MostrarTeclado(frmMain.edtApellidoM_Registro)
    else
    if Sender = frmMain.edtApellidoM_Registro then
      MostrarTeclado(frmMain.edtEdad_Registro)
    else
    if Sender = frmMain.edtEdad_Registro then
      MostrarTeclado(frmMain.edtCorreo_Registro)
    else
    if Sender = frmMain.edtCorreo_Registro then
      MostrarTeclado(frmMain.edtClave_Registro)
    else
    if Sender = frmMain.edtClave_Registro then
      MostrarTeclado(frmMain.edtConfirmarClave_Registro)
    else
    if Sender = frmMain.edtConfirmarClave_Registro then
    begin
      if frmMain.btnRegistrarse_Registro.Enabled then
        frmMain.btnRegistrarse_RegistroClick(frmMain.btnRegistrarse_Registro);
    end;
  end;
end;

class procedure TAcciones_Registro.DatosChange(Sender: TObject);
begin
  frmMain.btnRegistrarse_Registro.Enabled:=
  not frmMain.edtNombreUsr_Registro.Text.Trim.IsEmpty and
  not frmMain.edtApellidoP_Registro.Text.Trim.IsEmpty and
  not frmMain.edtApellidoM_Registro.Text.Trim.IsEmpty and
  not frmMain.edtEdad_Registro.Text.Trim.IsEmpty      and
  not frmMain.edtCorreo_Registro.Text.Trim.IsEmpty    and
  not frmMain.edtClave_Registro.Text.Trim.IsEmpty     and
  not frmMain.edtCorreo_Registro.Text.Trim.Equals(frmMain.edtClave_Registro.Text.Trim)
  and (Length(frmMain.edtClave_Registro.Text.Trim) >= 8) and
  frmMain.edtClave_Registro.Text.Trim.Equals(frmMain.edtConfirmarClave_Registro.Text.Trim);

  if(not frmMain.edtClave_Registro.Text.Trim.IsEmpty and
  not frmMain.edtConfirmarClave_Registro.Text.Trim.IsEmpty) and
  (not frmMain.edtClave_Registro.Text.Trim.Equals(frmMain.edtConfirmarClave_Registro.Text.Trim)) then
  begin
    frmMain.lblClavesNoCoinciden_Registro.Visible:= True;
    frmMain.VSBxDatos_Registro.ViewportPosition:= TPointF.Create(0,
    frmMain.VSBxDatos_Registro.ContentBounds.Height);
  end else
  begin
    frmMain.lblClavesNoCoinciden_Registro.Visible:= False;
    frmMain.VSBxDatos_Registro.ViewportPosition:= TPointF.Create(0,
    frmMain.VSBxDatos_Registro.ContentBounds.Height);
  end;
end;

class procedure TAcciones_Registro.setCamposRegistroToDefault;
begin
  frmMain.rectMarcoFotoUsuario_Registro.Fill.Color:= $FFEAEAEA;
  frmMain.rectMarcoFotoUsuario_Registro.Width:= frmMain.LYFotoUsuario_Registro.Width / 3;
  frmMain.imgFotoUsuario_Registro.Visible:= False;
  frmMain.SVGFotoUsuarioDefault_Registro.Visible:= True;
  frmMain.edtNombreUsr_Registro.Text:= String.Empty;
  frmMain.edtApellidoP_Registro.Text:= String.Empty;
  frmMain.edtApellidoM_Registro.Text:= String.Empty;
  frmMain.edtEdad_Registro.Text:= String.Empty;
  frmMain.edtCorreo_Registro.Text:= String.Empty;
  frmMain.edtClave_Registro.Text:= String.Empty;
  frmMain.edtClave_Registro.Password:= True;
  frmMain.PasswordHidden_Registro.Visible:= True;
  frmMain.PasswordShown_Registro.Visible:= False;
  frmMain.edtConfirmarClave_Registro.Text:= string.Empty;
  frmMain.edtConfirmarClave_Registro.Password:= True;
  frmMain.PasswordHidden2_Registro.Visible:= True;
  frmMain.PasswordShown2_Registro.Visible:= False;
  frmMain.btnEliminarFotoUsuarioMVOpciones.Visible:= False;
end;

class procedure TAcciones_Registro.ThreadOnTerminate(Sender: TObject);
begin
  TInterlocked.Exchange(THREAD_IS_RUNNING, False);

  Encolar(
  procedure
  begin
    HideLoadingDialog;
  end);
end;

class procedure TAcciones_Registro.TomarFotoDeCamaraDidFinishTaking(
  Image: TBitmap);
begin
  case TIPO_FOTO of
    1:
    begin
      frmMain.rectMarcoFotoUsuario_Registro.Fill.Color:= TAlphaColors.Null;

      if Image.Height > Image.Width then
        frmMain.rectMarcoFotoUsuario_Registro.Width:= frmMain.LYFotoUsuario_Registro.Width / 3
      else
        frmMain.rectMarcoFotoUsuario_Registro.Width:= frmMain.LYFotoUsuario_Registro.Width / 2;

      frmMain.SVGFotoUsuarioDefault_Registro.Visible:= False;
      frmMain.imgFotoUsuario_Registro.Bitmap.Assign(Image);
      frmMain.imgFotoUsuario_Registro.Visible:= True;
      frmMain.btnEliminarFotoUsuarioMVOpciones.Visible:= True;
      OPCION_SELECCIONADA:= -1;
    end;

    2: TAcciones_MiCuenta.CambiarFotoPerfil(Image);
  end;
end;

{$IFDEF MSWINDOWS}
class procedure TAcciones_Registro.WinSeleccionarFotoDePerfil;
var
  OpenDialog: TOpenDialog;
  Image: TBitmap;
begin
  Image:= TBitmap.Create;
  OpenDialog:= TOpenDialog.Create(frmMain);
  OpenDialog.InitialDir:= TPath.GetPicturesPath;
  OpenDialog.Title:= 'Seleccionar foto de perfil';
  OpenDialog.Filter:= 'Archivos de imagen|*.png;*.bmp;*.jpg;*.jpeg';
  try
    try
      if OpenDialog.Execute then
      begin
        Image.LoadFromFile(OpenDialog.FileName);
        frmMain.rectMarcoFotoUsuario_Registro.Fill.Color:= TAlphaColors.Null;

        if Image.Height > Image.Width then
          frmMain.rectMarcoFotoUsuario_Registro.Width:= frmMain.LYFotoUsuario_Registro.Width / 3
        else
          frmMain.rectMarcoFotoUsuario_Registro.Width:= frmMain.LYFotoUsuario_Registro.Width / 2;

        frmMain.SVGFotoUsuarioDefault_Registro.Visible:= False;
        frmMain.imgFotoUsuario_Registro.Bitmap.Assign(Image);
        frmMain.imgFotoUsuario_Registro.Visible:= True;
        //Importante hacer lo mismo desde la selección de la galería
        frmMain.btnEliminarFotoUsuarioMVOpciones.Visible:= True;
        frmMain.Invalidate;
      end;
    except on E: Exception do
      EscribirLog('UAcciones_Registro.WinSeleccionarFotoDePerfil: ' + E.Message, 2);
    end;
  finally
    FreeAndNil(Image);
    FreeAndNil(OpenDialog);
  end;
end;
{$ENDIF}

{$IFDEF ANDROID}
class procedure TAcciones_Registro.TomarImagenDeCamara_RequestResult(
  Sender: TObject; const APermissions: TClassicStringDynArray;
  const AGrantResults: TClassicPermissionStatusDynArray);
begin
  if (Length(AGrantResults) = 1) and (AGrantResults[0] = TPermissionStatus.Granted) then
    frmMain.TomarFotoDeCamara.Execute
  else
    GoToAppPermissionsSettings;
end;

class procedure TAcciones_Registro.TomarImagenDeGaleria_RequestResult(
  Sender: TObject; const APermissions: TClassicStringDynArray;
  const AGrantResults: TClassicPermissionStatusDynArray);
begin
  if (Length(AGrantResults) = 1) and (AGrantResults[0] = TPermissionStatus.Granted) then
    frmMain.TomarFotoDeGaleria.Execute
  else
    GoToAppPermissionsSettings;
end;

{$ENDIF}

end.

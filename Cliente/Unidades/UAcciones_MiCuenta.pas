unit UAcciones_MiCuenta;

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

type TAcciones_MiCuenta = class
  private
    class procedure LimpiarCamposMiCuenta;
    class procedure LimpiarCamposCambiarClave;
    class procedure ThreadOnTerminate(Sender: TObject);
  public
    class procedure MostrarInfo;
    class procedure btnAtras_MiCuentaClick(Sender: TObject);
    class procedure btnCancelarCambiarClaveClick(Sender: TObject);
    class procedure OcultarCuadroDialogo_CambiarClave;
    class procedure MostrarCuadroDialogo_CambiarClave;
    class procedure btnCambiarClave_MiCuentaClick(Sender: TObject);
    class procedure edtClaveActualCambiarClaveKeyDown(Sender: TObject;
    var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
    class procedure edtClaveNueva_CClaveKeyDown(Sender: TObject; var Key: Word;
    var KeyChar: WideChar; Shift: TShiftState);
    class procedure edtBtnPassClaveActual_CClaveClick(Sender: TObject);
    class procedure edtBtnPassClaveNueva_CClaveClick(Sender: TObject);
    class procedure btnPassConfirmar_CClaveClick(Sender: TObject);
    class procedure ValidarCoincidenciasClaves(Sender: TObject);
    class procedure btnCambiarClaveClick(Sender: TObject);
    class procedure btnEditarFotoUsr_MiCuentaClick(Sender: TObject);
    class procedure CambiarFotoPerfil(const Imagen: TBitmap);
    class procedure EliminarFotoPerfil;
    class procedure edtConfirmarClave_CClaveKeyDown(Sender: TObject;
    var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
end;

implementation
uses
  UMain, Generales, System.SyncObjs, UJSONTool;

{ TAcciones_MiCuenta }

class procedure TAcciones_MiCuenta.btnAtras_MiCuentaClick(Sender: TObject);
begin
  try
    frmMain.Pantallas.ActiveTab:= frmMain.Principal;
  finally
    LimpiarCamposMiCuenta;
  end;
end;

class procedure TAcciones_MiCuenta.btnCambiarClaveClick(Sender: TObject);
var
  Thread: TThread;
begin
  ShowLoadingDialog;
  Thread:= TThread.CreateAnonymousThread(
  procedure
  var
    Correo, Clave, ClaveNueva: string;
  begin
    TInterlocked.Exchange(THREAD_IS_RUNNING, True);
    Sincronizar(
    procedure
    begin
      Correo:= Usuario.Correo;
      Clave:= frmMain.edtClaveActualCambiarClave.Text;
      ClaveNueva:= frmMain.edtClaveNueva_CClave.Text;
    end);

    case TJSONTool.CambiarClave(Correo, Clave, ClaveNueva) of
      200:
      begin
        Sincronizar(
        procedure
        begin
          frmMain.rectFondoCambiarClave.Visible:= False;
          frmMain.Pantallas.ActiveTab:= frmMain.Login;
        end);

        MessageDlg('Información', 'La contraseña se cambió con éxito, ' +
        'inicie sesión nuevamente.');
      end;

      204: MessageDlg('Información', 'La contraseña ingresada es incorrecta.');

      401: MessageDlg('Información', 'No hay datos válidos en la solicitud.');

      423:
      begin
        OcultarCuadroDialogo_CambiarClave;
        UsuarioBloqueado;
      end;

      503: MessageDlg('Información', 'Ocurrió un error en el servidor al intentar ' +
      'procesar la solicitud.');
    end;
  end);
  Thread.FreeOnTerminate:= True;
  Thread.OnTerminate:= ThreadOnTerminate;
  Thread.Start;
end;

class procedure TAcciones_MiCuenta.btnCambiarClave_MiCuentaClick(
  Sender: TObject);
begin
  TAcciones_MiCuenta.MostrarCuadroDialogo_CambiarClave;
end;

class procedure TAcciones_MiCuenta.btnCancelarCambiarClaveClick(
  Sender: TObject);
begin
  OcultarCuadroDialogo_CambiarClave;
end;

class procedure TAcciones_MiCuenta.btnEditarFotoUsr_MiCuentaClick(
  Sender: TObject);
begin
  TIPO_FOTO:= 2;
  frmMain.MVOpcionesFotoPerfil.ShowMaster;
end;

class procedure TAcciones_MiCuenta.btnPassConfirmar_CClaveClick(
  Sender: TObject);
var
  Edt: TEdit;
begin
  Edt:= frmMain.edtConfirmarClave_CClave;
  Edt.Password:= not Edt.Password;
  frmMain.SVGPswHiddenConfirm_CClave.Visible:= Edt.Password;
  frmMain.SVGPswShownConfirm_CClave.Visible:= not Edt.Password;
end;

class procedure TAcciones_MiCuenta.CambiarFotoPerfil(const Imagen: TBitmap);
var
  Thread: TThread;
  Copia: TBitmap;
begin
  Copia:= TBitmap.Create;
  Copia.Assign(Imagen);

  ShowLoadingDialog;
  Thread:= TThread.CreateAnonymousThread(
  procedure
  var
    Foto: TMemoryStream;
    Base64Foto: string;
    Resp: Integer;
  begin
    TInterlocked.Exchange(THREAD_IS_RUNNING, True);

    Foto:= TMemoryStream.Create;
    Foto.Position:= 0;
    try
      Copia.SaveToStream(Foto);
      Base64Foto:= MemoryStreamToBase64String(Foto);
    finally
      FreeAndNil(Foto);
    end;

    Resp:= TJSONTool.CambiarFotoPerfil(Usuario.Correo, Base64Foto);
    case Resp of
      200:
      begin
        Sincronizar(
        procedure
        {$IFDEF ANDROID}
        var
          Toast: JToast;
        {$ENDIF}
        begin
          frmMain.imgFotoPerfilUsuario.Bitmap.Assign(Copia);
          frmMain.btnEliminarFotoUsuarioMVOpciones.Visible:= True;
          frmMain.rectFotoUsr_MiCuenta.Fill.Color:= TAlphaColors.Null;

          if Copia.Height > Copia.Width then
            frmMain.rectFotoUsr_MiCuenta.Width:= frmMain.LYCntFotoUsr_MiCuenta.Width /3
          else
            frmMain.rectFotoUsr_MiCuenta.Width:= frmMain.LYCntFotoUsr_MiCuenta.Width /2;

          frmMain.SVGFotoDefault_MiCuenta.Visible:= False;
          frmMain.imgFotoUsr_MiCuenta.Bitmap.Assign(Copia);
          frmMain.imgFotoUsr_MiCuenta.Visible:= True;
          frmMain.btnEliminarFotoUsuarioMVOpciones.Visible:= True;

          {$IFDEF ANDROID}
          Toast:= TJToast.JavaClass.makeText(TAndroidHelper.Context,
          StrToJCharSequence('Se actualizó la foto del perfil.'),
          TJToast.JavaClass.LENGTH_SHORT);
          Toast.setGravity(TJGravity.JavaClass.CENTER, 0, 0);
          Toast.show;
          {$ENDIF}
          {$IFDEF MSWINDOWS}
          ShowMessage('Se actualizó la foto del perfil.');
          {$ENDIF}
        end);
        Usuario.Foto:= Base64Foto;
      end;

      423: UsuarioBloqueado;

      else
      begin
        EscribirLog('UAcciones_MiCuenta.CambiarFotoPerfil: No fue posible ' +
        'cambiar la foto del perfil del usuario, el webservice respondió con ' +
        'un código de estatus: ' + Resp.ToString);
        Sincronizar(
        procedure
        {$IFDEF ANDROID}
        var
          Toast: JToast;
        {$ENDIF}
        begin
          {$IFDEF ANDROID}
          Toast:= TJToast.JavaClass.makeText(TAndroidHelper.Context,
          StrToJCharSequence('No fue posible actualizar la foto del perfil.'),
          TJToast.JavaClass.LENGTH_SHORT);
          Toast.setGravity(TJGravity.JavaClass.CENTER, 0, 0);
          Toast.show;
          {$ENDIF}
          {$IFDEF MSWINDOWS}
          ShowMessage('No fue posible actualizar la foto del perfil.');
          {$ENDIF}
        end);
      end;
    end;

    TInterlocked.Exchange(TIPO_FOTO, -1);

    if Copia <> nil then
        FreeAndNil(Copia);
  end);
  Thread.FreeOnTerminate:= True;
  Thread.OnTerminate:= ThreadOnTerminate;
  Thread.Start;
end;

class procedure TAcciones_MiCuenta.edtBtnPassClaveActual_CClaveClick(
  Sender: TObject);
var
  Edt: TEdit;
begin
  Edt:= frmMain.edtClaveActualCambiarClave;
  Edt.Password:= not Edt.Password;
  frmMain.SVGPswHiddenActual_CClave.Visible:= Edt.Password;
  frmMain.SVGPswShownActual_CClave.Visible:= not Edt.Password;
end;

class procedure TAcciones_MiCuenta.edtBtnPassClaveNueva_CClaveClick(
  Sender: TObject);
var
  Edt: TEdit;
begin
  Edt:= frmMain.edtClaveNueva_CClave;
  Edt.Password:= not Edt.Password;
  frmMain.SVGPswHiddenNueva_CClave.Visible:= Edt.Password;
  frmMain.SVGPswShownNueva_CClave.Visible:= not Edt.Password;
end;

class procedure TAcciones_MiCuenta.edtClaveActualCambiarClaveKeyDown(
  Sender: TObject; var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
begin
  if Key = vkReturn then
    MostrarTeclado(frmMain.edtClaveNueva_CClave);
end;

class procedure TAcciones_MiCuenta.edtClaveNueva_CClaveKeyDown(Sender: TObject;
  var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
begin
  if Key = vkReturn then
    MostrarTeclado(frmMain.edtConfirmarClave_CClave);
end;

class procedure TAcciones_MiCuenta.edtConfirmarClave_CClaveKeyDown(
  Sender: TObject; var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
begin
  if Key = vkReturn then
  begin
    if frmMain.btnCambiarClave.Enabled then
      frmMain.btnCambiarClaveClick(frmMain.btnCambiarClave);
  end;
end;

class procedure TAcciones_MiCuenta.EliminarFotoPerfil;
var
  Thread: TThread;
begin
  ShowLoadingDialog;
  Thread:= TThread.CreateAnonymousThread(
  procedure
  var
    Resp: Integer;
  begin
    TInterlocked.Exchange(THREAD_IS_RUNNING, True);

    //Parámetro foto se manda como "vacío" para eliminar la foto de perfil
    Resp:= TJSONTool.CambiarFotoPerfil(Usuario.Correo, string.Empty);
    case Resp of
      200:
      begin
        Sincronizar(
        procedure
        {$IFDEF ANDROID}
        var
          Toast: JToast;
        {$ENDIF}
        begin
          frmMain.btnEliminarFotoUsuarioMVOpciones.Visible:= False;
          frmMain.rectFotoUsr_MiCuenta.Width:= frmMain.LYCntFotoUsr_MiCuenta.Width / 3;
          frmMain.rectFotoUsr_MiCuenta.Fill.Color:= $FFEAEAEA;
          frmMain.imgFotoUsr_MiCuenta.Visible:= False;
          frmMain.imgFotoUsr_MiCuenta.Bitmap:= nil;
          frmMain.SVGFotoDefault_MiCuenta.Visible:= True;
          frmMain.imgFotoPerfilUsuario.Bitmap:= frmMain.imgUsuario_Default.Bitmap;

          {$IFDEF ANDROID}
          Toast:= TJToast.JavaClass.makeText(TAndroidHelper.Context,
          StrToJCharSequence('Se eliminó la foto del perfil.'),
          TJToast.JavaClass.LENGTH_SHORT);
          Toast.setGravity(TJGravity.JavaClass.CENTER, 0, 0);
          Toast.show;
          {$ENDIF}
          {$IFDEF MSWINDOWS}
          ShowMessage('Se eliminó la foto del perfil.');
          {$ENDIF}
        end);
        Usuario.Foto:= string.Empty;
      end;

      423: UsuarioBloqueado;

      else
      begin
        EscribirLog('UAcciones_MiCuenta.EliminarFotoPerfil: No fue posible ' +
        'eliminar la foto del perfil del usuario, el webservice respondió con ' +
        'un código de estatus: ' + Resp.ToString);
        Sincronizar(
        procedure
        {$IFDEF ANDROID}
        var
          Toast: JToast;
        {$ENDIF}
        begin
          {$IFDEF ANDROID}
          Toast:= TJToast.JavaClass.makeText(TAndroidHelper.Context,
          StrToJCharSequence('No fue posible eliminar la foto del perfil.'),
          TJToast.JavaClass.LENGTH_SHORT);
          Toast.setGravity(TJGravity.JavaClass.CENTER, 0, 0);
          Toast.show;
          {$ENDIF}
          {$IFDEF MSWINDOWS}
          ShowMessage('No fue posible eliminar la foto del perfil.');
          {$ENDIF}
        end);
      end;
    end;

    TInterlocked.Exchange(TIPO_FOTO, -1);
  end);
  Thread.FreeOnTerminate:= True;
  Thread.OnTerminate:= ThreadOnTerminate;
  Thread.Start;
end;

class procedure TAcciones_MiCuenta.LimpiarCamposCambiarClave;
begin
  frmMain.edtClaveActualCambiarClave.Text:= string.Empty;
  frmMain.edtClaveActualCambiarClave.Password:= True;
  frmMain.SVGPswShownActual_CClave.Visible:= False;
  frmMain.SVGPswHiddenActual_CClave.Visible:= True;

  frmMain.edtClaveNueva_CClave.Text:= string.Empty;
  frmMain.edtClaveNueva_CClave.Password:= True;
  frmMain.SVGPswShownNueva_CClave.Visible:= False;
  frmMain.SVGPswHiddenNueva_CClave.Visible:= True;

  frmMain.edtConfirmarClave_CClave.Text:= string.Empty;
  frmMain.edtConfirmarClave_CClave.Password:= True;
  frmMain.SVGPswShownConfirm_CClave.Visible:= False;
  frmMain.SVGPswHiddenConfirm_CClave.Visible:= True;
end;

class procedure TAcciones_MiCuenta.LimpiarCamposMiCuenta;
begin
  frmMain.edtNombre_MiCuenta.Text:= string.Empty;
  frmMain.edtApellidoP_MiCuenta.Text:= string.Empty;
  frmMain.edtApellidoM_MiCuenta.Text:= string.Empty;
  frmMain.edtEdad_MiCuenta.Text:= string.Empty;
  frmMain.edtCorreoE_MiCuenta.Text:= string.Empty;
end;

class procedure TAcciones_MiCuenta.MostrarCuadroDialogo_CambiarClave;
begin
  Sincronizar(
  procedure
  begin
    LimpiarCamposCambiarClave;
    frmMain.rectFondoCambiarClave.Visible:= True;
    frmMain.rectFondoCambiarClave.BringToFront;
  end);
end;

class procedure TAcciones_MiCuenta.MostrarInfo;
var
  Image: TBitmap;
begin
  try
    frmMain.edtNombre_MiCuenta.Text:= Usuario.Nombre;
    frmMain.edtApellidoP_MiCuenta.Text:= Usuario.Apellido_P;
    frmMain.edtApellidoM_MiCuenta.Text:= Usuario.Apellido_M;
    frmMain.edtEdad_MiCuenta.Text:= Usuario.Edad;
    frmMain.edtCorreoE_MiCuenta.Text:= Usuario.Correo;
    if not Usuario.Foto.Trim.IsEmpty then
    begin
      frmMain.btnEliminarFotoUsuarioMVOpciones.Visible:= True;
      Image:= Base64ToBitmap(Usuario.Foto);
      try
        frmMain.rectFotoUsr_MiCuenta.Fill.Color:= TAlphaColors.Null;

        if Image.Height > Image.Width then
          frmMain.rectFotoUsr_MiCuenta.Width:= frmMain.LYCntFotoUsr_MiCuenta.Width / 3
        else
          frmMain.rectFotoUsr_MiCuenta.Width:= frmMain.LYCntFotoUsr_MiCuenta.Width / 2;

        frmMain.SVGFotoDefault_MiCuenta.Visible:= False;
        frmMain.imgFotoUsr_MiCuenta.Bitmap.Assign(Image);
        frmMain.imgFotoUsr_MiCuenta.Visible:= True;
      finally
        FreeAndNil(Image);
      end;
    end
    else
    begin
      frmMain.btnEliminarFotoUsuarioMVOpciones.Visible:= False;
      frmMain.rectFotoUsr_MiCuenta.Fill.Color:= $FFEAEAEA;
      frmMain.rectFotoUsr_MiCuenta.Width:= frmMain.LYCntFotoUsr_MiCuenta.Width / 3;
      frmMain.imgFotoUsr_MiCuenta.Visible:= False;
      frmMain.imgFotoUsr_MiCuenta.Bitmap:= nil;
      frmMain.SVGFotoDefault_MiCuenta.Visible:= True;
    end;
  finally
    frmMain.Pantallas.ActiveTab:= frmMain.Mi_Cuenta;
  end;
end;

class procedure TAcciones_MiCuenta.OcultarCuadroDialogo_CambiarClave;
begin
  Sincronizar(
  procedure
  begin
    frmMain.rectFondoCambiarClave.Visible:= False;
    LimpiarCamposCambiarClave;
  end);
end;

class procedure TAcciones_MiCuenta.ThreadOnTerminate(Sender: TObject);
begin
  TInterlocked.Exchange(THREAD_IS_RUNNING, False);

  Encolar(
  procedure
  begin
    HideLoadingDialog;
  end);
end;

class procedure TAcciones_MiCuenta.ValidarCoincidenciasClaves(Sender: TObject);
var
  Coinciden: Boolean;
begin
  Coinciden:= frmMain.edtClaveNueva_CClave.Text.Trim.Equals(
  frmMain.edtConfirmarClave_CClave.Text.Trim);

  frmMain.lblCoincidenciaClavesCambiarClave.Visible:= not Coinciden;
  frmMain.btnCambiarClave.Enabled:= (Coinciden) and
  (not frmMain.edtClaveActualCambiarClave.Text.Trim.IsEmpty) and
  (not frmMain.edtClaveNueva_CClave.Text.Trim.IsEmpty) and
  (not frmMain.edtConfirmarClave_CClave.Text.Trim.IsEmpty);
end;

end.

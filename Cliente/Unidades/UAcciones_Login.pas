unit UAcciones_Login;

interface
uses
  ECategoria,
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
  FMX.MediaLibrary, FMX.Objects, FMX.DialogService, System.SyncObjs,
  FMX.Layouts, FMX.Controls.Presentation, FMX.Edit, FMX.StdCtrls;

 type TAcciones_Login = class
   private
    class procedure ThreadOnTerminate(Sender: TObject);
    class procedure CargarCategorias(var Categorias: TArray<rCategoria>);
    class procedure setCamposLoginToDefault;
   public
    class procedure btnConfiguraciones_LoginClick(Sender: TObject);
    class procedure SKLblRegistrarse_LoginWords1Click(Sender: TObject);
    class procedure btnIniciarSesion_LoginClick(Sender: TObject);
    class procedure CamposChangeTracking(Sender: TObject);
    class procedure btnHideOrShowPassword_LoginClick(Sender: TObject);
    class procedure edtCorreo_LoginKeyDown(Sender: TObject; var Key: Word;
    var KeyChar: WideChar; Shift: TShiftState);
    class procedure edtClave_LoginKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: WideChar; Shift: TShiftState);
 end;

implementation
uses
  UMain, Generales, UAcciones_Configuraciones, UAcciones_Registro,
  EUsuario, UJSONTool;

{ TAcciones_Login }

class procedure TAcciones_Login.btnConfiguraciones_LoginClick(Sender: TObject);
begin
  TAcciones_Configuraciones.LoadSettings;
  frmMain.Pantallas.ActiveTab:= frmMain.Configuraciones;
end;

class procedure TAcciones_Login.btnHideOrShowPassword_LoginClick(
  Sender: TObject);
begin
  frmMain.edtClave_Login.Password:= not frmMain.edtClave_Login.Password;
  frmMain.SVGPasswordHidden_Login.Visible:= frmMain.edtClave_Login.Password;
  frmMain.SVGPasswordShown_Login.Visible:= not frmMain.edtClave_Login.Password;
end;

class procedure TAcciones_Login.btnIniciarSesion_LoginClick(Sender: TObject);
var
  Thread: TThread;
begin
  ShowLoadingDialog;

  Thread:= TThread.CreateAnonymousThread(
  procedure
  var
    Categorias: TArray<rCategoria>;
    MSBuffer: TMemoryStream;
  begin
    TInterlocked.Exchange(THREAD_IS_RUNNING, True);
    Usuario:= TJSONTool.IniciarSesion(frmMain.edtCorreo_Login.Text.Trim,
    frmMain.edtClave_Login.Text);

    case Usuario.Respuesta of
      200:
      begin
        Categorias:= TJSONTool.ObtenerCategorias;
        try
          CargarCategorias(Categorias);
        finally
          SetLength(Categorias, 0);
        end;


        if not Usuario.Foto.IsEmpty then
        begin
          MSBuffer:= Base64StringToMemoryStream(Usuario.Foto);
          try
            if Assigned(MSBuffer) then
            begin
              Sincronizar(
              procedure
              begin
                frmMain.imgFotoPerfilUsuario.Bitmap.LoadFromStream(MSBuffer);
              end);
            end;
          finally
            if Assigned(MSBuffer) then
              FreeAndNil(MSBuffer);
          end;
        end
        else
        begin
          Sincronizar(
          procedure
          begin
            frmMain.imgFotoPerfilUsuario.Bitmap:= frmMain.imgUsuario_Default.Bitmap;
          end);
        end;

        Sincronizar(
        procedure
        begin
          frmMain.lblBienvenida_Principal.Text:= '¡Bienvenid@ de nuevo, ' + Usuario.Nombre + '!';
          frmMain.lblNombreUsuarioMVOpciones.Text:= Usuario.Nombre + ' ' +
          Usuario.Apellido_P + ' ' + Usuario.Apellido_M;
          frmMain.lblCorreoMVOpciones.Text:= Usuario.Correo;

          frmMain.Pantallas.ActiveTab:= frmMain.Principal;
          setCamposLoginToDefault;
        end);
      end;

      204:  MessageDlg('Información', 'Usuario/contraseña no válidos.');

      423:  MessageDlg('Información', 'Su cuenta está bloqueada, contacte ' +
      'con el administrador para mayor información.');

      500:  MessageDlg('Error', 'Error de conexión con el servidor.');

      else  MessageDlg('Información', 'No es posible iniciar sesión en este momento.');
    end;
  end);

  Thread.FreeOnTerminate:= True;
  Thread.OnTerminate:= ThreadOnTerminate;
  {$IFDEF MSWINDOWS}
  Thread.Priority:= tpHigher;
  {$ENDIF}
  Thread.Start;
end;

class procedure TAcciones_Login.CamposChangeTracking(Sender: TObject);
begin
  frmMain.btnIniciarSesion_Login.Enabled:=
  not frmMain.edtCorreo_Login.Text.Trim.IsEmpty   and
  not frmMain.edtClave_Login.Text.Trim.IsEmpty    and
  frmMain.edtCorreo_Login.Text.Contains('@')      and
  frmMain.edtCorreo_Login.Text.Contains('.')      and
  (Length(frmMain.edtClave_Login.Text.Trim) >= 8) and
  (Length(frmMain.edtCorreo_Login.Text.Trim) > 2);
end;

class procedure TAcciones_Login.CargarCategorias(var Categorias: TArray<rCategoria>);
var
  Cat: rCategoria;
begin
  if Length(Categorias) > 0 then
  begin
    Sincronizar(
    procedure
    begin
      frmMain.CBECategorias_Principal.Text:= string.Empty;
      frmMain.CBECategorias_Principal.Items.Clear;
      frmMain.CBECategorias_Principal.ItemIndex:= -1;

      frmMain.CBECategorias_Principal.BeginUpdate;
    end);

    for Cat in Categorias do
    begin
      Sincronizar(
      procedure
      begin
        frmMain.CBECategorias_Principal.Items.Add(Cat.Descripcion);
      end);
    end;

    Sincronizar(
    procedure
    begin
      frmMain.CBECategorias_Principal.EndUpdate;
    end);
  end else
  begin
    Sincronizar(
    procedure
    begin
      frmMain.CBECategorias_Principal.Text:= string.Empty;
      frmMain.CBECategorias_Principal.Items.Clear;
      frmMain.CBECategorias_Principal.ItemIndex:= -1;
    end);
  end;
end;

class procedure TAcciones_Login.edtClave_LoginKeyDown(Sender: TObject;
  var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
begin
  if (Key = vkReturn) and (frmMain.btnIniciarSesion_Login.Enabled = True) then
    frmMain.btnIniciarSesion_LoginClick(frmMain.btnIniciarSesion_Login);
end;

class procedure TAcciones_Login.edtCorreo_LoginKeyDown(Sender: TObject;
  var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
begin
  if Key = vkReturn then
    MostrarTeclado(frmMain.edtClave_Login);
end;

class procedure TAcciones_Login.setCamposLoginToDefault;
begin
  frmMain.edtCorreo_Login.Text:= string.Empty;
  frmMain.edtClave_Login.Text:= string.Empty;
  frmMain.edtClave_Login.Password:= True;
  frmMain.SVGPasswordShown_Login.Visible:= False;
  frmMain.SVGPasswordHidden_Login.Visible:= True;
end;

class procedure TAcciones_Login.SKLblRegistrarse_LoginWords1Click(
  Sender: TObject);
begin
  TAcciones_Registro.setCamposRegistroToDefault;
  frmMain.Pantallas.ActiveTab:= frmMain.Registro;
end;

class procedure TAcciones_Login.ThreadOnTerminate(Sender: TObject);
begin
  TInterlocked.Exchange(THREAD_IS_RUNNING, False);

  Encolar(
  procedure
  begin
    HideLoadingDialog;
  end);
end;

end.

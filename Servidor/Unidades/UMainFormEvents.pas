unit UMainFormEvents;

interface
uses
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.MySQL, FireDAC.Phys.MySQLDef, FireDAC.FMXUI.Wait,
  FireDAC.Stan.Param, FireDAC.DApt, Winapi.Windows,
  Data.DB, FireDAC.Comp.Client, FMX.ComboEdit,
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects, FMX.Menus, FMX.MultiView,
  FMX.Layouts, FMX.ListBox, FMX.ExtCtrls, FMX.TabControl, System.Actions, System.UIConsts,
  FMX.ActnList, FMX.Edit, System.Rtti, FMX.Grid.Style, FMX.ScrollBox, FMX.Grid,
  System.Skia, FMX.Skia, IdHTTPWebBrokerBridge, IdGlobal, Web.HTTPApp, FMX.DialogService;

type TMainFormEvents = class
  private
    class procedure DatabaseProcessOnTerminate(Sender: TObject);
    class procedure SimularPulsacion(const Tecla: Word);
    class procedure ComboEditClick(Sender: TObject);
    class procedure setComboEditClick(const AOwner: TForm);
    class procedure NewOnEnter(Sender: TObject); //DRH 08/10/2025
    class procedure FixOnEnter(AOwner: TForm);
  public
    class procedure FormCreate(Sender: TObject);
    class procedure btnOkMessageDlgClick(Sender: TObject);
    class procedure FormDestroy(Sender: TObject);
    class procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    class procedure FormResize(Sender: TObject);
    class procedure FormKeyDown(Sender: TObject; var Key: Word;
    var KeyChar: WideChar; Shift: TShiftState);
    class procedure FormFocusChanged(Sender: TObject);
end;

implementation
uses
  FMX.Memo,
  UMain, Generales, UAcciones_Pantallas, Estilos, ECategoria,
  System.IOUtils, UAcciones_Inicio, DBActions, System.SyncObjs,
  UAcciones_Configuraciones;

{ TMainFormEvents }

class procedure TMainFormEvents.btnOkMessageDlgClick(Sender: TObject);
begin
  frmMain.MessageDialog.Visible:= False;
end;

class procedure TMainFormEvents.ComboEditClick(Sender: TObject);
begin
  if Sender <> nil then
    TComboEdit(Sender).DropDown;
end;

class procedure TMainFormEvents.DatabaseProcessOnTerminate(Sender: TObject);
begin
  TInterlocked.Exchange(THREAD_IS_RUNNING, False);
end;

class procedure TMainFormEvents.FixOnEnter(AOwner: TForm);
var
  i: Integer;
begin
  for i:= 0 to AOwner.ComponentCount - 1 do
  begin
    if AOwner.Components[i].ClassType = TMemo then
    begin
      if not Assigned(TMemo(AOwner.Components[i]).OnEnter) then
        TMemo(AOwner.Components[i]).OnEnter:= NewOnEnter;
    end
    else
    if AOwner.Components[i].ClassType = TEdit then
    begin
      if not Assigned(TEdit(AOwner.Components[i]).OnEnter) then
        TEdit(AOwner.Components[i]).OnEnter:= NewOnEnter;
    end;
  end;
end;

class procedure TMainFormEvents.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
var
  Mensaje: string;
begin
  if not THREAD_IS_RUNNING then
  begin
    (*
      Recuperar el foco en alguno de estos campos de texto al
      confirmar el cierre de la aplicación, provoca errores de
      acceso de memoria
    *)
    frmMain.edtPuertoServidor.OnExit:= nil;
    frmMain.edtBuscarLibro.OnEnter:= nil;

    CanClose:= False;
    Mensaje:= '¿Salir de la aplicación?';
    TDialogService.MessageDialog(Mensaje, TMsgDlgType.mtWarning,
    [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], TMsgDlgBtn.mbYes, 0,
    procedure(const AResult: TModalResult)
    begin
      case AResult of
        mrYes:
        begin
          (*
            Establecer el evento onExit del TEdit del puerto del servidor,
            evita un error de acceso múltiple al ejecutar de forma asíncrónica
            los bloques de instrucciones del TSwitch de activación del servidor
            [--Su activación se da en el evento onExit del TEdit que indica el puerto]
          *)
          frmMain.ConexionGUI.Connected:= False;
          Application.Terminate;
        end;

        mrNo:
        begin
          frmMain.edtPuertoServidor.OnExit:= frmMain.edtPuertoServidorExit;
        end;
      end;
    end);
  end else CanClose:= False;
end;

class procedure TMainFormEvents.FormCreate(Sender: TObject);
var
  i: Integer;
  Thread: TThread;
  Def: IFDStanConnectionDef;
begin
  PDF_FileName:= string.Empty;
  LAST_LIBRO_SELECTED:= -1;
  LAST_USUARIO_SELECTED:= -1;
  FLAG_SEARCHING_BOOK:= False;
  Semaforo:= TSemaphore.Create(nil, 50, 151, string.Empty);
  FUsingDB:= False;
  CriticalSection:= TCriticalSection.Create;
  XAMPP_PATH:= 'C:\xampp'; //Importante para crear los stored procedures
  (*
    ES MEJOR CREAR EL DRIVERLINK EN EL EVENTO ONCREATE DEL FORM
    PARA EVITAR PROBLEMAS EN MÓDULOS ESPECÍFICOS DEL PROGRAMA.
  *)
  frmMain.DriverLink:= TFDPhysMySQLDriverLink.Create(TForm(Sender));
  frmMain.DriverLink.DriverID:= 'MySQL';
  frmMain.DriverLink.VendorLib:= ExtractFileDir(ParamStr(0)) + PathDelim + 'libmysql.dll';

  FormatSettings.ShortDateFormat:= 'dd/mm/yyyy';
  THREAD_IS_RUNNING:= False;
  FLAG_MAKING_CHANGES:= False;
  ACCION_LIBROS:= 0; //1= INSERTAR 2= MODIFICAR
  LAST_CATEGORIA:= -1;
  LAST_ID_LIBRO:= string.Empty;
  frmMain.Pantallas.Enabled:= False;
  frmMain.RRctConfig_Opciones.Enabled:= False;
  frmMain.RRctInicio_Opciones.Enabled:= False;
  frmMain.RRctUsuarios_Opciones.Enabled:= False;
  frmMain.btnNotificaciones.Enabled:= False;

  frmMain.FServer := TIdHTTPWebBrokerBridge.Create(frmMain);

  (*
    Esto evita que las configuraciones en tiempo de diseño del header del stringGrid de
    los libros se muestre mientras se establece el header personalizado (UnidadEstilos).
  *)
  for i:= 0 to frmMain.SGLibros_Inicio.ColumnCount - 1 do
  begin
    frmMain.SGLibros_Inicio.Columns[i].HeaderSettings.TextSettings.FontColor:=
    TAlphaColors.Null;
  end;

  (*
    El procedimiento setApplicationTheme contiene la lógica del
    diseño general de la interfaz de usuario de la aplicación.
  *)
  setApplicationTheme(Sender as TForm);
  TAcciones_Pantallas.DefaultPantallasConfig;

  if TDBActions.ValidarConfiguraciones then
  begin
    FDManager.Active := False; // Asegurarse de que esté inactivo antes de modificarlo
    FDManager.WaitCursor:= gcrSQLWait;
    Def := FDManager.ConnectionDefs.AddConnectionDef;
    Def.Name := 'LanBraryConnection';
    Def.Params.Values['DriverID'] := 'MySQL';
    Def.Params.Values['User_Name'] := DB_USER;
    Def.Params.Values['Password'] := DB_PASSWORD;
    Def.Params.Values['Server'] := DB_HOSTNAME;
    Def.Params.Values['Port'] := DB_PORT;
    Def.Params.Values['Database'] := 'lanbrary';
    Def.Params.Values['PoolSize'] := '151';
    Def.Params.Values['Pooled']:= 'true';
    FDManager.Active := True;

    Thread:= TThread.CreateAnonymousThread(
    procedure
    var
      Categorias: TArray<rCategoria>;
    begin
      TInterlocked.Exchange(THREAD_IS_RUNNING, True);

      if TDBActions.ConectarBD(frmMain.ConexionGUI) then
      begin
        Categorias:= TDBActions.ObtenerCategorias(frmMain.ConexionGUI);
        try
          Sincronizar(
          procedure
          begin
            TAcciones_Inicio.MostrarCategorias(Categorias);
          end);
        finally
          SetLength(Categorias, 0);
        end;

        //Inicializar todo después de conectar con la base de datos
        Sincronizar(
        procedure
        begin
          (***************************************************************
            DRH 12/11/2025
            -Una vez conectado a la base de datos, se cargarán todas las
            configuraciones complementarias que hacen posible un correcto
            funcionamiento del software.
          *)
          TAcciones_Configuraciones.LoadSettings;
          setComboEditClick(Sender as TForm);
          FixOnEnter(Sender as TForm);

          //Habilitar interfaz de usuario después de usar la base de datos
          frmMain.Pantallas.Enabled:= True;
          frmMain.RRctConfig_Opciones.Enabled:= True;
          frmMain.RRctInicio_Opciones.Enabled:= True;
          frmMain.RRctUsuarios_Opciones.Enabled:= True;
          frmMain.btnNotificaciones.Enabled:= True;
          frmMain.Caption:= 'LANBrary - panel de administración';

          //DRH 13/11/2025
          TAcciones_Inicio.LoadServerSettings;
        end);
      end else
      begin
        TInterlocked.Exchange(THREAD_IS_RUNNING, False);

        Sincronizar(
        procedure
        begin
          TDialogService.MessageDialog(
          'No fue posible conectarse a la base de datos.',
          TMsgDlgType.mtError, [TMsgDlgBtn.mbOK], TMsgDlgBtn.mbOK, 0,
          procedure (const AModalResut: TModalResult)
          begin
            Application.Terminate;
          end);
        end);
      end;
    end);

    Thread.FreeOnTerminate:= True;
    Thread.Priority:= tpHigher;
    Thread.OnTerminate:= DatabaseProcessOnTerminate;
    Thread.Start;
  end else
  begin
    TDialogService.MessageDialog(
    'No fue posible conectarse a la base de datos.',
    TMsgDlgType.mtError, [TMsgDlgBtn.mbOK], TMsgDlgBtn.mbOK, 0,
    procedure (const AModalResut: TModalResult)
    begin
      Application.Terminate;
    end);
  end;
end;

class procedure TMainFormEvents.FormDestroy(Sender: TObject);
begin
  if Assigned(frmMain.DriverLink) then
    FreeAndNil(frmMain.DriverLink);

  if Assigned(frmMain.FServer) then
  begin
    frmMain.FServer.Active:= False;
    frmMain.FServer.Bindings.Clear;
    FreeAndNil(frmMain.FServer);
  end;

  if Assigned(CriticalSection) then
    FreeAndNil(CriticalSection);

  if Assigned(Semaforo) then
    FreeAndNil(Semaforo);
end;

class procedure TMainFormEvents.FormFocusChanged(Sender: TObject);
begin
  if Assigned(TForm(Sender).Focused) and
  (TForm(Sender).Focused.GetObject <> frmMain.LVResultBusq_Libros) then
  begin
    if frmMain.LVResultBusq_Libros.IsVisible then
    begin
      frmMain.LVResultBusq_Libros.Visible:= False;
      frmMain.LVResultBusq_Libros.Items.Clear;
    end;
  end;
end;

class procedure TMainFormEvents.FormKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: WideChar; Shift: TShiftState);
var
  Dialog_Visible: Boolean;
begin
  if (key = vkUp) or (Key = vkDown) or (Key = vkLeft) or (Key = vkRight) then
  begin
    Dialog_Visible:= (frmMain.MessageDialog.IsVisible or
    frmMain.LoadingDialog.IsVisible);

    if (frmMain.Pantallas.ActiveTab = frmMain.Inicio)
    and (frmMain.Pantallas_Opciones.ActiveTab = frmMain.Libros) and
    (frmMain.SGLibros_Inicio.RowCount > 0) and
    (frmMain.SGLibros_Inicio.Selected > -1) and (not Dialog_Visible) then
    begin
      if not frmMain.SGLibros_Inicio.IsFocused then
      begin
        frmMain.SGLibros_Inicio.SetFocus;
        SimularPulsacion(Key);
      end;
    end
    else
    if (frmMain.Pantallas.ActiveTab = frmMain.Usuarios) and
    (frmMain.SGUsuarios.RowCount > 0) and (frmMain.SGUsuarios.Selected > -1)
    and (not Dialog_Visible) then
    begin
      if not frmMain.SGUsuarios.IsFocused then
      begin
        frmMain.SGUsuarios.SetFocus;
        SimularPulsacion(Key);
      end;
    end;
  end;
end;

class procedure TMainFormEvents.FormResize(Sender: TObject);
var
  Width1: Single;
  Busqueda_PosX, Busqueda_PosY: Single;
  (*
    Variable utilizada para establecer el ancho de cada
    columna del TStringGrid de la pantalla "Usuarios"
  *)
  Ancho_Usuarios: Single;
begin
  //DRH 07/10/2025
  //StringGrid "Libros"
  Width1:= frmMain.Width / 5;
  frmMain.SGLibros_Inicio.Columns[0].Width:= 2 * Width1;
  frmMain.SGLibros_Inicio.Columns[1].Width:= frmMain.SGLibros_Inicio.Columns[0].Width;
  frmMain.SGLibros_Inicio.Columns[2].Width:= frmMain.SGLibros_Inicio.Columns[0].Width;
  frmMain.SGLibros_Inicio.Columns[3].Width:= Width1;
  frmMain.SGLibros_Inicio.Columns[4].Width:= frmMain.SGLibros_Inicio.Columns[0].Width;

  //DRH 07/10/2025
  //StringGrid "Usuarios"
  Ancho_Usuarios:= frmMain.Width / 6;
  frmMain.SGUsuarios.Columns[0].Width:= Ancho_Usuarios * 2;
  frmMain.SGUsuarios.Columns[1].Width:= frmMain.SGUsuarios.Columns[0].Width;
  frmMain.SGUsuarios.Columns[2].Width:= frmMain.SGUsuarios.Columns[0].Width;
  frmMain.SGUsuarios.Columns[3].Width:= Ancho_Usuarios;
  frmMain.SGUsuarios.Columns[4].Width:= frmMain.SGUsuarios.Columns[0].Width;
  frmMain.SGUsuarios.Columns[5].Width:= frmMain.SGUsuarios.Columns[0].Width;

  Busqueda_PosX:= (frmMain.Pantallas_Opciones.Position.X +
  frmMain.rectInventario_Inicio.Position.X + frmMain.RectBuscar_Libro.Position.X);

  Busqueda_PosY:= (frmMain.Pantallas_Opciones.Position.Y +
  frmMain.rectInventario_Inicio.Position.Y + frmMain.LYBuscarLibro.Position.Y +
  frmMain.RectBuscar_Libro.Height + 5);

  frmMain.LVResultBusq_Libros.Position.X:= Busqueda_PosX;
  frmMain.LVResultBusq_Libros.Position.y:= Busqueda_PosY;
  frmMain.LVResultBusq_Libros.Width:= frmMain.RectBuscar_Libro.Width;

  (*
    --DRH 08/10/2025
    Hacer BeginUpdate y EndUpdate en el Form parecía una manera rápida y fácil
    de evitar el "parpadeo" en pantalla mientras se ejecuta este evento.
    Sin embargo, al intentar mostrar la pantalla de carga mientras se ejecuta,
    ésta no es visible.

    -Necesito buscar una manera de reducir el parpadeo en pantalla;
    -No urge así que de momento queda pospuesto a las etapas finales del
    desarrollo.
  *)
end;

class procedure TMainFormEvents.NewOnEnter(Sender: TObject);
begin
  if Sender is TEdit then
    (Sender as TEdit).GoToTextEnd
  else
  if Sender is TMemo then
    (Sender as TMemo).GoToTextEnd;
end;

class procedure TMainFormEvents.setComboEditClick(const AOwner: TForm);
var
  i: Integer;
begin
  for i:= 0 to AOwner.ComponentCount - 1 do
  begin
    if AOwner.Components[i].ClassType = TComboEdit then
    begin
      if (TComboEdit(AOwner.Components[i]).Name <> 'CECategoriasLibros')
      and (TComboEdit(AOwner.Components[i]).Name <> 'CEFiltro_Usuarios') then
        TComboEdit(AOwner.Components[i]).OnClick:= ComboEditClick;
    end;
  end;
end;

class procedure TMainFormEvents.SimularPulsacion(const Tecla: Word);
var
  Input: TInput;
begin
  ZeroMemory(@Input, SizeOf(TInput));
  Input.Itype := INPUT_KEYBOARD;
  Input.ki.wVk := Tecla;
  SendInput(1, Input, SizeOf(TInput));

  Input.ki.dwFlags := KEYEVENTF_KEYUP;
  SendInput(1, Input, SizeOf(TInput));
end;

end.

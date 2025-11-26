(*
  Autor: Daniel Rodriguez Hernandez
  Fecha: 26/11/2025
  --
  Delphi fue mi primer lenguaje de programación cuando tenía 17 años.
  Desde ese primer “Hola Mundo” en Borland Delphi 7, mis noches ya nunca fueron
  iguales — ahí comenzó esta hermosa aventura sin fin, una que siempre me
  sorprende con algo nuevo cada vez.

  Más adelante descubrí que Delphi también podía usarse para crear aplicaciones
  móviles y, honestamente, mi corazón explotó de emoción y de amor más que con
  cualquier mujer que me hubiera hecho sentir algo así jaja :P.

  Quiero cerrar esta nota agradeciendo a Delphi y a toda la comunidad de
  desarrolladores por estar siempre ahí cuando he tenido dudas, por hacer del
  desarrollo de software mi refugio en los momentos difíciles, y porque Delphi
  —junto con el esfuerzo de estudiarlo— literalmente ha puesto comida en la mesa.

  Un enorme agradecimiento a Embarcadero Tech por mantener vivo un lenguaje
  tan increíble y tan a la vanguardia. Espero que este y otros ejemplos que he
  compartido (y que seguiré compartiendo) les sean de ayuda a todos.
*)
unit UMain;

interface

uses
  IdHTTPWebBrokerBridge, IdGlobal, IdSSLOpenSSL,

  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, Winapi.Windows,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects, FMX.Menus, FMX.MultiView,
  FMX.Layouts, FMX.ListBox, FMX.ExtCtrls, FMX.TabControl, System.Actions,
  FMX.ActnList, FMX.Edit, System.Rtti, FMX.Grid.Style, FMX.ScrollBox, FMX.Grid,
  Web.HTTPApp, FMX.Platform, fmx.Platform.Win,
  System.Skia, FMX.Skia, FMX.Memo.Types, FMX.Memo, FMX.ComboEdit, DBActions,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.MySQL, FireDAC.Phys.MySQLDef, FireDAC.FMXUI.Wait,
  Data.DB, FireDAC.Comp.Client, FireDAC.DApt, FireDAC.Stan.Param, FireDAC.DatS,
  FireDAC.DApt.Intf, FireDAC.Comp.DataSet, FMX.ListView.Types, System.SyncObjs,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, FMX.ListView;

type
  TfrmMain = class(TForm)
    StyleBook1: TStyleBook;
    imgDefaultPortadaLibro: TImage;
    Popup: TPopupMenu;
    ConexionGUI: TFDConnection;
    LoadingDialog: TRectangle;
    rectLoadingDialog: TRectangle;
    IndicadorLoadingDialog: TSkAnimatedImage;
    MensajeLoadingDialog: TLabel;
    MessageDialog: TRectangle;
    rectMessageDlg: TRectangle;
    RectToolBarTituloMsgDlg: TRectangle;
    TituloMessageDlg: TLabel;
    LYBtnMsgDlg: TLayout;
    btnOkMessageDlg: TButton;
    MensajeMsgDlg: TLabel;
    Pantallas: TTabControl;
    Inicio: TTabItem;
    lblTituloInicio: TLabel;
    LYAccionesInicio: TLayout;
    SeparadorOp_Inicio: TLine;
    btnLibros_Inicio: TButton;
    rectIndicadorLibros_Inicio: TRectangle;
    btnServidor: TButton;
    rectIndicadorServidor: TRectangle;
    Pantallas_Opciones: TTabControl;
    Libros: TTabItem;
    rectInventario_Inicio: TRectangle;
    SGLibros_Inicio: TStringGrid;
    SCNombreLibro: TStringColumn;
    SGDescripcionLibro: TStringColumn;
    SCAutorLibro: TStringColumn;
    SCFechaLibro: TStringColumn;
    SCUsuarioLibro: TStringColumn;
    SCIdLibro: TStringColumn;
    SCIdCategoria: TIntegerColumn;
    lyNombreLibro: TLayout;
    lblTituloNombreLibro: TLabel;
    edtNombreLibro: TEdit;
    LYAutorLibro: TLayout;
    lblAutorLibro: TLabel;
    edtAutorLibro: TEdit;
    LYFechaLibro: TLayout;
    lblFechaLibro: TLabel;
    edtFechaLibro: TEdit;
    LYUsuarioLibro: TLayout;
    lblUsuarioLibro: TLabel;
    edtUsuarioLibro: TEdit;
    GpnlLYBtnsAccRegLibros: TGridPanelLayout;
    btnFirstLibro_Inicio: TButton;
    SVGFirstLibro_Inicio: TSkSvg;
    btnPriorLibro_Inicio: TButton;
    SVGPriorLibro_Inicio: TSkSvg;
    btnNextLibro_Inicio: TButton;
    SVGNextLibro_Inicio: TSkSvg;
    btnLastLibro_Inicio: TButton;
    SVGLastLibro_Inicio: TSkSvg;
    LYBuscarLibro: TLayout;
    RectBuscar_Libro: TRectangle;
    edtBuscarLibro: TEdit;
    SVGBuscarLibro: TSkSvg;
    LYCategorias_Libros: TLayout;
    CECategoriasLibros: TComboEdit;
    lblTituloCategoriasLibros: TLabel;
    CEFiltro_Libros: TComboEdit;
    LYDescripcionLibro: TLayout;
    lblTituloDescripcionLibro: TLabel;
    edtDescripcionLibro: TEdit;
    lblNoHayLibrosAMostrar_Libros: TLabel;
    LYComplementarioLibros: TLayout;
    rectAccionesLibros_Inicio: TRectangle;
    lblTituloAccionesLibros_Inicio: TLabel;
    rectEliminarLibro: TRoundRect;
    btnEliminarLibro: TButton;
    rectInsertarLibro: TRoundRect;
    btnInsertarLibro: TButton;
    rectModificarLibro: TRoundRect;
    btnModificarLibro: TButton;
    RectCancelarLibros: TRoundRect;
    btnCancelarLibros: TButton;
    rectPortadaLibros_Inicio: TRectangle;
    lblTituloPortadaLibro_Inicio: TLabel;
    imgPortadaLibro_Inicio: TImage;
    Servidor: TTabItem;
    rectFondoServidor_Inicio: TRectangle;
    LYEstadoServidor: TLayout;
    SWEstadoServidor: TSwitch;
    lblEstadoServidor: TLabel;
    LYUrlServidor: TLayout;
    rectInfoURLServidor: TRectangle;
    lblInfoURLServidor: TEdit;
    LYEdtURLServidor: TLayout;
    lblURLServidor: TLabel;
    edtURLServidor: TEdit;
    lblPuertoServidor: TLabel;
    edtPuertoServidor: TEdit;
    rectProbarServidor: TRectangle;
    btnProbarServidor: TButton;
    rectConfirmarPuertoServidor: TRectangle;
    btnConfirmarPuertoServidor: TButton;
    SVGConfirmarPuertoServidor: TSkSvg;
    lblTituloEventosServidor: TLabel;
    rectEventosServidor: TRectangle;
    mmoEventosServidor: TMemo;
    LVResultBusq_Libros: TListView;
    Usuarios: TTabItem;
    lblTitulo_Usuarios: TLabel;
    rectDatosUsuarios: TRectangle;
    LYFiltro_Usuarios: TLayout;
    CEFiltro_Usuarios: TComboEdit;
    lblFiltro_Usuarios: TLabel;
    LYBuscar_Usuarios: TLayout;
    rectBuscar_Usuarios: TRectangle;
    edtBuscar_Usuarios: TEdit;
    SVGBuscar_Usuarios: TSkSvg;
    LYNombre_Usuarios: TLayout;
    lblNombre_Usuarios: TLabel;
    edtNombre_Usuarios: TEdit;
    LyApellidoP_Usuarios: TLayout;
    lblApellidoP_Usuarios: TLabel;
    edtApellidoP_Usuarios: TEdit;
    LyApellidoM_Usuarios: TLayout;
    lblApellidoM_Usuario: TLabel;
    edtApellidoM_Usuarios: TEdit;
    LyEdad_Usuarios: TLayout;
    lblEdad_Usuarios: TLabel;
    edtEdad_Usuarios: TEdit;
    LyCorreo_Usuarios: TLayout;
    lblCorreo_Usuarios: TLabel;
    edtCorreo_Usuarios: TEdit;
    LyEstatus_Usuarios: TLayout;
    lblEstatus_Usuarios: TLabel;
    edtEstatus_Usuarios: TEdit;
    lblNoHayRegistrosParaMostrar_Usuarios: TLabel;
    SGUsuarios: TStringGrid;
    SCNombre_Usuarios: TStringColumn;
    SCApellidoP_Usuarios: TStringColumn;
    SCApellidoM_Usuarios: TStringColumn;
    SCEdad_Usuarios: TStringColumn;
    SCCorreo_Usuarios: TStringColumn;
    SCEstatus_Usuarios: TStringColumn;
    LYAccionesYFoto_Usuarios: TLayout;
    RectAcciones_Usuarios: TRectangle;
    lblTituloAcciones_Usuarios: TLabel;
    RREliminar_Usuarios: TRoundRect;
    btnEliminar_Usuarios: TButton;
    RRBloquear_Usuarios: TRoundRect;
    btnBloquear_Usuarios: TButton;
    rectFoto_Usuarios: TRectangle;
    lblTituloFoto_Usuarios: TLabel;
    imgFoto_Usuarios: TImage;
    rectOpcionesMenu: TRectangle;
    RRctInicio_Opciones: TRoundRect;
    btnInicio_Opciones: TButton;
    SVGInicio_Opciones: TSkSvg;
    lblInicio_Opciones: TLabel;
    RRctUsuarios_Opciones: TRoundRect;
    btnUsuarios_Opciones: TButton;
    SVGUsuarios_Opciones: TSkSvg;
    lblUsuarios_Opciones: TLabel;
    RRctConfig_Opciones: TRoundRect;
    btnConfig_Opciones: TButton;
    SVGConfig_Opciones: TSkSvg;
    lblConfig_Opciones: TLabel;
    rectToolBar: TRectangle;
    SVGIconoToolBar: TSkSvg;
    lblTituloToolBar: TLabel;
    btnNotificaciones: TButton;
    SVGNotificaciones: TSkSvg;
    SCId_Usuarios: TStringColumn;
    GPnlLyActns_Usuarios: TGridPanelLayout;
    btnFirst_Usuarios: TButton;
    SVGFirst_Usuarios: TSkSvg;
    btnPrior_Usuarios: TButton;
    SVGPrior_Usuarios: TSkSvg;
    btnNext_Usuarios: TButton;
    SVGNext_Usuarios: TSkSvg;
    btnLast_Usuarios: TButton;
    SVGLast_Usuarios: TSkSvg;
    ImgDefaultFotoUsuario: TImage;
    rectDescargarLibro: TRoundRect;
    btnDescargarLibro: TButton;
    Configuraciones: TTabItem;
    lblTituloConfiguraciones: TLabel;
    LYRutaDescargas_Configuraciones: TLayout;
    lblTituloRutaDescargas_Configuraciones: TLabel;
    edtRutaDescargas_Configuraciones: TEdit;
    rectSeleccionarRutaDesc_Configuraciones: TRectangle;
    btnSelecRutaDesc_Config: TButton;
    ChckBxUsarHTTPS: TCheckBox;
    procedure SGLibros_InicioApplyStyleLookup(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnOkMessageDlgClick(Sender: TObject);
    procedure SWEstadoServidorSwitch(Sender: TObject);
    procedure btnProbarServidorClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure edtPuertoServidorExit(Sender: TObject);
    procedure edtPuertoServidorEnter(Sender: TObject);
    procedure btnLibros_InicioClick(Sender: TObject);
    procedure btnServidorClick(Sender: TObject);
    procedure btnInicio_OpcionesClick(Sender: TObject);
    procedure btnUsuarios_OpcionesClick(Sender: TObject);
    procedure btnResumen_OpcionesClick(Sender: TObject);
    procedure btnConfig_OpcionesClick(Sender: TObject);
    procedure btnInsertarLibroClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure CECategoriasLibrosChange(Sender: TObject);
    procedure edtPuertoServidorChangeTracking(Sender: TObject);
    procedure btnConfirmarPuertoServidorClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure btnCancelarLibrosClick(Sender: TObject);
    procedure SGLibros_InicioSelChanged(Sender: TObject);
    procedure btnFirstLibro_InicioClick(Sender: TObject);
    procedure btnPriorLibro_InicioClick(Sender: TObject);
    procedure btnNextLibro_InicioClick(Sender: TObject);
    procedure btnLastLibro_InicioClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: WideChar;
      Shift: TShiftState);
    procedure Pantallas_OpcionesChange(Sender: TObject);
    procedure btnModificarLibroClick(Sender: TObject);
    procedure btnEliminarLibroClick(Sender: TObject);
    procedure CECategoriasLibrosClick(Sender: TObject);
    procedure FormFocusChanged(Sender: TObject);
    procedure LVResultBusq_LibrosItemClick(const Sender: TObject;
      const AItem: TListViewItem);
    procedure edtNombreLibroChangeTracking(Sender: TObject);
    procedure CEFiltro_LibrosChange(Sender: TObject);
    procedure edtBuscarLibroTyping(Sender: TObject);
    procedure edtNombreLibroKeyDown(Sender: TObject; var Key: Word;
      var KeyChar: WideChar; Shift: TShiftState);
    procedure CEFiltro_UsuariosClick(Sender: TObject);
    procedure CEFiltro_UsuariosChange(Sender: TObject);
    procedure SGUsuariosSelChanged(Sender: TObject);
    procedure btnFirst_UsuariosClick(Sender: TObject);
    procedure btnPrior_UsuariosClick(Sender: TObject);
    procedure btnNext_UsuariosClick(Sender: TObject);
    procedure btnLast_UsuariosClick(Sender: TObject);
    procedure btnEliminar_UsuariosClick(Sender: TObject);
    procedure btnBloquear_UsuariosClick(Sender: TObject);
    procedure edtBuscar_UsuariosKeyDown(Sender: TObject; var Key: Word;
      var KeyChar: WideChar; Shift: TShiftState);
    procedure btnSelecRutaDesc_ConfigClick(Sender: TObject);
    procedure btnDescargarLibroClick(Sender: TObject);
    procedure ChckBxUsarHTTPSChange(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
      FServer: TIdHTTPWebBrokerBridge;
      LIOHandleSSL: TIdServerIOHandlerSSLOpenSSL;
      DriverLink: TFDPhysMySQLDriverLink;
  end;

var
  (*
    PARA USO GLOBAL
  *)
  frmMain: TfrmMain;
  PDF_FileName: string;
  THREAD_IS_RUNNING: Boolean;
  FLAG_MAKING_CHANGES, FLAG_SEARCHING_BOOK: Boolean; //DRH 05/02/2025
  DB_USER, DB_PASSWORD, DB_HOSTNAME, DB_PORT, XAMPP_PATH: string;
  ACCION_LIBROS: Integer; //1 = INSERTAR 2 = MODIFICAR
  LAST_CATEGORIA: Integer;
  LAST_ID_LIBRO: string;
  LAST_LIBRO_SELECTED: Integer;
  LAST_USUARIO_SELECTED: Integer;
  CriticalSection: TCriticalSection;
  FUsingDB: Boolean;
  Semaforo: TSemaphore;
implementation
uses
  UMainFormEvents, UAcciones_Inicio, UAcciones_Pantallas, Generales,
  UAcciones_Usuarios, UAcciones_Configuraciones;

{$R *.fmx}

procedure TfrmMain.btnBloquear_UsuariosClick(Sender: TObject);
begin
  TAcciones_Usuarios.btnBloquear_UsuariosClick(Sender);
end;

procedure TfrmMain.btnCancelarLibrosClick(Sender: TObject);
begin
  TAcciones_Inicio.btnCancelarLibrosClick(Sender);
end;

procedure TfrmMain.btnConfig_OpcionesClick(Sender: TObject);
begin
  TAcciones_Pantallas.btnConfig_OpcionesClick(Sender);
end;

procedure TfrmMain.btnConfirmarPuertoServidorClick(Sender: TObject);
begin
  TAcciones_Inicio.btnConfirmarPuertoServidorClick(Sender);
end;

procedure TfrmMain.btnDescargarLibroClick(Sender: TObject);
begin
  TAcciones_Inicio.btnDescargarLibroClick(Sender);
end;

procedure TfrmMain.btnEliminarLibroClick(Sender: TObject);
begin
  TAcciones_Inicio.btnEliminarLibroClick(Sender);
end;

procedure TfrmMain.btnEliminar_UsuariosClick(Sender: TObject);
begin
  TAcciones_Usuarios.btnEliminar_UsuariosClick(Sender);
end;

procedure TfrmMain.btnFirstLibro_InicioClick(Sender: TObject);
begin
  TAcciones_Inicio.btnFirstLibro_InicioClick(Sender);
end;

procedure TfrmMain.btnFirst_UsuariosClick(Sender: TObject);
begin
  TAcciones_Usuarios.btnFirst_UsuariosClick(Sender);
end;

procedure TfrmMain.btnInicio_OpcionesClick(Sender: TObject);
begin
  TAcciones_Pantallas.btnInicio_OpcionesClick(Sender);
end;

procedure TfrmMain.btnInsertarLibroClick(Sender: TObject);
begin
  TAcciones_Inicio.btnInsertarLibroClick(Sender);
end;

procedure TfrmMain.btnLastLibro_InicioClick(Sender: TObject);
begin
  TAcciones_Inicio.btnLastLibro_InicioClick(Sender);
end;

procedure TfrmMain.btnLast_UsuariosClick(Sender: TObject);
begin
  TAcciones_Usuarios.btnLast_UsuariosClick(Sender);
end;

procedure TfrmMain.btnLibros_InicioClick(Sender: TObject);
begin
  TAcciones_Inicio.btnLibros_InicioClick(Sender);
end;

procedure TfrmMain.btnModificarLibroClick(Sender: TObject);
begin
  TAcciones_Inicio.btnModificarLibroClick(Sender);
end;

procedure TfrmMain.btnNextLibro_InicioClick(Sender: TObject);
begin
  TAcciones_Inicio.btnNextLibro_InicioClick(Sender);
end;

procedure TfrmMain.btnNext_UsuariosClick(Sender: TObject);
begin
  TAcciones_Usuarios.btnNext_UsuariosClick(Sender);
end;

procedure TfrmMain.btnOkMessageDlgClick(Sender: TObject);
begin
  TMainFormEvents.btnOkMessageDlgClick(Sender);
end;

procedure TfrmMain.btnPriorLibro_InicioClick(Sender: TObject);
begin
  TAcciones_Inicio.btnPriorLibro_InicioClick(Sender);
end;

procedure TfrmMain.btnPrior_UsuariosClick(Sender: TObject);
begin
  TAcciones_Usuarios.btnPrior_UsuariosClick(Sender);
end;

procedure TfrmMain.btnProbarServidorClick(Sender: TObject);
begin
  TAcciones_Inicio.btnProbarServidorClick(Sender);
end;

procedure TfrmMain.btnResumen_OpcionesClick(Sender: TObject);
begin
  TAcciones_Pantallas.btnResumen_OpcionesClick(Sender);
end;

procedure TfrmMain.btnSelecRutaDesc_ConfigClick(Sender: TObject);
begin
  TAcciones_Configuraciones.btnSelecRutaDesc_ConfigClick(Sender);
end;

procedure TfrmMain.btnServidorClick(Sender: TObject);
begin
  TAcciones_Inicio.btnServidorClick(Sender);
end;

procedure TfrmMain.btnUsuarios_OpcionesClick(Sender: TObject);
begin
  TAcciones_Pantallas.btnUsuarios_OpcionesClick(Sender);
end;

procedure TfrmMain.CECategoriasLibrosChange(Sender: TObject);
begin
  TAcciones_Inicio.CECategoriasLibrosChange(Sender);
end;

procedure TfrmMain.CECategoriasLibrosClick(Sender: TObject);
begin
  TAcciones_Inicio.CECategoriasLibrosClick(Sender);
end;

procedure TfrmMain.CEFiltro_LibrosChange(Sender: TObject);
begin
  TAcciones_Inicio.CEFiltro_LibrosChange(Sender);
end;

procedure TfrmMain.CEFiltro_UsuariosChange(Sender: TObject);
begin
  TAcciones_Usuarios.CEFiltro_UsuariosChange(Sender);
end;

procedure TfrmMain.CEFiltro_UsuariosClick(Sender: TObject);
begin
  TAcciones_Usuarios.CEFiltro_UsuariosClick(Sender);
end;

procedure TfrmMain.ChckBxUsarHTTPSChange(Sender: TObject);
begin
  TAcciones_Inicio.ChckBxUsarHTTPSChange(Sender);
end;

procedure TfrmMain.edtBuscarLibroTyping(Sender: TObject);
begin
  TAcciones_Inicio.edtBuscarLibroTyping(Sender);
end;

procedure TfrmMain.edtBuscar_UsuariosKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: WideChar; Shift: TShiftState);
begin
  TAcciones_Usuarios.edtBuscar_UsuariosKeyDown(Sender, Key, KeyChar, Shift);
end;

procedure TfrmMain.edtNombreLibroChangeTracking(Sender: TObject);
begin
  TAcciones_Inicio.edtNombreLibroChangeTracking(Sender);
end;

procedure TfrmMain.edtNombreLibroKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: WideChar; Shift: TShiftState);
begin
  TAcciones_Inicio.LibrosFieldsKeyDown(Sender, Key, KeyChar, Shift);
end;

procedure TfrmMain.edtPuertoServidorChangeTracking(Sender: TObject);
begin
  TAcciones_Inicio.edtPuertoServidorChangeTracking(Sender);
end;

procedure TfrmMain.edtPuertoServidorEnter(Sender: TObject);
begin
  TAcciones_Inicio.edtPuertoServidorEnter(Sender);
end;

procedure TfrmMain.edtPuertoServidorExit(Sender: TObject);
begin
  TAcciones_Inicio.edtPuertoServidorExit(Sender);
end;

procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  TMainFormEvents.FormCloseQuery(Sender, CanClose);
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  TMainFormEvents.FormCreate(Sender);
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  TMainFormEvents.FormDestroy(Sender);
end;

procedure TfrmMain.FormFocusChanged(Sender: TObject);
begin
  TMainFormEvents.FormFocusChanged(Sender);
end;

procedure TfrmMain.FormKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: WideChar; Shift: TShiftState);
begin
  TMainFormEvents.FormKeyDown(Sender, Key, KeyChar, Shift);
end;

procedure TfrmMain.FormResize(Sender: TObject);
begin
  TMainFormEvents.FormResize(Sender);
end;

procedure TfrmMain.LVResultBusq_LibrosItemClick(const Sender: TObject;
  const AItem: TListViewItem);
begin
  TAcciones_Inicio.LVResultBusq_LibrosItemClick(Sender, AItem);
end;

procedure TfrmMain.Pantallas_OpcionesChange(Sender: TObject);
begin
  TAcciones_Pantallas.Pantallas_OpcionesChange(Sender);
end;

procedure TfrmMain.SGLibros_InicioApplyStyleLookup(Sender: TObject);
begin
  TAcciones_Inicio.SGLibros_InicioApplyStyleLookup(Sender);
end;

procedure TfrmMain.SGLibros_InicioSelChanged(Sender: TObject);
begin
  TAcciones_Inicio.SGLibros_InicioSelChanged(Sender);
end;

procedure TfrmMain.SGUsuariosSelChanged(Sender: TObject);
begin
  TAcciones_Usuarios.SGUsuariosSelChanged(Sender);
end;

procedure TfrmMain.SWEstadoServidorSwitch(Sender: TObject);
begin
  TAcciones_Inicio.SWEstadoServidorSwitch(Sender);
end;

end.

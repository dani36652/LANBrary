(*
  Autor: Daniel Rodriguez Hernandez
  Fecha: 26/11/2025
*)
unit UMain;

interface

uses
  URest, ELibro, EPagina, EUsuario, FMX.SearchBox,
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.TabControl,
  FMX.Layouts, FMX.Objects, FMX.Controls.Presentation, FMX.Edit, FMX.StdCtrls,
  System.Skia, FMX.Skia, FMX.MultiView, FMX.MediaLibrary, System.SyncObjs,
  FMX.MediaLibrary.Actions, System.Actions, FMX.ActnList, FMX.StdActns,

  UJSONTool, FMX.ComboEdit, FMX.Ani, FMX.Gestures, System.Rtti, FMX.Grid.Style,
  FMX.Grid, FMX.ScrollBox, IdComponent, IdUDPClient, IdBaseComponent, IdUDPBase,
  IdUDPServer, FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base, FMX.ListView;

type
  TfrmMain = class(TForm)
    MainLayout: TLayout;
    ScrollForm: TVertScrollBox;
    MVOpcionesFotoPerfil: TMultiView;
    LYIndicadorMVOpcionesFoto: TLayout;
    RRctPickerMVOpcionesFoto: TRoundRect;
    lblTituloMVOpcionesFoto: TLabel;
    btnCerrarMVOpcionesFoto: TButton;
    SVGCerrarMVOpciones: TSkSvg;
    GpnLYMVOpcionesFoto: TGridPanelLayout;
    btnCamaraMVOpcionesFoto: TButton;
    lblCamaraMVOpciones: TLabel;
    SVGCamaraMVOpciones: TSkSvg;
    btnGaleriaMVOpcionesFoto: TButton;
    lblGaleriaMVOpciones: TLabel;
    SVGGaleriaMVOpciones: TSkSvg;
    Acciones: TActionList;
    TomarFotoDeGaleria: TTakePhotoFromLibraryAction;
    TomarFotoDeCamara: TTakePhotoFromCameraAction;
    btnEliminarFotoUsuarioMVOpciones: TButton;
    SVGEliminarFotoPerfilMVOpciones: TSkSvg;
    MessageDialog: TRectangle;
    rectMsgDlg: TRectangle;
    rectToolBarMsgDlg: TRectangle;
    TituloMessageDialog: TLabel;
    LYBtnMessageDlg: TLayout;
    btnOkMessageDlg: TButton;
    MensajeMessageDialog: TLabel;
    LoadingDialog: TRectangle;
    rectLoadingDlg: TRectangle;
    IndicadorLoadingDlg: TSkAnimatedImage;
    lblMensajeLoadingDlg: TLabel;
    MVOpciones_Principal: TMultiView;
    rectFondoMVOpciones: TRectangle;
    rectToolbarMVOpciones: TRectangle;
    LYFotoUsuarioMVOpciones: TLayout;
    lblNombreUsuarioMVOpciones: TLabel;
    lblCorreoMVOpciones: TLabel;
    MVOpciones_ClasificacionLibros: TMultiView;
    LYSizeGripClasificaciones: TLayout;
    GripClasificaciones: TRoundRect;
    lblTituloClasificacion: TLabel;
    GPLYOrdenClasificacion: TGridPanelLayout;
    imgUsuario_Default: TImage;
    imgFotoPerfilUsuario: TImage;
    Estilo: TStyleBook;
    RBtnMasReciente: TRadioButton;
    RBtnMasAntiguo: TRadioButton;
    btnDescargas_Principal: TButton;
    SVGDescargas_Principal: TSkSvg;
    lblDescargas_Principal: TLabel;
    btnAbout_Principal: TButton;
    SVGAbout_Principal: TSkSvg;
    lblAbout_Principal: TLabel;
    btnContact_Principal: TButton;
    SVGContact_Principal: TSkSvg;
    lblContact_Principal: TLabel;
    LYLogoutMain_Principal: TLayout;
    LYLogout_Principal: TLayout;
    btnSalir_Principal: TButton;
    SVGSalir_Principal: TSkSvg;
    btnMiCuenta_Principal: TButton;
    SVGMiCuenta_Principal: TSkSvg;
    lblMiCuenta_Principal: TLabel;
    Pantallas: TTabControl;
    Configuraciones: TTabItem;
    rectToolBar_Configuraciones: TRectangle;
    btnAtras_Configuraciones: TButton;
    SVGAtras_Configuraciones: TSkSvg;
    lblTitulo_Configuraciones: TLabel;
    VSBxContCampos_Configuraciones: TVertScrollBox;
    lblSeccionServidor_Configuraciones: TLabel;
    rectURL_Configuraciones: TRectangle;
    SVGURLServidor_Configuraciones: TSkSvg;
    edtURLServidor_Configuraciones: TEdit;
    rectPuertoServidor_Configuraciones: TRectangle;
    SVGPuerto_Configuraciones: TSkSvg;
    edtPuertoServidor_Configuraciones: TEdit;
    rectGuardar_Configuraciones: TRectangle;
    btnGuardar_Configuraciones: TButton;
    SVGIcono_Configuraciones: TSkSvg;
    Registro: TTabItem;
    rectToolBar_Registro: TRectangle;
    btnAtras_Registro: TButton;
    SVGAtras_Registro: TSkSvg;
    lblTituloRectToolBar_Registro: TLabel;
    VSBxDatos_Registro: TVertScrollBox;
    LYFotoUsuario_Registro: TLayout;
    rectMarcoFotoUsuario_Registro: TRectangle;
    SVGFotoUsuarioDefault_Registro: TSkSvg;
    imgFotoUsuario_Registro: TImage;
    LYFloatingBtnSelectPic_Registro: TLayout;
    LYCFloatingBtnSelectPic_Registro: TLayout;
    CircleSelectPic_Registro: TCircle;
    BtnSelecFotoUsr_Registro: TButton;
    SVGSeleccionarFotoUsr_Registro: TSkSvg;
    rectApellidoP_Registro: TRectangle;
    SVGApellidoP_Registro: TSkSvg;
    edtApellidoP_Registro: TEdit;
    rectNombreUsr_Registro: TRectangle;
    SVGNombreUsr_Registro: TSkSvg;
    edtNombreUsr_Registro: TEdit;
    rectApellidoM_Registro: TRectangle;
    SVGApellidoM_Registro: TSkSvg;
    edtApellidoM_Registro: TEdit;
    rectCorreo_Registro: TRectangle;
    SVGCorreo_Registro: TSkSvg;
    edtCorreo_Registro: TEdit;
    rectClave_Registro: TRectangle;
    SVGClave_Registro: TSkSvg;
    edtClave_Registro: TEdit;
    btnHideAndShowClave_Registro: TEditButton;
    PasswordHidden_Registro: TSkSvg;
    PasswordShown_Registro: TSkSvg;
    rectEdad_Registro: TRectangle;
    SVGEdad_Registro: TSkSvg;
    edtEdad_Registro: TEdit;
    rectConfirmarClave_Registro: TRectangle;
    SVGConfirmarClave_Registro: TSkSvg;
    edtConfirmarClave_Registro: TEdit;
    btnHideAndShowConfClave_Registro: TEditButton;
    PasswordHidden2_Registro: TSkSvg;
    PasswordShown2_Registro: TSkSvg;
    lblClavesNoCoinciden_Registro: TLabel;
    rectRegistrarse_Registro: TRectangle;
    btnRegistrarse_Registro: TButton;
    Login: TTabItem;
    LYLogo_Login: TLayout;
    imgLogo_Login: TImage;
    edtCorreo_Login: TEdit;
    edtClave_Login: TEdit;
    btnHideOrShowPassword_Login: TEditButton;
    SVGPasswordHidden_Login: TSkSvg;
    SVGPasswordShown_Login: TSkSvg;
    rectIniciarSesion_Login: TRectangle;
    btnIniciarSesion_Login: TButton;
    SKLblRegistrarse_Login: TSkLabel;
    LYContConfig_Login: TLayout;
    LYBtnConfig_Login: TLayout;
    btnConfiguraciones_Login: TButton;
    SVGConfiguraciones_Login: TSkSvg;
    Principal: TTabItem;
    LYToolBar_Principal: TLayout;
    btnMVOpciones_Principal: TButton;
    SVGMVOpciones_Principal: TSkSvg;
    lblBienvenida_Principal: TLabel;
    lblQuevasALeer_Principal: TLabel;
    LYCategorias_Principal: TLayout;
    CBECategorias_Principal: TComboEdit;
    btnFiltroBusqueda_Principal: TButton;
    SVGFiltroCategorias_Principal: TSkSvg;
    lblNoHayLibrosAMostrar_Libros: TLabel;
    rectBuscar_Principal: TRectangle;
    SVGBuscar_Principal: TSkSvg;
    edtBuscar_Principal: TEdit;
    LYContent_Principal: TLayout;
    GPNLyBtns_Principal: TGridPanelLayout;
    btnNextLibro_Principal: TButton;
    SVGNext_Principal: TSkSvg;
    btnPriorLibro_Principal: TButton;
    SVGPrior_Principal: TSkSvg;
    lblPageCounter_Principal: TLabel;
    Mi_Cuenta: TTabItem;
    rectToolbarMi_Cuenta: TRectangle;
    btnAtras_MiCuenta: TButton;
    SVGAtras_MiCuenta: TSkSvg;
    lblTituloToolbar_MiCuenta: TLabel;
    VSBxDatos_MiCuenta: TVertScrollBox;
    LYCntFotoUsr_MiCuenta: TLayout;
    rectFotoUsr_MiCuenta: TRectangle;
    SVGFotoDefault_MiCuenta: TSkSvg;
    imgFotoUsr_MiCuenta: TImage;
    LYBtnEditarFotoUsr_MiCuenta: TLayout;
    btnEditarFotoUsr_MiCuenta: TButton;
    RectApellidoP_MiCuenta: TRectangle;
    SVGApellidoP_MiCuenta: TSkSvg;
    edtApellidoP_MiCuenta: TEdit;
    RectNombre_MiCuenta: TRectangle;
    SVGNombre_MiCuenta: TSkSvg;
    edtNombre_MiCuenta: TEdit;
    RectApellidoM_MiCuenta: TRectangle;
    SVGApellidoM_MiCuenta: TSkSvg;
    edtApellidoM_MiCuenta: TEdit;
    rectCorreoE_MiCuenta: TRectangle;
    SVGCorreoE_MiCuenta: TSkSvg;
    edtCorreoE_MiCuenta: TEdit;
    rectEdad_MiCuenta: TRectangle;
    SVGEdad_MiCuenta: TSkSvg;
    edtEdad_MiCuenta: TEdit;
    rectFondoCambiarClave: TRectangle;
    rectCambiarClave: TRectangle;
    btnCancelarCambiarClave: TButton;
    lblTituloCambiarClave: TLabel;
    LYClaveActualCambiarClave: TLayout;
    rectClaveActualCambiarClave: TRectangle;
    edtClaveActualCambiarClave: TEdit;
    edtSeparacionBtnMostrarClaveClaveActual: TEditButton;
    lblCoincidenciaClavesCambiarClave: TLabel;
    LYBtnCambiarClave: TLayout;
    rectBtnCambiarClave: TRectangle;
    btnCambiarClave: TButton;
    RectCambiarClave_MiCuenta: TRectangle;
    btnCambiarClave_MiCuenta: TButton;
    SVGCambiarClave_MiCuenta: TSkSvg;
    SVGCambiarClave: TSkSvg;
    edtBtnPassClaveActual_CClave: TEditButton;
    SVGPswHiddenActual_CClave: TSkSvg;
    SVGPswShownActual_CClave: TSkSvg;
    SVGClaveActual_CClave: TSkSvg;
    LYClaveNueva_CClave: TLayout;
    rectClaveNueva_CClave: TRectangle;
    edtClaveNueva_CClave: TEdit;
    edtSeparacionCNueva_CClave: TEditButton;
    edtBtnPassClaveNueva_CClave: TEditButton;
    SVGPswHiddenNueva_CClave: TSkSvg;
    SVGPswShownNueva_CClave: TSkSvg;
    SVGClaveNueva_CClave: TSkSvg;
    LYConfirmarClave_CClave: TLayout;
    rectConfirmPsw_CClave: TRectangle;
    edtConfirmarClave_CClave: TEdit;
    SeparacionEdtConfirm_CClave: TEditButton;
    btnPassConfirmar_CClave: TEditButton;
    SVGPswHiddenConfirm_CClave: TSkSvg;
    SVGPswShownConfirm_CClave: TSkSvg;
    SVGConfirmarClave_CClave: TSkSvg;
    SVGDownload: TSkSvg;
    SKAnimDownload: TSkAnimatedImage;
    SVGDownload_Done: TSkSvg;
    Descargas: TTabItem;
    RectToolBarDecargas: TRectangle;
    btnAtrasDescargas: TButton;
    SVGAtrasDescargas: TSkSvg;
    lblTituloDescargas: TLabel;
    rectBuscar_Descargas: TRectangle;
    SVGBuscar_Descargas: TSkSvg;
    edtBuscar_Descargas: TEdit;
    LVDescargas: TListView;
    lblNoHayDescargasPMostrar: TLabel;
    btnEliminar_Descargas: TButton;
    SVGEliminar_Descargas: TSkSvg;
    btnLeer_Descargas: TButton;
    SVGLeer_Descargas: TSkSvg;
    clredtBtnBuscar_Descargas: TClearEditButton;
    EdtBtnClearBusqueda_Principal: TClearEditButton;
    procedure FormCreate(Sender: TObject);
    procedure FormFocusChanged(Sender: TObject);
    procedure FormVirtualKeyboardHidden(Sender: TObject;
      KeyboardVisible: Boolean; const Bounds: TRect);
    procedure FormVirtualKeyboardShown(Sender: TObject;
      KeyboardVisible: Boolean; const Bounds: TRect);
    procedure edtNombreUsr_RegistroChangeTracking(Sender: TObject);
    procedure BtnSelecFotoUsr_RegistroClick(Sender: TObject);
    procedure btnCerrarMVOpcionesFotoClick(Sender: TObject);
    procedure btnHideAndShowClave_RegistroClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: WideChar;
      Shift: TShiftState);
    procedure TomarFotoDeCamaraDidFinishTaking(Image: TBitmap);
    procedure btnCamaraMVOpcionesFotoClick(Sender: TObject);
    procedure btnEliminarFotoUsuarioMVOpcionesClick(Sender: TObject);
    procedure btnAtras_RegistroClick(Sender: TObject);
    procedure btnGaleriaMVOpcionesFotoClick(Sender: TObject);
    procedure edtNombreUsr_RegistroKeyDown(Sender: TObject; var Key: Word;
      var KeyChar: WideChar; Shift: TShiftState);
    procedure btnAtras_ConfiguracionesClick(Sender: TObject);
    procedure edtURLServidor_ConfiguracionesChangeTracking(Sender: TObject);
    procedure btnGuardar_ConfiguracionesClick(Sender: TObject);
    procedure edtURLServidor_ConfiguracionesKeyDown(Sender: TObject;
      var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
    procedure edtPuertoServidor_ConfiguracionesKeyDown(Sender: TObject;
      var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
    procedure btnConfiguraciones_LoginClick(Sender: TObject);
    procedure SKLblRegistrarse_LoginWords1Click(Sender: TObject);
    procedure btnOkMessageDlgClick(Sender: TObject);
    procedure btnRegistrarse_RegistroClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure edtCorreo_LoginChangeTracking(Sender: TObject);
    procedure btnHideOrShowPassword_LoginClick(Sender: TObject);
    procedure btnIniciarSesion_LoginClick(Sender: TObject);
    procedure btnMVOpciones_PrincipalClick(Sender: TObject);
    procedure btnFiltroBusqueda_PrincipalClick(Sender: TObject);
    procedure CBECategorias_PrincipalChange(Sender: TObject);
    procedure btnHideAndShowConfClave_RegistroClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure edtCorreo_LoginKeyDown(Sender: TObject; var Key: Word;
      var KeyChar: WideChar; Shift: TShiftState);
    procedure edtClave_LoginKeyDown(Sender: TObject; var Key: Word;
      var KeyChar: WideChar; Shift: TShiftState);
    procedure edtConfirmarClave_RegistroKeyDown(Sender: TObject; var Key: Word;
      var KeyChar: WideChar; Shift: TShiftState);
    procedure btnPriorLibro_PrincipalClick(Sender: TObject);
    procedure btnNextLibro_PrincipalClick(Sender: TObject);
    procedure RBtnMasAntiguoClick(Sender: TObject);
    procedure RBtnMasRecienteClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnSalir_PrincipalClick(Sender: TObject);
    procedure MVOpciones_PrincipalHidden(Sender: TObject);
    procedure btnMiCuenta_PrincipalClick(Sender: TObject);
    procedure btnAtras_MiCuentaClick(Sender: TObject);
    procedure btnCancelarCambiarClaveClick(Sender: TObject);
    procedure btnCambiarClave_MiCuentaClick(Sender: TObject);
    procedure edtClaveActualCambiarClaveKeyDown(Sender: TObject; var Key: Word;
      var KeyChar: WideChar; Shift: TShiftState);
    procedure edtClaveNueva_CClaveKeyDown(Sender: TObject; var Key: Word;
      var KeyChar: WideChar; Shift: TShiftState);
    procedure edtBtnPassClaveActual_CClaveClick(Sender: TObject);
    procedure edtBtnPassClaveNueva_CClaveClick(Sender: TObject);
    procedure btnPassConfirmar_CClaveClick(Sender: TObject);
    procedure edtClaveActualCambiarClaveChangeTracking(Sender: TObject);
    procedure btnCambiarClaveClick(Sender: TObject);
    procedure btnEditarFotoUsr_MiCuentaClick(Sender: TObject);
    procedure edtConfirmarClave_CClaveKeyUp(Sender: TObject; var Key: Word;
      var KeyChar: WideChar; Shift: TShiftState);
    procedure MVOpciones_ClasificacionLibrosHidden(Sender: TObject);
    procedure MVOpciones_ClasificacionLibrosStartShowing(Sender: TObject);
    procedure MVOpciones_PrincipalStartShowing(Sender: TObject);
    procedure MVOpcionesFotoPerfilHidden(Sender: TObject);
    procedure MVOpcionesFotoPerfilStartShowing(Sender: TObject);
    procedure btnAtrasDescargasClick(Sender: TObject);
    procedure btnDescargas_PrincipalClick(Sender: TObject);
    procedure edtBuscar_DescargasChangeTracking(Sender: TObject);
    procedure LVDescargasItemsChange(Sender: TObject);
    procedure LVDescargasItemClick(const Sender: TObject;
      const AItem: TListViewItem);
    procedure btnEliminar_DescargasClick(Sender: TObject);
    procedure btnLeer_DescargasClick(Sender: TObject);
    procedure edtBuscar_PrincipalChange(Sender: TObject);
    procedure edtBuscar_PrincipalTyping(Sender: TObject);
    procedure EdtBtnClearBusqueda_PrincipalClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;
{$IFDEF ANDROID}
  CAMERA_PERMISSION, STORAGE_PERMISSION, IMAGES_PERMISSION: string;
{$ENDIF}
 URLServidor: string;
 THREAD_IS_RUNNING: Boolean; //Bandera para impedir el cierre de la app mientras corre un subproceso
 CriticalSection: TCriticalSection;
 REST: TREST;
 OPCION_SELECCIONADA: Integer; //DRH 09/09/2025 Para OnHide de MVOpciones.
 TIPO_FOTO: Integer; //DRH 10/09/2025 1=Registro 2=MiCuenta
 Usuario: rUsuario; //DRH 09/09/2025
 RutaPDFS: string; //DRH 30/09/2025
 RutaThumbnails: string; //DRH 30/09/2025
 FLAG_BOOK_DELETED: Boolean; //DRH 26/10/2025
 SearchBox_Descargas: TSearchBox;
 ACCOUNT_IS_LOCKED: Boolean;
 SCROLLING_BOOKS: Boolean;
 FLAG_SEARCHING_BOOKS: Boolean; //DRH 19/11/2025
 (*
  VARIABLES UTILIZADAS EN LA CARGA DINÁMICA DE LIBROS.
 *)

  Paginas: TArray<TPagina>;
  PaginaActual: TPagina;
implementation
uses
  UMainFormEvents, UAcciones_Registro, UAcciones_Configuraciones,
  UAcciones_Login, UAcciones_Principal, UAcciones_MiCuenta,
  UAcciones_Descargas;

{$R *.fmx}

procedure TfrmMain.btnAtrasDescargasClick(Sender: TObject);
begin
  TAcciones_Descargas.btnAtrasDescargasClick(Sender);
end;

procedure TfrmMain.btnAtras_ConfiguracionesClick(Sender: TObject);
begin
  TAcciones_Configuraciones.btnAtras_ConfiguracionesClick(Sender);
end;

procedure TfrmMain.btnAtras_MiCuentaClick(Sender: TObject);
begin
  TAcciones_MiCuenta.btnAtras_MiCuentaClick(Sender);
end;

procedure TfrmMain.btnAtras_RegistroClick(Sender: TObject);
begin
  TAcciones_Registro.btnAtras_RegistroClick(Sender);
end;

procedure TfrmMain.btnCamaraMVOpcionesFotoClick(Sender: TObject);
begin
  TAcciones_Registro.btnCamaraMVOpcionesFotoClick(Sender);
end;

procedure TfrmMain.btnCambiarClaveClick(Sender: TObject);
begin
  TAcciones_MiCuenta.btnCambiarClaveClick(Sender);
end;

procedure TfrmMain.btnCambiarClave_MiCuentaClick(Sender: TObject);
begin
  TAcciones_MiCuenta.btnCambiarClave_MiCuentaClick(Sender);
end;

procedure TfrmMain.btnCancelarCambiarClaveClick(Sender: TObject);
begin
  TAcciones_MiCuenta.btnCancelarCambiarClaveClick(Sender);
end;

procedure TfrmMain.btnCerrarMVOpcionesFotoClick(Sender: TObject);
begin
  TAcciones_Registro.btnCerrarMVOpcionesFotoClick(Sender);
end;

procedure TfrmMain.btnConfiguraciones_LoginClick(Sender: TObject);
begin
  TAcciones_Login.btnConfiguraciones_LoginClick(Sender);
end;

procedure TfrmMain.btnDescargas_PrincipalClick(Sender: TObject);
begin
  TAcciones_Principal.btnDescargas_PrincipalClick(Sender);
end;

procedure TfrmMain.btnEditarFotoUsr_MiCuentaClick(Sender: TObject);
begin
  TAcciones_MiCuenta.btnEditarFotoUsr_MiCuentaClick(Sender);
end;

procedure TfrmMain.btnEliminarFotoUsuarioMVOpcionesClick(Sender: TObject);
begin
  TAcciones_Registro.btnEliminarFotoUsuarioMVOpcionesClick(Sender);
end;

procedure TfrmMain.btnEliminar_DescargasClick(Sender: TObject);
begin
  TAcciones_Descargas.btnEliminar_DescargasClick(Sender);
end;

procedure TfrmMain.btnFiltroBusqueda_PrincipalClick(Sender: TObject);
begin
  TAcciones_Principal.btnFiltroBusqueda_PrincipalClick(Sender);
end;

procedure TfrmMain.btnGaleriaMVOpcionesFotoClick(Sender: TObject);
begin
  TAcciones_Registro.btnGaleriaMVOpcionesFotoClick(Sender);
end;

procedure TfrmMain.btnGuardar_ConfiguracionesClick(Sender: TObject);
begin
  TAcciones_Configuraciones.btnGuardar_ConfiguracionesClick(Sender);
end;

procedure TfrmMain.btnHideAndShowClave_RegistroClick(Sender: TObject);
begin
  TAcciones_Registro.btnHideAndShowClave_RegistroClick(Sender);
end;

procedure TfrmMain.btnHideAndShowConfClave_RegistroClick(Sender: TObject);
begin
  TAcciones_Registro.btnHideAndShowConfClave_RegistroClick(Sender);
end;

procedure TfrmMain.btnHideOrShowPassword_LoginClick(Sender: TObject);
begin
  TAcciones_Login.btnHideOrShowPassword_LoginClick(Sender);
end;

procedure TfrmMain.btnIniciarSesion_LoginClick(Sender: TObject);
begin
  TAcciones_Login.btnIniciarSesion_LoginClick(Sender);
end;

procedure TfrmMain.btnLeer_DescargasClick(Sender: TObject);
begin
  TAcciones_Descargas.btnLeer_DescargasClick(Sender);
end;

procedure TfrmMain.btnMiCuenta_PrincipalClick(Sender: TObject);
begin
  TAcciones_Principal.btnMiCuenta_PrincipalClick(Sender);
end;

procedure TfrmMain.btnMVOpciones_PrincipalClick(Sender: TObject);
begin
  TAcciones_Principal.btnMVOpciones_PrincipalClick(Sender);
end;

procedure TfrmMain.btnNextLibro_PrincipalClick(Sender: TObject);
begin
  TAcciones_Principal.btnNextLibro_PrincipalClick(Sender);
end;

procedure TfrmMain.btnOkMessageDlgClick(Sender: TObject);
begin
  TMainFormEvents.btnOkMessageDlgClick(Sender);
end;

procedure TfrmMain.btnPassConfirmar_CClaveClick(Sender: TObject);
begin
  TAcciones_MiCuenta.btnPassConfirmar_CClaveClick(Sender);
end;

procedure TfrmMain.btnPriorLibro_PrincipalClick(Sender: TObject);
begin
  TAcciones_Principal.btnPriorLibro_PrincipalClick(Sender);
end;

procedure TfrmMain.btnRegistrarse_RegistroClick(Sender: TObject);
begin
  TAcciones_Registro.btnRegistrarse_RegistroClick(Sender);
end;

procedure TfrmMain.btnSalir_PrincipalClick(Sender: TObject);
begin
  TAcciones_Principal.btnSalir_PrincipalClick(Sender);
end;

procedure TfrmMain.BtnSelecFotoUsr_RegistroClick(Sender: TObject);
begin
  TAcciones_Registro.BtnSelecFotoUsr_RegistroClick(Sender);
end;

procedure TfrmMain.CBECategorias_PrincipalChange(Sender: TObject);
begin
  TAcciones_Principal.CBECategorias_PrincipalChange(Sender);
end;

procedure TfrmMain.EdtBtnClearBusqueda_PrincipalClick(Sender: TObject);
begin
  TAcciones_Principal.EdtBtnClearBusqueda_PrincipalClick(Sender);
end;

procedure TfrmMain.edtBtnPassClaveActual_CClaveClick(Sender: TObject);
begin
  TAcciones_MiCuenta.edtBtnPassClaveActual_CClaveClick(Sender);
end;

procedure TfrmMain.edtBtnPassClaveNueva_CClaveClick(Sender: TObject);
begin
  TAcciones_MiCuenta.edtBtnPassClaveNueva_CClaveClick(Sender);
end;

procedure TfrmMain.edtBuscar_DescargasChangeTracking(Sender: TObject);
begin
  TAcciones_Descargas.edtBuscar_DescargasChangeTracking(Sender);
end;

procedure TfrmMain.edtBuscar_PrincipalChange(Sender: TObject);
begin
  TAcciones_Principal.edtBuscar_PrincipalChange(Sender);
end;

procedure TfrmMain.edtBuscar_PrincipalTyping(Sender: TObject);
begin
  TAcciones_Principal.edtBuscar_PrincipalTyping(Sender);
end;

procedure TfrmMain.edtClaveActualCambiarClaveChangeTracking(Sender: TObject);
begin
  TAcciones_MiCuenta.ValidarCoincidenciasClaves(Sender);
end;

procedure TfrmMain.edtClaveActualCambiarClaveKeyDown(Sender: TObject;
  var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
begin
  TAcciones_MiCuenta.edtClaveActualCambiarClaveKeyDown(Sender, Key, KeyChar,
  Shift);
end;

procedure TfrmMain.edtClaveNueva_CClaveKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: WideChar; Shift: TShiftState);
begin
  TAcciones_MiCuenta.edtClaveNueva_CClaveKeyDown(Sender, Key, KeyChar, Shift);
end;

procedure TfrmMain.edtClave_LoginKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: WideChar; Shift: TShiftState);
begin
  TAcciones_Login.edtClave_LoginKeyDown(Sender, Key, KeyChar, Shift);
end;

procedure TfrmMain.edtConfirmarClave_CClaveKeyUp(Sender: TObject; var Key: Word;
  var KeyChar: WideChar; Shift: TShiftState);
begin
  TAcciones_MiCuenta.edtConfirmarClave_CClaveKeyDown(Sender, Key,
  KeyChar, Shift);
end;

procedure TfrmMain.edtConfirmarClave_RegistroKeyDown(Sender: TObject;
  var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
begin
  TAcciones_Registro.CamposKeyDown(Sender, Key, KeyChar, Shift);
end;

procedure TfrmMain.edtCorreo_LoginChangeTracking(Sender: TObject);
begin
  TAcciones_Login.CamposChangeTracking(Sender);
end;

procedure TfrmMain.edtCorreo_LoginKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: WideChar; Shift: TShiftState);
begin
  TAcciones_Login.edtCorreo_LoginKeyDown(Sender, Key, KeyChar, Shift);
end;

procedure TfrmMain.edtNombreUsr_RegistroChangeTracking(Sender: TObject);
begin
  TAcciones_Registro.DatosChange(Sender);
end;

procedure TfrmMain.edtNombreUsr_RegistroKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: WideChar; Shift: TShiftState);
begin
  TAcciones_Registro.CamposKeyDown(Sender, Key, KeyChar, Shift);
end;

procedure TfrmMain.edtPuertoServidor_ConfiguracionesKeyDown(Sender: TObject;
  var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
begin
  TAcciones_Configuraciones.edtPuertoServidor_ConfiguracionesKeyDown(Sender, Key,
  KeyChar, Shift);
end;

procedure TfrmMain.edtURLServidor_ConfiguracionesChangeTracking(
  Sender: TObject);
begin
  TAcciones_Configuraciones.CamposChangeTracking(Sender);
end;

procedure TfrmMain.edtURLServidor_ConfiguracionesKeyDown(Sender: TObject;
  var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
begin
  TAcciones_Configuraciones.edtURLServidor_ConfiguracionesKeyDown(Sender,
  Key, KeyChar, Shift);
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

procedure TfrmMain.FormShow(Sender: TObject);
begin
  TMainFormEvents.FormShow(Sender);
end;

procedure TfrmMain.FormVirtualKeyboardHidden(Sender: TObject;
  KeyboardVisible: Boolean; const Bounds: TRect);
begin
  TMainFormEvents.FormVirtualKeyboardHidden(Sender, KeyboardVisible, Bounds);
end;

procedure TfrmMain.FormVirtualKeyboardShown(Sender: TObject;
  KeyboardVisible: Boolean; const Bounds: TRect);
begin
  TMainFormEvents.FormVirtualKeyboardShown(Sender, KeyboardVisible, Bounds);
end;

procedure TfrmMain.LVDescargasItemClick(const Sender: TObject;
  const AItem: TListViewItem);
begin
  TAcciones_Descargas.LVDescargasItemClick(Sender, AItem);
end;

procedure TfrmMain.LVDescargasItemsChange(Sender: TObject);
begin
  TAcciones_Descargas.LVDescargasItemsChange(Sender);
end;

procedure TfrmMain.MVOpcionesFotoPerfilHidden(Sender: TObject);
begin
  TAcciones_Principal.MVOpcionesFotoPerfilHidden(Sender);
end;

procedure TfrmMain.MVOpcionesFotoPerfilStartShowing(Sender: TObject);
begin
  TAcciones_Principal.MVOpcionesFotoPerfilStartShowing(Sender);
end;

procedure TfrmMain.MVOpciones_ClasificacionLibrosHidden(Sender: TObject);
begin
  TAcciones_Principal.MVOpciones_ClasificacionLibrosHidden(Sender);
end;

procedure TfrmMain.MVOpciones_ClasificacionLibrosStartShowing(Sender: TObject);
begin
  TAcciones_Principal.MVOpciones_ClasificacionLibrosStartShowing(Sender);
end;

procedure TfrmMain.MVOpciones_PrincipalHidden(Sender: TObject);
begin
  TAcciones_Principal.MVOpciones_PrincipalHidden(Sender);
end;

procedure TfrmMain.MVOpciones_PrincipalStartShowing(Sender: TObject);
begin
  TAcciones_Principal.MVOpciones_PrincipalStartShowing(Sender);
end;

procedure TfrmMain.RBtnMasAntiguoClick(Sender: TObject);
begin
  TAcciones_Principal.RBtnFiltroBusqueda_PrincipalClick(Sender);
end;

procedure TfrmMain.RBtnMasRecienteClick(Sender: TObject);
begin
  TAcciones_Principal.RBtnFiltroBusqueda_PrincipalClick(Sender);
end;

procedure TfrmMain.SKLblRegistrarse_LoginWords1Click(Sender: TObject);
begin
  TAcciones_Login.SKLblRegistrarse_LoginWords1Click(Sender);
end;

procedure TfrmMain.TomarFotoDeCamaraDidFinishTaking(Image: TBitmap);
begin
  TAcciones_Registro.TomarFotoDeCamaraDidFinishTaking(Image);
end;

end.

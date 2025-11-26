program LANBrary;

uses
  System.StartUpCopy,
  FMX.Forms,
  FMX.Skia,
  ECategoria in 'Unidades\Entidades\ECategoria.pas',
  ELibro in 'Unidades\Entidades\ELibro.pas',
  EPagina in 'Unidades\Entidades\EPagina.pas',
  EUsuario in 'Unidades\Entidades\EUsuario.pas',
  Estilos in 'Unidades\Estilos.pas',
  Generales in 'Unidades\Generales.pas',
  UAcciones_Configuraciones in 'Unidades\UAcciones_Configuraciones.pas',
  UAcciones_Descargas in 'Unidades\UAcciones_Descargas.pas',
  UAcciones_LectorPDF in 'Unidades\UAcciones_LectorPDF.pas',
  UAcciones_Login in 'Unidades\UAcciones_Login.pas',
  UAcciones_MiCuenta in 'Unidades\UAcciones_MiCuenta.pas',
  UAcciones_Principal in 'Unidades\UAcciones_Principal.pas',
  UAcciones_Registro in 'Unidades\UAcciones_Registro.pas',
  UJSONTool in 'Unidades\UJSONTool.pas',
  ULibros in 'Unidades\ULibros.pas',
  UMainFormEvents in 'Unidades\UMainFormEvents.pas',
  URest in 'Unidades\URest.pas',
  UMain in 'UMain.pas' {frmMain};

{$R *.res}

begin
  GlobalUseSkia := True;
  Application.Initialize;
  Application.FormFactor.Orientations := [TFormOrientation.Portrait, TFormOrientation.InvertedPortrait];
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.

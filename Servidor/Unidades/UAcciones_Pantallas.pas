unit UAcciones_Pantallas;

interface
uses
  System.Classes, System.Types, System.SysConst, System.SysUtils,
  System.StrUtils, FMX.Objects, FMX.StdCtrls, FMX.Colors, FMX.Controls,
  FMX.Edit, FMX.TabControl,
  FMX.Platform, FMX.Utils, System.Generics.Collections, System.UIConsts,
  System.UITypes, FMX.Grid;

type TAcciones_Pantallas = class
  private
    const
      ColorSeleccion: TAlphaColor = $FF53E193;
      ColorDefault: TAlphaColor = $FF3AAE6D;
  public
    class procedure btnInicio_OpcionesClick(Sender: TObject);
    class procedure btnUsuarios_OpcionesClick(Sender: TObject);
    class procedure btnResumen_OpcionesClick(Sender: TObject);
    class procedure btnConfig_OpcionesClick(Sender: TObject);
    class procedure DefaultPantallasConfig;

    (*
      Pantallas_Opciones
    *)
    class procedure Pantallas_OpcionesChange(Sender: TObject);
end;

implementation
uses
  UMain, Generales;

{ TAcciones_Principal }

class procedure TAcciones_Pantallas.btnConfig_OpcionesClick(Sender: TObject);
begin
  frmMain.RRctInicio_Opciones.Fill.Color:= ColorDefault;
  frmMain.RRctUsuarios_Opciones.Fill.Color:= ColorDefault;
  frmMain.RRctConfig_Opciones.Fill.Color:= ColorSeleccion;
  frmMain.Pantallas.ActiveTab:= frmMain.Configuraciones;
end;

class procedure TAcciones_Pantallas.btnInicio_OpcionesClick(Sender: TObject);
begin
  frmMain.RRctInicio_Opciones.Fill.Color:= ColorSeleccion;
  frmMain.RRctUsuarios_Opciones.Fill.Color:= ColorDefault;
  frmMain.RRctConfig_Opciones.Fill.Color:= ColorDefault;
  frmMain.Pantallas.ActiveTab:= frmMain.Inicio;
end;

class procedure TAcciones_Pantallas.btnResumen_OpcionesClick(Sender: TObject);
begin
  frmMain.RRctInicio_Opciones.Fill.Color:= ColorDefault;
  frmMain.RRctUsuarios_Opciones.Fill.Color:= ColorDefault;
  frmMain.RRctConfig_Opciones.Fill.Color:= ColorDefault;
end;

class procedure TAcciones_Pantallas.btnUsuarios_OpcionesClick(Sender: TObject);
begin
  frmMain.RRctInicio_Opciones.Fill.Color:= ColorDefault;
  frmMain.RRctUsuarios_Opciones.Fill.Color:= ColorSeleccion;
  frmMain.RRctConfig_Opciones.Fill.Color:= ColorDefault;
  frmMain.Pantallas.ActiveTab:= frmMain.Usuarios;
  frmMain.CEFiltro_Usuarios.ItemIndex:= 0;
  frmMain.CEFiltro_Usuarios.OnChange(frmMain.CEFiltro_Usuarios);
end;

class procedure TAcciones_Pantallas.DefaultPantallasConfig;
begin
  frmMain.Pantallas.ActiveTab:= frmMain.Inicio;
  try
    frmMain.Pantallas_Opciones.OnChange:= nil;
    frmMain.Pantallas_Opciones.ActiveTab:= frmMain.Libros;
  finally
    frmMain.Pantallas_Opciones.OnChange:= frmMain.Pantallas_OpcionesChange;
  end;
  frmMain.rectIndicadorLibros_Inicio.Visible:= True;
  frmMain.rectIndicadorServidor.Visible:= False;
end;

class procedure TAcciones_Pantallas.Pantallas_OpcionesChange(Sender: TObject);
begin
  case TTabControl(Sender).TabIndex of
    0: //Libros
    begin
      if (frmMain.SGLibros_Inicio.RowCount > 0) and
      (frmMain.SGLibros_Inicio.Selected > 0) then
      begin
        frmMain.btnFirstLibro_InicioClick(frmMain.btnFirstLibro_Inicio);
        DesplazarStringGrid(frmMain.SGLibros_Inicio, 1);
      end;
    end;

    1: //Usuarios
    begin

    end;
  end;
end;

end.

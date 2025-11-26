unit UAcciones_Usuarios;

interface
uses
  FMX.DialogService, EUsuario,
  System.Classes, System.Types, System.SysConst, System.SysUtils, FMX.ComboEdit,
  System.StrUtils, FMX.Objects, FMX.StdCtrls, FMX.Colors, FMX.Controls,
  FMX.Edit, IdHTTPWebBrokerBridge, Web.HTTPApp, FMX.Dialogs,
  FMX.Platform, FMX.Utils, System.Generics.Collections, System.UIConsts,
  FMX.ListView.Appearances, FMX.ListView,
  System.UITypes, FMX.Grid;

type TAcciones_Usuarios = class
  private
    class procedure ClearUsuariosFields;
    class procedure ClearUsuariosFieldsAfterNoResults;
    class procedure MostrarUsuarios(const Usuarios: TArray<rUsuario>);
    class function LastUsuario: Integer;
    class procedure SinUsuariosParaMostrar;
  public
    class procedure CEFiltro_UsuariosClick(Sender: TObject);
    class procedure SGUsuariosSelChanged(Sender: TObject);
    class procedure CEFiltro_UsuariosChange(Sender: TObject);
    class procedure btnFirst_UsuariosClick(Sender: TObject);
    class procedure btnPrior_UsuariosClick(Sender: TObject);
    class procedure btnNext_UsuariosClick(Sender: TObject);
    class procedure btnLast_UsuariosClick(Sender: TObject);
    class procedure btnEliminar_UsuariosClick(Sender: TObject);
    class procedure btnBloquear_UsuariosClick(Sender: TObject);
    class procedure edtBuscar_UsuariosKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: WideChar; Shift: TShiftState);
end;

implementation
uses
  UMain, DBActions, Generales;

{ TAcciones_Usuarios }

class procedure TAcciones_Usuarios.btnBloquear_UsuariosClick(Sender: TObject);
var
  Mensaje: string;
begin
  if (frmMain.SGUsuarios.Selected > - 1) and
  (frmMain.SGUsuarios.RowCount > 0) then
  begin
    if TButton(Sender).Text.Trim.ToLower.Equals('bloquear') then
    begin
      Mensaje:= '¿Bloquear usuario?';
      TDialogService.MessageDialog(Mensaje, TMsgDlgType.mtWarning,
      [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], TMsgDlgBtn.mbNo, 0,
      procedure (const AResult: TModalResult)
      var
        IdUsuario: string;
      begin
        IdUsuario:= frmMain.SGUsuarios.Cells[0, frmMain.SGUsuarios.Selected];
        case AResult of
          mrYes:
          begin
            if TDBActions.CambiarEstatusUsuario(frmMain.ConexionGUI,
            IdUsuario, 0) then
            begin
              frmMain.CEFiltro_Usuarios.OnChange(frmMain.CEFiltro_Usuarios);
              MessageDialog('INFORMACIÓN', 'Bloqueado con éxito.');
            end
            else
              MessageDialog('INFORMACIÓN', 'No fue posible bloquear ' +
              'al usuario seleccionado.');
          end;
        end;
      end);
    end
    else
    if TButton(Sender).Text.Trim.ToLower.Equals('desbloquear') then
    begin
      Mensaje:= '¿Desbloquear usuario?';
      TDialogService.MessageDialog(Mensaje, TMsgDlgType.mtWarning,
      [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], TMsgDlgBtn.mbNo, 0,
      procedure (const AResult: TModalResult)
      var
        IdUsuario: string;
      begin
        IdUsuario:= frmMain.SGUsuarios.Cells[0, frmMain.SGUsuarios.Selected];
        case AResult of
          mrYes:
          begin
            if TDBActions.CambiarEstatusUsuario(frmMain.ConexionGUI,
            IdUsuario, 1) then
            begin
              frmMain.CEFiltro_Usuarios.OnChange(frmMain.CEFiltro_Usuarios);
              MessageDialog('INFORMACIÓN', 'Desbloqueado con éxito.');
            end
            else
              MessageDialog('INFORMACIÓN', 'No fue posible desbloquear ' +
              'al usuario seleccionado.');
          end;
        end;
      end);
    end;
  end;
end;

class procedure TAcciones_Usuarios.btnEliminar_UsuariosClick(Sender: TObject);
var
  Mensaje: string;
begin
  if (frmMain.SGUsuarios.Selected > - 1) and
  (frmMain.SGUsuarios.RowCount > 0) then
  begin
    Mensaje:= '¿Eliminar usuario?';
    TDialogService.MessageDialog(Mensaje, TMsgDlgType.mtWarning,
    [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], TMsgDlgBtn.mbNo, 0,
    procedure (const AResult: TModalResult)
    var
      IdUsuario: string;
    begin
      IdUsuario:= frmMain.SGUsuarios.Cells[0, frmMain.SGUsuarios.Selected];
      case AResult of
        mrYes:
        begin
          if TDBActions.EliminarUsuario(frmMain.ConexionGUI,
          IdUsuario) then
          begin
            frmMain.CEFiltro_Usuarios.OnChange(frmMain.CEFiltro_Usuarios);
            MessageDialog('INFORMACIÓN', 'Eliminado con éxito.');
          end
          else
            MessageDialog('INFORMACIÓN', 'No fue posible eliminar ' +
            'el registro seleccionado.');
        end;
      end;
    end);
  end;
end;

class procedure TAcciones_Usuarios.btnFirst_UsuariosClick(Sender: TObject);
begin
  if (frmMain.SGUsuarios.Selected > -1) and
  (frmMain.SGUsuarios.RowCount > 0) then
    frmMain.SGUsuarios.Selected:= 0;
end;

class procedure TAcciones_Usuarios.btnLast_UsuariosClick(Sender: TObject);
begin
  if (frmMain.SGUsuarios.Selected > -1) and
  (frmMain.SGUsuarios.RowCount > 0) then
    frmMain.SGUsuarios.Selected:= frmMain.SGUsuarios.RowCount - 1;
end;

class procedure TAcciones_Usuarios.btnNext_UsuariosClick(Sender: TObject);
begin
  if (frmMain.SGUsuarios.Selected > -1) and
  (frmMain.SGUsuarios.RowCount > 0) then
  begin
    if frmMain.SGUsuarios.Selected = frmMain.SGUsuarios.RowCount - 1 then
      frmMain.SGUsuarios.Selected:= 0
    else
      frmMain.SGUsuarios.Selected:= frmMain.SGUsuarios.Selected + 1;
  end;
end;

class procedure TAcciones_Usuarios.btnPrior_UsuariosClick(Sender: TObject);
begin
  if (frmMain.SGUsuarios.Selected > -1) and
  (frmMain.SGUsuarios.RowCount > 0) then
  begin
    if frmMain.SGUsuarios.Selected = 0 then
      frmMain.SGUsuarios.Selected:= frmMain.SGUsuarios.RowCount - 1
    else
      frmMain.SGUsuarios.Selected:= frmMain.SGUsuarios.Selected - 1;
  end;
end;

class procedure TAcciones_Usuarios.CEFiltro_UsuariosChange(Sender: TObject);
var
  Indx: Integer;
  Usuarios: TArray<rUsuario>;
begin
  Indx:= TComboEdit(Sender).ItemIndex;
  if Indx > -1 then
  begin
    Usuarios:= TDBActions.ObtenerUsuarios(frmMain.ConexionGUI, Indx + 1);
    try
      MostrarUsuarios(Usuarios);
    finally
      SetLength(Usuarios, 0);
    end;
  end
  else
    SinUsuariosParaMostrar;
end;

class procedure TAcciones_Usuarios.CEFiltro_UsuariosClick(Sender: TObject);
begin
  TComboEdit(Sender).DropDown;
end;

class procedure TAcciones_Usuarios.ClearUsuariosFields;
begin
  frmMain.edtNombre_Usuarios.Text:= string.Empty;
  frmMain.edtApellidoP_Usuarios.Text:= string.Empty;
  frmMain.edtApellidoM_Usuarios.Text:= string.Empty;
  frmMain.edtEdad_Usuarios.Text:= string.Empty;
  frmMain.edtCorreo_Usuarios.Text:= string.Empty;
  frmMain.edtEstatus_Usuarios.Text:= string.Empty;
end;

class procedure TAcciones_Usuarios.ClearUsuariosFieldsAfterNoResults;
begin
  ClearUsuariosFields;
  frmMain.imgFoto_Usuarios.Bitmap:= frmMain.ImgDefaultFotoUsuario.Bitmap;
end;

class procedure TAcciones_Usuarios.edtBuscar_UsuariosKeyDown(Sender: TObject;
  var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
var
  Busqueda: string;
  Usuarios: TArray<rUsuario>;
begin
  if Key = vkReturn then
  begin
    Busqueda:= TEdit(Sender).Text.Trim;
    if not Busqueda.IsEmpty then
    begin
      Usuarios:= TDBActions.BuscarUsuarios(frmMain.ConexionGUI, Busqueda);
      try
        MostrarUsuarios(Usuarios);
      finally
        SetLength(Usuarios, 0);
      end;
    end;
  end;
end;

class function TAcciones_Usuarios.LastUsuario: Integer;
begin
  if frmMain.SGUsuarios.RowCount > 0 then
  begin
    if frmMain.SGUsuarios.RowCount - 1 < LAST_USUARIO_SELECTED then
      Result:= 0
    else
      Result:= LAST_USUARIO_SELECTED;

  end else Result:= 0;
end;

class procedure TAcciones_Usuarios.MostrarUsuarios(
  const Usuarios: TArray<rUsuario>);
var
  Usuario: rUsuario;
  Indx: Integer;
begin
  frmMain.SGUsuarios.RowCount:= 0;
  Indx:= 0;
  if Length(Usuarios) > 0 then
  begin
    frmMain.lblNoHayRegistrosParaMostrar_Usuarios.Visible:= False;
    frmMain.GPnlLyActns_Usuarios.Visible:= True;
    frmMain.SGUsuarios.Visible:= True;
    frmMain.SGUsuarios.BeginUpdate;
    for Usuario in Usuarios do
    begin
      frmMain.SGUsuarios.RowCount:= frmMain.SGUsuarios.RowCount + 1;
      frmMain.SGUsuarios.Cells[0, Indx]:= Usuario.id;
      frmMain.SGUsuarios.Cells[1, Indx]:= Usuario.Nombre;
      frmMain.SGUsuarios.Cells[2, Indx]:= Usuario.Apellido_P;
      frmMain.SGUsuarios.Cells[3, Indx]:= Usuario.Apellido_M;
      frmMain.SGUsuarios.Cells[4, Indx]:= Usuario.Edad;
      frmMain.SGUsuarios.Cells[5, Indx]:= Usuario.Correo;

      case Usuario.Estatus of
        0: frmMain.SGUsuarios.Cells[6, Indx]:= 'BLOQUEADO';

        1: frmMain.SGUsuarios.Cells[6, Indx]:= 'ACTIVO';
      end;
      Inc(Indx);
    end;
    frmMain.SGUsuarios.EndUpdate;
    frmMain.SGUsuarios.Selected:= LastUsuario;
    frmMain.SGUsuarios.RealignContent;
  end
  else
    SinUsuariosParaMostrar;
end;

 class procedure TAcciones_Usuarios.SGUsuariosSelChanged(Sender: TObject);
var
  SG: TStringGrid;
  MSFoto: TMemoryStream;
  IdUsuario: string;

  Nombre_Usuario, ApellidoP_Usuario,
  ApellidoM_Usuario, Edad_Usuario,
  Correo_Usuario, Estatus_Usuario: string;
begin
  SG:= Sender as TStringGrid;
  if SG.Selected <> -1 then
  begin
    LAST_USUARIO_SELECTED:= SG.Selected;
    IdUsuario:= SG.Cells[0, SG.Selected];
    Nombre_Usuario:= SG.Cells[1, SG.Selected];
    ApellidoP_Usuario:= SG.Cells[2, SG.Selected];
    ApellidoM_Usuario:= SG.Cells[3, SG.Selected];
    Edad_Usuario:= SG.Cells[4, SG.Selected];
    Correo_Usuario:= SG.Cells[5, SG.Selected];
    Estatus_Usuario:= SG.Cells[6, SG.Selected];

    if Estatus_Usuario.Trim.ToLower.Equals('activo') then
      frmMain.btnBloquear_Usuarios.Text:= 'Bloquear'
    else
      frmMain.btnBloquear_Usuarios.Text:= 'Desbloquear';

    frmMain.edtNombre_Usuarios.Text:= Nombre_Usuario;
    frmMain.edtApellidoP_Usuarios.Text:= ApellidoP_Usuario;
    frmMain.edtApellidoM_Usuarios.Text:= ApellidoM_Usuario;
    frmMain.edtEdad_Usuarios.Text:= Edad_Usuario;
    frmMain.edtCorreo_Usuarios.Text:= Correo_Usuario;
    frmMain.edtEstatus_Usuarios.Text:= Estatus_Usuario;

    MSFoto:= TDBActions.ObtenerFotoUsuarioPorID(frmMain.ConexionGUI, IdUsuario);
    try
      if MSFoto <> nil then
        frmMain.imgFoto_Usuarios.Bitmap.LoadFromStream(MSFoto)
      else
        frmMain.imgFoto_Usuarios.Bitmap:= frmMain.ImgDefaultFotoUsuario.Bitmap;
    finally
      if MSFoto <> nil then
        FreeAndNil(MSFoto);
    end;
  end;
end;

class procedure TAcciones_Usuarios.SinUsuariosParaMostrar;
begin
  frmMain.SGUsuarios.Visible:= False;
  frmMain.GPnlLyActns_Usuarios.Visible:= False;
  frmMain.lblNoHayRegistrosParaMostrar_Usuarios.Visible:= True;
  frmMain.btnBloquear_Usuarios.Text:= 'Bloquear';
  ClearUsuariosFieldsAfterNoResults;
end;

end.

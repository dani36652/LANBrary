unit UAcciones_Inicio;

interface
uses
  ECategoria, FMX.DialogService, ELibro, IdGlobal, IdSSLOpenSSL,
  System.Classes, System.Types, System.SysConst, System.SysUtils, FMX.ComboEdit,
  System.StrUtils, FMX.Objects, FMX.StdCtrls, FMX.Colors, FMX.Controls,
  FMX.Edit, FMX.Dialogs,
  FMX.Platform, FMX.Utils, System.Generics.Collections, System.UIConsts,
  FMX.ListView.Appearances, FMX.ListView,
  System.UITypes, FMX.Grid;

type TAcciones_Inicio = class
  private
    // Procedimientos relacionados a la sección "Servidor" 1 = Operación 2 = Excepción
    class procedure OnGetSSLPassword(var APassword: String);
    class procedure OnQuerySSLPort(APort: TIdPort; var AUseSSL: Boolean);
    class procedure HttpsConfig(const aActive: Boolean);

    class function isSafePort(aPort: string): Boolean;
    class procedure ThreadOnTerminate(Sender: TObject);

    //Procedimientos relacionados a la sección "Libros"
    class procedure EnableLibrosInsertMode;
    class procedure CancelLibrosInsertMode;
    class procedure LibrosFieldsCanFocus(const aCanFocus: Boolean);
    class procedure LibrosFieldsSetReadOnly(const aValue: Boolean);
    class procedure ClearLibrosFields;
    class procedure ClearLibrosFieldsAfterNoResults;
    class procedure MostrarLibros(const Libros: TArray<rLibro>);
    class procedure EnableLibrosEditMode;
    class procedure CancelLibrosEditMode;
    class procedure ShowLastCategoriaChanges;
    class function LastRegistro: Integer;
    class procedure MostrarCoincidencias(var Libros: TArray<rLibro>);
    class procedure CancelLibrosSearchingMode;
  public
    class procedure SGLibros_InicioApplyStyleLookup(Sender: TObject);
    //Eventos de los botones para la selección de secciones
    class procedure btnLibros_InicioClick(Sender: TObject);
    class procedure btnServidorClick(Sender: TObject);

    //Eventos de la sección "Servidor" de la pantalla de Inicio
    class procedure SWEstadoServidorSwitch(Sender: TObject);
    class procedure btnProbarServidorClick(Sender: TObject);
    class procedure edtPuertoServidorExit(Sender: TObject);
    class procedure edtPuertoServidorEnter(Sender: TObject);
    class procedure edtPuertoServidorChangeTracking(Sender: TObject);
    class procedure btnConfirmarPuertoServidorClick(Sender: TObject);
    class procedure ChckBxUsarHTTPSChange(Sender: TObject);
    //1 = Operación 2 = Excepción
    class procedure MostrarEvento_Servidor(const Mensaje: string; const Nivel: Integer = 1);
    class procedure LoadServerSettings;

    //Eventos de la sección "Libros" de la pantalla de Inicio
    class procedure btnInsertarLibroClick(Sender: TObject);
    class procedure btnCancelarLibrosClick(Sender: TObject);
    class procedure CECategoriasLibrosChange(Sender: TObject);
    class procedure SGLibros_InicioSelChanged(Sender: TObject);
    class procedure btnFirstLibro_InicioClick(Sender: TObject);
    class procedure btnPriorLibro_InicioClick(Sender: TObject);
    class procedure btnNextLibro_InicioClick(Sender: TObject);
    class procedure btnLastLibro_InicioClick(Sender: TObject);
    class procedure btnModificarLibroClick(Sender: TObject);
    class procedure btnEliminarLibroClick(Sender: TObject);
    class procedure MostrarCategorias(var Categorias: TArray<rCategoria>);
    class procedure CECategoriasLibrosClick(Sender: TObject);
    class procedure LVResultBusq_LibrosItemClick(const Sender: TObject;
    const AItem: TListViewItem);
    class procedure edtNombreLibroChangeTracking(Sender: TObject);
    class procedure CEFiltro_LibrosChange(Sender: TObject);
    class procedure edtBuscarLibroTyping(Sender: TObject);
    class procedure LibrosFieldsKeyDown(Sender: TObject; var Key: Word;
    var KeyChar: WideChar; Shift: TShiftState);
    class procedure btnDescargarLibroClick(Sender: TObject);
end;

implementation
uses
  Estilos, UMain, Generales, System.IOUtils, FMX.Graphics, DBActions,
  System.SyncObjs;

{ TAccionesPrincipal }

class procedure TAcciones_Inicio.btnCancelarLibrosClick(Sender: TObject);
begin
  if FLAG_MAKING_CHANGES then
  begin
    case ACCION_LIBROS of
      1:  CancelLibrosInsertMode;

      2:  CancelLibrosEditMode;
    end;
  end else
  if FLAG_SEARCHING_BOOK then
    CancelLibrosSearchingMode;
end;

class procedure TAcciones_Inicio.btnConfirmarPuertoServidorClick(
  Sender: TObject);
begin
  frmMain.rectConfirmarPuertoServidor.Visible:= False;
end;

class procedure TAcciones_Inicio.btnDescargarLibroClick(Sender: TObject);
var
  idLibro, NombreLibro: string;
  FileName: string;
  SVDlg: TSaveDialog;
  MS: TMemoryStream;
begin
  idLibro:= frmMain.SGLibros_Inicio.Cells[5, frmMain.SGLibros_Inicio.Selected];
  NombreLibro:= frmMain.SGLibros_Inicio.Cells[0, frmMain.SGLibros_Inicio.Selected];
  FileName:= frmMain.edtRutaDescargas_Configuraciones.Text + PathDelim + NombreLibro + '.pdf';
  MS:= TDBActions.ObtenerArchivoLibro(frmMain.ConexionGUI, idLibro);
  if MS <> nil then
  begin
    SVDlg:= TSaveDialog.Create(frmMain);
    SVDlg.Parent:= frmMain;
    SVDlg.InitialDir:= frmMain.edtRutaDescargas_Configuraciones.Text;
    SVDlg.Filter:= 'Portable Document Format|*.pdf';
    SVDlg.Title:= 'Guardar libro';
    SVDlg.DefaultExt:= '.pdf';
    SVDlg.FileName:= NombreLibro;
    (*
      Habilita el cuadro de diálogo que advierte si ya existe un archivo
      y le pregunta al usuario si quiere sobreescribilro.
    *)
    SVDlg.Options:= [TOpenOption.ofOverwritePrompt];
    try
      if SVDlg.Execute then
      begin
        MS.SaveToFile(SVDlg.FileName);
        MessageDialog('INFORMACIÓN', 'Libro descargado con éxito.');
      end;
    finally
      FreeAndNil(SVDlg);
      FreeAndNil(MS);
    end;
  end
  else
    MessageDialog('INFORMACIÓN', 'No fue posible descargar el libro.');
end;

class procedure TAcciones_Inicio.btnEliminarLibroClick(Sender: TObject);
var
  IdLibro: string;
  Libro: string;
  Mensaje: string;
begin
  if (frmMain.SGLibros_Inicio.RowCount > 0) and
  (frmMain.SGLibros_Inicio.Selected > -1) then
  begin
    IdLibro:= frmMain.SGLibros_Inicio.Cells[5, frmMain.SGLibros_Inicio.Selected];
    Libro:= frmMain.SGLibros_Inicio.Cells[0, frmMain.SGLibros_Inicio.Selected];
    Mensaje:= '¿Quiere elminiar el libro "' + Libro + '" ?';

    TDialogService.MessageDialog(Mensaje, TMsgDlgType.mtWarning, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo],
    TMsgDlgBtn.mbYes, 0,
    procedure (const AResult: TModalResult)
    begin
      case AResult of
        mrYes:
        begin
          if TDBActions.EliminarLibro(frmMain.ConexionGUI, IdLibro) then
          begin
            MessageDialog('Información', 'Eliminado correctamente.');
            ClearLibrosFields;
            ShowLastCategoriaChanges;
          end
          else
            MessageDialog('Información', 'No pudo realizarse la acción solicitada.');
        end;
      end;
    end);
  end;
end;

class procedure TAcciones_Inicio.btnFirstLibro_InicioClick(Sender: TObject);
begin
  if (frmMain.SGLibros_Inicio.Row > 0) and
  (frmMain.SGLibros_Inicio.Selected <> 0) then
    frmMain.SGLibros_Inicio.Selected:= 0;
end;

class procedure TAcciones_Inicio.btnInsertarLibroClick(Sender: TObject);
var
  OpnDlg: TOpenDialog;
  Thread: TThread;
begin
  if TButton(Sender).Text.Trim.Equals('Agregar') then
  begin
    PDF_FileName:= string.Empty;
    OpnDlg:= TOpenDialog.Create(frmMain);
    OpnDlg.InitialDir:= TPath.GetDocumentsPath;
    OpnDlg.Filter:= 'Portable Document Format|*.pdf';
    OpnDlg.Title:= 'Seleccionar libro electrónico';
    try
      try
        if OpnDlg.Execute then
        begin
          PDF_FileName:= OpnDlg.FileName;
          EnableLibrosInsertMode;
          frmMain.edtNombreLibro.Text:= TPath.GetFileNameWithoutExtension(PDF_FileName);
          frmMain.edtNombreLibro.SelStart:= Length(frmMain.edtNombreLibro.Text);
        end else CancelLibrosInsertMode;
      except on E: Exception do
        begin
          EscribirLog(E.ClassName + ' Error al intentar seleccionar un archivo PDF: ' +
          E.Message, 2);
          ShowMessage(E.ClassName + ': ' + E.Message);
          CancelLibrosInsertMode;
        end;
      end;
    finally
      FreeAndNil(OpnDlg);
    end;
  end else

  if TButton(Sender).Text.Trim.Equals('Aceptar') then
  begin
    TButton(Sender).Enabled:= False;

    ShowLoadingDialog;
    Thread:= TThread.CreateAnonymousThread(
    procedure
    var
      MS: TMemoryStream;
      NombreLibro, DescripLibro, AutorLibro: string;
      FechaHora: TDateTime;
      Portada, Archivo, ID_Usuario: string;
      ID_Categoria: Integer;
      Mensaje: string;
    begin
      TInterlocked.Exchange(THREAD_IS_RUNNING, True);

      //Obtención de información del libro seleccionado
      NombreLibro:= frmMain.edtNombreLibro.Text.Trim;
      DescripLibro:= frmMain.edtDescripcionLibro.Text.Trim;
      AutorLibro:= frmMain.edtAutorLibro.Text.Trim;
      FechaHora:= StrToDateTime(FormatDateTime('DD/MM/YYYY hh:nn:ss ampm', Now));

      MS:= TMemoryStream.Create;
      try
        MS.Position:= 0;
        frmMain.imgPortadaLibro_Inicio.Bitmap.SaveToStream(MS);
        Portada:= StreamToBase64String(MS);
      finally
        if MS <> nil then
          FreeAndNil(MS);
      end;

      Archivo:= FileToBase64String(PDF_FileName);
      ID_Usuario:= 'Admin';
      ID_Categoria:= frmMain.CECategoriasLibros.ItemIndex;

      //Una vez insertado el libro, se cancela el modo de inserción
      case TDBActions.InsertarLibro(frmMain.ConexionGUI, NombreLibro, DescripLibro, AutorLibro, FechaHora,
        1, Portada, Archivo, ID_Usuario, ID_Categoria) of
        -1:
        begin
          Mensaje:= 'El archivo que intenta añadir ya existe.';
          MessageDialog('Información', Mensaje);
        end;

        0:
        begin
          Mensaje:= 'No fue posible realizar la acción solicitada.';
          MessageDialog('Información', Mensaje);
        end;

        1:
        begin
          Mensaje:= 'Agregado con éxito';
          MessageDialog('Información', Mensaje);
        end;
      end;

      Sincronizar(
      procedure
      begin
        TButton(Sender).Enabled:= True;
        CancelLibrosInsertMode;
        ShowLastCategoriaChanges;
      end);
    end);
    Thread.FreeOnTerminate:= True;
    Thread.OnTerminate:= ThreadOnTerminate;
    Thread.Priority:= tpHigher;
    Thread.Start;
  end;
end;

class procedure TAcciones_Inicio.btnLastLibro_InicioClick(Sender: TObject);
begin
  if (frmMain.SGLibros_Inicio.RowCount > 0) and
  (frmMain.SGLibros_Inicio.Selected <> frmMain.SGLibros_Inicio.RowCount -1) then
    frmMain.SGLibros_Inicio.Selected:= frmMain.SGLibros_Inicio.RowCount -1;
end;

class procedure TAcciones_Inicio.btnLibros_InicioClick(Sender: TObject);
begin
  frmMain.rectIndicadorServidor.Visible:= False;
  frmMain.rectIndicadorLibros_Inicio.Visible:= True;
  frmMain.Pantallas_Opciones.ActiveTab:= frmMain.Libros;
end;

class procedure TAcciones_Inicio.btnModificarLibroClick(Sender: TObject);
var
  Thread: TThread;
begin
  if (frmMain.SGLibros_Inicio.RowCount > 0) and (frmMain.SGLibros_Inicio.Selected > -1) then
  begin
    if TButton(Sender).Text.Equals('Modificar') then
    begin
      EnableLibrosEditMode;
    end else
    if TButton(Sender).Text.Equals('Aceptar') then
    begin
      TButton(Sender).Enabled:= False;
      ShowLoadingDialog;

      Thread:= TThread.CreateAnonymousThread(
      procedure
      var
        IdLibro, Nombre, Descripcion,
        Autor: string;
        IdCategoria: Integer;
      begin
        TInterlocked.Exchange(THREAD_IS_RUNNING, True);

        IdLibro:= frmMain.SGLibros_Inicio.Cells[5, frmMain.SGLibros_Inicio.Selected];
        Nombre:= frmMain.edtNombreLibro.Text;
        Descripcion:= frmMain.edtDescripcionLibro.Text;
        Autor:= frmMain.edtAutorLibro.Text;
        IdCategoria:= frmMain.CECategoriasLibros.ItemIndex;

        if TDBActions.ModificarLibro(frmMain.ConexionGUI, IdLibro, Nombre, Descripcion, Autor, IdCategoria) then
          MessageDialog('Información', 'Modificado con éxito.')
        else
          MessageDialog('Información', 'No es posible realizar la acción solicitada.');

        Sincronizar(
        procedure
        begin
          CancelLibrosEditMode;
          TButton(Sender).Enabled:= True;
        end);
      end);
      Thread.FreeOnTerminate:= True;
      Thread.OnTerminate:= ThreadOnTerminate;
      Thread.Priority:= tpHigher;
      Thread.Start;
    end;
  end;
end;

class procedure TAcciones_Inicio.btnNextLibro_InicioClick(Sender: TObject);
begin
  if frmMain.SGLibros_Inicio.RowCount > 0 then
  begin
    if frmMain.SGLibros_Inicio.Selected = frmMain.SGLibros_Inicio.RowCount - 1 then
      frmMain.SGLibros_Inicio.Selected:= 0
    else
      frmMain.SGLibros_Inicio.Selected:= frmMain.SGLibros_Inicio.Selected + 1;
  end;
end;

class procedure TAcciones_Inicio.btnPriorLibro_InicioClick(Sender: TObject);
begin
  if frmMain.SGLibros_Inicio.RowCount > 0 then
  begin
    if frmMain.SGLibros_Inicio.Selected = 0 then
      frmMain.SGLibros_Inicio.Selected:= frmMain.SGLibros_Inicio.RowCount - 1
    else
      frmMain.SGLibros_Inicio.Selected:= frmMain.SGLibros_Inicio.Selected - 1;
  end;
end;

class procedure TAcciones_Inicio.btnProbarServidorClick(Sender: TObject);
begin
  AbrirURL(frmMain.edtURLServidor.Text + ':' + frmMain.edtPuertoServidor.Text);
  EscribirLog('Probar URL: ' + frmMain.edtURLServidor.Text +
    ':' + frmMain.edtPuertoServidor.Text, 1);

  MostrarEvento_Servidor('Probar URL: ' + frmMain.edtURLServidor.Text +
    ':' + frmMain.edtPuertoServidor.Text, 1);
end;

class procedure TAcciones_Inicio.btnServidorClick(Sender: TObject);
begin
  frmMain.rectIndicadorLibros_Inicio.Visible:= False;
  frmMain.rectIndicadorServidor.Visible:= True;
  frmMain.Pantallas_Opciones.ActiveTab:= frmMain.Servidor;
end;

class procedure TAcciones_Inicio.CancelLibrosEditMode;
begin
  FLAG_MAKING_CHANGES:= False;
  ACCION_LIBROS:= 0;
  frmMain.LYFechaLibro.Visible:= True;
  frmMain.LYUsuarioLibro.Visible:= True;
  frmMain.btnInsertarLibro.Enabled:= True;
  frmMain.btnEliminarLibro.Enabled:= True;
  ClearLibrosFields;
  frmMain.edtBuscarLibro.Enabled:= True;
  LibrosFieldsSetReadOnly(True);
  LibrosFieldsCanFocus(True);
  frmMain.btnModificarLibro.Text:= 'Modificar';
  ShowLastCategoriaChanges;
end;

class procedure TAcciones_Inicio.CancelLibrosInsertMode;
begin
  FLAG_MAKING_CHANGES:= False;
  ACCION_LIBROS:= 0;
  frmMain.LYFechaLibro.Visible:= True;
  frmMain.LYUsuarioLibro.Visible:= True;
  PDF_FileName:= string.Empty;
  frmMain.btnModificarLibro.Enabled:= True;
  frmMain.btnEliminarLibro.Enabled:= True;
  ClearLibrosFields;
  frmMain.edtBuscarLibro.Enabled:= True;
  LibrosFieldsSetReadOnly(True);
  LibrosFieldsCanFocus(True);
  frmMain.btnInsertarLibro.Text:= 'Agregar';
  ShowLastCategoriaChanges;
end;

class procedure TAcciones_Inicio.CancelLibrosSearchingMode;
begin
  frmMain.edtBuscarLibro.Text:= string.Empty;
  LAST_ID_LIBRO:= string.Empty;
  ShowLastCategoriaChanges;
  FLAG_SEARCHING_BOOK:= False;
end;

class procedure TAcciones_Inicio.CECategoriasLibrosChange(Sender: TObject);
var
  Indx: Integer;
  Libros: TArray<rLibro>;
  Id_Categoria: Integer;
begin
  Indx:= frmMain.CECategoriasLibros.ItemIndex;
  LAST_CATEGORIA:= Indx;
  if not FLAG_MAKING_CHANGES then
  begin
    if Indx > -1 then
    begin
      Libros:= TDBActions.ObtenerLibros(frmMain.ConexionGUI, Indx, False,
      frmMain.CEFiltro_Libros.ItemIndex);
      try
        MostrarLibros(Libros);
      finally
        SetLength(Libros, 0);
      end;
    end;
  end else
  begin
    if Indx = 0 then
    begin
      TThread.ForceQueue(nil,
      procedure
      begin
        MessageDialog('Información', 'Debe seleccionar una categoría.');

        if frmMain.SGLibros_Inicio.Selected > -1 then
          Id_Categoria:= frmMain.SGLibros_Inicio.Cells[6, frmMain.SGLibros_Inicio.Selected].ToInteger
        else
          Id_Categoria:= 1;
        frmMain.CECategoriasLibros.ItemIndex:= Id_Categoria;
      end);
    end;
  end;
end;

class procedure TAcciones_Inicio.CECategoriasLibrosClick(Sender: TObject);
begin
  LAST_ID_LIBRO:= string.Empty;
  TComboEdit(Sender).DropDown;
end;

class procedure TAcciones_Inicio.CEFiltro_LibrosChange(Sender: TObject);
begin
  if (TComboEdit(Sender).ItemIndex > -1) and
  (frmMain.CECategoriasLibros.ItemIndex > -1) then
    frmMain.CECategoriasLibrosChange(frmMain.CECategoriasLibros);
end;

class procedure TAcciones_Inicio.ChckBxUsarHTTPSChange(Sender: TObject);
var
  Thread: TThread;
  Check: TCheckBox;
begin
  (*
    DRH 13/11/2025
    -Se usa un hilo para permitirle al TSwicth mostrar su animación
    y el usuario sepa que el servidor ha sido reiniciado.
  *)
  Check:= Sender as TCheckBox;

  Check.Enabled:= False;
  frmMain.SWEstadoServidor.IsChecked:= False;

  Thread:= TThread.CreateAnonymousThread(
  procedure
  begin
    EscribirConfigIni('PROTOCOL', 'HTTPS', BoolToStr(Check.IsChecked, True));

    Sleep(200);

    Sincronizar(
    procedure
    begin
      frmMain.SWEstadoServidor.IsChecked:= True;
      Check.Enabled:= True;
    end);
  end);
  Thread.FreeOnTerminate:= True;
  Thread.Start;
end;

class procedure TAcciones_Inicio.ClearLibrosFields;
begin
  frmMain.edtNombreLibro.Text:= string.Empty;
  frmMain.edtDescripcionLibro.Text:= string.Empty;
  frmMain.edtAutorLibro.Text:= string.Empty;
  frmMain.edtFechaLibro.Text:= string.Empty;
  frmMain.edtUsuarioLibro.Text:= string.Empty;
  frmMain.edtBuscarLibro.Text:= string.Empty;
end;

class procedure TAcciones_Inicio.ClearLibrosFieldsAfterNoResults;
begin
  ClearLibrosFields;
  frmMain.imgPortadaLibro_Inicio.Bitmap:= frmMain.imgDefaultPortadaLibro.Bitmap;
end;

class procedure TAcciones_Inicio.edtBuscarLibroTyping(Sender: TObject);
var
  Busqueda: string;
  Libros: TArray<rLibro>;
begin
  FLAG_SEARCHING_BOOK:= True;
  Busqueda:= TEdit(Sender).Text.Trim;
  if Busqueda.IsEmpty then
  begin
    frmMain.LVResultBusq_Libros.Items.Clear;
    frmMain.LVResultBusq_Libros.Visible:= False;
    Exit;
  end;

  Libros:= TDBActions.ObtenerCoincidenciasLibros(frmMain.ConexionGUI, Busqueda);
  try
    MostrarCoincidencias(Libros);
  finally
    SetLength(Libros, 0);
  end;
end;

class procedure TAcciones_Inicio.edtNombreLibroChangeTracking(Sender: TObject);
begin
  if FLAG_MAKING_CHANGES then
  begin
    if TEdit(Sender).Text.Trim.IsEmpty then
    begin
      case ACCION_LIBROS of
        1: frmMain.btnInsertarLibro.Enabled:= False;

        2:  frmMain.btnModificarLibro.Enabled:= False;
      end;
    end else
    begin
      case ACCION_LIBROS of
        1: frmMain.btnInsertarLibro.Enabled:= True;

        2:  frmMain.btnModificarLibro.Enabled:= True;
      end;
    end;
  end;
end;

class procedure TAcciones_Inicio.edtPuertoServidorChangeTracking(
  Sender: TObject);
begin
  frmMain.rectConfirmarPuertoServidor.Visible:=
  (not (Sender as TEdit).Text.Trim.IsEmpty) and
  (isSafePort(TEdit(Sender).Text)) and
  (TEdit(Sender).Text.ToInteger >= 10) and
  (TEdit(Sender).Text.ToInteger <= 65535);
end;

class procedure TAcciones_Inicio.edtPuertoServidorEnter(Sender: TObject);
begin
  TEdit(Sender).GoToTextEnd;
  frmMain.rectConfirmarPuertoServidor.Visible:=
  (not (Sender as TEdit).Text.Trim.IsEmpty) and
  (isSafePort(TEdit(Sender).Text)) and
  (TEdit(Sender).Text.ToInteger >= 10) and
  (TEdit(Sender).Text.ToInteger <= 65535);

  frmMain.SWEstadoServidor.IsChecked:= False;
  frmMain.SWEstadoServidor.Enabled:= False;
end;

class procedure TAcciones_Inicio.edtPuertoServidorExit(Sender: TObject);
begin
  if (not (Sender as TEdit).Text.Trim.IsEmpty) and
  (isSafePort(TEdit(Sender).Text)) and
  (TEdit(Sender).Text.ToInteger >= 10) and
  (TEdit(Sender).Text.ToInteger <= 65535) then
  begin
    frmMain.rectConfirmarPuertoServidor.Visible:= False;
    EscribirConfigIni('SERVIDOR', 'PUERTO', (Sender as TEdit).Text.Trim);
  end
  else
  begin
    frmMain.edtPuertoServidor.OnChangeTracking:= nil;
    try
      if not LeerConfigIni('SERVIDOR', 'PUERTO').IsEmpty then
        TEdit(Sender).Text:= LeerConfigIni('SERVIDOR', 'PUERTO')
      else
      begin //En caso de que el ini sea eliminado antes de dispararse este evento
        TEdit(Sender).Text:= '49815';
        EscribirConfigIni('SERVIDOR', 'PUERTO', TEdit(Sender).Text.Trim);
      end;
    finally
      frmMain.edtPuertoServidor.OnChangeTracking:= frmMain.edtPuertoServidorChangeTracking;
    end;
  end;

  frmMain.SWEstadoServidor.Enabled:= True;
  frmMain.SWEstadoServidor.IsChecked:= True;
end;

class procedure TAcciones_Inicio.EnableLibrosEditMode;
var
  Id_Categoria: Integer;
begin
  FLAG_MAKING_CHANGES:= True;
  ACCION_LIBROS:= 2;
  frmMain.LYFechaLibro.Visible:= False;
  frmMain.LYUsuarioLibro.Visible:= False;
  frmMain.btnInsertarLibro.Enabled:= False;
  frmMain.btnEliminarLibro.Enabled:= False;
  frmMain.edtBuscarLibro.Enabled:= False;
  Id_Categoria:= frmMain.SGLibros_Inicio.Cells[6,
  frmMain.SGLibros_Inicio.Selected].ToInteger;
  frmMain.CECategoriasLibros.ItemIndex:= Id_Categoria;
  frmMain.CECategoriasLibrosChange(frmMain.CECategoriasLibros);



  LibrosFieldsSetReadOnly(False);
  LibrosFieldsCanFocus(True);
  frmMain.edtNombreLibro.SetFocus;
  frmMain.edtNombreLibro.GoToTextEnd;
  frmMain.btnModificarLibro.Text:= 'Aceptar';
end;

class procedure TAcciones_Inicio.EnableLibrosInsertMode;
var
  MSPortada: TMemoryStream;
begin
  FLAG_MAKING_CHANGES:= True;
  if frmMain.CECategoriasLibros.ItemIndex = 0 then
    frmMain.CECategoriasLibros.ItemIndex:= 1;
  ACCION_LIBROS:= 1;
  frmMain.LYFechaLibro.Visible:= False;
  frmMain.LYUsuarioLibro.Visible:= False;
  frmMain.btnModificarLibro.Enabled:= False;
  frmMain.btnEliminarLibro.Enabled:= False;
  ClearLibrosFields;
  frmMain.edtBuscarLibro.Enabled:= False;

  if not PDF_FileName.IsEmpty then
  begin
    MSPortada:= getPDFThumbnail(PDF_FileName, 356, 612);
    if MSPortada <> nil then
    begin
      try
        frmMain.imgPortadaLibro_Inicio.Bitmap.LoadFromStream(MSPortada); //256, 512));
      finally
        FreeAndNil(MSPortada);
      end;
    end
    else
      frmMain.imgPortadaLibro_Inicio.Bitmap:= frmMain.imgDefaultPortadaLibro.Bitmap;
  end
  else
    frmMain.imgPortadaLibro_Inicio.Bitmap:= frmMain.imgDefaultPortadaLibro.Bitmap;

  LibrosFieldsSetReadOnly(False);
  LibrosFieldsCanFocus(True);
  frmMain.btnInsertarLibro.Text:= 'Aceptar';
  frmMain.edtNombreLibro.SetFocus;
end;

class procedure TAcciones_Inicio.HttpsConfig(const aActive: Boolean);
var
  ExePath: string;
begin
  case aActive of
    True:
    begin
      if Assigned(frmMain.LIOHandleSSL) then
        FreeAndNil(frmMain.LIOHandleSSL);

      ExePath:= ExtractFileDir(ParamStr(0));

      frmMain.LIOHandleSSL := TIdServerIOHandlerSSLOpenSSL.Create(
      frmMain.FServer);
      frmMain.LIOHandleSSL.SSLOptions.CertFile:= ExePath + PathDelim + 'cert.pem';
      frmMain.LIOHandleSSL.SSLOptions.RootCertFile:= ExePath + PathDelim + 'cert.pem';
      frmMain.LIOHandleSSL.SSLOptions.KeyFile:= ExePath + PathDelim + 'key.pem';
      frmMain.LIOHandleSSL.SSLOptions.Method:= sslvTLSv1_2;
      frmMain.LIOHandleSSL.SSLOptions.Mode:= sslmServer;
      frmMain.LIOHandleSSL.SSLOptions.SSLVersions:= [sslvTLSv1_2];
      frmMain.LIOHandleSSL.OnGetPassword := OnGetSSLPassword;
      frmMain.FServer.IOHandler := frmMain.LIOHandleSSL;
      frmMain.FServer.OnQuerySSLPort := OnQuerySSLPort;
    end;

    False:
    begin
      if Assigned(frmMain.LIOHandleSSL) then
        FreeAndNil(frmMain.LIOHandleSSL);

      frmMain.FServer.IOHandler:= nil;
      frmMain.FServer.OnQuerySSLPort:= nil;
    end;
  end;
end;

class function TAcciones_Inicio.isSafePort(aPort: string): Boolean;
var
  i: Integer;
const
  unsafe_ports: array[0..130] of string = (
    '1', '7', '9', '11', '13', '15', '17', '19', '20', '21', '22', '23', '80',
    '25', '37', '42', '43', '53', '77', '79', '87', '95', '101', '102', '103',
    '104', '109', '110', '111', '113', '115', '117', '119', '123', '135', '139',
    '143', '179', '389', '427', '465', '512', '513', '514', '515', '526', '530',
    '531', '532', '540', '548', '554', '556', '563', '587', '601', '636', '993',
    '995', '2049', '3659', '4045', '6000', '6001', '6002', '6003', '6004', '6005',
    '6006', '6007', '6008', '6009', '6010', '6011', '6012', '6013', '6014', '6015',
    '6016', '6017', '6018', '6019', '6020', '6021', '6022', '6023', '6024', '6025',
    '6026', '6027', '6028', '6029', '6030', '6031', '6032', '6033', '6034', '6035',
    '6036', '6037', '6038', '6039', '6040', '6041', '6042', '6043', '6044', '6045',
    '6046', '6047', '6048', '6049', '6050', '6051', '6052', '6053', '6054', '6055',
    '6056', '6057', '6058', '6059', '6060', '6061', '6062', '6063', '6665', '6666',
    '6667', '6668', '6669');
begin
  for i:= 0 to Length(unsafe_ports) - 1 do
  begin
    if aPort.Equals(unsafe_ports[i]) then
    begin
      Result:= False;
      Exit;
    end else Result:= True;
  end;
end;

class function TAcciones_Inicio.LastRegistro: Integer;
begin
  if frmMain.SGLibros_Inicio.RowCount > 0 then
  begin
    if frmMain.SGLibros_Inicio.RowCount - 1 < LAST_LIBRO_SELECTED then
      Result:= 0
    else
      Result:= LAST_LIBRO_SELECTED;

  end else Result:= 0;
end;

class procedure TAcciones_Inicio.LibrosFieldsCanFocus(const aCanFocus: Boolean);
begin
  frmMain.edtNombreLibro.CanFocus:= aCanFocus;
  frmMain.edtDescripcionLibro.CanFocus:= aCanFocus;
  frmMain.edtAutorLibro.CanFocus:= aCanFocus;
  frmMain.edtFechaLibro.CanFocus:= aCanFocus;
  frmMain.edtUsuarioLibro.CanFocus:= aCanFocus;
end;

class procedure TAcciones_Inicio.LibrosFieldsKeyDown(Sender: TObject;
  var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
begin
  if Key = vkReturn then
  begin
    if not (FLAG_MAKING_CHANGES) then 
      Exit;
    
    if Sender = frmMain.edtNombreLibro then
    begin  
      frmMain.edtDescripcionLibro.SetFocus;
      frmMain.edtDescripcionLibro.GoToTextEnd;
    end else 
    
    if Sender = frmMain.edtDescripcionLibro then
    begin  
      frmMain.edtAutorLibro.SetFocus;
      frmMain.edtAutorLibro.GoToTextEnd;
    end else 
    
    if Sender = frmMain.edtAutorLibro then 
    begin
      frmMain.edtNombreLibro.SetFocus;
      frmMain.edtNombreLibro.GoToTextEnd;
    end;
  end;
end;

class procedure TAcciones_Inicio.LibrosFieldsSetReadOnly(const aValue: Boolean);
begin
  frmMain.edtNombreLibro.ReadOnly:= aValue;
  frmMain.edtDescripcionLibro.ReadOnly:= aValue;
  frmMain.edtAutorLibro.ReadOnly:= aValue;
  frmMain.edtFechaLibro.ReadOnly:= aValue;
  frmMain.edtUsuarioLibro.ReadOnly:= aValue;
end;

class procedure TAcciones_Inicio.LoadServerSettings;
var
  PuertoStr: string;
  UsaHttps: string;
begin
  frmMain.edtURLServidor.Text:= string.Empty;
  frmMain.mmoEventosServidor.Lines.Clear;
  frmMain.edtPuertoServidor.OnChangeTracking:= nil;

  PuertoStr:= LeerConfigIni('SERVIDOR', 'PUERTO');
  if PuertoStr.IsEmpty then
  begin
    //Desde aquí se guardará el puerto por defecto
    frmMain.edtPuertoServidor.Text:= '49815';
    EscribirConfigIni('SERVIDOR', 'PUERTO', frmMain.edtPuertoServidor.Text.Trim);
  end else frmMain.edtPuertoServidor.Text:= PuertoStr;

  frmMain.edtPuertoServidor.OnChangeTracking:= frmMain.edtPuertoServidorChangeTracking;
  frmMain.rectConfirmarPuertoServidor.Visible:= False;

  frmMain.ChckBxUsarHTTPS.OnChange:= nil;

  UsaHttps:= LeerConfigIni('PROTOCOL', 'HTTPS');
  if UsaHttps.IsEmpty then
  begin
    frmMain.ChckBxUsarHTTPS.IsChecked:= False;
    EscribirConfigIni('PROTOCOL', 'HTTPS', BoolToStr(False, True));
  end
  else
    frmMain.ChckBxUsarHTTPS.IsChecked:= StrToBool(UsaHttps);

  frmMain.ChckBxUsarHTTPS.OnChange:= frmMain.ChckBxUsarHTTPSChange;
  frmMain.SWEstadoServidor.IsChecked:= True;
end;

class procedure TAcciones_Inicio.LVResultBusq_LibrosItemClick(
  const Sender: TObject; const AItem: TListViewItem);
var
  Libro: rLibro;
begin
  LAST_CATEGORIA:= AItem.Tag;
  LAST_ID_LIBRO:= AItem.ButtonText;
  //frmMain.edtBuscarLibro.Text:= string.Empty;
  frmMain.LVResultBusq_Libros.Items.Clear;
  frmMain.LVResultBusq_Libros.Visible:= False;
  frmMain.CECategoriasLibros.ItemIndex:= LAST_CATEGORIA;
  Libro:= TDBActions.ObtenerLibroPorId(frmMain.ConexionGUI, LAST_ID_LIBRO, False, False);
  MostrarLibros([Libro]);
end;

class procedure TAcciones_Inicio.MostrarCategorias(var Categorias: TArray<rCategoria>);
var
  i: Integer;
begin
  frmMain.CECategoriasLibros.Items.Clear;
  frmMain.CECategoriasLibros.Text:= string.Empty;
  frmMain.CECategoriasLibros.ItemIndex:= -1;
  frmMain.CECategoriasLibros.BeginUpdate;

  for i:= 0 to Length(Categorias) - 1 do
  begin
    frmMain.CECategoriasLibros.Items.Add(Categorias[i].Descripcion);
  end;
  frmMain.CECategoriasLibros.EndUpdate;
  frmMain.CECategoriasLibros.ItemIndex:= 0;
  frmMain.CECategoriasLibros.OnChange(frmMain.CECategoriasLibros);
end;

class procedure TAcciones_Inicio.MostrarCoincidencias(var Libros: TArray<rLibro>);
var
  i: Integer;
  Item: TListViewItem;
begin
  frmMain.LVResultBusq_Libros.Items.Clear;
  if Length(Libros) > 0 then
  begin
    frmMain.LVResultBusq_Libros.BeginUpdate;
    for i:= 0 to Length(Libros) - 1 do
    begin
      Item:= frmMain.LVResultBusq_Libros.Items.Add;
      Item.Text:= Libros[i].Nombre;

      if Libros[i].Descripcion.IsEmpty then
      begin
        if not Libros[i].Autor.IsEmpty then
          Item.Detail:= 'Autor: ' + Libros[i].Autor;
      end else
      begin
        if not Libros[i].Autor.IsEmpty then
          Item.Detail:= 'Autor: ' + Libros[i].Autor + '   Descripción: ' + Libros[i].Descripcion
        else
          Item.Detail:= 'Descripción: ' + Libros[i].Descripcion;
      end;

      Item.ButtonText:= Libros[i].Id;
      Item.Tag:= Libros[i].Id_Categoria;
    end;
    frmMain.LVResultBusq_Libros.EndUpdate;
    frmMain.LVResultBusq_Libros.Visible:= True;
  end else frmMain.LVResultBusq_Libros.Visible:= False;
end;

class procedure TAcciones_Inicio.MostrarEvento_Servidor(const Mensaje: string;
  const Nivel: Integer);
begin
  TThread.Queue(nil,
  procedure
  begin
    //Limpiar cada 100 registros
    if frmMain.mmoEventosServidor.Lines.Count = 100 then
      frmMain.mmoEventosServidor.Lines.Clear;

    case Nivel of
      1: frmMain.mmoEventosServidor.Lines.Add(
        FormatDateTime('DD/MM/YYYY hh:nn ampm', Now) + ' - ' + Mensaje);

      2: frmMain.mmoEventosServidor.Lines.Add(
        FormatDateTime('DD/MM/YYYY hh:nn ampm', Now) + ' - Excepción: ' + Mensaje);
    end;

    frmMain.mmoEventosServidor.GoToTextEnd;
  end);
end;

class procedure TAcciones_Inicio.MostrarLibros(const Libros: TArray<rLibro>);
var
  i: Integer;
begin
  frmMain.SGLibros_Inicio.RowCount:= 0;
  if Length(Libros) > 0 then
  begin
    frmMain.lblNoHayLibrosAMostrar_Libros.Visible:= False;
    frmMain.GpnlLYBtnsAccRegLibros.Visible:= True;
    frmMain.SGLibros_Inicio.Visible:= True;
    frmMain.SGLibros_Inicio.BeginUpdate;
    for i:= 0 to Length(Libros) - 1 do
    begin
      frmMain.SGLibros_Inicio.RowCount:= frmMain.SGLibros_Inicio.RowCount + 1;
      frmMain.SGLibros_Inicio.Cells[5, i]:= Libros[i].Id;
      frmMain.SGLibros_Inicio.Cells[6, i]:= Libros[i].Id_Categoria.ToString;
      frmMain.SGLibros_Inicio.Cells[0, i]:= Libros[i].Nombre;
      frmMain.SGLibros_Inicio.Cells[1, i]:= Libros[i].Descripcion;
      frmMain.SGLibros_Inicio.Cells[2, i]:= Libros[i].Autor;
      frmMain.SGLibros_Inicio.Cells[3, i]:= Libros[i].Fechahora;
      frmMain.SGLibros_Inicio.Cells[4, i]:= Libros[i].Usuario;
    end;
   frmMain.SGLibros_Inicio.EndUpdate;
   frmMain.SGLibros_Inicio.Selected:= LastRegistro;
   frmMain.SGLibros_Inicio.RealignContent;
  end else
  begin
    frmMain.SGLibros_Inicio.Visible:= False;
    frmMain.GpnlLYBtnsAccRegLibros.Visible:= False;
    frmMain.lblNoHayLibrosAMostrar_Libros.Visible:= True;
    ClearLibrosFieldsAfterNoResults;
  end;
end;

class procedure TAcciones_Inicio.OnGetSSLPassword(var APassword: String);
begin
  APassword:= '';
end;

class procedure TAcciones_Inicio.OnQuerySSLPort(APort: TIdPort; var AUseSSL: Boolean);
begin
  AUseSSL:= True;
end;

class procedure TAcciones_Inicio.SGLibros_InicioApplyStyleLookup(
  Sender: TObject);
begin
  ColorFondoHeaderStringGrid(TStringGrid(Sender));
end;

class procedure TAcciones_Inicio.SGLibros_InicioSelChanged(Sender: TObject);
var
  Grid: TStringGrid;
  idLibro: string;
  (*
    Se toman del StringGrid para evitar consultar
    dichos datos de la Base de Datos.
  *)
  Nombre_Libro, Descrip_Libro,
  Autor_Libro, FechaHora_Libro,
  Usuario_Libro: string;
  MSPortada: TStream;
begin
  Grid:= Sender as TStringGrid;
  if Grid.Selected > -1 then
  begin
    LAST_LIBRO_SELECTED:= TStringGrid(Sender).Selected;
    idLibro:= Grid.Cells[5, Grid.Selected];
    LAST_ID_LIBRO:= idLibro;

    Nombre_Libro:= Grid.Cells[0, Grid.Selected];
    Descrip_Libro:= Grid.Cells[1, Grid.Selected];
    Autor_Libro:= Grid.Cells[2, Grid.Selected];
    FechaHora_Libro:= Grid.Cells[3, Grid.Selected];
    Usuario_Libro:= Grid.Cells[4, Grid.Selected];

    frmMain.edtNombreLibro.Text:= Nombre_Libro;
    frmMain.edtDescripcionLibro.Text:= Descrip_Libro;
    frmMain.edtAutorLibro.Text:= Autor_Libro;
    frmMain.edtFechaLibro.Text:= FechaHora_Libro;
    frmMain.edtUsuarioLibro.Text:= Usuario_Libro;

    MSPortada:= TDBActions.ObtenerPortadaLibroPorID(frmMain.ConexionGUI,
    idLibro);
    try
      if MSPortada <> nil then
        frmMain.imgPortadaLibro_Inicio.Bitmap.LoadFromStream(MSPortada)
      else
        frmMain.imgPortadaLibro_Inicio.Bitmap:= frmMain.imgDefaultPortadaLibro.Bitmap;
    finally
      if MSPortada <> nil then
        FreeAndNil(MSPortada);
    end;
  end;
end;

class procedure TAcciones_Inicio.ShowLastCategoriaChanges;
begin
  if LAST_CATEGORIA > -1 then
    frmMain.CECategoriasLibros.ItemIndex:= LAST_CATEGORIA
  else 
    frmMain.CECategoriasLibros.ItemIndex:= 0;

  frmMain.CECategoriasLibros.OnChange(frmMain.CECategoriasLibros);
end;

class procedure TAcciones_Inicio.SWEstadoServidorSwitch(Sender: TObject);
begin
  TThread.ForceQueue(nil,
  procedure
  var
    ip: string;
    UsaHTTPS: Boolean;
  begin
    //DRH 13/11/2025
    UsaHTTPS:= frmMain.ChckBxUsarHTTPS.IsChecked;

    ip:= GetLocalIPAddress;
    if ip.IsEmpty then
    begin
      frmMain.edtURLServidor.Text:= string.Empty;
      frmMain.FServer.Active:= False;
      frmMain.FServer.Bindings.Clear;
      frmMain.lblEstadoServidor.Text:= 'Servidor: apagado';
      frmMain.btnProbarServidor.Enabled:= False;
      TSwitch(Sender).OnSwitch:= nil;
      TSwitch(Sender).IsChecked:= False;
      TSwitch(Sender).OnSwitch:= frmMain.SWEstadoServidorSwitch;
      EscribirLog('Verificar configuración de red del equipo.');
      MostrarEvento_Servidor(
      'Verificar configuración de red del equipo', 1);
      frmMain.lblInfoURLServidor.Text:= 'No se puede conectar ningún usuario, servidor apagado.';
      Exit;
    end else
    begin
      case UsaHTTPS of
        True: frmMain.edtURLServidor.Text:= 'https://' + ip;

        False: frmMain.edtURLServidor.Text:= 'http://' + ip;
      end;
    end;

    try
      if TSwitch(Sender).IsChecked then
      begin
        try
          frmMain.FServer.Active:= False;
          frmMain.FServer.Bindings.Clear;

          //DRH 14/11/2025
          HttpsConfig(UsaHTTPS);
        finally
          frmMain.FServer.Bindings.Clear;
          frmMain.FServer.DefaultPort := StrToInt(frmMain.edtPuertoServidor.Text);
          frmMain.FServer.Active := True;
          frmMain.btnProbarServidor.Enabled:= True;
          frmMain.lblEstadoServidor.Text:= 'Servidor: encendido';
          frmMain.lblinfoURLServidor.Text:= 'URL a la que deberán conectarse los usuarios: ' +
          frmMain.edtURLServidor.Text + ' Puerto: ' + frmMain.edtPuertoServidor.Text;
          MostrarEvento_Servidor('Servidor encendido, IP= ' + ip + ', Puerto: ' +
          frmMain.edtPuertoServidor.Text);
          EscribirLog('Servidor encendido, IP= ' + ip + ', Puerto: ' +
          frmMain.edtPuertoServidor.Text, 1);
        end;
      end else
      begin
        frmMain.FServer.Active:= False;
        frmMain.FServer.Bindings.Clear;
        frmMain.btnProbarServidor.Enabled:= False;
        frmMain.lblEstadoServidor.Text:= 'Servidor: apagado';
        frmMain.lblInfoURLServidor.Text:= 'No se puede conectar ningún usuario, servidor apagado.';
        EscribirLog('Servidor apagado', 1);
        MostrarEvento_Servidor('Servidor apagado', 1);
      end;
    except
      on E: exception do
      begin
        if E.ClassName.Equals('EIdCouldNotBindSocket') then
        begin
          EscribirLog(E.ClassName + ': ' + E.Message, 2);
          MostrarEvento_Servidor('Error al encender servidor: el puerto asignado ya está en uso', 2);
        end else
        begin
          EscribirLog(E.ClassName + ': ' + E.Message, 2);
          MostrarEvento_Servidor('Error al encender servidor: ' + E.Message, 2);
        end;

        frmMain.FServer.Active:= False;
        frmMain.FServer.Bindings.Clear;
        frmMain.lblEstadoServidor.Text:= 'Servidor: apagado';
        frmMain.lblInfoURLServidor.Text:= 'No se puede conectar ningún usuario, servidor apagado.';
        frmMain.btnProbarServidor.Enabled:= False;
        TSwitch(Sender).OnSwitch:= nil;
        TSwitch(Sender).IsChecked:= False;
        TSwitch(Sender).OnSwitch:= frmMain.SWEstadoServidorSwitch;
      end;
    end;
  end);
end;

class procedure TAcciones_Inicio.ThreadOnTerminate(Sender: TObject);
begin
  TInterlocked.Exchange(THREAD_IS_RUNNING, False);

  Encolar(
  procedure
  begin
    HideLoadingDialog;
  end);
end;

end.

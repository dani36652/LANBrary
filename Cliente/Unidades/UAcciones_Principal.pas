unit UAcciones_Principal;

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
  FMX.MediaLibrary, FMX.Objects, FMX.DialogService, FMX.ComboEdit,
  FMX.Layouts, FMX.Controls.Presentation, FMX.Edit, FMX.StdCtrls;

type TAcciones_Principal = class
  private
    class procedure MostrarLibros(const Id_categoria, Filtro, Accion: Integer);
    class procedure ThreadOnTerminate(Sender: TObject);
    class procedure Salir;
  public
    class procedure btnMVOpciones_PrincipalClick(Sender: TObject);
    class procedure btnFiltroBusqueda_PrincipalClick(Sender: TObject);
    class procedure CBECategorias_PrincipalChange(Sender: TObject);
    class procedure RBtnFiltroBusqueda_PrincipalClick(Sender: TObject);
    class procedure btnPriorLibro_PrincipalClick(Sender: TObject);
    class procedure btnNextLibro_PrincipalClick(Sender: TObject);
    class procedure btnSalir_PrincipalClick(Sender: TObject);
    class procedure MVOpciones_PrincipalHidden(Sender: TObject);
    class procedure btnMiCuenta_PrincipalClick(Sender: TObject);
    class procedure MVOpciones_ClasificacionLibrosHidden(Sender: TObject);
    class procedure MVOpciones_ClasificacionLibrosStartShowing(Sender: TObject);
    class procedure MVOpciones_PrincipalStartShowing(Sender: TObject);
    class procedure MVOpcionesFotoPerfilHidden(Sender: TObject);
    class procedure MVOpcionesFotoPerfilStartShowing(Sender: TObject);
    class procedure btnDescargas_PrincipalClick(Sender: TObject);
    class procedure edtBuscar_PrincipalChange(Sender: TObject);
    class procedure edtBuscar_PrincipalTyping(Sender: TObject);
    class procedure EdtBtnClearBusqueda_PrincipalClick(Sender: TObject);
end;

implementation
uses
  Generales, UMain, ELibro, ULibros, System.SyncObjs, FMX.MultiView,
  UAcciones_MiCuenta, UAcciones_Descargas, UJSONTool, EPagina;

{ TAcciones_Principal }

class procedure TAcciones_Principal.btnDescargas_PrincipalClick(
  Sender: TObject);
begin
  OPCION_SELECCIONADA:= 2;
  frmMain.MVOpciones_Principal.HideMaster;
end;

class procedure TAcciones_Principal.btnFiltroBusqueda_PrincipalClick(
  Sender: TObject);
begin
  frmMain.MVOpciones_ClasificacionLibros.ShowMaster;
end;

class procedure TAcciones_Principal.btnMiCuenta_PrincipalClick(Sender: TObject);
begin
  OPCION_SELECCIONADA:= 1;
  frmMain.MVOpciones_Principal.HideMaster;
end;

class procedure TAcciones_Principal.btnMVOpciones_PrincipalClick(
  Sender: TObject);
begin
  frmMain.MVOpciones_Principal.ShowMaster;
end;

class procedure TAcciones_Principal.btnNextLibro_PrincipalClick(
  Sender: TObject);
var
  Id_Categoria, Filtro: Integer;
begin
  if PaginaActual.Indx > -1 then
  begin
    Id_Categoria:= frmMain.CBECategorias_Principal.ItemIndex;
    filtro:= 0;

    if frmMain.RBtnMasReciente.IsChecked then
      filtro:= 0;

    if frmMain.RBtnMasAntiguo.IsChecked then
      filtro:= 1;

    MostrarLibros(Id_Categoria, filtro, 2);
  end;
end;

class procedure TAcciones_Principal.btnPriorLibro_PrincipalClick(
  Sender: TObject);
var
  Id_Categoria, Filtro: Integer;
begin
  if PaginaActual.Indx > 0 then
  begin
    Id_Categoria:= frmMain.CBECategorias_Principal.ItemIndex;
    filtro:= 0;

    if frmMain.RBtnMasReciente.IsChecked then
      filtro:= 0;

    if frmMain.RBtnMasAntiguo.IsChecked then
      filtro:= 1;

    MostrarLibros(Id_Categoria, filtro, 1);
  end;
end;

class procedure TAcciones_Principal.btnSalir_PrincipalClick(Sender: TObject);
begin
  Salir;
end;

class procedure TAcciones_Principal.CBECategorias_PrincipalChange(
 Sender: TObject);
var
  indx, filtro: Integer;
begin
  indx:= TComboEdit(Sender).ItemIndex;

  if indx = -1 then
  begin
    frmMain.LYContent_Principal.Visible:= False;
    frmMain.lblNoHayLibrosAMostrar_Libros.Visible:= True;
    frmMain.edtBuscar_Principal.Enabled:= False;
  end else
  begin
    frmMain.edtBuscar_Principal.Enabled:= True;
    filtro:= 0;

    if frmMain.RBtnMasReciente.IsChecked then
      filtro:= 0;

    if frmMain.RBtnMasAntiguo.IsChecked then
      filtro:= 1;

    MostrarLibros(indx, filtro, 0);
  end;
end;

class procedure TAcciones_Principal.EdtBtnClearBusqueda_PrincipalClick(
  Sender: TObject);
var
  EdtBtn: TClearEditButton;
begin
  EdtBtn:= Sender as TClearEditButton;
  EdtBtn.Visible:= False;
end;

class procedure TAcciones_Principal.edtBuscar_PrincipalChange(Sender: TObject);
var
  EdtSearch: TEdit;
  Search: string;
  Indx: Integer;
  Filtro: Integer;
begin
  EdtSearch:= Sender as TEdit;
  Search:= EdtSearch.Text.Trim;

  FLAG_SEARCHING_BOOKS:= not Search.IsEmpty;

  indx:= frmMain.CBECategorias_Principal.ItemIndex;

  if indx > -1 then
  begin
    filtro:= 0;

    if frmMain.RBtnMasReciente.IsChecked then
      filtro:= 0;

    if frmMain.RBtnMasAntiguo.IsChecked then
      filtro:= 1;

    MostrarLibros(indx, filtro, 0);
  end;
end;

class procedure TAcciones_Principal.edtBuscar_PrincipalTyping(Sender: TObject);
var
  Edit: TEdit;
  Text: string;
begin
  Edit:= Sender as TEdit;
  Text:= Edit.Text.Trim;
  frmMain.EdtBtnClearBusqueda_Principal.Visible:= not Text.IsEmpty;
end;

class procedure TAcciones_Principal.MostrarLibros(const Id_categoria,
  Filtro, Accion: Integer);
var
  Thread: TThread;
  KeyWord: string;
begin
  (*
    DRH 22/11/2025
    -EVITA EJECUCIONES SIMULTANEAS ACCIDENTALES DE ESTE HILO
  *)

  CriticalSection.Acquire;
  try
    if THREAD_IS_RUNNING then
     Exit;
  finally
    CriticalSection.Release;
  end;

  ShowLoadingDialog;

  Thread:= TThread.CreateAnonymousThread(
  procedure
  var
    Libros: TArray<rLibro>;
    StrId, StrFechahora: string;
    IdCategoria: Integer;
    Indx: Integer;
    Usr_Bloqueado: Boolean;
    StatusCode: Integer;
  begin
    TInterlocked.Exchange(THREAD_IS_RUNNING, True);

    (*
      Valores que puede tomar "Accion"
      0:  Ninguna (Mostrar todo desde pagina 1)
      1:  Prior
      2:  Next
    *)

    case Accion of
      0:
      begin
        case FLAG_SEARCHING_BOOKS of
          True:
          begin
            Sincronizar(
            procedure
            begin
              KeyWord:= frmMain.edtBuscar_Principal.Text.Trim;
            end);

            Libros:= TJSONTool.BuscarLibros(KeyWord, id_categoria, Filtro, 16,
            Usr_Bloqueado, StatusCode);
          end;

          False:
            Libros:= TJSONTool.ObtenerLibros(id_categoria, filtro, 16,
            Usr_Bloqueado, StatusCode);
        end;

        if Length(Libros) > 0 then
        begin
          LimpiarPaginas;
          SetLength(Paginas, Length(Paginas) + 1);
          Paginas[High(Paginas)].Indx:= High(Paginas);
          Paginas[High(Paginas)].Ult_Id:= Libros[High(Libros)].Id;
          Paginas[High(Paginas)].Ult_Fechahora:= Libros[High(Libros)].Fechahora;
          Paginas[High(Paginas)].Ult_IdCategoria:= Libros[High(Libros)].Id_Categoria;

          PaginaActual.Indx:= Paginas[High(Paginas)].Indx;
          PaginaActual.Ult_Id:= Paginas[High(Paginas)].Ult_Id;
          PaginaActual.Ult_Fechahora:= Paginas[High(Paginas)].Ult_Fechahora;
          PaginaActual.Ult_IdCategoria:= Paginas[High(Paginas)].Ult_IdCategoria;
        end;
      end;

      1: //Prior
      begin
        case PaginaActual.Indx of
          1:
          begin
            case FLAG_SEARCHING_BOOKS of
              True:
              begin
                Sincronizar(
                procedure
                begin
                  KeyWord:= frmMain.edtBuscar_Principal.Text.Trim;
                end);

                Libros:= TJSONTool.BuscarLibros(KeyWord, id_categoria, Filtro,
                16, Usr_Bloqueado, StatusCode);
              end;

              False:
                Libros:= TJSONTool.ObtenerLibros(id_categoria, filtro, 16,
                Usr_Bloqueado, StatusCode);
            end;

            if Length(Libros) > 0 then
            begin
              LimpiarPaginas;
              SetLength(Paginas, Length(Paginas) + 1);
              Paginas[High(Paginas)].Indx:= High(Paginas);
              Paginas[High(Paginas)].Ult_Id:= Libros[High(Libros)].Id;
              Paginas[High(Paginas)].Ult_Fechahora:= Libros[High(Libros)].Fechahora;
              Paginas[High(Paginas)].Ult_IdCategoria:= Libros[High(Libros)].Id_Categoria;

              PaginaActual.Indx:= Paginas[High(Paginas)].Indx;
              PaginaActual.Ult_Id:= Paginas[High(Paginas)].Ult_Id;
              PaginaActual.Ult_Fechahora:= Paginas[High(Paginas)].Ult_Fechahora;
              PaginaActual.Ult_IdCategoria:= Paginas[High(Paginas)].Ult_IdCategoria;
            end;
          end
          else
          begin
            //Obtener registros a partir del ultimo registro 2 posiciones antes
            Indx:= PaginaActual.Indx - 2;

            case FLAG_SEARCHING_BOOKS of
              True:
              begin
                Sincronizar(
                procedure
                begin
                  KeyWord:= frmMain.edtBuscar_Principal.Text.Trim;
                end);

                Libros:= TJSONTool.BuscarLibros(KeyWord, Filtro,
                Paginas[Indx].Ult_IdCategoria,
                Paginas[Indx].Ult_Fechahora, Paginas[Indx].Ult_Id, 16,
                Usr_Bloqueado, StatusCode);
              end;

              False:
                Libros:= TJSONTool.ObtenerLibros(Filtro,
                Paginas[Indx].Ult_IdCategoria,
                Paginas[Indx].Ult_Fechahora, Paginas[Indx].Ult_Id, 16,
                Usr_Bloqueado, StatusCode);
            end;

            if Length(Libros) > 0 then
            begin
              StrId:= Libros[High(Libros)].Id;
              StrFechahora:= Libros[High(Libros)].Fechahora;
              IdCategoria:= Libros[High(Libros)].Id_Categoria;

              Indx:= PaginaActual.Indx - 1;

              if (not StrId.Equals(Paginas[Indx].Ult_Id))
              or (not StrFechahora.Equals(Paginas[Indx].Ult_Fechahora))
              or (IdCategoria <> Paginas[Indx].Ult_IdCategoria) then
              begin
                Paginas[Indx].Ult_Id:= StrId;
                Paginas[Indx].Ult_Fechahora:= StrFechahora;
                Paginas[Indx].Ult_IdCategoria:= IdCategoria;
              end;

              PaginaActual.Indx:= Indx;
              PaginaActual.Ult_Id:= Paginas[Indx].Ult_Id;
              PaginaActual.Ult_Fechahora:= Paginas[Indx].Ult_Fechahora;
              PaginaActual.Ult_IdCategoria:= Paginas[Indx].Ult_IdCategoria;
            end;
          end;
        end;
      end;

      2: //Next
      begin
        case FLAG_SEARCHING_BOOKS of
          True:
          begin
            Sincronizar(
            procedure
            begin
              KeyWord:= frmMain.edtBuscar_Principal.Text.Trim;
            end);

            Libros:= TJSONTool.BuscarLibros(KeyWord, Filtro,
            PaginaActual.Ult_IdCategoria, PaginaActual.Ult_Fechahora,
            PaginaActual.Ult_Id, 16, Usr_Bloqueado, StatusCode);
          end;

          False:
            Libros:= TJSONTool.ObtenerLibros(Filtro,
            PaginaActual.Ult_IdCategoria, PaginaActual.Ult_Fechahora,
            PaginaActual.Ult_Id, 16, Usr_Bloqueado, StatusCode);
        end;

        if Length(Libros) > 0 then
        begin
          if (PaginaActual.Indx + 1) = Length(Paginas) then
          begin
            SetLength(Paginas, Length(Paginas) + 1);
            Paginas[High(Paginas)].Indx:= High(Paginas);
            Paginas[High(Paginas)].Ult_Id:= Libros[High(Libros)].Id;
            Paginas[High(Paginas)].Ult_Fechahora:= Libros[High(Libros)].Fechahora;
            Paginas[High(Paginas)].Ult_IdCategoria:= Libros[High(Libros)].Id_Categoria;

            PaginaActual.Indx:= Paginas[High(Paginas)].Indx;
            PaginaActual.Ult_Id:= Paginas[High(Paginas)].Ult_Id;
            PaginaActual.Ult_Fechahora:= Paginas[High(Paginas)].Ult_Fechahora;
            PaginaActual.Ult_IdCategoria:= Paginas[High(Paginas)].Ult_IdCategoria;
          end else
          begin
            Indx:= PaginaActual.Indx + 1;

            StrId:= Libros[High(Libros)].Id;
            StrFechahora:= Libros[High(Libros)].Fechahora;
            IdCategoria:= Libros[High(Libros)].Id_Categoria;

            if (not StrId.Equals(Paginas[Indx].Ult_Id))
            or (not StrFechahora.Equals(Paginas[Indx].Ult_Fechahora))
            or (IdCategoria <> Paginas[Indx].Ult_IdCategoria) then
            begin
              Paginas[Indx].Ult_Id:= StrId;
              Paginas[Indx].Ult_Fechahora:= StrFechahora;
              Paginas[Indx].Ult_IdCategoria:= IdCategoria;
            end;

            PaginaActual.Indx:= Indx;
            PaginaActual.Ult_Id:= Paginas[Indx].Ult_Id;
            PaginaActual.Ult_Fechahora:= Paginas[Indx].Ult_Fechahora;
            PaginaActual.Ult_IdCategoria:= Paginas[Indx].Ult_IdCategoria;
          end;
        end else Exit;
      end;
    end;

    if Usr_Bloqueado = True then
    begin
      UsuarioBloqueado;

      SetLength(Libros, 0);
      LimpiarPaginas;
      PaginaActual:= Default(TPagina);
      Exit;
    end;

    try
      Sincronizar(
      procedure
      begin
        if CrearBotonesLibros(frmMain.LYContent_Principal, Libros) then
        begin
          frmMain.lblPageCounter_Principal.Text:= 'Página: ' +
          IntToStr(PaginaActual.Indx + 1);
          frmMain.GPNLyBtns_Principal.Visible:= True;
          frmMain.lblNoHayLibrosAMostrar_Libros.Visible:= False;
          frmMain.LYContent_Principal.Visible:= True;
          frmMain.btnNextLibro_Principal.Enabled:= False;
          //frmMain.edtBuscar_Principal.Enabled:= True;
        end else
        begin
          frmMain.GPNLyBtns_Principal.Visible:= False;
          frmMain.lblPageCounter_Principal.Text:= 'Página: 1';
          frmMain.LYContent_Principal.Visible:= False;
          frmMain.lblNoHayLibrosAMostrar_Libros.Visible:= True;
          frmMain.btnNextLibro_Principal.Enabled:= False;
          //frmMain.edtBuscar_Principal.Enabled:= False;
        end;
      end);
    finally
      SetLength(Libros, 0);
    end;
  end);

  Thread.FreeOnTerminate:= True;
  Thread.OnTerminate:= ThreadOnTerminate;
  {$IFDEF MSWINDOWS}
  Thread.Priority:= tpHigher;
  {$ENDIF}
  Thread.Start;
end;

class procedure TAcciones_Principal.MVOpcionesFotoPerfilHidden(Sender: TObject);
begin
  TMultiView(Sender).Enabled:= False;
end;

class procedure TAcciones_Principal.MVOpcionesFotoPerfilStartShowing(
  Sender: TObject);
begin
  TMultiView(Sender).Enabled:= True;
end;

class procedure TAcciones_Principal.MVOpciones_ClasificacionLibrosHidden(
  Sender: TObject);
begin
  TMultiView(Sender).Enabled:= False;
end;

class procedure TAcciones_Principal.MVOpciones_ClasificacionLibrosStartShowing(
  Sender: TObject);
begin
  TMultiView(Sender).Enabled:= True;
end;

class procedure TAcciones_Principal.MVOpciones_PrincipalHidden(Sender: TObject);
begin
  case OPCION_SELECCIONADA of
    1:  TAcciones_MiCuenta.MostrarInfo;

    2: TAcciones_Descargas.CargarDescargas;
  end;
  OPCION_SELECCIONADA:= -1;

  TMultiView(Sender).Enabled:= False;
end;

class procedure TAcciones_Principal.MVOpciones_PrincipalStartShowing(
  Sender: TObject);
begin
  TMultiView(Sender).Enabled:= True;
end;

class procedure TAcciones_Principal.RBtnFiltroBusqueda_PrincipalClick(
  Sender: TObject);
var
  indx, filtro: Integer;
begin
  frmMain.MVOpciones_ClasificacionLibros.HideMaster;

  indx:= frmMain.CBECategorias_Principal.ItemIndex;

  if indx = -1 then
  begin
    frmMain.LYContent_Principal.Visible:= False;
    frmMain.lblNoHayLibrosAMostrar_Libros.Visible:= True;
  end else
  begin
    filtro:= 0;

    if Sender = frmMain.RBtnMasReciente then
      filtro:= 0;

    if Sender = frmMain.RBtnMasAntiguo then
      filtro:= 1;

    MostrarLibros(indx, filtro, 0);
  end;
end;

class procedure TAcciones_Principal.Salir;
begin
  frmMain.MVOpciones_Principal.HideMaster;
  try
    frmMain.Pantallas.ActiveTab:= frmMain.Login;
  finally
    LimpiarBotonesLibros;
    frmMain.CBECategorias_Principal.Index:= -1;
    frmMain.CBECategorias_Principal.Text:= string.Empty;
    frmMain.edtBuscar_Principal.Text:= string.Empty;
    frmMain.RBtnMasReciente.IsChecked:= True;
    frmMain.lblPageCounter_Principal.Text:= 'Pagina: 1';
    frmMain.GPNLyBtns_Principal.Visible:= False;
    frmMain.btnNextLibro_Principal.Enabled:= False;
  end;
end;

class procedure TAcciones_Principal.ThreadOnTerminate(Sender: TObject);
begin
  TInterlocked.Exchange(THREAD_IS_RUNNING, False);

  Encolar(
  procedure
  begin
    HideLoadingDialog;
  end);
end;

end.

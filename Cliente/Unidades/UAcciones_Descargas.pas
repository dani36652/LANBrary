unit UAcciones_Descargas;

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
  System.Generics.Collections, FMX.ListView, FMX.ListView.Appearances,
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.TabControl,
  FMX.MediaLibrary, FMX.Objects, FMX.DialogService, System.SyncObjs,
  FMX.Layouts, FMX.Controls.Presentation, FMX.Edit, FMX.StdCtrls;

type TAcciones_Descargas = class
  private
    class procedure ClearContent;
    //class procedure ThreadOnTerminate(Sender: TObject);
    class procedure ClearUnusedThumbnails;
  public
    class procedure btnAtrasDescargasClick(Sender: TObject);
    class procedure CargarDescargas;
    class procedure edtBuscar_DescargasChangeTracking(Sender: TObject);
    class procedure LVDescargasItemsChange(Sender: TObject);
    class procedure LVDescargasItemClick(const Sender: TObject;
    const AItem: TListViewItem);
    class procedure btnEliminar_DescargasClick(Sender: TObject);
    class procedure btnLeer_DescargasClick(Sender: TObject);
end;

implementation
uses
  UMain, System.IOUtils, Generales, UMainFormEvents;

{ TAcciones_Descargas }

class procedure TAcciones_Descargas.btnAtrasDescargasClick(Sender: TObject);
begin
  ClearUnusedThumbnails;
  frmMain.Pantallas.ActiveTab:= frmMain.Principal;
  if FLAG_BOOK_DELETED = True then
  begin
    FLAG_BOOK_DELETED:= False;
    if frmMain.CBECategorias_Principal.ItemIndex > -1 then
      frmMain.CBECategorias_Principal.OnChange(frmMain.CBECategorias_Principal);
  end;
  ClearContent;
end;

class procedure TAcciones_Descargas.btnEliminar_DescargasClick(Sender: TObject);
var
  Mensaje, Resp, FileName: string;
begin
  if (frmMain.LVDescargas.ItemIndex > -1) and
  (frmMain.LVDescargas.Items.Count > 0) then
  begin
    Mensaje:= '¿Eliminar libro?';
    FileName:= frmMain.LVDescargas.Selected.TagString;
    TDialogService.MessageDialog(Mensaje, TMsgDlgType.mtWarning,
    [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], TMsgDlgBtn.mbNo, 0,
    procedure (const AResult: TModalResult)
    var
      Mensaje: string;
      {$IFDEF ANDROID}
      Toast: JToast;
      {$ENDIF}
    begin
      case AResult of
        mrYes:
        begin
          if EliminarArchivo(FileName, Resp) then
          begin
            try
              FLAG_BOOK_DELETED:= True;
              Mensaje:= 'Eliminado con éxito.';
              {$IFDEF ANDROID}
              Toast:= TJToast.JavaClass.makeText(TAndroidHelper.Context,
              StrToJCharSequence(Mensaje), TJToast.JavaClass.LENGTH_SHORT);
              Toast.setGravity(TJGravity.JavaClass.CENTER, 0, 0);
              Toast.show;
              {$ENDIF}

              {$IFDEF MSWINDOWS}
              MessageDlg('INFORMACIÓN', Mensaje);
              {$ENDIF}
            finally
              CargarDescargas;
            end;
          end
          else
          begin
            Mensaje:= 'No se pudo completar la acción solicitada.';
            {$IFDEF ANDROID}
            Toast:= TJToast.JavaClass.makeText(TAndroidHelper.Context,
            StrToJCharSequence(Mensaje), TJToast.JavaClass.LENGTH_SHORT);
            Toast.setGravity(TJGravity.JavaClass.CENTER, 0, 0);
            Toast.show;
            {$ENDIF}

            {$IFDEF MSWINDOWS}
            MessageDlg('INFORMACIÓN', Mensaje);
            {$ENDIF}
          end;
        end;
      end;
    end);
  end;
end;

class procedure TAcciones_Descargas.btnLeer_DescargasClick(Sender: TObject);
var
  FileName: string;
begin
  if frmMain.LVDescargas.ItemIndex > -1 then
  begin
    FileName:= frmMain.LVDescargas.Selected.TagString;
    AbrirPDF(FileName);
  end;
end;

class procedure TAcciones_Descargas.CargarDescargas;
var
  PdfFiles: TStringDynArray;
  Item: TListViewItem;
  MSPortada: TMemoryStream;

  ThumbnailName: string;
  i: Integer;
begin
  {$IFDEF ANDROID}
  if not TMainFormEvents.ReadyForDownloading then
    Exit;
  {$ENDIF}

  try
    ClearContent;
    SetLength(PdfFiles, 0);
    try
      PdfFiles:= TDirectory.GetFiles(RutaPDFS, '*.pdf');
    except on E: Exception do
      begin
        EscribirLog('TAcciones_Descargas.btnAtrasDescargasClick: ' +
        E.Message);
        Exit;
      end;
    end;

    if Length(PdfFiles) > 0 then
    begin
      {
        En la propiedad "TagString" de cada TListViewItem se
        encuantra la ruta completa del archivo en cuestión.

        La ruta nos será de ayuda más adelante para abrir los pdf
        o eliminarlos.
      }
      frmMain.lblNoHayDescargasPMostrar.Visible:= False;
      frmMain.LVDescargas.Items.Clear;
      frmMain.LVDescargas.Visible:= True;
      frmMain.LVDescargas.BeginUpdate;
      for i:= 0 to Length(PdfFiles) - 1 do
      begin
        Item:= frmMain.LVDescargas.Items.Add;
        Item.Text:= TPath.GetFileNameWithoutExtension(PdfFiles[i]);
        Item.TagString:= PdfFiles[i]; //DRH 22/10/2025

        (*
          DRH 15/11/2025
          -Verificar si existe el Thumbnail y si no, se crea
          y se guarda.
        *)

        ThumbnailName:= TPath.GetFileNameWithoutExtension(PdfFiles[i]);
        if TFile.Exists(RutaThumbnails + PathDelim + ThumbnailName +
        '.thumbnail') then
        begin
          MSPortada:= TMemoryStream.Create;
          MSPortada.LoadFromFile(RutaThumbnails + PathDelim + ThumbnailName +
          '.thumbnail');
          MSPortada.Position:= 0;
        end
        else
        begin
          MSPortada:= getPDFThumbnail(PdfFiles[i], 40, 46);
          MSPortada.SaveToFile(RutaThumbnails + PathDelim + ThumbnailName +
          '.thumbnail');
        end;

        try
          Item.Bitmap.LoadFromStream(MSPortada);
        finally
          FreeAndNil(MSPortada);
        end;
      end;
      frmMain.LVDescargas.EndUpdate;
      frmMain.edtBuscar_Descargas.Enabled:= True;
      SetLength(PdfFiles, 0);
    end;
  finally
    if frmMain.Pantallas.ActiveTab <> frmMain.Descargas then
      frmMain.Pantallas.ActiveTab:= frmMain.Descargas;
  end;
end;

class procedure TAcciones_Descargas.ClearContent;
begin
  frmMain.LVDescargas.Visible:= False;
  frmMain.lblNoHayDescargasPMostrar.Visible:= True;
  frmMain.LVDescargas.Items.Clear;
  frmMain.edtBuscar_Descargas.Text:= string.Empty;
  frmMain.edtBuscar_Descargas.Enabled:= False;
end;

class procedure TAcciones_Descargas.ClearUnusedThumbnails;
var
  Thumbnails: TArray<string>;
  Thumbnail: string;
  ThumbnailName: string;
begin
  if not TDirectory.Exists(RutaThumbnails) then
  begin
    TDirectory.CreateDirectory(RutaThumbnails);
    Exit;
  end;
  SetLength(Thumbnails, 0);

  try
    //Obtener arreglo con todos los Thumbnail
    Thumbnails:= TDirectory.GetFiles(RutaThumbnails, '*.thumbnail');
    if Length(Thumbnails) > 0 then
    begin
      for Thumbnail in Thumbnails do
      begin
        ThumbnailName:= TPath.GetFileNameWithoutExtension(Thumbnail);
        (*
          Verificar si el libro asociado a cada Thumbnail existe
          y de no ser así, borrar el thumnail en cuestión.
        *)

        if not TFile.Exists(RutaPDFS + PathDelim + ThumbnailName + '.pdf') then
        begin
          TFile.Delete(Thumbnail);
          FLAG_BOOK_DELETED:= True; //Deberán refrescarse los libros mostrados
        end;
      end;
    end;
  except on E: Exception do
    EscribirLog('TAcciones_Descargas.ClearUnusedThumbnails: ' + E.Message, 2);
  end;
end;

class procedure TAcciones_Descargas.edtBuscar_DescargasChangeTracking(
  Sender: TObject);
var
  Edt: TEdit;
begin
  Edt:= Sender as TEdit;
  SearchBox_Descargas.Text:= Edt.Text;
  frmMain.clredtBtnBuscar_Descargas.Visible:= not Edt.Text.IsEmpty;
end;

class procedure TAcciones_Descargas.LVDescargasItemClick(const Sender: TObject;
  const AItem: TListViewItem);
begin
  frmMain.btnEliminar_Descargas.Enabled:= True;
  frmMain.btnLeer_Descargas.Enabled:= True;
end;

class procedure TAcciones_Descargas.LVDescargasItemsChange(Sender: TObject);
begin
  frmMain.btnEliminar_Descargas.Enabled:= False;
  frmMain.btnLeer_Descargas.Enabled:= False;
end;

(*class procedure TAcciones_Descargas.ThreadOnTerminate(Sender: TObject);
begin
  TInterlocked.Exchange(THREAD_IS_RUNNING, False);

  Sincronizar(
  procedure
  begin
    HideLoadingDialog;
  end);
end;*)

end.

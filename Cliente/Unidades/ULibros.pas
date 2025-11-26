unit ULibros;

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
  FMX.Skia,
  System.JSON, System.Threading, System.SyncObjs,
  System.JSON.Builders, System.JSON.Converters, System.JSon.Types,
  ELibro, FMX.Gestures, FMX.Types, FMX.DialogService, FMX.Dialogs,
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.UIConsts, FMX.StdCtrls, FMX.Colors, FMX.Controls,
  FMX.Consts, FMX.Layouts, FMX.Utils, FMX.Graphics, FMX.Objects;

function CrearBotonesLibros(const Contenedor: TLayout; var Libros: TArray<rLibro>): Boolean;
procedure LimpiarBotonesLibros;
procedure LimpiarPaginas;

type TScroll_Actions = class
  private
  public
    (*class procedure VSBxLibrosViewportPositionChange(Sender: TObject;
    const OldViewportPosition, NewViewportPosition: TPointF;
    const ContentSizeChanged: Boolean);*)
    class procedure VSBxLibrosStop(Sender: TObject);
    class procedure VSBxLibrosStart(Sender: TObject);
end;

type TLibro_Actions = class
  private
    class procedure ThreadOnTerminate(Sender: TObject);
    class function AlreadyDownloaded(const AFileName: string): Boolean;
  public
    class procedure btnDescargarClick(Sender: TObject);
    class function GuardarLibro(const AFileName: string;
     const MStream: TMemoryStream): Boolean;
    class procedure BtnLibroClick(Sender: TObject);
end;

implementation
uses
  UMain, Generales, Estilos, System.IOUtils, UMainFormEvents,
  UJSONTool;

procedure LimpiarBotonesLibros;
begin
  if Assigned(frmMain.FindComponent('VSBxLibros')) then
    FreeAndNil(frmMain.FindComponent('VSBxLibros'));
end;

procedure LimpiarPaginas;
begin
  //Limpiar paginas previas y la actual
  PaginaActual.Indx:= -1;
  PaginaActual.Ult_id:= string.Empty;
  PaginaActual.Ult_Fechahora:= string.Empty;
  PaginaActual.Ult_IdCategoria:= -1;
  SetLength(Paginas, 0);
end;

function CrearBotonesLibros(const Contenedor: TLayout; var Libros: TArray<rLibro>): Boolean;
var
  VSBxLibros: TVertScrollBox;
  LYLibros: TLayout;
  BtnLibro: TButton;
  RectLibro: TRectangle;
  CardWidth: Single;
  Base_Height: Single;
  Contador: Integer;
  MSBuffer: TMemoryStream;
  Buffer: TBitmap;
  Libro: rLibro;
  //---DRH 11/09/2025
  LYDescargar: TLayout;
  RectDescargar: TRectangle;
  BtnDescargar: TButton;
  SVGDescargar: TSkSvg;
  //---DRH 23/09/2025
  RectDatos: TRectangle;
  lblNombreLibro, lblAutorLibro: TLabel;
  DatosHeight: Single;
const
  ColorDatos: TAlphaColor = TAlphaColorRec.Seagreen;
  DatosFontColor: TAlphaColor = TAlphaColorRec.White;
begin
  Base_Height:= (Contenedor.Height / 1.90);
  CardWidth:= Contenedor.Width / 2.35;
  (*
    1/4 de la altura de cada tarjeta...
  *)
  DatosHeight:= Base_Height / 4.5;
  try
    LimpiarBotonesLibros; //Revisar

    if Length(Libros) > 0 then
    begin
      Contador:= 1;
      VSBxLibros := TVertScrollBox.Create(frmMain);
      VSBxLibros.Parent := Contenedor;
      VSBxLibros.Align := TAlignLayout.Client;
      VSBxLibros.Name:= 'VSBxLibros';
      VSBxLibros.Align:= TAlignLayout.Client;
      VSBxLibros.Margins.Left:= 15;
      VSBxLibros.Margins.Right:= 15;
      VSBxLibros.Margins.Top:= 15;
      VSBxLibros.ShowScrollBars:= False;
      VSBxLibros.Touch.InteractiveGestures:= [TInteractiveGesture.Pan];
      VSBxLibros.Visible:= False;
      VSBxLibros.AniCalculations.OnStart:= TScroll_Actions.VSBxLibrosStart;
      VSBxLibros.AniCalculations.OnStop:= TScroll_Actions.VSBxLibrosStop;
      VSBxLibros.AniCalculations.BoundsAnimation:= True;
      VSBxLibros.AniCalculations.DecelerationRate:= 3.2;
      VSBxLibros.BeginUpdate;

      for Libro in Libros do
      begin
        case Contador of
          1:
          begin
            LYLibros:= TLayout.Create(VSBxLibros);
            LYLibros.Parent:= VSBxLibros;
            LYLibros.Align:= TAlignLayout.Top;
            LYLibros.Height:= Base_Height;
            LYLibros.HitTest:= False;


            BtnLibro:= TButton.Create(LYLibros);
            BtnLibro.Parent:= LYLibros;
            BtnLibro.Align:= TAlignLayout.Left;
            BtnLibro.Width:= CardWidth;
            BtnLibro.StyleLookup:= 'SpeedButtonstyle';
            BtnLibro.Text:= string.Empty;
            BtnLibro.Margins.Top:= 10;
            BtnLibro.Margins.Bottom:= 10;
            BtnLibro.HitTest:= True;
            BtnLibro.TagString:= Libro.Nombre;
            BtnLibro.OnClick:= TLibro_Actions.BtnLibroClick;

            RectLibro:= TRectangle.Create(BtnLibro);
            RectLibro.Parent:= BtnLibro;
            RectLibro.Align:= TAlignLayout.Client;
            RectLibro.Fill.Kind:= TBrushKind.Bitmap;
            RectLibro.Fill.Bitmap.WrapMode:= TWrapMode.TileStretch;
            RectLibro.Stroke.Thickness:= 2;
            RectLibro.HitTest:= False;
            RectLibro.Stroke.Color:= TAlphaColors.Black;
            RectLibro.XRadius:= 5;
            RectLibro.YRadius:= 5;

            RectDatos:= TRectangle.Create(RectLibro);
            RectDatos.Parent:= RectLibro;
            RectDatos.Stroke.Kind:= TBrushKind.None;
            RectDatos.Align:= TAlignLayout.Bottom;
            RectDatos.XRadius:= 5;
            RectDatos.YRadius:= 5;
            RectDatos.Fill.Color:= ColorDatos;
            RectDatos.Height:= DatosHeight;
            //ColorFondoRectangulo(RectDatos);

            if (not Libro.Nombre.IsEmpty) and
            (Libro.Autor.IsEmpty) then
            begin
              lblNombreLibro:= TLabel.Create(RectDatos);
              lblNombreLibro.Parent:= RectDatos;
              lblNombreLibro.Align:= TAlignLayout.Client;
              lblNombreLibro.Margins.Bottom:= 5;
              lblNombreLibro.Margins.Left:= 5;
              lblNombreLibro.Margins.Right:= 5;
              lblNombreLibro.Margins.Top:= 5;
              lblNombreLibro.AutoSize:= False;
              lblNombreLibro.StyledSettings:= [];
              lblNombreLibro.Font.Size:= 13;
              lblNombreLibro.WordWrap:= True;
              lblNombreLibro.Font.Style:= [TFontStyle.fsBold];
              lblNombreLibro.Text:= Libro.Nombre;
              lblNombreLibro.FontColor:= DatosFontColor;
            end
            else
            if (not Libro.Autor.IsEmpty) and
            (Libro.Nombre.IsEmpty) then
            begin
              lblAutorLibro:= TLabel.Create(RectDatos);
              lblAutorLibro.Parent:= RectDatos;
              lblAutorLibro.Align:= TAlignLayout.Client;
              lblAutorLibro.Margins.Bottom:= 5;
              lblAutorLibro.Margins.Left:= 5;
              lblAutorLibro.Margins.Right:= 5;
              lblAutorLibro.Margins.Top:= 5;
              lblAutorLibro.AutoSize:= False;
              lblAutorLibro.StyledSettings:= [];
              lblAutorLibro.Font.Size:= 13;
              lblAutorLibro.Font.Style:= [TFontStyle.fsBold];
              lblAutorLibro.WordWrap:= True;
              lblAutorLibro.Text:= Libro.Autor;
              lblAutorLibro.FontColor:= DatosFontColor;
            end
            else
            if (not Libro.Autor.IsEmpty) and
            (not Libro.Nombre.IsEmpty) then
            begin
              lblNombreLibro:= TLabel.Create(RectDatos);
              lblNombreLibro.Parent:= RectDatos;
              lblNombreLibro.Align:= TAlignLayout.Top;
              lblNombreLibro.Margins.Bottom:= 5;
              lblNombreLibro.Margins.Left:= 5;
              lblNombreLibro.Margins.Right:= 5;
              lblNombreLibro.Margins.Top:= 5;
              lblNombreLibro.AutoSize:= True;
              lblNombreLibro.StyledSettings:= [];
              lblNombreLibro.Font.Size:= 13;
              lblNombreLibro.WordWrap:= False;
              lblNombreLibro.Font.Style:= [TFontStyle.fsBold];
              lblNombreLibro.Text:= Libro.Nombre;
              lblNombreLibro.FontColor:= DatosFontColor;

              lblAutorLibro:= TLabel.Create(RectDatos);
              lblAutorLibro.Parent:= RectDatos;
              lblAutorLibro.Align:= TAlignLayout.Bottom;
              lblAutorLibro.Margins.Bottom:= 5;
              lblAutorLibro.Margins.Left:= 5;
              lblAutorLibro.Margins.Right:= 5;
              lblAutorLibro.Margins.Top:= 5;
              lblAutorLibro.AutoSize:= True;
              lblAutorLibro.StyledSettings:= [];
              lblAutorLibro.Font.Style:= [TFontStyle.fsBold];
              lblAutorLibro.Font.Size:= 11;
              lblAutorLibro.WordWrap:= False;
              lblAutorLibro.Text:= Libro.Autor;
              lblAutorLibro.FontColor:= DatosFontColor;
            end;

            LYDescargar:= TLayout.Create(RectLibro);
            LYDescargar.Parent:= RectLibro;
            LYDescargar.Align:= TAlignLayout.Top;
            LYDescargar.Height:= 43;
            LYDescargar.HitTest:= True;

            RectDescargar:= TRectangle.Create(LYDescargar);
            RectDescargar.Parent:= LYDescargar;
            RectDescargar.Align:= TAlignLayout.Right;
            RectDescargar.Margins.Bottom:= 5;
            RectDescargar.Margins.Top:= 5;
            RectDescargar.Margins.Right:= 5;
            RectDescargar.Width:= 33;
            RectDescargar.Stroke.Kind:= TBrushKind.None;
            RectDescargar.XRadius:= 5;
            RectDescargar.YRadius:= 5;
            RectDescargar.Fill.Color:= TAlphaColorRec.Seagreen;
            ColorFondoRectangulo(RectDescargar);

            BtnDescargar:= TButton.Create(RectDescargar);
            BtnDescargar.Parent:= RectDescargar;
            BtnDescargar.Align:= TAlignLayout.Client;
            BtnDescargar.StyleLookup:= 'SpeedButtonstyle';
            BtnDescargar.TagString:= Libro.Nombre;
            BtnDescargar.Hint:= Libro.Id;
            BtnDescargar.ShowHint:= False;
            BtnDescargar.OnClick:= TLibro_Actions.btnDescargarClick;

            SVGDescargar:= TSkSvg.Create(BtnDescargar);
            SVGDescargar.Parent:= BtnDescargar;
            SVGDescargar.Align:= TAlignLayout.Client;
            SVGDescargar.Svg.Source:= frmMain.SVGDownload.Svg.Source;
            SVGDescargar.Svg.OverrideColor:= TAlphaColorRec.White;
            BtnDescargar.TagObject:= SVGDescargar;

            if TLibro_Actions.AlreadyDownloaded(RutaPDFS + PathDelim +
            Libro.Nombre + '.pdf') then
            begin
              SVGDescargar.Svg.Source:= frmMain.SVGDownload_Done.Svg.Source;
              BtnDescargar.HitTest:= False;
              BtnDescargar.OnClick:= nil;
              BtnDescargar.TagString:= string.Empty;
            end;

            if not Libro.Portada.IsEmpty then
            begin
              MSBuffer:= Base64StringToMemoryStream(Libro.Portada);
              try
                Buffer:= TBitmap.Create;
                try
                  Buffer.LoadFromStream(MSBuffer);
                  RectLibro.Fill.Bitmap.Bitmap.Assign(Buffer);
                finally
                  FreeAndNil(Buffer);
                end;
              finally
                FreeAndNil(MSBuffer);
              end;
            end;

            Inc(Contador);
          end;

          2:
          begin
            BtnLibro:= TButton.Create(LYLibros);
            BtnLibro.Parent:= LYLibros;
            BtnLibro.Align:= TAlignLayout.Right;
            BtnLibro.Width:= CardWidth;
            BtnLibro.StyleLookup:= 'SpeedButtonstyle';
            BtnLibro.Text:= string.Empty;
            BtnLibro.Margins.Top:= 10;
            BtnLibro.Margins.Bottom:= 10;
            BtnLibro.HitTest:= True;
            BtnLibro.TagString:= Libro.Nombre;
            BtnLibro.OnClick:= TLibro_Actions.BtnLibroClick;

            RectLibro:= TRectangle.Create(BtnLibro);
            RectLibro.Parent:= BtnLibro;
            RectLibro.Align:= TAlignLayout.Client;
            RectLibro.Fill.Kind:= TBrushKind.Bitmap;
            RectLibro.Fill.Bitmap.WrapMode:= TWrapMode.TileStretch;
            RectLibro.Stroke.Thickness:= 2;
            RectLibro.HitTest:= False;
            RectLibro.Stroke.Color:= TAlphaColors.Black;
            RectLibro.XRadius:= 5;
            RectLibro.YRadius:= 5;

            RectDatos:= TRectangle.Create(RectLibro);
            RectDatos.Parent:= RectLibro;
            RectDatos.Stroke.Kind:= TBrushKind.None;
            RectDatos.Align:= TAlignLayout.Bottom;
            RectDatos.XRadius:= 5;
            RectDatos.YRadius:= 5;
            RectDatos.Fill.Color:= ColorDatos;
            RectDatos.Height:= DatosHeight;
            //ColorFondoRectangulo(RectDatos);

            if (not Libro.Nombre.IsEmpty) and
            (Libro.Autor.IsEmpty) then
            begin
              lblNombreLibro:= TLabel.Create(RectDatos);
              lblNombreLibro.Parent:= RectDatos;
              lblNombreLibro.Align:= TAlignLayout.Client;
              lblNombreLibro.Margins.Bottom:= 5;
              lblNombreLibro.Margins.Left:= 5;
              lblNombreLibro.Margins.Right:= 5;
              lblNombreLibro.Margins.Top:= 5;
              lblNombreLibro.AutoSize:= False;
              lblNombreLibro.StyledSettings:= [];
              lblNombreLibro.Font.Size:= 13;
              lblNombreLibro.WordWrap:= True;
              lblNombreLibro.Font.Style:= [TFontStyle.fsBold];
              lblNombreLibro.Text:= Libro.Nombre;
              lblNombreLibro.FontColor:= DatosFontColor;
            end
            else
            if (not Libro.Autor.IsEmpty) and
            (Libro.Nombre.IsEmpty) then
            begin
              lblAutorLibro:= TLabel.Create(RectDatos);
              lblAutorLibro.Parent:= RectDatos;
              lblAutorLibro.Align:= TAlignLayout.Client;
              lblAutorLibro.Margins.Bottom:= 5;
              lblAutorLibro.Margins.Left:= 5;
              lblAutorLibro.Margins.Right:= 5;
              lblAutorLibro.Margins.Top:= 5;
              lblAutorLibro.AutoSize:= False;
              lblAutorLibro.StyledSettings:= [];
              lblAutorLibro.Font.Size:= 13;
              lblAutorLibro.Font.Style:= [TFontStyle.fsBold];
              lblAutorLibro.WordWrap:= True;
              lblAutorLibro.Text:= Libro.Autor;
              lblAutorLibro.FontColor:= DatosFontColor;
            end
            else
            if (not Libro.Autor.IsEmpty) and
            (not Libro.Nombre.IsEmpty) then
            begin
              lblNombreLibro:= TLabel.Create(RectDatos);
              lblNombreLibro.Parent:= RectDatos;
              lblNombreLibro.Align:= TAlignLayout.Top;
              lblNombreLibro.Margins.Bottom:= 5;
              lblNombreLibro.Margins.Left:= 5;
              lblNombreLibro.Margins.Right:= 5;
              lblNombreLibro.Margins.Top:= 5;
              lblNombreLibro.AutoSize:= True;
              lblNombreLibro.StyledSettings:= [];
              lblNombreLibro.Font.Size:= 13;
              lblNombreLibro.WordWrap:= False;
              lblNombreLibro.Font.Style:= [TFontStyle.fsBold];
              lblNombreLibro.Text:= Libro.Nombre;
              lblNombreLibro.FontColor:= DatosFontColor;

              lblAutorLibro:= TLabel.Create(RectDatos);
              lblAutorLibro.Parent:= RectDatos;
              lblAutorLibro.Align:= TAlignLayout.Bottom;
              lblAutorLibro.Margins.Bottom:= 5;
              lblAutorLibro.Margins.Left:= 5;
              lblAutorLibro.Margins.Right:= 5;
              lblAutorLibro.Margins.Top:= 5;
              lblAutorLibro.AutoSize:= True;
              lblAutorLibro.StyledSettings:= [];
              lblAutorLibro.Font.Style:= [TFontStyle.fsBold];
              lblAutorLibro.Font.Size:= 11;
              lblAutorLibro.WordWrap:= False;
              lblAutorLibro.Text:= Libro.Autor;
              lblAutorLibro.FontColor:= DatosFontColor;
            end;

            LYDescargar:= TLayout.Create(RectLibro);
            LYDescargar.Parent:= RectLibro;
            LYDescargar.Align:= TAlignLayout.Top;
            LYDescargar.Height:= 43;
            LYDescargar.HitTest:= True;

            RectDescargar:= TRectangle.Create(LYDescargar);
            RectDescargar.Parent:= LYDescargar;
            RectDescargar.Align:= TAlignLayout.Right;
            RectDescargar.Margins.Bottom:= 5;
            RectDescargar.Margins.Top:= 5;
            RectDescargar.Margins.Right:= 5;
            RectDescargar.Width:= 33;
            RectDescargar.Stroke.Kind:= TBrushKind.None;
            RectDescargar.XRadius:= 5;
            RectDescargar.YRadius:= 5;
            RectDescargar.Fill.Color:= TAlphaColorRec.Seagreen;
            ColorFondoRectangulo(RectDescargar);

            BtnDescargar:= TButton.Create(RectDescargar);
            BtnDescargar.Parent:= RectDescargar;
            BtnDescargar.Align:= TAlignLayout.Client;
            BtnDescargar.StyleLookup:= 'SpeedButtonstyle';
            BtnDescargar.TagString:= Libro.Nombre;
            BtnDescargar.Hint:= Libro.Id;
            BtnDescargar.ShowHint:= False;
            BtnDescargar.OnClick:= TLibro_Actions.btnDescargarClick;

            SVGDescargar:= TSkSvg.Create(BtnDescargar);
            SVGDescargar.Parent:= BtnDescargar;
            SVGDescargar.Align:= TAlignLayout.Client;
            SVGDescargar.Svg.Source:= frmMain.SVGDownload.Svg.Source;
            SVGDescargar.Svg.OverrideColor:= TAlphaColorRec.White;
            BtnDescargar.TagObject:= SVGDescargar;

            if TLibro_Actions.AlreadyDownloaded(RutaPDFS + PathDelim +
            Libro.Nombre + '.pdf') then
            begin
              SVGDescargar.Svg.Source:= frmMain.SVGDownload_Done.Svg.Source;
              BtnDescargar.HitTest:= False;
              BtnDescargar.OnClick:= nil;
              BtnDescargar.TagString:= string.Empty;
            end;

            if not Libro.Portada.IsEmpty then
            begin
              MSBuffer:= Base64StringToMemoryStream(Libro.Portada);
              try
                Buffer:= TBitmap.Create;
                try
                  Buffer.LoadFromStream(MSBuffer);
                  RectLibro.Fill.Bitmap.Bitmap.Assign(Buffer);
                finally
                  FreeAndNil(Buffer);
                end;
              finally
                FreeAndNil(MSBuffer);
              end;
            end;
            Contador:= 1;
          end;
        end;
      end;
      VSBxLibros.EndUpdate;
      VSBxLibros.Visible:= True;
      Result:= True;
    end else Result:= False;
  except on E: Exception do
    begin
      Result:= False;
    end;
  end;
end;

{ TScroll_Actions }

class procedure TScroll_Actions.VSBxLibrosStart(Sender: TObject);
begin
  SeccionCritica(
  procedure
  begin
    SCROLLING_BOOKS:= True;
  end);

  frmMain.btnNextLibro_Principal.Enabled:= False;
end;

class procedure TScroll_Actions.VSBxLibrosStop(Sender: TObject);
var
  VSBx: TVertScrollBox;
  VisibleHeight: Single;
  ContentHeight: Single;
  ScrollPos: Single;
begin
  SeccionCritica(
  procedure
  begin
    SCROLLING_BOOKS:= False;
  end);

  VSBx:= TScrollCalculations(Sender).ScrollBox as TVertScrollBox;

  VisibleHeight:= VSBx.Height;
  ContentHeight:= VSBx.ContentBounds.Height;
  ScrollPos:= VSBx.ViewportPosition.Y;

  if ScrollPos = 0 then
    Exit;

  frmMain.btnNextLibro_Principal.Enabled:= ScrollPos + VisibleHeight >=
  ContentHeight - 2; //Evita margen de error por diferencias de pixeles
end;

{ TLibro_Actions }

class function TLibro_Actions.AlreadyDownloaded(const AFileName: string): Boolean;
begin
  Result:= TFile.Exists(AFileName);
end;

class procedure TLibro_Actions.btnDescargarClick(Sender: TObject);
var
  Thread: TThread;
  ID: string;
  Btn: TButton;
  FileName: string;
  LibroBase64: string;
  MS: TMemoryStream;
  Guardado: Boolean;
  Usr_Bloqueado: Boolean;

  IndicadorDescarga: TSkAnimatedImage;
  SVGImagen: TSkSvg;
  Mensaje: string;
begin
  {$IFDEF ANDROID}
  if not TMainFormEvents.ReadyForDownloading then
    Exit;
  {$ENDIF}

  Mensaje:= '¿Descargar libro?';
  TDialogService.MessageDialog(Mensaje, TMsgDlgType.mtConfirmation,
  [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], TMsgDlgBtn.mbYes, 0,
  procedure(const AResult: TModalResult)
  begin
    case AResult of
      mrYes:
      begin
        Usr_Bloqueado:= False;
        Btn:= Sender as TButton;
        ID:= Btn.Hint;
        SVGImagen:= Btn.TagObject as TSkSvg;
        SVGImagen.Visible:= False;
        IndicadorDescarga:= TSkAnimatedImage.Create(Btn);
        IndicadorDescarga.Parent:= Btn;
        IndicadorDescarga.Align:= TAlignLayout.Client;
        IndicadorDescarga.Source:= frmMain.SKAnimDownload.Source;
        IndicadorDescarga.Animation.Enabled:= True;
        FileName:= RutaPDFS + PathDelim + Btn.TagString + '.pdf';
        Btn.HitTest:= False;

        Thread:= TThread.CreateAnonymousThread(
        procedure
        begin
          TInterlocked.Exchange(THREAD_IS_RUNNING, True);

          LibroBase64:= TJSONTool.DescargarLibro(ID, Usr_Bloqueado);

          (*
            DRH 28/10/2025
            -Usuario bloqueado.
          *)
          if Usr_Bloqueado = True then
          begin
            UsuarioBloqueado;
            LibroBase64:= string.Empty;
            Exit;
          end;

          if not LibroBase64.IsEmpty then
          begin
            MS:= Base64StringToMemoryStream(LibroBase64);
            try
              Guardado:= GuardarLibro(FileName, MS);

              Encolar(
              procedure
              begin
                try
                  IndicadorDescarga.Animation.Enabled:= False;
                  IndicadorDescarga.Visible:= False;
                  if Guardado then
                  begin
                    SVGImagen.Svg.Source:= frmMain.SVGDownload_Done.Svg.Source;
                    Btn.HitTest:= False;
                    Btn.OnClick:= nil;
                  end else Btn.HitTest:= True;
                finally
                  FreeAndNil(IndicadorDescarga);
                  SVGImagen.Visible:= True;
                end;
              end);
            finally
              FreeAndNil(MS);
              LibroBase64:= string.Empty;
            end;
          end
          else
          begin
            Encolar(
            procedure
            begin
              Btn.HitTest:= True;
              try
                IndicadorDescarga.Animation.Enabled:= False;
                IndicadorDescarga.Visible:= False;
              finally
                FreeAndNil(IndicadorDescarga);
                SVGImagen.Visible:= True;
              end;
            end);
          end;
        end);
        Thread.FreeOnTerminate:= True;
        Thread.OnTerminate:= TLibro_Actions.ThreadOnTerminate;
        Thread.Start;
      end;
    end;
  end);
end;

class procedure TLibro_Actions.BtnLibroClick(Sender: TObject);
var
  Mensaje: string;
  Btn: TButton;
  PDFFileName: string;
  {$IFDEF ANDROID}
  Toast: JToast;
  {$ENDIF}
begin
  (*
    DRH 15/11/2025
    -CON ESTO SE EVITA QUE SE DISPARE EL EVENTO
    ONCLICK ACCIDENTALMENTE, DE LOS BOTONES DE CADA LIBRO AL HACER
    SCROLL.
  *)

  CriticalSection.Acquire;
  try
    if SCROLLING_BOOKS = True then
      Exit;
  finally
    CriticalSection.Release;
  end;

  Btn:= Sender as TButton;
  PDFFileName:= RutaPDFS + PathDelim + Btn.TagString + '.pdf';

  if not TLibro_Actions.AlreadyDownloaded(PDFFileName) then
  begin
    Mensaje:= 'La lectura de este libro estará disponible después de ' +
    'descargarlo.';
    {$IFDEF ANDROID}
    Toast:= TJToast.JavaClass.makeText(TAndroidHelper.Context,
    StrToJCharSequence(Mensaje), TJToast.JavaClass.LENGTH_SHORT);
    Toast.setGravity(TJGravity.JavaClass.CENTER, 0, 0);
    Toast.show;
    {$ENDIF}
    {$IFDEF MSWINDOWS}
    ShowMessage(Mensaje);
    {$ENDIF}
  end
  else
    AbrirPDF(PDFFileName);
end;

class function TLibro_Actions.GuardarLibro(const AFileName: string;
  const MStream: TMemoryStream): Boolean;
var
  Resultado: Boolean;
  Thumbnail: TMemoryStream;
begin
  SeccionCritica(
  procedure
  var
    ThumbnailName: string;
  begin
    Resultado:= False;
    try
      MStream.SaveToFile(AFileName);
      Thumbnail:= getPDFThumbnail(AFileName, 40, 46);
      try
        ThumbnailName:= TPath.GetFileNameWithoutExtension(AFileName);
        Thumbnail.SaveToFile(RutaThumbnails + PathDelim + ThumbnailName +
        '.thumbnail');
      finally
        FreeAndNil(Thumbnail);
      end;
      Resultado:= True;
    except on E: Exception do
      begin
        Resultado:= False;
        EscribirLog('TLibro_Actions.GuardarLibro: ' + E.ClassName + ': ' +
        E.Message, 2);
      end;
    end;
  end);
  Result:= Resultado;
end;

class procedure TLibro_Actions.ThreadOnTerminate(Sender: TObject);
begin
  TInterlocked.Exchange(THREAD_IS_RUNNING, False);

  Encolar(
  procedure
  begin
    frmMain.IndicadorLoadingDlg.Animation.Enabled:= False;
    frmMain.LoadingDialog.Visible:= False;
  end);
end;

end.

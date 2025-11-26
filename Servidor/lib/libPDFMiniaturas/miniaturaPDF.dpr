library miniaturaPDF;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters.

  Important note about VCL usage: when this DLL will be implicitly
  loaded and this DLL uses TWicImage / TImageCollection created in
  any unit initialization section, then Vcl.WicImageInit must be
  included into your library's USES clause. }

uses
  Sharemem,
  System.SysUtils,
  System.Classes,
  System.Types,
  Vcl.Graphics,
  Forms,
  Windows,
  Vcl.Dialogs,
  Vcl.Controls,
  uPDFMiniatura in 'uPDFMiniatura.pas' {frmPDFMiniatura},
  PdfiumCore in 'Unidades\pdfium\PdfiumCore.pas',
  PdfiumCtrl in 'Unidades\pdfium\PdfiumCtrl.pas',
  PdfiumLib in 'Unidades\pdfium\PdfiumLib.pas';

{$R *.res}

function getPDFThumbnail(FileName: string; aWidth, aHeight: Single): TMemoryStream;
var
  FBitmap: VCL.Graphics.TBitmap;
  Page_is_Loaded: Boolean;
  FrmContenedor: TfrmPDFMiniatura;
  PDFCtrl: TPdfControl;
  Canvas_Unlocked: Boolean;
begin
  PDFiumDllDir := ExtractFilePath(ParamStr(0));

  Result:= nil;
  Canvas_Unlocked:= True; //Aún no se bloquea el canvas en este punto.

  //Crear el Form que contiene el PDFControl
  FrmContenedor:= TfrmPDFMiniatura.Create(nil);

  PDFCtrl:= TPdfControl.Create(FrmContenedor.pnl);
  PDFCtrl.Parent:= FrmContenedor.pnl;
  PDFCtrl.ParentDoubleBuffered:= True;
  PDFCtrl.DoubleBuffered:= True;
  PDFCtrl.Align := alClient;
  FBitmap := VCL.Graphics.TBitmap.Create;
  try
    try
      PDFCtrl.Color := clWhite;
      PDFCtrl.ScaleMode:= TPdfControlScaleMode.smFitAuto;
      PDFCtrl.LoadFromFile(FileName);
      PDFCtrl.PageIndex:= 0;
      //Asignar tamaño de la imagen final
      if FrmContenedor.pnl.Width <> Round(aWidth) then
        FrmContenedor.pnl.Width:= Round(aWidth);

      if FrmContenedor.pnl.Height <> Round(aHeight) then
        FrmContenedor.pnl.Height:= Round(aHeight);

      // Establece el tamaño del bitmap igual al tamaño del panel
      FBitmap.Width := FrmContenedor.pnl.Width;
      FBitmap.Height := FrmContenedor.pnl.Height;
      FBitmap.Canvas.Lock;
      Canvas_Unlocked:= False;

      repeat
        Page_is_Loaded:= PDFCtrl.CurrentPage.IsLoaded;
        //Application.ProcessMessages;
        if Page_is_Loaded = True then
        begin
          FBitmap.Canvas.FillRect(Rect(0, 0, FBitmap.Width, FBitmap.Height));
          FrmContenedor.pnl.PaintTo(FBitmap.Canvas.Handle, 0, 0);
          FBitmap.Canvas.Unlock;
          Canvas_Unlocked:= True;

          Result:= TMemoryStream.Create;
          FBitmap.SaveToStream(Result);
          Result.Position:= 0;
          Break;
        end;
      until Page_is_Loaded = True;
    except on E: exception do
      begin
        Result:= nil;
      end;
    end;
  finally
    (*
      Al parecer liberar el TPdfControl provoca un error de tipo
      "Pointer operation" por eso no se libera aquí.

      Quizás tiene su propia lógica de administración de memoria.
    *)
    if Canvas_Unlocked = False then
      FBitmap.Canvas.Unlock;

    FreeAndNil(FBitmap);
    FreeAndNil(FrmContenedor);
  end;
end;

exports getPDFThumbnail;

begin
end.

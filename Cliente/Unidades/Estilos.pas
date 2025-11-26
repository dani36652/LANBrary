
unit Estilos;

interface

Uses
  {$IFDEF ANDROID}
  Androidapi.JNI.Webkit, FMX.VirtualKeyboard,
  Androidapi.JNI.Print, Androidapi.JNI.Util,
  fmx.Platform.Android,
  Androidapi.jni,fmx.helpers.android, Androidapi.Jni.app,
  Androidapi.Jni.GraphicsContentViewText, Androidapi.JniBridge,
  Androidapi.JNI.Os, Androidapi.Jni.Telephony,
  Androidapi.JNI.JavaTypes,Androidapi.Helpers,
  Androidapi.JNI.Widget,System.Permissions,
  FMX.DialogService,Androidapi.Jni.Provider,Androidapi.Jni.Net,
  fmx.TextLayout,AndroidAPI.JNI.Support,
 {$ENDIF}
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  FMX.Forms, FMX.Styles,
  FMX.Objects, FMX.Types, FMX.Edit, FMX.Memo, FMX.ListBox, FMX.StdCtrls,
  FMX.Controls, FMX.Graphics, FMX.Grid, FMX.Header;


procedure ColorFondoHeaderStringGrid(const ObjetoGrid: TStringGrid);
procedure ColorFondoRectangulo(const aRectangulo: TRectangle);
procedure ColorFondoRoundRect(const aRoundRect: TRoundRect);
procedure ColorFondoCircle(const aCircle: TCircle);
procedure setApplicationTheme(const aForm: TForm);

{$IFDEF ANDROID}
procedure setStatusBarColor(AColor: TAlphaColor);
{$ENDIF}

type TStyleSettings = class
  private
  public
    class procedure Edit_ApplyStyleLookUp(Sender: TObject);
end;

const FavoriteColor: TAlphaColor = TAlphaColors.Seagreen;

implementation

procedure ColorFondoHeaderStringGrid(const ObjetoGrid: TStringGrid);
var
  i: integer;
  Header: THeader;
  RecColor: TRectangle;
  Texto: TText;
  Obj: TFmxObject;
  Headerlbl:TLabel;
const
  SecondColor: TAlphaColor = $FF2A6846;
begin
  Header := THeader(ObjetoGrid.FindStyleResource('Header'));
  if Assigned(Header) then
  begin
    for i := 0 to ObjetoGrid.ColumnCount do
    // NOTA: ColumnCount-1 pinta solo las que ocupa el grid como tal
    // y ColumnCount pinta las que se ocupan más el resto del Header
    begin
      Obj := Header.Items[i];
      if Assigned(Obj) then
      begin
        RecColor := TRectangle.Create(Obj);
        Obj.AddObject(RecColor);
        RecColor.Fill.Kind := TBrushKind.Gradient;
        RecColor.Fill.Gradient.Points.Points[0].Color := FavoriteColor;
        RecColor.Fill.Gradient.Points.Points[0].Offset := 0.000000000000000000;
        RecColor.Fill.Gradient.Points.Points[1].Color := SecondColor;
        RecColor.Fill.Gradient.Points.Points[1].Offset := 1.000000000000000000;
        RecColor.Stroke.Kind:= TBrushKind.None;
        RecColor.Align := TAlignLayout.Contents;
        RecColor.HitTest := False;
        RecColor.SendToBack;
        if Assigned(Obj.FindStyleResource('Text')) then
        begin
        //Nota: Se sustituyen los TText de los Headers ya que en Android al hacer Scrolling a los lados
        // Desaparecían todos los headers
          Texto := TText(Header.Items[i].FindStyleResource('Text'));
          Texto.Visible:= False;
          Headerlbl:= TLabel.Create(RecColor);
          Headerlbl.Parent:= RecColor;
          Headerlbl.Align:= TAlignLayout.Client;
          Headerlbl.HitTest:= False;
          Headerlbl.StyledSettings:= [];
          Headerlbl.Text:= Texto.Text;
          Headerlbl.FontColor:= TAlphaColors.White;
          Headerlbl.Font.Size:= ObjetoGrid.TextSettings.Font.Size + 1;
          Headerlbl.Font.Style:= [TFontStyle.fsBold];
          Headerlbl.TextAlign:= TTextAlign.Center;
        end;
      end;
    end;
  end;
end;

procedure ColorFondoRectangulo(const aRectangulo: TRectangle);
begin
  if aRectangulo.Fill.Color = FavoriteColor then
  begin
    aRectangulo.Fill.Kind := TBrushKind.Gradient;
    aRectangulo.Fill.Gradient.Points.Points[0].Color := FavoriteColor;
    aRectangulo.Fill.Gradient.Points.Points[0].Offset := 0.000000000000000000;
    aRectangulo.Fill.Gradient.Points.Points[1].Color := $FF2A6846;
    aRectangulo.Fill.Gradient.Points.Points[1].Offset := 1.000000000000000000;
  end;
end;

procedure ColorFondoRoundRect(const aRoundRect: TRoundRect);
begin
  if aRoundRect.Fill.Color = FavoriteColor then
  begin
    aRoundRect.Fill.Kind := TBrushKind.Gradient;
    aRoundRect.Fill.Gradient.Points.Points[0].Color := FavoriteColor;
    aRoundRect.Fill.Gradient.Points.Points[0].Offset := 0.000000000000000000;
    aRoundRect.Fill.Gradient.Points.Points[1].Color := $FF2A6846;
    aRoundRect.Fill.Gradient.Points.Points[1].Offset := 1.000000000000000000;
  end;
end;

procedure ColorFondoCircle(const aCircle: TCircle);
begin
  if aCircle.Fill.Color = FavoriteColor then
  begin
    aCircle.Fill.Kind := TBrushKind.Gradient;
    aCircle.Fill.Gradient.Points.Points[0].Color := FavoriteColor;
    aCircle.Fill.Gradient.Points.Points[0].Offset := 0.000000000000000000;
    aCircle.Fill.Gradient.Points.Points[1].Color := $FF2A6846;
    aCircle.Fill.Gradient.Points.Points[1].Offset := 1.000000000000000000;
  end;
end;

procedure setApplicationTheme(const aForm: TForm);
var
  i: Integer;
const
  StatusBarColor: TAlphaColor = TAlphaColors.Seagreen;
begin
  {$IFDEF ANDROID}
  (*
    DRH 26/11/2025
    -Pendiente:
    Realizar los ajustes pertinentes aquí cuando se haga la migración del
    proyecto al nivel de api 35 o superior para tomar en cuenta el
    "edge to edge enforcement".
  *)
  setStatusBarColor(StatusBarColor);
  {$ENDIF}

  for i:= 0 to aForm.ComponentCount - 1 do
  begin
    if aForm.Components[i].ClassType = TRectangle then
      ColorFondoRectangulo(aForm.Components[i] as TRectangle) else

    if aForm.Components[i].ClassType = TRoundRect then
      ColorFondoRoundRect(aForm.Components[i] as TRoundRect) else

    if aForm.Components[i].ClassType = TCircle then
      ColorFondoCircle(aForm.Components[i] as TCircle) else

    if aForm.Components[i].ClassType = TEdit then
    begin
      if not TEdit(aForm.Components[i]).StyleLookup.Equals('ClearEditstyle') then
        TEdit(aForm.Components[i]).OnApplyStyleLookup:= TStyleSettings.Edit_ApplyStyleLookUp;
    end;
  end;
end;

{$IFDEF ANDROID}
procedure setStatusBarColor(AColor: TAlphaColor);
var
  Window: JWindow;
begin
  try
    Window:= TAndroidHelper.Activity.getWindow;
    Window.setStatusBarColor(TAndroidHelper.AlphaColorToJColor(AColor));
  except

  end;
end;
{$ENDIF}

{ TStyleSettings }

class procedure TStyleSettings.Edit_ApplyStyleLookUp(Sender: TObject);
var
  RecColor: TRectangle;
  Obj: TFmxObject;
begin
  Obj := (Sender as TEdit).FindStyleResource('background');
  if Obj <> nil then
  begin
    RecColor := TRectangle.Create(Obj);
    Obj.AddObject(RecColor);
    RecColor.Align := TAlignLayout.Client;
    RecColor.Fill.Color := $FFEAEAEA;
    RecColor.Stroke.Kind:= TBrushKind.None;
    RecColor.HitTest := False;
    RecColor.SendToBack;
  end;
end;

end.

unit Estilos;

interface

Uses
  System.Skia, FMX.Skia,
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  FMX.Forms, FMX.Styles,
  FMX.Objects, FMX.Types, FMX.Edit, FMX.Memo, FMX.ListBox, FMX.StdCtrls,
  FMX.Controls, FMX.Graphics, FMX.Grid, FMX.Header;


procedure ColorFondoHeaderStringGrid(const ObjetoGrid: TStringGrid);
procedure ColorFondoRectangulo(const aRectangulo: TRectangle);
procedure ColorFondoRoundRect(const aRoundRect: TRoundRect);
procedure setApplicationTheme(const aForm: TForm);

type TStyleSettings = class
  private

  public
    class procedure Edit_ApplyStyleLookUp(Sender: TObject);
end;

type TStyledControls_Events = class
  private
  public
    class procedure OnMouseEnter(Sender: TObject);
    class procedure OnMouseLeave(Sender: TObject);
end;

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
  FirstColor: TAlphaColor = TAlphaColors.Seagreen;
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
        RecColor.Fill.Gradient.Points.Points[0].Color := FirstColor;
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
  if aRectangulo.Fill.Color = TAlphaColors.Seagreen then
  begin
    aRectangulo.Fill.Kind := TBrushKind.Gradient;
    aRectangulo.Fill.Gradient.Points.Points[0].Color := TAlphaColors.Seagreen;
    aRectangulo.Fill.Gradient.Points.Points[0].Offset := 0.000000000000000000;
    aRectangulo.Fill.Gradient.Points.Points[1].Color := $FF2A6846;
    aRectangulo.Fill.Gradient.Points.Points[1].Offset := 1.000000000000000000;
  end;
end;

procedure ColorFondoRoundRect(const aRoundRect: TRoundRect);
begin
  if aRoundRect.Fill.Color = TAlphaColors.Seagreen then
  begin
    aRoundRect.Fill.Kind := TBrushKind.Gradient;
    aRoundRect.Fill.Gradient.Points.Points[0].Color := TAlphaColors.Seagreen;
    aRoundRect.Fill.Gradient.Points.Points[0].Offset := 0.000000000000000000;
    aRoundRect.Fill.Gradient.Points.Points[1].Color := $FF2A6846;
    aRoundRect.Fill.Gradient.Points.Points[1].Offset := 1.000000000000000000;
  end;
end;

procedure setApplicationTheme(const aForm: TForm);
var
  i: Integer;
begin
  for i:= 0 to aForm.ComponentCount - 1 do
  begin
    if aForm.Components[i].ClassType = TButton then
    begin
      TButton(aForm.Components[i]).OnMouseEnter:= TStyledControls_Events.OnMouseEnter;
      TButton(aForm.Components[i]).OnMouseLeave:= TStyledControls_Events.OnMouseLeave;
    end
    else

    if aForm.Components[i].ClassType = TSpeedButton then
    begin
      TSpeedButton(aForm.Components[i]).OnMouseEnter:= TStyledControls_Events.OnMouseEnter;
      TSpeedButton(aForm.Components[i]).OnMouseLeave:= TStyledControls_Events.OnMouseLeave;
    end
    else

    if aForm.Components[i].ClassType = TRectangle then
      ColorFondoRectangulo(aForm.Components[i] as TRectangle) else

    if aForm.Components[i].ClassType = TRoundRect then
      ColorFondoRoundRect(aForm.Components[i] as TRoundRect) else

    if aForm.Components[i].ClassType = TEdit then
    begin
      if not TEdit(aForm.Components[i]).StyleLookup.Equals('ClearEditstyle') then
        TEdit(aForm.Components[i]).OnApplyStyleLookup:= TStyleSettings.Edit_ApplyStyleLookUp;
    end;
  end;
end;

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

{ TStyledControls_Events }

class procedure TStyledControls_Events.OnMouseEnter(Sender: TObject);
var
  Color: TAlphaColor;
  Btn: TButton;
  SpdBtn: TSpeedButton;
  Lbl: TLabel;
  SVG: TSkSvg;
begin
  TThread.ForceQueue(nil,
  procedure
  var
    i: Integer;
  begin
    Color:= TAlphaColorRec.Black;

    if Sender is TButton then
    begin
      Btn:= Sender as TButton;
      if not Btn.Text.Trim.IsEmpty then
      begin
        Btn.Tag:= Btn.FontColor;
        Btn.FontColor:= Color;
      end;

      for i:= 0 to Btn.ChildrenCount - 1 do
      begin
        if Btn.Children[i].ClassType = TLabel then
        begin
          Lbl:= Btn.Children[i] as TLabel;
          Lbl.Tag:= Lbl.FontColor;
          Lbl.FontColor:= Color;
        end
        else
        if Btn.Children[i].ClassType = TSkSvg then
        begin
          SVG:= Btn.Children[i] as TSkSvg;
          SVG.Tag:= SVG.Svg.OverrideColor;
          SVG.Svg.OverrideColor:= Color;
        end;
      end;
    end
    else
    if Sender is TSpeedButton then
    begin
      SpdBtn:= Sender as TSpeedButton;
      if not SpdBtn.Text.Trim.IsEmpty then
      begin
        SpdBtn.Tag:= SpdBtn.FontColor;
        SpdBtn.FontColor:= Color;
      end;

      for i:= 0 to SpdBtn.ChildrenCount - 1 do
      begin
        if SpdBtn.Children[i].ClassType = TLabel then
        begin
          Lbl:= SpdBtn.Children[i] as TLabel;
          Lbl.Tag:= Lbl.FontColor;
          Lbl.FontColor:= Color;
        end
        else
        if SpdBtn.Children[i].ClassType = TSkSvg then
        begin
          SVG:= SpdBtn.Children[i] as TSkSvg;
          SVG.Tag:= SVG.Svg.OverrideColor;
          SVG.Svg.OverrideColor:= Color;
        end;
      end;
    end;
  end);
end;

class procedure TStyledControls_Events.OnMouseLeave(Sender: TObject);
var
  Btn: TButton;
  SpdBtn: TSpeedButton;
  Lbl: TLabel;
  SVG: TSkSvg;
begin
  TThread.ForceQueue(nil,
  procedure
  var
    i: Integer;
  begin
    if Sender is TButton then
    begin
      Btn:= Sender as TButton;
      if not Btn.Text.Trim.IsEmpty then
        Btn.FontColor:= TAlphaColor(Btn.Tag);

      for i:= 0 to Btn.ChildrenCount - 1 do
      begin
        if Btn.Children[i].ClassType = TLabel then
        begin
          Lbl:= Btn.Children[i] as TLabel;
          Lbl.FontColor:= TAlphaColor(Lbl.Tag);
        end
        else
        if Btn.Children[i].ClassType = TSkSvg then
        begin
          SVG:= Btn.Children[i] as TSkSvg;
          SVG.Svg.OverrideColor:= TAlphaColor(SVG.Tag);
        end;
      end;
    end
    else
    if Sender is TSpeedButton then
    begin
      SpdBtn:= Sender as TSpeedButton;
      if not SpdBtn.Text.Trim.IsEmpty then
        SpdBtn.FontColor:= TAlphaColor(SpdBtn.Tag);

      for i:= 0 to SpdBtn.ChildrenCount - 1 do
      begin
        if SpdBtn.Children[i].ClassType = TLabel then
        begin
          Lbl:= SpdBtn.Children[i] as TLabel;
          Lbl.FontColor:= TAlphaColor(Lbl.Tag);
        end
        else
        if SpdBtn.Children[i].ClassType = TSkSvg then
        begin
          SVG:= SpdBtn.Children[i] as TSkSvg;
          SVG.Svg.OverrideColor:= TAlphaColor(SVG.Tag);
        end;
      end;
    end;
  end);
end;

end.
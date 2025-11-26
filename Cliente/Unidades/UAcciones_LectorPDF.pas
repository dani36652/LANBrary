unit UAcciones_LectorPDF;

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

type TAcciones_LectorPDF = class
  private
  public
    class procedure btnAtras_VisorPDFClick(Sender: TObject);
end;

implementation
uses
  UMain;

{ TAcciones_LectorPDF }

class procedure TAcciones_LectorPDF.btnAtras_VisorPDFClick(Sender: TObject);
begin
  frmMain.Pantallas.ActiveTab:= frmMain.Principal;
end;

end.

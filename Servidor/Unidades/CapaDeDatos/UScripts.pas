unit UScripts;

interface

uses
  System.SysUtils, System.Classes, FireDAC.UI.Intf, FireDAC.Stan.Async,
  FireDAC.Comp.ScriptCommands, FireDAC.Stan.Util, FireDAC.Stan.Intf,
  FireDAC.Comp.Script;

type
  TScripts = class(TDataModule)
    StoredProcedures: TFDScript;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Scripts: TScripts;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}

{$R *.dfm}

end.

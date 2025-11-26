(*
  DRH 28/10/2025
  -El StatusCode 423 será el que se devuelve en todos los endpoints
  para indicar que la cuenta del usuario está bloqueada.
*)

unit UWebServer;

interface

uses
  System.SysUtils, System.Classes, Web.HTTPApp, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf,
  FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys,
  FireDAC.FMXUI.Wait, Data.DB, FireDAC.Comp.Client, System.SyncObjs;

type
  TWebServer = class(TWebModule)
    procedure WebModule1DefaultHandlerAction(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
    procedure WebServerRegistrarUsuarioAction(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
    procedure WebServerLoginAction(Sender: TObject; Request: TWebRequest;
      Response: TWebResponse; var Handled: Boolean);
    procedure WebServerObtenerCategoriasAction(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
    procedure WebServerObtenerLibrosAction(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
    procedure WebServerObtenerLibros2Action(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
    procedure WebServerCambiarClaveAction(Sender: TObject; Request: TWebRequest;
      Response: TWebResponse; var Handled: Boolean);
    procedure WebServerCambiarFotoPerfilAction(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
    procedure WebServerDescargarLibroAction(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
    procedure WebServerBuscarLibrosAction(Sender: TObject; Request: TWebRequest;
      Response: TWebResponse; var Handled: Boolean);
    procedure WebServerBuscarLibros2Action(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
  private
    { Private declarations }
    class procedure ServidorOcupado(const Response: TWebResponse);
  public
  end;

var
  WebModuleClass: TComponentClass = TWebServer;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}
uses
  UMain,
  System.JSON, System.JSON.Builders, System.JSON.BSON, System.JSON.Readers,
  System.JSON.Converters, System.JSON.Types, System.JSON.Utils,

  Generales, DBActions, uJSONTool, UAcciones_Inicio;

{$R *.dfm}

class procedure TWebServer.ServidorOcupado(const Response: TWebResponse);
begin
  Response.ContentType:= 'application/json; charset=utf-8';
  Response.StatusCode:= 503;
  Response.Content:= 'Servidor ocupado, intente más tarde.';
end;

procedure TWebServer.WebModule1DefaultHandlerAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
begin
  Response.ContentType:= 'application/json; charset=utf-8';
  Response.StatusCode:= 400;
end;

procedure TWebServer.WebServerBuscarLibros2Action(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
var
  JStr: string;
  StatusCode: Integer;
  Session: string;
begin
  if Semaforo.WaitFor(7000) = wrSignaled then
  begin
    try
      Session:= Request.GetFieldByName('us-session');
      Response.ContentType:= 'application/json; charset=utf-8';
      if Session.Trim.IsEmpty then
      begin
        Response.StatusCode:= 403;
        Exit;
      end;

      JStr:= GenerarJSONArrayBusquedaLibros(2, Session,
      Request.Content, StatusCode);

      Response.StatusCode:= StatusCode;
      if StatusCode = 200 then
        Response.Content:= JStr;
    finally
      Semaforo.Release;
    end;
  end
  else
    ServidorOcupado(Response);
end;

procedure TWebServer.WebServerBuscarLibrosAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
var
  JStr, Session: string;
  StatusCode: Integer;
begin
  if Semaforo.WaitFor(7000) = wrSignaled then
  begin
    try
      Session:= Request.GetFieldByName('us-session');
      Response.ContentType:= 'application/json; charset=utf-8';
      if Session.Trim.IsEmpty then
      begin
        Response.StatusCode:= 403;
        Exit;
      end;

      JStr:= GenerarJSONArrayBusquedaLibros(1, Session,
      Request.Content, StatusCode);

      Response.StatusCode:= StatusCode;
      if StatusCode = 200 then
        Response.Content:= JStr;
    finally
      Semaforo.Release;
    end;
  end
  else
    ServidorOcupado(Response);
end;

procedure TWebServer.WebServerCambiarClaveAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
var
  Mensaje, Session: string;
begin
  if Semaforo.WaitFor(7000) = wrSignaled then
  begin
    try
      Session:= Request.GetFieldByName('us-session');
      Response.ContentType:= 'application/json; charset=utf-8';
      if Session.Trim.IsEmpty then
      begin
        Response.StatusCode:= 403;
        Exit;
      end;

      Response.StatusCode:= CambiarClave(Session,
      Request.Content, Mensaje);

      if not Mensaje.IsEmpty then
        TAcciones_Inicio.MostrarEvento_Servidor(Mensaje);
    finally
      Semaforo.Release;
    end;
  end
  else
    ServidorOcupado(Response);
end;

procedure TWebServer.WebServerCambiarFotoPerfilAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
var
  Mensaje, Session: string;
begin
  if Semaforo.WaitFor(7000) = wrSignaled then
  begin
    try
      Response.ContentType:= 'application/json; charset=utf-8';
      Session:= Request.GetFieldByName('us-session');
      if Session.Trim.IsEmpty then
      begin
        Response.StatusCode:= 403;
        Exit;
      end;

      Response.StatusCode:= CambiarFotoPerfil(Session,
      Request.Content, Mensaje);

      if not Mensaje.IsEmpty then
        TAcciones_Inicio.MostrarEvento_Servidor(Mensaje);
    finally
      Semaforo.Release;
    end;
  end
  else
    ServidorOcupado(Response);
end;

procedure TWebServer.WebServerDescargarLibroAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
var
  StatusCode: Integer;
  Base64String, Session:string;
begin
  if Semaforo.WaitFor(7000) = wrSignaled then
  begin
    try
      Session:= Request.GetFieldByName('us-session');
      Response.ContentType:= 'application/json; charset=utf-8';
      if Session.Trim.IsEmpty then
      begin
        Response.StatusCode:= 403;
        Exit;
      end;

      Base64String:= ObetenerLibroPorID(Session,
      Request.Content, StatusCode);

      Response.StatusCode:= StatusCode;
      if not Base64String.IsEmpty then
        Response.Content:= Base64String;
    finally
      Semaforo.Release;
    end;
  end
  else
    ServidorOcupado(Response);
end;

procedure TWebServer.WebServerLoginAction(Sender: TObject; Request: TWebRequest;
  Response: TWebResponse; var Handled: Boolean);
var
  JSONObj: TJSONObject;
begin
  if Semaforo.WaitFor(7000) = wrSignaled then
  begin
    try
      Response.ContentType:= 'application/json; charset=utf-8';
      JSONObj:= IniciarSesion(Request.Content);
      try
        if Assigned(JSONObj.FindValue('error')) then
          Response.StatusCode:= JSONObj.Values['error'].Value.ToInteger
        else
        if Assigned(JSONObj.FindValue('id')) then
        begin
          Response.StatusCode:= 200;
          Response.Content:= JSONObj.ToString;
          TAcciones_Inicio.MostrarEvento_Servidor(JSONObj.Values['correo'].Value +
          ' ha iniciado sesión', 1);
        end;
      finally
        FreeAndNil(JSONObj);
      end;
    finally
      Semaforo.Release;
    end;
  end
  else
    ServidorOcupado(Response);
end;

procedure TWebServer.WebServerObtenerCategoriasAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
var
  JStr: string;
  StatusCode: Integer;
  Session: string;
begin
  if Semaforo.WaitFor(7000) = wrSignaled then
  begin
    try
      Session:= Request.GetFieldByName('us-session');
      Response.ContentType:= 'application/json; charset=utf-8';
      if Session.Trim.IsEmpty then
      begin
        Response.StatusCode:= 403;
        Exit;
      end;

      JStr:= GenerarJSONArrayCategorias(Session, StatusCode);
      Response.StatusCode:= StatusCode;
      if StatusCode = 200 then
        Response.Content:= JStr;
    finally
      Semaforo.Release;
    end;
  end
  else
    ServidorOcupado(Response);
end;

procedure TWebServer.WebServerObtenerLibros2Action(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
var
  JStr: string;
  StatusCode: Integer;
  Session: string;
begin
  if Semaforo.WaitFor(7000) = wrSignaled then
  begin
    try
      Session:= Request.GetFieldByName('us-session');
      Response.ContentType:= 'application/json; charset=utf-8';
      if Session.Trim.IsEmpty then
      begin
        Response.StatusCode:= 403;
        Exit;
      end;

      JStr:= GenerarJSONArrayLibros(Session, Request.Content, StatusCode);

      Response.StatusCode:= StatusCode;
      if StatusCode = 200 then
        Response.Content:= JStr;
    finally
      Semaforo.Release;
    end;
  end
  else
    ServidorOcupado(Response);
end;

procedure TWebServer.WebServerObtenerLibrosAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
var
  JStr: string;
  strIdCat, StrFiltro, StrCount: string;
  idCategoria: Integer;
  Filtro: Integer;
  Count: Integer;
  Parametros: TStringList;
  StatusCode: Integer;
  Session: string;
begin
  if Semaforo.WaitFor(7000) = wrSignaled then
  begin
    try
      Session:= Request.GetFieldByName('us-session');
      Response.ContentType:= 'application/json; charset=utf-8';
      if Session.Trim.IsEmpty then
      begin
        Response.StatusCode:= 403;
        Exit;
      end;

      //Se espera 'n&n&n'
      Parametros:= TStringList.Create;
      try
        Parametros.Text:= Request.Content.Replace('&', sLineBreak);
        if Parametros.Count = 3 then
        begin
          strIdCat:= Parametros[0];
          StrFiltro:= Parametros[1];
          StrCount:= Parametros[2];
        end
        else
        begin
          Response.StatusCode:= 409;
          Exit;
        end;
      finally
        FreeAndNil(Parametros);
      end;

      if (not TryStrToInt(strIdCat, idCategoria)) or
      (not TryStrToInt(StrFiltro, Filtro)) or
      (not TryStrToInt(StrCount, Count)) then
      begin
        Response.StatusCode:= 409;
        Exit;
      end;

      JStr:= GenerarJSONArrayLibros(Session,
      idCategoria, Filtro, StatusCode, Count);

      Response.StatusCode:= StatusCode;
      if StatusCode = 200 then
        Response.Content:= JStr;
    finally
      Semaforo.Release;
    end;
  end
  else
    ServidorOcupado(Response);
end;

procedure TWebServer.WebServerRegistrarUsuarioAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
var
  JSONObj: TJSONObject;
  StatusCode: Integer;
begin
  if Semaforo.WaitFor(7000) = wrSignaled then
  begin
    try
      Response.ContentType:= 'application/json; charset=utf-8';
      StatusCode:= RegistrarUsuario(Request.Content);
      Response.StatusCode:= StatusCode;

      if StatusCode = 200 then
      begin
        JSONObj:= TJSONObject.ParseJSONValue(Request.Content) as TJSONObject;
        try
          try
            if JSONObj.FindValue('correo') <> nil then
              TAcciones_Inicio.MostrarEvento_Servidor('El usuario: ' +
              JSONObj.Values['correo'].Value + ' se registró con éxito' , 1);
          except on E: Exception do
            begin
              EscribirLog('UWebServer.WebServerRegistrarUsuarioAction: ' + E.Message, 2);
            end;
          end;
        finally
          if JSONObj <> nil then
            FreeAndNil(JSONObj);
        end;
      end;
    finally
      Semaforo.Release;
    end;
  end
  else
    ServidorOcupado(Response);
end;

end.

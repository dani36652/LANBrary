unit URest;

interface

Uses
  System.Types, System.SysConst, System.StrUtils, System.Generics.Collections,
  System.Classes, System.SysUtils, System.Net.URLClient, System.Net.HttpClient,
  System.Net.HttpClientComponent;

type
  RRespuesta = Record
  Code: Integer;
  Code_Descrip: String;
  Mensaje: String;
End;

type TREST=Class(TComponent)
  private
    BaseURL: String;
    Client: TNetHTTPClient;
    Request: TNetHTTPRequest;
    HttpRespuesta: RRespuesta;
    Headers: TNetHeaders;
    procedure NetHTTPClientRequestError(const Sender: TObject; const AError: string);
    procedure ProcesarRespuesta(const Response: IHTTPResponse);
    procedure InicializarRespuesta;
    Procedure OnValidateCert(const Sender: TObject; const ARequest: TURLRequest;
    const Certificate: TCertificate; var Accepted: Boolean);
    procedure setBaseURL(URL: string);
  public
    Constructor Create(AOwner: TComponent); override;
    Procedure POST(const jstr: String; EndPoint: string; Params: String = '');
    Procedure GET(const Params: String; EndPoint: string);
    Procedure PUT(const jstr: string; EndPoint: string; Params: String = '');
    Property Respuesta: RRespuesta Read HttpRespuesta;
    property URL: string read BaseURL write setBaseURL;
    procedure setAuthorization(const ID: string);
End;

implementation

constructor TREST.Create(AOwner: TComponent);
begin
  inherited;
  SetLength(Headers, 2);
  Headers[1].Name:= 'ngrok-skip-browser-warning';
  Headers[1].Value:= 'remove';

  Client := TNetHTTPClient.Create(self);
  Client.OnRequestError := NetHTTPClientRequestError;
  Client.OnValidateServerCertificate := OnValidateCert;
  Request := TNetHTTPRequest.Create(self);
  Request.ResponseTimeout:= 10000;
  Request.ConnectionTimeout:= 10000;

  Client.UserAgent := 'Mozilla/5.0';
  Client.Accept := 'text/plain';
  Client.ContentType := 'application/json;';
  Client.AcceptCharSet := 'utf-8';
  Client.ResponseTimeout:= 10000;
  Client.ConnectionTimeout:= 10000;
end;

procedure TREST.GET(const Params: String; EndPoint: string);
var
  resp: TMemoryStream;
  res: IHTTPResponse;
  URL: String;
begin
  if EndPoint.StartsWith('/') then
    EndPoint:= EndPoint.Remove(1);

  InicializarRespuesta;
  URL:= BaseURL + EndPoint + Params;

  resp := TMemoryStream.Create;
  try
    if not Headers[0].Value.IsEmpty then
      res:= Client.Get(URL, resp, Headers)
    else
      res := Client.Get(URL, resp);

    if Assigned(res) then
      ProcesarRespuesta(res);
  finally
    FreeAndNil(resp);
  end;
end;

procedure TREST.InicializarRespuesta;
begin
  HttpRespuesta.Code := 0;
  HttpRespuesta.Mensaje := '';
end;

procedure TREST.NetHTTPClientRequestError(const Sender: TObject;
  const AError: string);
begin
  HttpRespuesta.Code := 500;
  HttpRespuesta.Mensaje := AError;
end;

procedure TREST.OnValidateCert(const Sender: TObject;
  const ARequest: TURLRequest; const Certificate: TCertificate;
  var Accepted: Boolean);
begin
  Accepted := true;
end;

procedure TREST.POST(const jstr: String; EndPoint: string; Params: String = '');
var
  body: TStringStream;
  resp: TMemoryStream;
  res: IHTTPResponse;
  URL: String;
begin
  if EndPoint.StartsWith('/') then
    EndPoint:= EndPoint.Remove(1);

  InicializarRespuesta;
  URL:= BaseURL + EndPoint;

  body := TStringStream.Create(jstr);
  resp := TMemoryStream.Create;
  try
    if not Headers[0].Value.IsEmpty then
      res := Client.Post(URL, body, resp, Headers)
    else
      res:= Client.Post(URL, body, resp);

    if Assigned(res) then
      ProcesarRespuesta(res);
  finally
    FreeAndNil(body);
    FreeAndNil(resp);
  end;
end;

procedure TREST.ProcesarRespuesta(const Response: IHTTPResponse);
begin
  HttpRespuesta.Code := Response.StatusCode;
  HttpRespuesta.Code_Descrip := Response.StatusText;
  HttpRespuesta.Mensaje := Response.ContentAsString(TUTF8Encoding.UTF8);
end;

procedure TREST.PUT(const jstr: string; EndPoint: string; Params: String);
var
  body: TStringStream;
  resp: TMemoryStream;
  res: IHTTPResponse;
  URL: String;
begin
  if EndPoint.StartsWith('/') then
    EndPoint:= EndPoint.Remove(1);

  InicializarRespuesta;
  URL:= BaseURL + EndPoint;

  body := TStringStream.Create(jstr);
  resp := TMemoryStream.Create;
  try
    if not Headers[0].Value.IsEmpty then
      res := Client.PUT(URL, body, resp, Headers)
    else
      res:= Client.Post(URL, body, resp);

    if Assigned(res) then
      ProcesarRespuesta(res);
  finally
    FreeAndNil(body);
    FreeAndNil(resp);
  end;
end;

procedure TREST.setAuthorization(const ID: string);
begin
  Headers[0].Name:= 'us-session';
  Headers[0].Value:= ID;
end;

procedure TREST.setBaseURL(URL: string);
begin
  if not BaseURL.Equals(URL + '/') then
    BaseURL:= URL + '/';
end;

end.

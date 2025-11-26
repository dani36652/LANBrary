unit UJSONTool;

interface
uses
  EUsuario, ECategoria, ELibro,
  System.Classes, fmx.Dialogs, System.Generics.Collections,
  System.SysUtils, System.Types, System.UITypes, System.JSON,
  System.JSON.Builders, System.JSON.Converters, System.JSon.Types;

type TJSONTool = class
  private
  public
    //Categorias
    class function ObtenerCategorias: TArray<rCategoria>;

    //Usuarios
    class function RegistrarUsuario(const Nombre, Apellido_P, Apellido_M, Correo, Clave,
    Edad, Foto: string): Integer;

    class function CambiarClave(const Correo, Clave, ClaveNueva: string): Integer;
    class function CambiarFotoPerfil(const Correo, Foto: string): Integer;
    class function IniciarSesion(const Correo, Clave: string): rUsuario;

    //Libros
    class function ObtenerLibros(const Id_Categoria, Filtro,
    Cantidad: Integer; var Usr_Bloqueado: Boolean;
    out StatusCode: Integer): TArray<rLibro>; overload;

    class function ObtenerLibros(const Filtro, Ult_id_cat: Integer;
    const Ult_fechahora, Ult_id: string; const Cantidad: Integer;
    var Usr_Bloqueado: Boolean;
    out StatusCode: Integer): TArray<rLibro>; overload;

    class function DescargarLibro(const ID: string; var Usr_Bloqueado: Boolean): string;

    class function BuscarLibros(const AKeyword: string; const Id_Categoria, Filtro,
    Cantidad: Integer; var Usr_Bloqueado: Boolean;
    out StatusCode: Integer): TArray<rLibro>; overload;

    class function BuscarLibros(const AKeyword: string; const Filtro,
    Ult_id_cat: Integer; const Ult_fechahora, Ult_id: string;
    const Cantidad: Integer;
    var Usr_Bloqueado: Boolean;
    out StatusCode: Integer): TArray<rLibro>; overload;
end;

implementation
uses
  URest, UMain, Generales, System.IOUtils;

{ TJSONTool }

class function TJSONTool.ObtenerCategorias: TArray<rCategoria>;
var
  JSObj: TJSONObject;
  JArray: TJSONArray;
  i: Integer;
begin
  SetLength(Result, 0);
  try
    REST.URL:= URLServidor;
    REST.setAuthorization(Usuario.id);
    REST.GET('?', 'categorias');
    case REST.Respuesta.Code of
      200:
      begin
        if REST.Respuesta.Mensaje.Trim.Equals('{}') then
        begin
          EscribirLog('UJSONTool.ObtenerCategorias: Error al obtener categorías, ' +
          'la respuesta es un JSON vacío "{}"');
          Exit;
        end;

        JSObj:= TJSONObject.ParseJSONValue(REST.Respuesta.Mensaje) as TJSONObject;
        try
          if JSObj.FindValue('categorias') <> nil then
          begin
            JArray:= JSObj.Values['categorias'] as TJSONArray;
            EscribirLog(JArray.Count.ToString + ' categorías fueron obtenidas desde el servidor.');
            if JArray.Count > 0 then
            begin
              for i:= 0 to JArray.Count - 1 do
              begin
                SetLength(Result, Length(Result) + 1);
                Result[i].Id:= TJSONObject(JArray.Items[i]).Values['id'].Value;
                Result[i].Descripcion:= TJSONObject(JArray.Items[i]).Values['descripcion'].Value;
              end;
            end;
          end;
        finally
          if JSObj <> nil then
            FreeAndNil(JSObj);
        end;
      end;
    end;
  except on E: exception do
    EscribirLog(E.ClassName + ': Error al obtener categorías: ' + E.Message, 2);
  end;
end;

class function TJSONTool.ObtenerLibros(const Filtro, Ult_id_cat: Integer;
  const Ult_fechahora, Ult_id: string; const Cantidad: Integer;
  var Usr_Bloqueado: Boolean;
  out StatusCode: Integer): TArray<rLibro>;
var
  JSONObj, JSONObjDatos: TJSONObject;
  JArray: TJSONArray;
  i: Integer;
  Jstr: string;
begin
  SetLength(Result, 0);
  try
    JSONObjDatos:= TJSONObject.Create;
    try
      JSONObjDatos.AddPair('filtro', TJSONNumber.Create(Filtro));
      JSONObjDatos.AddPair('ult_id_cat', TJSONNumber.Create(Ult_id_cat));
      JSONObjDatos.AddPair('ult_fechahora', Ult_fechahora);
      JSONObjDatos.AddPair('ult_id', Ult_id);
      JSONObjDatos.AddPair('cantidad', TJSONNumber.Create(Cantidad));
      Jstr:= JSONObjDatos.ToString;
    finally
      FreeAndNil(JSONObjDatos);
    end;

    REST.URL:= URLServidor;
    REST.setAuthorization(Usuario.id);
    REST.POST(Jstr, 'books/scrolling');
    case REST.Respuesta.Code of
      200:
      begin
        JSONObj:= TJSONObject.ParseJSONValue(REST.Respuesta.Mensaje) as TJSONObject;
        try
          if JSONObj.FindValue('libros') <> nil then
          begin
            JArray:= JSONObj.Values['libros'] as TJSONArray;
            if JArray.Count > 0 then
            begin
              for i:= 0 to JArray.Count - 1 do
              begin
                SetLength(Result, Length(Result) + 1);
                Result[i].Id:= TJSONObject(JArray.Items[i]).Values['id'].Value;
                Result[i].Nombre:= TJSONObject(JArray.Items[i]).Values['nombre'].Value;
                Result[i].Descripcion:= TJSONObject(JArray.Items[i]).Values['descripcion'].Value;
                Result[i].Autor:= TJSONObject(JArray.Items[i]).Values['autor'].Value;
                Result[i].Fechahora:= TJSONObject(JArray.Items[i]).Values['fechahora'].Value;
                Result[i].Estatus:= TJSONObject(JArray.Items[i]).Values['estatus'].Value.ToInteger;
                Result[i].Portada:= TJSONObject(JArray.Items[i]).Values['portada'].Value;
                Result[i].Archivo:= TJSONObject(JArray.Items[i]).Values['archivo'].Value;
                Result[i].Usuario:= TJSONObject(JArray.Items[i]).Values['usuario'].Value;
                Result[i].Id_Categoria:= TJSONObject(JArray.Items[i]).Values['id_categoria'].Value.ToInteger;
              end;

              EscribirLog('TJSONTool.ObtenerLibros2: Libros obtenidos ' +
              'correctamente.', 1);
            end;
          end;
        finally
          if JSONObj <> nil then
            FreeAndNil(JSONObj);
        end;
      end;

      204:
        EscribirLog('TJSONTool.ObtenerLibros2: No se obtuvieron los libros, ' +
        'sin resultados StatusCode = 204');

      403:
        EscribirLog('TJSONTool.ObtenerLibros2: No fue posible obtener ' +
        'libros, sesión no válida.', 1);

      409:
        EscribirLog('TJSONTool.ObtenerLibros2: No fue posible obtener ' +
        'libros los parametros enviados no son correctos.', 1);


      423:
      begin
        Usr_Bloqueado:= True;
        EscribirLog('TJSONTool.ObtenerLibros2: No se obtuvieron los libros, ' +
        'la cuenta del usuario está bloqueada.');
      end;

      503:
        EscribirLog('TJSONTool.ObtenerLibros2: No fue posible obtener ' +
        'libros, error interno del servidor.', 1);

      else
        EscribirLog('TJSONTool.ObtenerLibros2: No fue posible obtener ' +
        'los libros StatusCode = ' + REST.Respuesta.Code.ToString);
    end;
  except on E: Exception do
    begin
      EscribirLog('UJSONTool.ObtenerLibros2: ' + E.Message, 2);
      SetLength(Result, 0);
    end;
  end;
end;

class function TJSONTool.ObtenerLibros(const Id_Categoria, Filtro,
Cantidad: Integer; var Usr_Bloqueado: Boolean;
out StatusCode: Integer): TArray<rLibro>;
var
  JSONObj: TJSONObject;
  JArray: TJSONArray;
  i: Integer;
begin
  SetLength(Result, 0);
  try
    REST.URL:= URLServidor;
    REST.setAuthorization(Usuario.id);
    REST.GET('?' + IntToStr(Id_Categoria) + '&' + IntToStr(Filtro) +
    '&' + IntToStr(Cantidad), 'books');
    case REST.Respuesta.Code of
      200:
      begin
        JSONObj:= TJSONObject.ParseJSONValue(REST.Respuesta.Mensaje) as TJSONObject;
        try
          if JSONObj.FindValue('libros') <> nil then
          begin
            JArray:= JSONObj.Values['libros'] as TJSONArray;
            if JArray.Count > 0 then
            begin
              for i:= 0 to JArray.Count - 1 do
              begin
                SetLength(Result, Length(Result) + 1);
                Result[i].Id:= TJSONObject(JArray.Items[i]).Values['id'].Value;
                Result[i].Nombre:= TJSONObject(JArray.Items[i]).Values['nombre'].Value;
                Result[i].Descripcion:= TJSONObject(JArray.Items[i]).Values['descripcion'].Value;
                Result[i].Autor:= TJSONObject(JArray.Items[i]).Values['autor'].Value;
                Result[i].Fechahora:= TJSONObject(JArray.Items[i]).Values['fechahora'].Value;
                Result[i].Estatus:= TJSONObject(JArray.Items[i]).Values['estatus'].Value.ToInteger;
                Result[i].Portada:= TJSONObject(JArray.Items[i]).Values['portada'].Value;
                Result[i].Archivo:= TJSONObject(JArray.Items[i]).Values['archivo'].Value;
                Result[i].Usuario:= TJSONObject(JArray.Items[i]).Values['usuario'].Value;
                Result[i].Id_Categoria:= TJSONObject(JArray.Items[i]).Values['id_categoria'].Value.ToInteger;
              end;

              EscribirLog('TJSONTool.ObtenerLibros: Libros obtenidos ' +
              'correctamente', 1);
            end;
          end;
        finally
          if JSONObj <> nil then
            FreeAndNil(JSONObj);
        end;
      end;

      204:
        EscribirLog('TJSONTool.ObtenerLibros: No se obtuvieron los libros, ' +
        'sin resultados StatusCode = 204');

      403:
        EscribirLog('TJSONTool.ObtenerLibros: No fue posible obtener ' +
        'libros, sesión no válida.', 1);

      409:
        EscribirLog('TJSONTool.ObtenerLibros: No fue posible obtener ' +
        'libros los parametros enviados no son correctos.', 1);


      423:
      begin
        Usr_Bloqueado:= True;
        EscribirLog('TJSONTool.ObtenerLibros: No se obtuvieron los libros, ' +
        'la cuenta del usuario está bloqueada.');
      end;

      503:
        EscribirLog('TJSONTool.ObtenerLibros: No fue posible obtener ' +
        'libros, error interno del servidor.', 1);

      else
        EscribirLog('TJSONTool.ObtenerLibros: No fue posible obtener ' +
        'los libros StatusCode = ' + REST.Respuesta.Code.ToString);
    end;
  except on E: Exception do
    begin
      EscribirLog('UJSONTool.ObtenerLibros: ' + E.Message, 2);
      SetLength(Result, 0);
    end;
  end;
end;

class function TJSONTool.BuscarLibros(const AKeyword: string; const Filtro,
  Ult_id_cat: Integer; const Ult_fechahora, Ult_id: string;
  const Cantidad: Integer; var Usr_Bloqueado: Boolean;
  out StatusCode: Integer): TArray<rLibro>;
var
  JSONObj, JSONObjDatos: TJSONObject;
  JArray: TJSONArray;
  i: Integer;
  Jstr: string;
begin
  SetLength(Result, 0);
  try
    JSONObjDatos:= TJSONObject.Create;
    try
      JSONObjDatos.AddPair('filtro', TJSONNumber.Create(Filtro));
      JSONObjDatos.AddPair('ult_id_cat', TJSONNumber.Create(Ult_id_cat));
      JSONObjDatos.AddPair('ult_fechahora', Ult_fechahora);
      JSONObjDatos.AddPair('ult_id', Ult_id);
      JSONObjDatos.AddPair('cantidad', TJSONNumber.Create(Cantidad));
      JSONObjDatos.AddPair('keyword', AKeyword);
      Jstr:= JSONObjDatos.ToString;
    finally
      FreeAndNil(JSONObjDatos);
    end;

    REST.URL:= URLServidor;
    REST.setAuthorization(Usuario.id);
    REST.POST(Jstr, 'search/books2');
    StatusCode:= REST.Respuesta.Code;
    case REST.Respuesta.Code of
      200:
      begin
        JSONObj:= TJSONObject.ParseJSONValue(REST.Respuesta.Mensaje) as TJSONObject;
        try
          if JSONObj.FindValue('libros') <> nil then
          begin
            JArray:= JSONObj.Values['libros'] as TJSONArray;
            if JArray.Count > 0 then
            begin
              for i:= 0 to JArray.Count - 1 do
              begin
                SetLength(Result, Length(Result) + 1);
                Result[i].Id:= TJSONObject(JArray.Items[i]).Values['id'].Value;
                Result[i].Nombre:= TJSONObject(JArray.Items[i]).Values['nombre'].Value;
                Result[i].Descripcion:= TJSONObject(JArray.Items[i]).Values['descripcion'].Value;
                Result[i].Autor:= TJSONObject(JArray.Items[i]).Values['autor'].Value;
                Result[i].Fechahora:= TJSONObject(JArray.Items[i]).Values['fechahora'].Value;
                Result[i].Estatus:= TJSONObject(JArray.Items[i]).Values['estatus'].Value.ToInteger;
                Result[i].Portada:= TJSONObject(JArray.Items[i]).Values['portada'].Value;
                Result[i].Archivo:= TJSONObject(JArray.Items[i]).Values['archivo'].Value;
                Result[i].Usuario:= TJSONObject(JArray.Items[i]).Values['usuario'].Value;
                Result[i].Id_Categoria:= TJSONObject(JArray.Items[i]).Values['id_categoria'].Value.ToInteger;
              end;

              EscribirLog('TJSONTool.BuscarLibros2: Busqueda realizada  ' +
              'correctamente');
            end;
          end;
        finally
          if JSONObj <> nil then
            FreeAndNil(JSONObj);
        end;
      end;

      204:
        EscribirLog('TJSONTool.BuscarLibros2: Sin resultados en la busqueda, ' +
        'SattusCode = 204', 1);

      403:
        EscribirLog('TJSONTool.BuscarLibros2: Sin resultados en la busqueda, ' +
        'sesion no válida SattusCode = 403', 1);

      409:
        EscribirLog('TJSONTool.BuscarLibros2: Sin resultados en la busqueda, ' +
        'parametros incorrectos SattusCode = 409', 1);

      423:
      begin
        Usr_Bloqueado:= True;
        EscribirLog('TJSONTool.BuscarLibros2: Sin resultados en la busqueda, ' +
        'cuenta de usuario bloqueada SattusCode = 423', 1);
      end;

      503:
        EscribirLog('TJSONTool.BuscarLibros2: Sin resultados en la busqueda, ' +
        'error interno del servidor SattusCode = 503', 1);

      else
        EscribirLog('TJSONTool.BuscarLibros2: Sin resultados en la busqueda, ' +
        'SattusCode = ' + REST.Respuesta.Code.ToString + ' ' +
        REST.Respuesta.Mensaje, 1);
    end;
  except on E: Exception do
    begin
      EscribirLog('UJSONTool.ObtenerLibros2: ' + E.Message, 2);
      SetLength(Result, 0);
    end;
  end;
end;

class function TJSONTool.BuscarLibros(const AKeyword: string; const Id_Categoria,
  Filtro, Cantidad: Integer; var Usr_Bloqueado: Boolean;
  out StatusCode: Integer): TArray<rLibro>;
var
  JSONObj, JSONObjDatos: TJSONObject;
  JArray: TJSONArray;
  i: Integer;
  Jstr: string;
begin
  SetLength(Result, 0);
  try
    JSONObjDatos:= TJSONObject.Create;
    try
      JSONObjDatos.AddPair('id_categoria', TJSONNumber.Create(Id_Categoria));
      JSONObjDatos.AddPair('filtro', TJSONNumber.Create(Filtro));
      JSONObjDatos.AddPair('cantidad', TJSONNumber.Create(Cantidad));
      JSONObjDatos.AddPair('keyword', AKeyword);
      Jstr:= JSONObjDatos.ToString;
    finally
      FreeAndNil(JSONObjDatos);
    end;

    REST.URL:= URLServidor;
    REST.setAuthorization(Usuario.id);
    REST.POST(Jstr, 'search/books');
    StatusCode:= REST.Respuesta.Code;
    case REST.Respuesta.Code of
      200:
      begin
        JSONObj:= TJSONObject.ParseJSONValue(REST.Respuesta.Mensaje) as TJSONObject;
        try
          if JSONObj.FindValue('libros') <> nil then
          begin
            JArray:= JSONObj.Values['libros'] as TJSONArray;
            if JArray.Count > 0 then
            begin
              for i:= 0 to JArray.Count - 1 do
              begin
                SetLength(Result, Length(Result) + 1);
                Result[i].Id:= TJSONObject(JArray.Items[i]).Values['id'].Value;
                Result[i].Nombre:= TJSONObject(JArray.Items[i]).Values['nombre'].Value;
                Result[i].Descripcion:= TJSONObject(JArray.Items[i]).Values['descripcion'].Value;
                Result[i].Autor:= TJSONObject(JArray.Items[i]).Values['autor'].Value;
                Result[i].Fechahora:= TJSONObject(JArray.Items[i]).Values['fechahora'].Value;
                Result[i].Estatus:= TJSONObject(JArray.Items[i]).Values['estatus'].Value.ToInteger;
                Result[i].Portada:= TJSONObject(JArray.Items[i]).Values['portada'].Value;
                Result[i].Archivo:= TJSONObject(JArray.Items[i]).Values['archivo'].Value;
                Result[i].Usuario:= TJSONObject(JArray.Items[i]).Values['usuario'].Value;
                Result[i].Id_Categoria:= TJSONObject(JArray.Items[i]).Values['id_categoria'].Value.ToInteger;
              end;

              EscribirLog('TJSONTool.BuscarLibros: Busqueda correcta.', 1);
            end;
          end;
        finally
          if JSONObj <> nil then
            FreeAndNil(JSONObj);
        end;
      end;

      204:
        EscribirLog('TJSONTool.BuscarLibros: Sin resultados en la busqueda, ' +
        'SattusCode = 204', 1);

      403:
        EscribirLog('TJSONTool.BuscarLibros: Sin resultados en la busqueda, ' +
        'sesion no válida SattusCode = 403', 1);

      409:
        EscribirLog('TJSONTool.BuscarLibros: Sin resultados en la busqueda, ' +
        'parametros incorrectos SattusCode = 409', 1);

      423:
      begin
        Usr_Bloqueado:= True;
        EscribirLog('TJSONTool.BuscarLibros: Sin resultados en la busqueda, ' +
        'cuenta de usuario bloqueada SattusCode = 423', 1);
      end;

      503:
        EscribirLog('TJSONTool.BuscarLibros: Sin resultados en la busqueda, ' +
        'error interno del servidor SattusCode = 503', 1);

      else
        EscribirLog('TJSONTool.BuscarLibros: Sin resultados en la busqueda, ' +
        'SattusCode = ' + REST.Respuesta.Code.ToString + ' ' +
        REST.Respuesta.Mensaje, 1);
    end;
  except on E: Exception do
    begin
      EscribirLog('UJSONTool.BuscarLibros: ' + E.Message, 2);
      SetLength(Result, 0);
    end;
  end;
end;

class function TJSONTool.CambiarClave(const Correo, Clave,
  ClaveNueva: string): Integer;
var
  JSONObj: TJSONObject;
begin
  JSONObj:= TJSONObject.Create;
  try
    JSONObj.AddPair('correo', Correo);
    JSONObj.AddPair('clave', Clave);
    JSONObj.AddPair('clave_n', ClaveNueva);
    try
      REST.URL:= URLServidor;
      REST.setAuthorization(Usuario.id);
      REST.PUT(JSONObj.ToString, 'editpassword', '');
      Result:= REST.Respuesta.Code;
    except on E: Exception do
      begin
        EscribirLog('uJSONTool.CambiarClave: ' + E.Message, 2);
        Result:= -1;
      end;
    end;
  finally
    FreeAndNil(JSONObj);
  end;
end;

class function TJSONTool.CambiarFotoPerfil(const Correo, Foto: string): Integer;
var
  JSONObj: TJSONObject;
begin
  JSONObj:= TJSONObject.Create;
  try
    JSONObj.AddPair('correo', Correo);
    JSONObj.AddPair('foto', Foto);
    try
      REST.URL:= URLServidor;
      REST.setAuthorization(Usuario.id);
      REST.PUT(JSONObj.ToString, 'editprofilepic', '');
      Result:= REST.Respuesta.Code;
    except on E: Exception do
      begin
        EscribirLog('uJSONTool.CambiarFotoPerfil: ' + E.Message, 2);
        Result:= -1;
      end;
    end;
  finally
    FreeAndNil(JSONObj);
  end;
end;

class function TJSONTool.DescargarLibro(const ID: string;
var Usr_Bloqueado: Boolean): string;
var
  FConnection: TREST;
begin
  (*
    -Crear un objeto de tipo TREST en vez de usar
    el que está asignado para uso global, nos permitirá
    las descargas múltiples en un contexto multihilo.
  *)
  Usr_Bloqueado:= False;
  Result:= string.Empty;
  FConnection:= TREST.Create(nil);
  FConnection.URL:= URLServidor;
  try
    try
      FConnection.setAuthorization(Usuario.id);
      FConnection.GET('?' + ID, 'books/download');
      case FConnection.Respuesta.Code of
        200: Result:= FConnection.Respuesta.Mensaje;

        423:
        begin
          Usr_Bloqueado:= True;
          EscribirLog('uJSONTool.DescargarLibro: Cuenta de usuario bloqueada.');
        end;

        204: EscribirLog('uJSONTool.DescargarLibro: El libro solicitado no fue encontrado.');

        403: EscribirLog('uJSONTool.DescargarLibro: No se cuenta con los ' +
        'permisos para esta operación.');
      end;
    except on E: Exception do
      EscribirLog('uJSONTool.DescargarLibro: ' + E.Message, 2);
    end;
  finally
    FreeAndNil(FConnection);
  end;
end;

class function TJSONTool.IniciarSesion(const Correo, Clave: string): rUsuario;
var
  JSONObj, JSRespuesta: TJSONObject;
begin
  JSONObj:= TJSONObject.Create;
  try
    try
      JSONObj.AddPair('correo', Correo);
      JSONObj.AddPair('clave', Clave);
      REST.URL:= URLServidor;
      REST.POST(JSONObj.ToString, 'login');
      Result.Respuesta:= REST.Respuesta.Code;

      case REST.Respuesta.Code of
        200:
        begin
          if REST.Respuesta.Mensaje.Trim.Equals('{}') then
          begin
            EscribirLog('UJSONTool.IniciarSesion: La respuesta es ' +
            'un JSON vacío "{}"', 2);
            Result.Respuesta:= -1;
            Exit;
          end;

          EscribirLog('Se inició sesión correctamente con el correo: ' + Correo);
          JSRespuesta:= TJSONObject.ParseJSONValue(REST.Respuesta.Mensaje) as TJSONObject;
          try
            Result.id:= JSRespuesta.Values['id'].Value;
            Result.Nombre:= JSRespuesta.Values['nombre'].Value;
            Result.Apellido_P:= JSRespuesta.Values['apellido_paterno'].Value;
            Result.Apellido_M:= JSRespuesta.Values['apellido_materno'].Value;
            Result.Correo:= JSRespuesta.Values['correo'].Value;
            Result.Edad:= JSRespuesta.Values['edad'].Value;
            Result.Estatus:= JSRespuesta.Values['estatus'].Value.ToInteger;
            Result.Foto:= JSRespuesta.Values['foto'].Value;
          finally
            FreeAndNil(JSRespuesta);
          end;
        end;

        204:  EscribirLog('No fue posible iniciar sesión: clave o correo no validos.');

        500:  EscribirLog('No fue posible conectarse al servidor', 3);

        else
        begin
          EscribirLog('No fue posible iniciar sesión: codigo de estatus: ' +
          REST.Respuesta.Code.ToString + ', descripcion: ' + REST.Respuesta.Code_Descrip);
        end;
      end;
    except on E: Exception do
      begin
        EscribirLog('UJSONTool.IniciarSesion: ' + E.Message, 2);
        Result.Respuesta:= -1;
      end;
    end;
  finally
    FreeAndNil(JSONObj);
  end;
end;

class function TJSONTool.RegistrarUsuario(const Nombre, Apellido_P, Apellido_M, Correo,
  Clave, Edad, Foto: string): Integer;
var
  JSDatos: TJSONObject;
begin
  JSDatos:= TJSONObject.Create;
  try
    try
      JSDatos.AddPair('nombre', Nombre);
      JSDatos.AddPair('apellido_paterno', Apellido_P);
      JSDatos.AddPair('apellido_materno', Apellido_M);
      JSDatos.AddPair('correo', Correo);
      JSDatos.AddPair('clave', Clave);
      JSDatos.AddPair('edad', Edad);
      JSDatos.AddPair('foto', Foto);

      REST.URL:= URLServidor;
      REST.POST(JSDatos.ToString, 'registrar_usr');
      Result:= REST.Respuesta.Code;

      case REST.Respuesta.Code of
        200:  EscribirLog('Registro de usuario fue correcto Estatus = 200');

        400:  EscribirLog('Error al registrar usuario: Faltan datos Estatus = 400');

        409:  EscribirLog('Error al registrar usuario: Cuenta ya existe Estatus = 409');

        503:  EscribirLog('Error al registrar usuario: Error por parte del servidor Estatus = 503');
      end;
    except on E: Exception do
      begin
        EscribirLog('UJSONTool.RegistrarUsuario: ' + E.Message);
        Result:= -1;
      end;
    end;
  finally
    FreeAndNil(JSDatos);
  end;
end;

end.

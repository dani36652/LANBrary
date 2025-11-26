(*
  DRH 28/10/2025
  -El StatusCode 423 será el que se devuelve en todos los endpoints
  para indicar que la cuenta del usuario está bloqueada.
*)

unit uJSONTool;

interface
uses
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.MySQL, FireDAC.Phys.MySQLDef, FireDAC.FMXUI.Wait,
  FireDAC.Stan.Param, FireDAC.DApt, UWebServer,
  Data.DB, FireDAC.Comp.Client,
  System.Classes, System.Types, System.SysConst, System.SysUtils,
  System.StrUtils,
  System.JSON, System.JSON.Builders, System.JSON.Converters,
  System.JSON.Types, System.JSON.Utils, System.JSON.BSON;

//Usuario
function RegistrarUsuario(const Jstr: string): Integer;
function IniciarSesion(const Jstr: string): TJSONObject;
//A partir de aquí, usar la misma metodología... session,
function CambiarClave(const session, Jstr: string; var Mensaje: string): Integer;
function CambiarFotoPerfil(const session, Jstr: string; var Mensaje: string): Integer;

//CATEGORIAS
function GenerarJSONArrayCategorias(const session: string; var StatusCode: Integer): string;

//LIBROS
function GenerarJSONArrayLibros(const session: string;
const id_categoria: Integer; const Filtro: Integer; var StatusCode: Integer;
const Cantidad: Integer): string; overload;

function GenerarJSONArrayLibros(const session, Jstr: string;
 var StatusCode: Integer): string; overload;

(*
  DRH 16/11/2025
  -La primer búsqueda así como la búsqueda con avance de página,
  se realizan mediante una petición de tipo POST recibiendo lo
  necesario en un JSON.

  Siendo así, se realiza la petición anteriormente descrita con la
  constante "FlagSearch".

  FlagSearch: 1= Busqueda Normal 2=Busqueda con paginación
*)
function GenerarJSONArrayBusquedaLibros(const FlagSearch: Integer;
  const session, Jstr: string; var StatusCode: Integer): string;

//Devuelve el Base64String del libro seleccionado por el Cliente (ANDROID).
function ObetenerLibroPorID(const session, ID: string; var StatusCode: Integer): string;


implementation
uses
  UMain, Generales, EUsuario, ECategoria, ELibro, DBActions_WS;

// 0 faltan datos, 1 registro correcto 2 error interno 3 correo ya registrado
function RegistrarUsuario(const Jstr: string): Integer;
var
  JSONObj: TJSONObject;
  Nombre, ApellidoP, ApellidoM, Correo, Clave,
  Edad, Foto: string;
  Conexion: TFDCustomConnection;
begin
  if Jstr.Trim.IsEmpty then
    Exit(400);

  Conexion:= TDBActions_WS.LanbraryConnection;
  try
    try
      JSONObj:= TJSONObject.ParseJSONValue(Jstr) as TJSONObject;
      try
        Nombre:= JSONObj.Values['nombre'].Value;
        ApellidoP:= JSONObj.Values['apellido_paterno'].Value;
        ApellidoM:= JSONObj.Values['apellido_materno'].Value;
        Correo:= JSONObj.Values['correo'].Value;
        Clave:= JSONObj.Values['clave'].Value;
        Edad:= JSONObj.Values['edad'].Value;

        if Assigned(JSONObj.FindValue('foto')) then
          Foto:= JSONObj.Values['foto'].Value
        else
          Foto:= string.Empty;
      finally
        if JSONObj <> nil then
          FreeAndNil(JSONObj);
      end;

      Result:= TDBActions_WS.InsertarUsuarioWS(Conexion, Nombre, ApellidoP, ApellidoM, Correo, Clave,
      Edad, Foto);
    except on E: Exception do
      begin
        EscribirLog('UJSONTool.RegistrarUsuario: ' + E.Message);
        //Cuando faltan datos se da una excepción al intentar usar un campo inexistente
        Result:= 400;
      end;
    end;
  finally
    TDBActions_WS.ReleaseConnection(Conexion);
  end;
end;

function IniciarSesion(const Jstr: string): TJSONObject;
var
  Usuario: rUsuario;
  Correo, Clave: string;
  JSONObj: TJSONObject;
  Conexion: TFDCustomConnection;
begin
  Result:= TJSONObject.Create;
  JSONObj:= TJSONObject.ParseJSONValue(Jstr) as TJSONObject;
  try
    try
      if Assigned(JSONObj.FindValue('correo')) and
      Assigned(JSONObj.FindValue('clave')) then
      begin
        Correo:= JSONObj.Values['correo'].Value;
        Clave:= JSONObj.Values['clave'].Value;
      end else
      begin
        Result.AddPair('error', TJSONNumber.Create(400)); //Faltan datos (JSON incompleto)
        Exit;
      end;
    except
      Result.AddPair('error', TJSONNumber.Create(400)); //Faltan datos (JSON incompleto)
      Exit;
    end;
  finally
    if JSONObj <> nil then
      FreeAndNil(JSONObj);
  end;

  Conexion:= TDBActions_WS.LanbraryConnection;
  try
    Usuario:= TDBActions_WS.ObtenerUsuarioWS(Conexion, Correo, Clave);
    case Usuario.Respuesta of
      200:
      begin
        Result.AddPair('id', Usuario.id);
        Result.AddPair('nombre', Usuario.Nombre);
        Result.AddPair('apellido_paterno', Usuario.Apellido_P);
        Result.AddPair('apellido_materno', Usuario.Apellido_M);
        Result.AddPair('correo', Usuario.Correo);
        Result.AddPair('edad', Usuario.Edad);
        Result.AddPair('estatus', TJSONNumber.Create(Usuario.Estatus));
        Result.AddPair('foto', Usuario.Foto);
      end;
      else
        Result.AddPair('error', TJSONNumber.Create(Usuario.Respuesta));
    end;

  finally
    TDBActions_WS.ReleaseConnection(Conexion);
  end;
end;

function GenerarJSONArrayCategorias(const Session: string; var StatusCode: Integer): string;
var 
  Categorias: TArray<rCategoria>;
  i: Integer;
  JArrayCategorias: TJSONArray;
  JSONObj, JSCategoria: TJSONObject;
  Conexion: TFDCustomConnection;
  Usr_Bloqueado: Boolean;
begin
  Result:= string.Empty;
  Conexion:= TDBActions_WS.LanbraryConnection;
  try
    if TDBActions_WS.ValidarSesionWS(Conexion, session, Usr_Bloqueado) then
    begin
      (*
        DRH 28/10/2025
        -Usuario bloqueado.
      *)
      if Usr_Bloqueado = True then
      begin
        StatusCode:= 423;
        Exit(string.Empty);
      end;

      Categorias:= TDBActions_WS.ObtenerCategoriasWS(Conexion);
      if Length(Categorias) > 0 then
      begin
        JSONObj:= TJSONObject.Create;
        JArrayCategorias:= TJSONArray.Create;
        try
          for i:= 0 to Length(Categorias) - 1 do
          begin
            JSCategoria:= TJSONObject.Create;
            JSCategoria.AddPair('id', Categorias[i].Id);
            JSCategoria.AddPair('descripcion', Categorias[i].Descripcion);
            JArrayCategorias.AddElement(JSCategoria);
          end;

          JSONObj.AddPair('categorias', JArrayCategorias);
          Result:= JSONObj.ToString;
          StatusCode:= 200;
        finally
          FreeAndNil(JSONObj);
        end;
      end else StatusCode:= 204;
    end else StatusCode:= 403;
  finally
    TDBActions_WS.ReleaseConnection(Conexion);
  end;
end;

function GenerarJSONArrayLibros(const session: string; const id_categoria: Integer;
 const Filtro: Integer; var StatusCode: Integer; const Cantidad: Integer): string;
var
  Libros: TArray<rLibro>;
  JSONObj, JSONObjLibro: TJSONObject;
  Jarray: TJSONArray;
  i: Integer;
  Conexion: TFDCustomConnection;
  Usr_Bloqueado: Boolean;
begin
  Result:= string.Empty;
  Conexion:= TDBActions_WS.LanbraryConnection;
  try
    if TDBActions_WS.ValidarSesionWS(Conexion, session, Usr_Bloqueado) then
    begin
      (*
        DRH 28/10/2025
        -Usuario bloqueado.
      *)
      if Usr_Bloqueado = True then
      begin
        StatusCode:= 423;
        Exit(string.Empty);
      end;

      Libros:= TDBActions_WS.ObtenerLibrosWS(Conexion, id_categoria, Filtro, Cantidad);
      if Length(Libros) > 0 then
      begin
        JSONObj:= TJSONObject.Create;
        Jarray:= TJSONArray.Create;
        try
          try
            for i:= 0 to Length(Libros) - 1 do
            begin
              JSONObjLibro:= TJSONObject.Create;
              JSONObjLibro.AddPair('id', Libros[i].Id);
              JSONObjLibro.AddPair('nombre', Libros[i].Nombre);
              JSONObjLibro.AddPair('descripcion', Libros[i].Descripcion);
              JSONObjLibro.AddPair('autor', Libros[i].Autor);
              JSONObjLibro.AddPair('fechahora', Libros[i].Fechahora);
              JSONObjLibro.AddPair('estatus', TJSONNumber.Create(Libros[i].Estatus));
              JSONObjLibro.AddPair('portada', Libros[i].Portada);
              JSONObjLibro.AddPair('archivo', Libros[i].Archivo);
              JSONObjLibro.AddPair('usuario', Libros[i].Usuario);
              JSONObjLibro.AddPair('id_categoria', TJSONNumber.Create(Libros[i].Id_Categoria));
              Jarray.AddElement(JSONObjLibro);
            end;

            JSONObj.AddPair('libros', Jarray);
            Result:= JSONObj.ToString;
            StatusCode:= 200;
          except on E: exception do
            begin
              EscribirLog('uJSONTool.GenerarJSONArrayLibros: ' + E.Message);
              Result:= string.Empty;
              StatusCode:= 503;
            end;
          end;
        finally
          if JSONObj <> nil then
            FreeAndNil(JSONObj);
        end;
      end else
      begin
        Result:= string.Empty;
        StatusCode:= 204;
      end;
    end else StatusCode:= 403;
  finally
    TDBActions_WS.ReleaseConnection(Conexion);
  end;
end;

function GenerarJSONArrayLibros(const session, Jstr: string; var StatusCode: Integer): string;
var
  JArray: TJSONArray;
  JSONObj, JSONObjLibro, JSONObjParams: TJSONObject;
  Conexion: TFDCustomConnection;
  Libros: TArray<rLibro>;
  i: Integer;

  Filtro: Integer;
  Ult_id_cat: Integer;
  Ult_fechahora: string;
  Ult_id: string;
  cantidad: Integer;
  Usr_Bloqueado: Boolean;
begin
  Result:= string.Empty;
  Conexion:= TDBActions_WS.LanbraryConnection;
  try
    if TDBActions_WS.ValidarSesionWS(Conexion, session, Usr_Bloqueado) then
    begin
      (*
        DRH 28/10/2025
        -Usuario bloqueado.
      *)
      if Usr_Bloqueado = True then
      begin
        StatusCode:= 423;
        Exit(string.Empty);
      end;

      JSONObjParams:= TJSONObject.ParseJSONValue(Jstr) as TJSONObject;
      try
        try
          Filtro:= JSONObjParams.Values['filtro'].Value.ToInteger;
          Ult_id_cat:= JSONObjParams.Values['ult_id_cat'].Value.ToInteger;
          Ult_fechahora:= JSONObjParams.Values['ult_fechahora'].Value;
          Ult_id:= JSONObjParams.Values['ult_id'].Value;
          cantidad:= JSONObjParams.Values['cantidad'].Value.ToInteger;
        except
          begin
            Result:= string.Empty;
            StatusCode:= 503;
            Exit;
          end;
        end;
      finally
        if Assigned(JSONObjParams) then
          FreeAndNil(JSONObjParams);
      end;

      Libros:= TDBActions_WS.ObtenerLibrosWS(Conexion, Filtro, Ult_id_cat, Ult_fechahora,
      Ult_id, cantidad);

      if Length(Libros) > 0 then
      begin
        JSONObj:= TJSONObject.Create;
        Jarray:= TJSONArray.Create;
        try
          try
            for i:= 0 to Length(Libros) - 1 do
            begin
              JSONObjLibro:= TJSONObject.Create;
              JSONObjLibro.AddPair('id', Libros[i].Id);
              JSONObjLibro.AddPair('nombre', Libros[i].Nombre);
              JSONObjLibro.AddPair('descripcion', Libros[i].Descripcion);
              JSONObjLibro.AddPair('autor', Libros[i].Autor);
              JSONObjLibro.AddPair('fechahora', Libros[i].Fechahora);
              JSONObjLibro.AddPair('estatus', TJSONNumber.Create(Libros[i].Estatus));
              JSONObjLibro.AddPair('portada', Libros[i].Portada);
              JSONObjLibro.AddPair('archivo', Libros[i].Archivo);
              JSONObjLibro.AddPair('usuario', Libros[i].Usuario);
              JSONObjLibro.AddPair('id_categoria', TJSONNumber.Create(Libros[i].Id_Categoria));
              Jarray.AddElement(JSONObjLibro);
            end;

            JSONObj.AddPair('libros', Jarray);
            Result:= JSONObj.ToString;
            StatusCode:= 200;
          except on E: exception do
            begin
              EscribirLog('uJSONTool.GenerarJSONArrayLibros: ' + E.Message);
              Result:= string.Empty;
              StatusCode:= 503;
            end;
          end;
        finally
          if JSONObj <> nil then
            FreeAndNil(JSONObj);
        end;
      end else
      begin
        Result:= string.Empty;
        StatusCode:= 204;
      end;
    end else StatusCode:= 403;
  finally
    TDBActions_WS.ReleaseConnection(Conexion);
  end;
end;

function GenerarJSONArrayBusquedaLibros(const FlagSearch: Integer;
  const session, Jstr: string; var StatusCode: Integer): string;
var
  JArray: TJSONArray;
  JSONObj, JSONObjLibro, JSONObjParams: TJSONObject;
  Conexion: TFDCustomConnection;
  Libros: TArray<rLibro>;
  i: Integer;

  Id_Categoria: Integer;
  Filtro: Integer;
  Ult_id_cat: Integer;
  Ult_fechahora: string;
  Ult_id: string;
  cantidad: Integer;
  KeyWord: string;
  Usr_Bloqueado: Boolean;
begin
  Result:= string.Empty;
  Conexion:= TDBActions_WS.LanbraryConnection;
  try
    if TDBActions_WS.ValidarSesionWS(Conexion, session, Usr_Bloqueado) then
    begin
      (*
        DRH 28/10/2025
        -Usuario bloqueado.
      *)
      if Usr_Bloqueado = True then
      begin
        StatusCode:= 423;
        Exit(string.Empty);
      end;

      JSONObjParams:= TJSONObject.ParseJSONValue(Jstr) as TJSONObject;
      try
        try
          //FlagSearch: 1= Busqueda Normal 2=Busqueda con paginación
          case FlagSearch of
            1:
            begin
              Id_Categoria:= JSONObjParams.Values['id_categoria'].Value.ToInteger;
              Filtro:= JSONObjParams.Values['filtro'].Value.ToInteger;
              cantidad:= JSONObjParams.Values['cantidad'].Value.ToInteger;
              KeyWord:= JSONObjParams.Values['keyword'].Value;

              Libros:= TDBActions_WS.BuscarLibros(Conexion, KeyWord,
              Id_Categoria, Filtro, cantidad);
            end;

            2:
            begin
              Filtro:= JSONObjParams.Values['filtro'].Value.ToInteger;
              Ult_id_cat:= JSONObjParams.Values['ult_id_cat'].Value.ToInteger;
              Ult_fechahora:= JSONObjParams.Values['ult_fechahora'].Value;
              Ult_id:= JSONObjParams.Values['ult_id'].Value;
              cantidad:= JSONObjParams.Values['cantidad'].Value.ToInteger;
              KeyWord:= JSONObjParams.Values['keyword'].Value;

              Libros:= TDBActions_WS.BuscarLibros(Conexion, KeyWord, Filtro,
              Ult_id_cat, Ult_fechahora, Ult_id, cantidad);
            end;
          end;
        except
          begin
            Result:= string.Empty;
            StatusCode:= 503;
            Exit;
          end;
        end;
      finally
        if Assigned(JSONObjParams) then
          FreeAndNil(JSONObjParams);
      end;

      if Length(Libros) > 0 then
      begin
        JSONObj:= TJSONObject.Create;
        Jarray:= TJSONArray.Create;
        try
          try
            for i:= 0 to Length(Libros) - 1 do
            begin
              JSONObjLibro:= TJSONObject.Create;
              JSONObjLibro.AddPair('id', Libros[i].Id);
              JSONObjLibro.AddPair('nombre', Libros[i].Nombre);
              JSONObjLibro.AddPair('descripcion', Libros[i].Descripcion);
              JSONObjLibro.AddPair('autor', Libros[i].Autor);
              JSONObjLibro.AddPair('fechahora', Libros[i].Fechahora);
              JSONObjLibro.AddPair('estatus', TJSONNumber.Create(Libros[i].Estatus));
              JSONObjLibro.AddPair('portada', Libros[i].Portada);
              JSONObjLibro.AddPair('archivo', Libros[i].Archivo);
              JSONObjLibro.AddPair('usuario', Libros[i].Usuario);
              JSONObjLibro.AddPair('id_categoria', TJSONNumber.Create(Libros[i].Id_Categoria));
              Jarray.AddElement(JSONObjLibro);
            end;

            JSONObj.AddPair('libros', Jarray);
            Result:= JSONObj.ToString;
            StatusCode:= 200;
          except on E: exception do
            begin
              EscribirLog('uJSONTool.GenerarJSONArrayLibros: ' + E.Message);
              Result:= string.Empty;
              StatusCode:= 503;
            end;
          end;
        finally
          if JSONObj <> nil then
            FreeAndNil(JSONObj);
        end;
      end else
      begin
        Result:= string.Empty;
        StatusCode:= 204;
      end;
    end else StatusCode:= 403;
  finally
    TDBActions_WS.ReleaseConnection(Conexion);
  end;
end;

function CambiarClave(const session, Jstr: string; var Mensaje: string): Integer;
var
  Conexion: TFDCustomConnection;
  JSONObj: TJSONObject;
  Correo, Clave, ClaveNueva: string;
  Usr_Bloqueado: Boolean;
begin
  Mensaje:= string.Empty;
  Conexion:= TDBActions_WS.LanbraryConnection;
  try
    if TDBActions_WS.ValidarSesionWS(Conexion, session, Usr_Bloqueado) then
    begin
      (*
        DRH 28/10/2025
        -Usuario bloqueado.
      *)
      if Usr_Bloqueado = True then
        Exit(423);

      JSONObj:= TJSONObject.ParseJSONValue(Jstr) as TJSONObject;

      if JSONObj = nil then
        Exit(401);

      if JSONObj.IsEmpty then
      begin
        FreeAndNil(JSONObj);
        Exit(401);
      end;

      try
        try
          Correo:= JSONObj.Values['correo'].Value;
          Clave:= JSONObj.Values['clave'].Value;
          ClaveNueva:= JSONObj.Values['clave_n'].Value;
        except on E: Exception do
          begin
            EscribirLog('uJSONTool.CambiarClave: ' + E.Message, 2);
            Exit(503);
          end;
        end;
      finally
        FreeAndNil(JSONObj);
      end;

      Result:= TDBActions_WS.CambiarClave(Conexion, Correo, Clave, ClaveNueva);
    end
    else
      Result:= 403;
  finally
    TDBActions_WS.ReleaseConnection(Conexion);
  end;

  case Result of
    200: Mensaje:= 'El usuario ' + Correo + ' realizó un cambio de contraseña.';

    204: Mensaje:= 'El usuario ' + Correo + ' intentó cambiar su contraseña ' +
    'pero la contraseña ingresada es incorrecta.';

    401: Mensaje:= 'El usuario ' + Correo + ' intentó cambiar su contraseña ' +
    'pero los datos enviados están vacíos o son incorrectos.';

    503: Mensaje:= 'El usuario ' + Correo + ' intentó cambiar su contraseña ' +
    'pero ocurrió un error interno durante la petición.';
  end;
end;

function CambiarFotoPerfil(const session, Jstr: string; var Mensaje: string): Integer;
var
  Conexion: TFDCustomConnection;
  JSONObj: TJSONObject;
  Correo, Foto: string;
  Usr_Bloqueado: Boolean;
begin
  Mensaje:= string.Empty;
  Conexion:= TDBActions_WS.LanbraryConnection;
  try
    if TDBActions_WS.ValidarSesionWS(Conexion, session, Usr_Bloqueado) then
    begin
      (*
        DRH 28/10/2025
        -Usuario bloqueado.
      *)
      if Usr_Bloqueado = True then
        Exit(423);

      JSONObj:= TJSONObject.ParseJSONValue(Jstr) as TJSONObject;

      if JSONObj = nil then
        Exit(401);

      if JSONObj.IsEmpty then
      begin
        FreeAndNil(JSONObj);
        Exit(401);
      end;

      try
        try
          Correo:= JSONObj.Values['correo'].Value;
          Foto:= JSONObj.Values['foto'].Value;
        except on E: Exception do
          begin
            EscribirLog('uJSONTool.CambiarFotoPerfil: ' + E.Message, 2);
            Exit(503);
          end;
        end;
      finally
        FreeAndNil(JSONObj);
      end;

      Result:= TDBActions_WS.CambiarFotoPerfil(Conexion, session, Correo, Foto);
    end
    else
      Result:= 403;
  finally
    TDBActions_WS.ReleaseConnection(Conexion);
  end;

  case Result of
    200: Mensaje:= 'El usuario ' + Correo + ' realizó un cambio de foto de perfil.';

    401: Mensaje:= 'El usuario ' + Correo + ' intentó cambiar su foto de perfil ' +
    'pero los datos enviados están vacíos o son incorrectos.';

    503: Mensaje:= 'El usuario ' + Correo + ' intentó cambiar su foto de perfil ' +
    'pero ocurrió un error interno durante la petición.';
  end;
end;

function ObetenerLibroPorID(const session, ID: string; var StatusCode: Integer): string;
var
  Conexion: TFDCustomConnection;
  Usr_Bloqueado: Boolean;
begin
  Result:= string.Empty;
  Conexion:= TDBActions_WS.LanbraryConnection;
  try
    if TDBActions_WS.ValidarSesionWS(Conexion, session, Usr_Bloqueado) then
    begin
      (*
        DRH 28/10/2025
        -Usuario bloqueado.
      *)
      if Usr_Bloqueado = True then
      begin
        StatusCode:= 423;
        Exit(string.Empty);
      end;

      Result:= TDBActions_WS.ObtenerLibroPorIdWS(Conexion, ID);

      if not  Result.IsEmpty then
        StatusCode:= 200
      else
        StatusCode:= 204;
    end
    else
    begin
      Result:= string.Empty;
      StatusCode:= 403;
    end;
  finally
    TDBActions_WS.ReleaseConnection(Conexion);
  end;
end;

end.

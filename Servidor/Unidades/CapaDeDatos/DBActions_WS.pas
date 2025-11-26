unit DBActions_WS;

interface
uses
  EUsuario, ECategoria, ELibro, System.IniFiles, FMX.DialogService, FMX.Dialogs,
  System.Classes, System.Types, System.SysConst, System.SysUtils, FMX.Forms,
  System.Generics.Collections, System.DateUtils, System.StrUtils, System.UITypes,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.MySQL, FireDAC.Phys.MySQLDef, FireDAC.FMXUI.Wait,
  FireDAC.Stan.Param, FireDAC.DApt,
  Data.DB, FireDAC.Comp.Client;

//Para uso exclusivo del WebService

type TDBActions_WS = class
  private
    class function GenerarID_Usuario: string;
  public
    class function LanbraryConnection: TFDCustomConnection;
    class procedure ReleaseConnection(var Conexion: TFDCustomConnection);

    //Categorias
    class function ObtenerCategoriasWS(const Conexion: TFDCustomConnection): TArray<rCategoria>;

    //Usuarios
    class function InsertarUsuarioWS(const Conexion: TFDCustomConnection;
    const Nombre, Apellido_P, Apellido_M, Correo, Clave, Edad,
    Foto: string): Integer;

    class function UsuarioYaExisteWS(const Conexion: TFDCustomConnection;
    const Correo: string): Boolean;

    class function ObtenerUsuarioWS(const Conexion: TFDCustomConnection;
    const Correo, Clave: string): rUsuario;

    class function ValidarSesionWS(const Conexion: TFDCustomConnection;
    const ID: string; var Bloqueado: Boolean): Boolean;

    class function CambiarClave(const Conexion: TFDCustomConnection;
    const Correo, Clave, ClaveNueva: string): Integer;

    class function CambiarFotoPerfil(const Conexion: TFDCustomConnection;
    const session, Correo, Foto: string): Integer;

    //Libros
    class function ObtenerLibrosWS(const Conexion: TFDCustomConnection;
    const id_categoria: Integer; const Filtro: Integer;
    const Cantidad: Integer): TArray<rLibro>; overload;

    class function ObtenerLibrosWS(const Conexion: TFDCustomConnection;
    const Filtro: Integer; const Ult_id_cat: Integer;
    const Ult_fechahora: string; const Ult_id: string;
    const Cantidad: Integer): TArray<rLibro> overload;

    class function BuscarLibros(const Conexion: TFDCustomConnection;
    const AKeyWord: string; const id_categoria: Integer; const Filtro: Integer;
    const Cantidad: Integer): TArray<rLibro>; overload;

    class function BuscarLibros(const Conexion: TFDCustomConnection;
    const AKeyWord: string; const Filtro: Integer; const Ult_id_cat: Integer;
    const Ult_fechahora: string; const Ult_id: string;
    const Cantidad: Integer): TArray<rLibro> overload;

    class function ObtenerLibroPorIdWS(const Conexion: TFDCustomConnection; const
    ID: string): string;
end;

implementation
uses
  Generales, PasswordHashing;

{ TDBActns_WS }

class function TDBActions_WS.BuscarLibros(const Conexion: TFDCustomConnection;
  const AKeyWord: string; const id_categoria, Filtro,
  Cantidad: Integer): TArray<rLibro>;
var
  Qry: TFDQuery;
  SQL: string;
  Portada: TStream;
begin
  //NOTA, IMPLEMENTAR UN STORED PROCEDURE QUE OBTENGA EL ID_USUARIO COMO
  //EL NOMBRE COMPLETO CUANDO EL ID_USUARIO SEA DIFERENTE DE "admin"
  SetLength(Result, 0);
  Qry:= TFDQuery.Create(nil);
  Qry.Connection:= Conexion;
  try
    try
      Conexion.Connected:= True;
      case id_categoria of
        0:
        begin
          SQL:= 'SELECT id, nombre, descripcion, autor, fechahora, estatus, ' +
          'portada, usuario, id_categoria FROM libros ' +
          'WHERE (INSTR(nombre, :nombre) > 0 ' +
          'OR INSTR(descripcion, :descripcion) > 0 ' +
          'OR INSTR(autor, :autor) > 0) ';

          //0 = Desde el más reciente 1= Desde el más antiguo
          case Filtro of
            0:  SQL:= SQL + ' ORDER BY fechahora DESC, id DESC';

            1:  SQL:= SQL + ' ORDER BY fechahora ASC, id ASC';
          end;

          SQL:= SQL + ' LIMIT :count';
          Qry.SQL.Text:= SQL;

          Qry.ParamByName('nombre').AsString:= AKeyWord;
          Qry.ParamByName('descripcion').AsString:= AKeyWord;
          Qry.ParamByName('autor').AsString:= AKeyWord;
          Qry.ParamByName('count').AsInteger:= Cantidad;
        end;

        else
        begin
          SQL:= 'SELECT id, nombre, descripcion, autor, fechahora, estatus, ' +
          'usuario, portada, id_categoria FROM libros ' +
          'WHERE (INSTR(nombre, :nombre) > 0 ' +
          'OR INSTR(descripcion, :descripcion) > 0 ' +
          'OR INSTR(autor, :autor) > 0) AND id_categoria = :id_categoria';

          //0 = Desde el más reciente 1= Desde el más antiguo
          case Filtro of
            0:  SQL:= SQL + ' ORDER BY fechahora DESC, id DESC';

            1:  SQL:= SQL + ' ORDER BY fechahora ASC, id ASC';
          end;

          SQL:= SQL + ' LIMIT :count';
          Qry.SQL.Text:= SQL;

          Qry.ParamByName('nombre').AsString:= AKeyWord;
          Qry.ParamByName('descripcion').AsString:= AKeyWord;
          Qry.ParamByName('autor').AsString:= AKeyWord;
          Qry.ParamByName('id_categoria').AsInteger:= id_categoria;
          Qry.ParamByName('count').AsInteger:= Cantidad;
        end;
      end;
      Qry.Open;

      if Qry.RecordCount > 0 then
      begin
        Qry.First;
        while not Qry.Eof do
        begin
          SetLength(Result, Length(Result) + 1);
          Result[High(Result)].Id:= Qry.FieldByName('id').AsString;
          Result[High(Result)].Nombre:= Qry.FieldByName('nombre').AsString;
          Result[High(Result)].Descripcion:= Qry.FieldByName('descripcion').AsString;
          Result[High(Result)].Autor:= Qry.FieldByName('autor').AsString;
          Result[High(Result)].Fechahora:= Qry.FieldByName('fechahora').AsString;
          Result[High(Result)].Estatus:= Qry.FieldByName('estatus').AsInteger;

          Portada:= Qry.CreateBlobStream(Qry.FieldByName('portada'), bmRead);
          try
            Result[High(Result)].Portada:= StreamToBase64String(Portada);
          finally
            if Assigned(Portada) then
              FreeAndNil(Portada);
          end;

          Result[High(Result)].Archivo:= string.Empty;
          Result[High(Result)].Usuario:= Qry.FieldByName('usuario').AsString;
          Result[High(Result)].Id_Categoria:= Qry.FieldByName('id_categoria').AsInteger;
          Qry.Next;
        end;
      end else SetLength(Result, 0);
    except on E: Exception do
      begin
        EscribirLog('TDBActions_WS.BuscarLibros: ' + E.Message, 2);
        SetLength(Result, 0);
      end;
    end;
  finally
    Qry.Close;
    FreeAndNil(Qry);
  end;
end;

class function TDBActions_WS.BuscarLibros(const Conexion: TFDCustomConnection;
  const AKeyWord: string; const Filtro, Ult_id_cat: Integer;
  const Ult_fechahora, Ult_id: string; const Cantidad: Integer): TArray<rLibro>;
var
  Qry: TFDQuery;
  SQL: string;
  Portada: TStream;
begin
  SetLength(Result, 0);
  Qry:= TFDQuery.Create(nil);
  Qry.Connection:= Conexion;
  SQL:= 'SELECT id, nombre, descripcion, autor, fechahora, estatus, ' +
  'portada, usuario, id_categoria FROM libros';
  try
    try
      Conexion.Connected:= True;
      case Ult_id_cat of
        0:
        begin
          case Filtro of
            0: SQL:= SQL + ' WHERE ' +
            '(INSTR(nombre, :nombre) > 0 OR ' +
            'INSTR(descripcion, :descripcion) > 0 OR ' +
            'INSTR(autor, :autor) > 0) ' +
            'AND (fechahora < :fechahora OR ' +
            '(fechahora = :fechahora AND id < :id)) ' +
            'ORDER BY fechahora DESC, id DESC LIMIT :cantidad';

            1: SQL:= SQL + ' WHERE ' +
            '(INSTR(nombre, :nombre) > 0 OR ' +
            'INSTR(descripcion, :descripcion) > 0 OR ' +
            'INSTR(autor, :autor) > 0) ' +
            'AND (fechahora > :fechahora OR ' +
            '(fechahora = :fechahora AND id > :id)) ' +
            'ORDER BY fechahora ASC, id ASC LIMIT :cantidad';
          end;

          Qry.SQL.Text:= SQL;
          Qry.ParamByName('nombre').AsString:= AKeyWord;
          Qry.ParamByName('descripcion').AsString:= AKeyWord;
          Qry.ParamByName('autor').AsString:= AKeyWord;
          Qry.ParamByName('fechahora').AsDateTime:= StrToDateTime(Ult_fechahora);
          Qry.ParamByName('id').AsString:= Ult_id;
          Qry.ParamByName('cantidad').AsInteger:= cantidad;
        end;

        else
        begin
          case Filtro of
            0: SQL:= SQL + ' WHERE ' +
            '(INSTR(nombre, :nombre) > 0 OR ' +
            'INSTR(descripcion, :descripcion) > 0 OR ' +
            'INSTR(autor, :autor) > 0) ' +
            'AND (fechahora < :fechahora OR ' +
            '(fechahora = :fechahora AND id < :id)) ' +
            'AND id_categoria = :id_categoria ' +
            'ORDER BY fechahora DESC, id DESC LIMIT :cantidad';

            1: SQL:= SQL + ' WHERE ' +
            '(INSTR(nombre, :nombre) > 0 OR ' +
            'INSTR(descripcion, :descripcion) > 0 OR ' +
            'INSTR(autor, :autor) > 0) ' +
            'AND (fechahora > :fechahora OR ' +
            '(fechahora = :fechahora AND id > :id)) ' +
            'AND id_categoria = :id_categoria ' +
            'ORDER BY fechahora ASC, id ASC LIMIT :cantidad'
          end;

          Qry.SQL.Text:= SQL;
          Qry.ParamByName('nombre').AsString:= AKeyWord;
          Qry.ParamByName('descripcion').AsString:= AKeyWord;
          Qry.ParamByName('autor').AsString:= AKeyWord;
          Qry.ParamByName('fechahora').AsDateTime:= StrToDateTime(Ult_fechahora);
          Qry.ParamByName('id').AsString:= Ult_id;
          Qry.ParamByName('id_categoria').AsInteger:= Ult_id_cat;
          Qry.ParamByName('cantidad').AsInteger:= cantidad;
        end;
      end;

      Qry.Open;
      if Qry.RecordCount > 0 then
      begin
        Qry.First;
        while not Qry.Eof do
        begin
          SetLength(Result, Length(Result) + 1);
          Result[High(Result)].Id:= Qry.FieldByName('id').AsString;
          Result[High(Result)].Nombre:= Qry.FieldByName('nombre').AsString;
          Result[High(Result)].Descripcion:= Qry.FieldByName('descripcion').AsString;
          Result[High(Result)].Autor:= Qry.FieldByName('autor').AsString;
          Result[High(Result)].Fechahora:= Qry.FieldByName('fechahora').AsString;
          Result[High(Result)].Estatus:= Qry.FieldByName('estatus').AsInteger;

          Portada:= Qry.CreateBlobStream(Qry.FieldByName('portada'), bmRead);
          try
            Result[High(Result)].Portada:= StreamToBase64String(Portada);
          finally
            if Assigned(Portada) then
              FreeAndNil(Portada);
          end;

          Result[High(Result)].Archivo:= string.Empty;
          Result[High(Result)].Usuario:= Qry.FieldByName('usuario').AsString;
          Result[High(Result)].Id_Categoria:= Qry.FieldByName('id_categoria').AsInteger;
          Qry.Next;
        end;
      end else SetLength(Result, 0);
    except on E: Exception do
      begin
        EscribirLog('TDBActions_WS.BuscarLibros: ' + E.Message, 2);
        SetLength(Result, 0);
      end;
    end;
  finally
    Qry.Close;
    FreeAndNil(Qry);
    SQL:= string.Empty;
  end;
end;

class function TDBActions_WS.CambiarClave(const Conexion: TFDCustomConnection;
const Correo, Clave, ClaveNueva: string): Integer;
var
  Qry: TFDQuery;
  StoredHash: string;
begin
  Qry:= TFDQuery.Create(nil);
  Qry.Connection:= Conexion;
  try
    try
      Conexion.Connected:= True;
      Qry.SQL.Text:= 'SELECT correo, clave FROM usuarios WHERE ' +
      'correo = :correo';
      Qry.ParamByName('correo').AsString:= Correo;
      Qry.Open;

      if Qry.RecordCount > 0 then
      begin
        Qry.First;
        StoredHash:= Qry.FieldByName('clave').AsString;

        if TPasswordHasherPBKDF2.VerifyPassword(Clave, StoredHash) then
        begin
          Qry.SQL.Clear;
          Qry.SQL.Text:= 'UPDATE usuarios SET clave = :newclave WHERE ' +
          'correo = :correo';
          Qry.ParamByName('newclave').AsString:= TPasswordHasherPBKDF2.HashPassword(ClaveNueva);
          Qry.ParamByName('correo').AsString:= Correo;
          Qry.ExecSQL;
          Result:= 200; //OK
        end
        else
          Result:= 204; //Contraseña incorrecta
      end
      else
        Result:= 204;
    except on E: Exception do
      begin
        EscribirLog('DBActions_WS.CambiarClave: ' + E.Message, 2);
        Result:= 503; //Error interno del servidor
      end;
    end;
  finally
    Qry.Close;
    FreeAndNil(Qry);
  end;
end;

class function TDBActions_WS.CambiarFotoPerfil(
  const Conexion: TFDCustomConnection; const session, Correo, Foto: string): Integer;
var
  Qry: TFDQuery;
  MS: TMemoryStream;
begin
  Qry:= TFDQuery.Create(nil);
  Qry.Connection:= Conexion;
  try
    try
      Conexion.Connected:= True;
      Qry.SQL.Text:= 'UPDATE usuarios SET foto = :foto WHERE id = :id ' +
      'AND correo = :correo';

      if not Foto.Trim.IsEmpty then
      begin
        MS:= Base64StringToMemoryStream(Foto);
        try
          Qry.ParamByName('foto').LoadFromStream(MS, ftBlob);
        finally
          FreeAndNil(MS);
        end;
      end
      else
      begin
        Qry.ParamByName('foto').DataType:= ftBlob;
        Qry.ParamByName('foto').Clear;
      end;

      Qry.ParamByName('id').AsString:= session;
      Qry.ParamByName('correo').AsString:= Correo;
      Qry.ExecSQL;
      Result:= 200; //OK
    except on E: Exception do
      begin
        EscribirLog('DBActions_WS.CambiarFotoPerfil: ' + E.Message, 2);
        Result:= 503;
      end;
    end;
  finally
    Qry.Close;
    FreeAndNil(Qry);
  end;
end;

class function TDBActions_WS.GenerarID_Usuario: string;
var
  idUsuario: TGUID;
begin
  try
    if CreateGUID(idUsuario) = 0 then
      Result:= GUIDToString(idUsuario)
    else
      Result:= string.Empty;
  except on E: Exception do
    begin
      EscribirLog('DBActions_WS.GenerarID_Usuario: No fue posible generar ID: ' +
      E.Message, 2);
      Result:= string.Empty;
    end;
  end;
end;

class function TDBActions_WS.InsertarUsuarioWS(
  const Conexion: TFDCustomConnection; const Nombre, Apellido_P, Apellido_M,
  Correo, Clave, Edad, Foto: string): Integer;
var
  idUsuario: string;
  Qry: TFDQuery;
  MSFoto: TMemoryStream;
begin
  idUsuario:= GenerarID_Usuario;
  if idUsuario.IsEmpty then
    Exit(503);

  if UsuarioYaExisteWS(Conexion, Correo) then
    Exit(409);

  Qry:= TFDQuery.Create(nil);
  Qry.Connection:= Conexion;
  MSFoto:= Base64StringToMemoryStream(Foto);
  try
    try
      Conexion.Connected:= True;
      if MSFoto <> nil then
      begin
        Qry.SQL.Text:= 'INSERT INTO usuarios (id, nombre, apellido_paterno, ' +
        'apellido_materno, correo, clave, edad, estatus, foto) VALUES ' +
        '(:id, :nombre, :apellido_paterno, :apellido_materno, :correo,' +
        ' :clave, :edad, :estatus, :foto)';
        Qry.ParamByName('foto').LoadFromStream(MSFoto, ftBlob);
      end else
      begin
        Qry.SQL.Text:= 'INSERT INTO usuarios (id, nombre, apellido_paterno, ' +
        'apellido_materno, correo, clave, edad, estatus) VALUES ' +
        '(:id, :nombre, :apellido_paterno, :apellido_materno, :correo,' +
        ' :clave, :edad, :estatus)';
      end;

      Qry.ParamByName('id').AsString:= idUsuario;
      Qry.ParamByName('nombre').AsString:= Nombre;
      Qry.ParamByName('apellido_paterno').AsString:= Apellido_P;
      Qry.ParamByName('apellido_materno').AsString:= Apellido_M;
      Qry.ParamByName('correo').AsString:= Correo;
      Qry.ParamByName('clave').AsString:= TPasswordHasherPBKDF2.HashPassword(
      Clave);
      Qry.ParamByName('edad').AsString:= Edad;
      Qry.ParamByName('estatus').AsInteger:= 1;
      Qry.ExecSQL;

      Result:= 200;
    except on E: Exception do
      begin
        EscribirLog('DBActions_WS.InsertarUsuario: ' + E.Message, 2);
        Result:= 503;
      end;
    end;
  finally
    Qry.Close;
    FreeAndNil(Qry);
    if Assigned(MSFoto) then
      FreeAndNil(MSFoto);
  end;
end;

class function TDBActions_WS.LanbraryConnection: TFDCustomConnection;
begin
  Result:= TFDCustomConnection.Create(nil);
  Result.ConnectionDefName:= 'LanBraryConnection';
end;

class function TDBActions_WS.ObtenerCategoriasWS(
  const Conexion: TFDCustomConnection): TArray<rCategoria>;
var
  Qry: TFDQuery;
begin
  SetLength(Result, 0);
  Qry:= TFDQuery.Create(nil);
  Qry.Connection:= Conexion;
  try
    try
      Conexion.Connected:= True;
      Qry.SQL.Text:= 'SELECT * FROM categorias';
      Qry.Open;

      if Qry.RecordCount > 0 then
      begin
        while not Qry.Eof do
        begin
          SetLength(Result, Length(Result) + 1);
          Result[High(Result)].Id:= Qry.FieldByName('id').AsString;
          Result[High(Result)].Descripcion:= Qry.FieldByName('descripcion').AsString;
          Qry.Next;
        end;
      end;
    except on E: Exception do
      begin
        EscribirLog('DBActions_WS.ObtenerCategorias: ' + E.Message, 2);
        SetLength(Result, 0);
      end;
    end;
  finally
    Qry.Close;
    FreeAndNil(Qry);
  end;
end;

class function TDBActions_WS.ObtenerLibroPorIdWS(const Conexion: TFDCustomConnection;
  const ID: string): string;
var
  Qry: TFDQuery;
  Strm: TStream;
begin
  Result:= string.Empty;
  Qry:= TFDQuery.Create(nil);
  Qry.Connection:= Conexion;
  try
    try
      Conexion.Connected:= True;
      Qry.SQL.Text:= 'SELECT archivo FROM libros WHERE ID = :ID';
      Qry.ParamByName('ID').AsString:= ID;
      Qry.Open;

      if Qry.RecordCount > 0 then
      begin
        Qry.Last;
        Strm:= Qry.CreateBlobStream(Qry.FieldByName('archivo'), bmRead);
        try
          Result:= StreamToBase64String(Strm);
        finally
          FreeAndNil(Strm);
        end;
      end;
    except on E: exception do
      EscribirLog('DBActions_WS.ObtenerLibroPorIdWS: ' + E.Message, 2);
    end;
  finally
    Qry.Close;
    FreeAndNil(Qry);
  end;
end;

class function TDBActions_WS.ObtenerLibrosWS(const Conexion: TFDCustomConnection;
  const Filtro, Ult_id_cat: Integer; const Ult_fechahora, Ult_id: string;
  const Cantidad: Integer): TArray<rLibro>;
var
  Qry: TFDQuery;
  SQL: string;
  Portada: TStream;
begin
  SetLength(Result, 0);
  Qry:= TFDQuery.Create(nil);
  Qry.Connection:= Conexion;
  SQL:= 'SELECT id, nombre, descripcion, autor, fechahora, estatus, ' +
  'portada, usuario, id_categoria FROM libros';
  try
    try
      Conexion.Connected:= True;
      case Ult_id_cat of
        0:
        begin
          case Filtro of
            0: SQL:= SQL + ' WHERE fechahora < :fechahora OR ' +
            '(fechahora = :fechahora AND id < :id) ' +
            'ORDER BY fechahora DESC, id DESC LIMIT :cantidad';

            1: SQL:= SQL + ' WHERE fechahora > :fechahora OR ' +
            '(fechahora = :fechahora AND id > :id) ' +
            'ORDER BY fechahora ASC, id ASC LIMIT :cantidad';
          end;

          Qry.SQL.Text:= SQL;
          Qry.ParamByName('fechahora').AsDateTime:= StrToDateTime(Ult_fechahora);
          Qry.ParamByName('id').AsString:= Ult_id;
          Qry.ParamByName('cantidad').AsInteger:= cantidad;
        end;

        else
        begin
          case Filtro of
            0: SQL:= SQL + ' WHERE id_categoria = :id_categoria ' +
            'AND (fechahora < :fechahora OR ' +
            '(fechahora = :fechahora AND id < :id)) ' +
            'ORDER BY fechahora DESC, id DESC LIMIT :cantidad';

            1: SQL:= SQL + ' WHERE id_categoria = :id_categoria ' +
            'AND (fechahora > :fechahora OR ' +
            '(fechahora = :fechahora AND id > :id)) ' +
            'ORDER BY fechahora ASC, id ASC LIMIT :cantidad'
          end;

          Qry.SQL.Text:= SQL;
          Qry.ParamByName('id_categoria').AsInteger:= Ult_id_cat;
          Qry.ParamByName('fechahora').AsDateTime:= StrToDateTime(Ult_fechahora);
          Qry.ParamByName('id').AsString:= Ult_id;
          Qry.ParamByName('cantidad').AsInteger:= cantidad;
        end;
      end;

      Qry.Open;
      if Qry.RecordCount > 0 then
      begin
        Qry.First;
        while not Qry.Eof do
        begin
          SetLength(Result, Length(Result) + 1);
          Result[High(Result)].Id:= Qry.FieldByName('id').AsString;
          Result[High(Result)].Nombre:= Qry.FieldByName('nombre').AsString;
          Result[High(Result)].Descripcion:= Qry.FieldByName('descripcion').AsString;
          Result[High(Result)].Autor:= Qry.FieldByName('autor').AsString;
          Result[High(Result)].Fechahora:= Qry.FieldByName('fechahora').AsString;
          Result[High(Result)].Estatus:= Qry.FieldByName('estatus').AsInteger;

          Portada:= Qry.CreateBlobStream(Qry.FieldByName('portada'), bmRead);
          try
            Result[High(Result)].Portada:= StreamToBase64String(Portada);
          finally
            if Assigned(Portada) then
              FreeAndNil(Portada);
          end;

          Result[High(Result)].Archivo:= string.Empty;
          Result[High(Result)].Usuario:= Qry.FieldByName('usuario').AsString;
          Result[High(Result)].Id_Categoria:= Qry.FieldByName('id_categoria').AsInteger;
          Qry.Next;
        end;
      end else SetLength(Result, 0);
    except on E: Exception do
      begin
        EscribirLog('DBActions_WS.ObtenerLibros2WS: ' + E.Message, 2);
        SetLength(Result, 0);
      end;
    end;
  finally
    Qry.Close;
    FreeAndNil(Qry);
    SQL:= string.Empty;
  end;
end;

class function TDBActions_WS.ObtenerLibrosWS(const Conexion: TFDCustomConnection;
  const id_categoria, Filtro, Cantidad: Integer): TArray<rLibro>;
var
  Qry: TFDQuery;
  SQL: string;
  Portada: TStream;
begin
  //NOTA, IMPLEMENTAR UN STORED PROCEDURE QUE OBTENGA EL ID_USUARIO COMO
  //EL NOMBRE COMPLETO CUANDO EL ID_USUARIO SEA DIFERENTE DE "admin"
  SetLength(Result, 0);
  Qry:= TFDQuery.Create(nil);
  Qry.Connection:= Conexion;
  try
    try
      Conexion.Connected:= True;
      case id_categoria of
        0:
        begin
          SQL:= 'SELECT id, nombre, descripcion, autor, fechahora, estatus, ' +
          'portada, usuario, id_categoria FROM libros';

          //0 = Desde el más reciente 1= Desde el más antiguo
          case Filtro of
            0:  SQL:= SQL + ' ORDER BY fechahora DESC, id DESC';

            1:  SQL:= SQL + ' ORDER BY fechahora ASC, id ASC';
          end;

          SQL:= SQL + ' LIMIT :count';
          Qry.SQL.Text:= SQL;
          Qry.ParamByName('count').AsInteger:= Cantidad;
        end;

        else
        begin
          SQL:= 'SELECT id, nombre, descripcion, autor, fechahora, estatus, ' +
          'usuario, portada, id_categoria FROM libros WHERE id_categoria = :id_categoria';

          //0 = Desde el más reciente 1= Desde el más antiguo
          case Filtro of
            0:  SQL:= SQL + ' ORDER BY fechahora DESC, id DESC';

            1:  SQL:= SQL + ' ORDER BY fechahora ASC, id ASC';
          end;

          SQL:= SQL + ' LIMIT :count';
          Qry.SQL.Text:= SQL;
          Qry.ParamByName('id_categoria').AsInteger:= id_categoria;
          Qry.ParamByName('count').AsInteger:= Cantidad;
        end;
      end;
      Qry.Open;

      if Qry.RecordCount > 0 then
      begin
        Qry.First;
        while not Qry.Eof do
        begin
          SetLength(Result, Length(Result) + 1);
          Result[High(Result)].Id:= Qry.FieldByName('id').AsString;
          Result[High(Result)].Nombre:= Qry.FieldByName('nombre').AsString;
          Result[High(Result)].Descripcion:= Qry.FieldByName('descripcion').AsString;
          Result[High(Result)].Autor:= Qry.FieldByName('autor').AsString;
          Result[High(Result)].Fechahora:= Qry.FieldByName('fechahora').AsString;
          Result[High(Result)].Estatus:= Qry.FieldByName('estatus').AsInteger;

          Portada:= Qry.CreateBlobStream(Qry.FieldByName('portada'), bmRead);
          try
            Result[High(Result)].Portada:= StreamToBase64String(Portada);
          finally
            if Assigned(Portada) then
              FreeAndNil(Portada);
          end;

          Result[High(Result)].Archivo:= string.Empty;
          Result[High(Result)].Usuario:= Qry.FieldByName('usuario').AsString;
          Result[High(Result)].Id_Categoria:= Qry.FieldByName('id_categoria').AsInteger;
          Qry.Next;
        end;
      end else SetLength(Result, 0);
    except on E: Exception do
      begin
        EscribirLog('DBActions_WS.ObtenerLibrosWS: ' + E.Message, 2);
        SetLength(Result, 0);
      end;
    end;
  finally
    Qry.Close;
    FreeAndNil(Qry);
  end;
end;

class function TDBActions_WS.ObtenerUsuarioWS(const Conexion: TFDCustomConnection;
  const Correo, Clave: string): rUsuario;
var
  Qry: TFDQuery;
  Foto: TStream;
  StoredHash: string;
begin
  Qry:= TFDQuery.Create(nil);
  Qry.Connection:= Conexion;
  try
    try
      Conexion.Connected:= True;

      Qry.SQL.Text:= 'SELECT id, nombre, clave, apellido_paterno, apellido_materno, ' +
      'correo, edad, estatus, foto FROM usuarios WHERE correo = :correo';
      Qry.ParamByName('correo').AsString:= Correo;
      Qry.Open;

      if Qry.RecordCount > 0 then
      begin
        Qry.Last;
        if Qry.FieldByName('estatus').AsInteger = 0 then
          Result.Respuesta:= 423
        else
        begin
          StoredHash:= Qry.FieldByName('clave').AsString;

          if TPasswordHasherPBKDF2.VerifyPassword(Clave, StoredHash) then
          begin
            Result.id:= Qry.FieldByName('id').AsString;
            Result.Nombre:= Qry.FieldByName('nombre').AsString;
            Result.Apellido_P:= Qry.FieldByName('apellido_paterno').AsString;
            Result.Apellido_M:= Qry.FieldByName('apellido_materno').AsString;
            Result.Correo:= Qry.FieldByName('correo').AsString;
            Result.Edad:= Qry.FieldByName('edad').AsString;
            Result.Estatus:= Qry.FieldByName('estatus').AsInteger;

            Foto:= Qry.CreateBlobStream(Qry.FieldByName('foto'), bmRead);
            try
              Result.Foto:= StreamToBase64String(Foto);
            finally
              if Assigned(Foto) then
                FreeAndNil(Foto);
            end;
            Result.Respuesta:= 200;
          end
          else
            Result.Respuesta:= 204;
        end;
      end
      else
        Result.Respuesta:= 204;
    except on E: Exception do
      begin
        EscribirLog('DBActions_WS.ObtenerUsuario: ' + E.Message, 2);
        Result.Respuesta:= 503;
      end;
    end;
  finally
    Qry.Close;
    FreeAndNil(Qry);
  end;
end;

class procedure TDBActions_WS.ReleaseConnection(
  var Conexion: TFDCustomConnection);
begin
  if Conexion <> nil then
  begin
    Conexion.Connected:= False;
    FreeAndNil(Conexion);
  end;
end;

class function TDBActions_WS.UsuarioYaExisteWS(
  const Conexion: TFDCustomConnection; const Correo: string): Boolean;
var
  Qry: TFDQuery;
begin
  Qry:= TFDQuery.Create(nil);
  Qry.Connection:= Conexion;
  try
    try
      Conexion.Connected:= True;

      Qry.SQL.Text:= 'SELECT id FROM usuarios WHERE correo = :correo';
      Qry.ParamByName('correo').AsString:= Correo;
      Qry.Open;
      Qry.Last;

      Result:= Qry.RecordCount > 0;
    except on E: Exception do
      begin
        EscribirLog('DBActions_WS.UsuarioYaExiste: ' + E.Message, 2);
        Result:= False;
      end;
    end;
  finally
    Qry.Close;
    FreeAndNil(Qry);
  end;
end;

class function TDBActions_WS.ValidarSesionWS(const Conexion: TFDCustomConnection;
  const ID: string; var Bloqueado: Boolean): Boolean;
var
  QryValidarSesion: TFDQuery;
  Estatus: Integer;
begin
  if ID.Trim.IsEmpty then
    Exit(False);

  Bloqueado:= False;
  Result:= False;
  QryValidarSesion:= TFDQuery.Create(nil);
  QryValidarSesion.Connection:= Conexion;
  try
    try
      Conexion.Connected:= True;

      QryValidarSesion.SQL.Text:= 'SELECT id, estatus FROM usuarios WHERE id = :id';
      QryValidarSesion.ParamByName('id').AsString:= ID;
      QryValidarSesion.Open;

      if QryValidarSesion.RecordCount > 0 then
      begin
        Result:= True;
        QryValidarSesion.First;
        Estatus:= QryValidarSesion.FieldByName('estatus').AsInteger;

        case Estatus of
          0: Bloqueado:= True;

          1: Bloqueado:= False;
        end;
      end
      else
        Result:= False;
    except on E: Exception do
      EscribirLog(E.ClassName + ': Error al validar sesión: ' + E.Message);
    end;
  finally
    QryValidarSesion.Close;
    FreeAndNil(QryValidarSesion);
  end;
end;

end.

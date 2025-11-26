unit DBActions;

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
(*
  NOTA IMPORTANTE:
  CUANDO SE CREE UNA INSTANCIA DE FDCONNECTION CON LA FUNCIÓN
  LANBRARYCONNECTION NO SE DESCONECTA NI SE LIBERA EN MEMORIA YA QUE FIREDAC SE ENCARGA DE TODO
  MEDIANTE EL USO DE CONEXIONES AGRUPADAS O "POOLING"
*)

//Para uso exclusivo del programa con interfaz gráfica
type TDBActions = class
  private
    (*
      Libros
    *)
    class function GenerarID_Libro: string;
  public  
    class function ConectarBD(const Conexion: TFDConnection): Boolean;
    class procedure CrearTablas(const Conexion: TFDConnection);
    class procedure ActualizarTablas(const Conexion: TFDConnection);
    class procedure CrearStoredProcedures(const Conexion: TFDConnection);
    class function ValidarConfiguraciones: boolean;

    (*
      Categorias
    *)
    class procedure InsertarCategorias(const Conexion: TFDConnection);
    class function ObtenerCategorias(const Conexion: TFDConnection): TArray<rCategoria>;

    (*
      Usuarios
    *)
    class function ObtenerUsuarios(const Conexion: TFDConnection;
    const Filtro: Integer): TArray<rUsuario>;
    class function ObtenerUsuarioPorID(const Conexion: TFDConnection;
    const ID: string; const Foto: Boolean): rUsuario;
    class function ObtenerFotoUsuarioPorID(const Conexion: TFDConnection;
    const ID: string): TMemoryStream;
    class function EliminarUsuario(const Conexion: TFDConnection;
    const ID: string): Boolean;
    class function CambiarEstatusUsuario(const Conexion: TFDConnection;
    const ID: string; const Estatus: Integer): Boolean;
    class function BuscarUsuarios(const Conexion: TFDConnection;
    const AKeyword: string): TArray<rUsuario>;

    (*
      Libros
    *)
    class function ObtenerLibros(const Conexion: TFDConnection; const id_categoria: Integer; getBLOBS: Boolean;
    const Filtro: Integer = 0): TArray<rLibro>;
    //0= Excepción 1= Correcto 2= Libro ya existe
    class function InsertarLibro(const Conexion: TFDConnection; const Nombre, Descripcion, Autor: string; const Fecha: TDateTime;
    const Estatus: Integer; const Portada, Archivo, Usuario: string; const ID_Categoria: Integer): Integer;
    class function ModificarLibro(const Conexion: TFDConnection; const Id, Nombre, Descripcion, Autor: string;
    const IdCategoria: Integer): Boolean;
    class function EliminarLibro(const Conexion: TFDConnection; const Id: string): Boolean;
    class function ObtenerCoincidenciasLibros(const Conexion: TFDConnection;
    const PalabraClave: string): TArray<rLibro>;
    class function ObtenerPortadaLibroPorID(const Conexion: TFDConnection;
    const ID: string): TMemoryStream;
    class function ObtenerLibroPorId(const Conexion: TFDConnection; const Id: string; const Portada,
    Archivo: Boolean): rLibro;
    class function ObtenerArchivoLibro(const Conexion: TFDConnection;
    const ID: string): TMemoryStream;
end;

implementation
uses
  System.IOUtils, Generales, Winapi.ShellAPI, Winapi.Windows, UScripts,
  UMain, System.NetEncoding;

{ TDBActions }

class procedure TDBActions.ActualizarTablas(const Conexion: TFDConnection);
begin

end;

class function TDBActions.BuscarUsuarios(const Conexion: TFDConnection;
  const AKeyword: string): TArray<rUsuario>;
var 
  Qry: TFDQuery;
begin
  SetLength(Result, 0);
  Qry:= TFDQuery.Create(nil);
  Qry.Connection:= Conexion;
  try  
    try
      Conexion.Connected:= True;
      Qry.SQL.Text:= 'SELECT id, nombre, apellido_paterno, apellido_materno, ' +
      'edad, estatus, correo FROM usuarios ' + 
      'WHERE INSTR(nombre, :nombre) > 0 OR ' + 
      'INSTR(apellido_paterno, :apellido_paterno) > 0 OR ' +
      'INSTR(apellido_materno, :apellido_materno) > 0';
      
      Qry.ParamByName('nombre').AsString:= AKeyword;
      Qry.ParamByName('apellido_paterno').AsString:= AKeyword;
      Qry.ParamByName('apellido_materno').AsString:= AKeyword;
      Qry.Open;

      if Qry.RecordCount > 0 then 
      begin
        Qry.First;
        while not Qry.Eof do
        begin
          SetLength(Result, Length(Result) + 1);
          Result[High(Result)].id:= Qry.FieldByName('id').AsString;
          Result[High(Result)].Nombre:= Qry.FieldByName('nombre').AsString;
          Result[High(Result)].Apellido_P:= Qry.FieldByName('apellido_paterno').AsString;
          Result[High(Result)].Apellido_M:= Qry.FieldByName('apellido_materno').AsString;
          Result[High(Result)].Edad:= Qry.FieldByName('edad').AsString;
          Result[High(Result)].Estatus:= Qry.FieldByName('estatus').AsInteger;
          Result[High(Result)].Correo:= Qry.FieldByName('correo').AsString;
          Qry.Next;
        end;
      end;
    except on E: Exception do
      EscribirLog('TDBActions.BuscarUsuarios: ' + E.Message, 2);
    end;
  finally
    Qry.Close;
    FreeAndNil(Qry);
    Conexion.Connected:= False;
  end;
end;

class function TDBActions.CambiarEstatusUsuario(const Conexion: TFDConnection;
  const ID: string; const Estatus: Integer): Boolean;
var
  Qry: TFDQuery;
begin
  Result:= False;

  Qry:= TFDQuery.Create(nil);
  Qry.Connection:= Conexion;
  try
    try
      Conexion.Connected:= True;
      Qry.SQL.Text:= 'UPDATE usuarios SET estatus = :estatus WHERE id = :id';
      Qry.ParamByName('estatus').AsInteger:= Estatus;
      Qry.ParamByName('id').AsString:= ID;
      Qry.ExecSQL;
      Result:= True;
    except on E: Exception do
      EscribirLog('TDBActions.CambiarEstatusUsuario: ' + E.Message, 2);
    end;
  finally
    Qry.Close;
    FreeAndNil(Qry);
    Conexion.Connected:= False;
  end;
end;

class function TDBActions.ConectarBD(const Conexion: TFDConnection): Boolean;
var
  Qry, Qry2: TFDQuery;
begin
  Conexion.DriverName:= 'MySQL';
  Conexion.Params.Values['DriverID']:= 'MySQL';
  Conexion.Params.Values['User_Name']:= DB_USER;
  Conexion.Params.Values['Password']:= DB_PASSWORD;
  Conexion.Params.Values['Server']:= DB_HOSTNAME;
  Conexion.Params.Values['Port']:= DB_PORT;
  Qry:= TFDQuery.Create(nil);
  Qry.Connection:= Conexion;
  Qry.SQL.Clear;
  try
    try
      Conexion.Connected:= True;

      Qry.SQL.Text:= 'SHOW DATABASES LIKE :NombreBD';
      Qry.ParamByName('NombreBD').AsString:= 'lanbrary';
      Qry.Open;

      if Qry.RecordCount = 0 then
      begin
        Qry2:= TFDQuery.Create(nil);
        Qry2.Connection:= Conexion;
        try
          Qry2.SQL.Text:= 'CREATE DATABASE lanbrary';
          Qry2.ExecSQL;
        finally
          Qry2.Close;
          FreeAndNil(Qry2);
        end;
      end;

      Conexion.Params.Values['Database']:= 'lanbrary';
      Conexion.Connected:= True;
      CrearTablas(Conexion);
      ActualizarTablas(Conexion);
      CrearStoredProcedures(Conexion);
      InsertarCategorias(Conexion);
      Result:= True;
    except on E: Exception do
      begin
        EscribirLog('DBActions.ConectarBD: ' + E.Message, 2);
        Result:= False;
      end;
    end;
  finally
    Qry.Close;
    FreeAndNil(Qry);
    Conexion.Connected:= False;
  end;
end;

class procedure TDBActions.CrearStoredProcedures(const Conexion: TFDConnection);
  function SPYaExiste(nombre: string; Qry: TFDQuery): boolean;
  begin
    Qry.SQL.Clear;
    Qry.SQL.Text:= 'SELECT ROUTINE_NAME FROM information_schema.ROUTINES ' +
    'WHERE ROUTINE_TYPE = :routine_type AND ROUTINE_SCHEMA = :routine_schema AND ROUTINE_NAME = :nombre';
    Qry.ParamByName('routine_type').AsString:= 'PROCEDURE';
    Qry.ParamByName('routine_schema').AsString:= 'lanbrary';
    Qry.ParamByName('nombre').AsString:= nombre;
    Qry.Open;
    Result:= Qry.RecordCount > 0;
  end;
var
  Qry: TFDQuery;
  i: Integer;
  InfoEjecucion: TShellExecuteInfo;
  ExePath: string;
  BatFileName: string;
  SQLFileName: string;
  BatStr: string;
  BatStrLst: TStringList;
begin
  Qry:= TFDQuery.Create(nil);
  Qry.Connection:= Conexion;
  BatStrLst:= TStringList.Create;
  try
    ExePath:= ExtractFileDir(ParamStr(0));
    BatFileName:= ExePath + PathDelim + 'Temp.bat';
    for i:= 0 to Scripts.StoredProcedures.SQLScripts.Count - 1 do
    begin
      if not SPYaExiste(Scripts.StoredProcedures.SQLScripts[i].Name, Qry) then
      begin
        SQLFileName:= ExePath + PathDelim + Scripts.StoredProcedures.SQLScripts[i].Name + '.sql';
        Scripts.StoredProcedures.SQLScripts[i].SQL.SaveToFile(SQLFileName);

        if not DB_PASSWORD.IsEmpty then
        begin
          BatStr:=
          '@echo off' + sLineBreak +
          'set USER="' + DB_USER + '"' + sLineBreak +
          'set PASSWORD="' + DB_PASSWORD + '"' + sLineBreak +
          'set DATABASE="lanbrary"' + sLineBreak +
          'set SQL_FILE="' + SQLFileName + '"' + sLineBreak + sLineBreak +
          'cd ' + XAMPP_PATH + PathDelim + 'mysql' + PathDelim + 'bin' + sLineBreak +
          'mysql -u %USER% -p%PASSWORD% %DATABASE% < %SQL_FILE%';
        end else
        begin
          BatStr:=
          '@echo off' + sLineBreak +
          'set USER="' + DB_USER + '"' + sLineBreak +
          'set DATABASE="lanbrary"' + sLineBreak +
          'set SQL_FILE="' + SQLFileName + '"' + sLineBreak + sLineBreak +
          'cd ' + XAMPP_PATH + PathDelim + 'mysql' + PathDelim + 'bin' + sLineBreak +
          'mysql -u %USER% %DATABASE% < %SQL_FILE%';
        end;

        BatStrLst.Text:= BatStr;
        BatStrLst.SaveToFile(BatFileName);

        FillChar(InfoEjecucion, SizeOf(InfoEjecucion), 0);
        InfoEjecucion.cbSize := SizeOf(InfoEjecucion);
        InfoEjecucion.fMask := SEE_MASK_NOCLOSEPROCESS;
        InfoEjecucion.Wnd := 0;
        InfoEjecucion.lpVerb := 'open';
        InfoEjecucion.lpFile := PChar(BatFileName);
        InfoEjecucion.nShow := SW_HIDE; // Ocultar ventana
        if ShellExecuteEx(@InfoEjecucion) then
        begin
          WaitForSingleObject(InfoEjecucion.hProcess, INFINITE);
          CloseHandle(InfoEjecucion.hProcess);

          if TFile.Exists(SQLFileName) then
            TFile.Delete(SQLFileName);

          if TFile.Exists(BatFileName) then
            TFile.Delete(BatFileName);
        end;
      end;
    end;
  finally
    Qry.Close;
    FreeAndNil(Qry);
    FreeAndNil(BatStrLst);
  end;
end;

class procedure TDBActions.CrearTablas(const Conexion: TFDConnection);
  function TablaYaExiste(Qry:TFDQuery; Nombre: string): Boolean;
  begin
    Qry.SQL.Clear;
    Qry.SQL.Text := 'SELECT TABLE_NAME FROM information_schema.tables ' +
    'WHERE table_schema = :NombreBD AND table_name = :NombreTabla';
    Qry.ParamByName('NombreBD').AsString := 'lanbrary';
    Qry.ParamByName('NombreTabla').AsString := Nombre;
    Qry.Open;

    Result:= Qry.RecordCount > 0;
  end;
var
  Qry, Qry2: TFDQuery;
begin
  Qry:= TFDQuery.Create(nil);
  Qry.Connection:= Conexion;

  Qry2:= TFDQuery.Create(nil);
  Qry2.Connection:= Conexion;
  try
    try
      if not TablaYaExiste(Qry, 'libros') then
      begin
        Qry2.SQL.Text:= 'CREATE TABLE libros (' +
        'id varchar(100) NOT NULL,' +
        'nombre varchar(256) NOT NULL,' +
        'descripcion varchar(256) NOT NULL,' +
        'autor varchar(256) NOT NULL,' +
        'fechahora datetime NOT NULL,' +
        'estatus int(1) NOT NULL,' +
        'portada mediumblob NOT NULL,' +
        'archivo longblob NOT NULL,' +
        'hash_archivo varchar(32) NOT NULL,' +
        'usuario varchar(256) NOT NULL,' +
        'id_categoria int(11) NOT NULL)';
        Qry2.ExecSQL;

        Qry2.SQL.Text:= 'ALTER TABLE libros ADD UNIQUE KEY id (id)';
        Qry2.ExecSQL;

        Qry2.SQL.Text:= 'CREATE INDEX idx_hash_archivo ON libros(hash_archivo)';
        Qry2.ExecSQL;

        Qry2.SQL.Text:= 'CREATE INDEX idx_libros_categoria_fecha ON libros' +
        '(id_categoria, fechahora, id)';
        Qry2.ExecSQL;
      end;

      if not TablaYaExiste(Qry, 'categorias') then
      begin
        Qry2.SQL.Text:= 'CREATE TABLE categorias (' +
        'id int(11) NOT NULL, descripcion varchar(256) NOT NULL)';
        Qry2.ExecSQL;

        Qry2.SQL.Text:= 'ALTER TABLE categorias ADD PRIMARY KEY (id)';
        Qry2.ExecSQL;

        Qry2.SQL.Text:= 'ALTER TABLE categorias MODIFY id int(11) NOT NULL AUTO_INCREMENT';
        Qry2.ExecSQL;
      end;

      if not TablaYaExiste(Qry, 'usuarios') then
      begin
        Qry2.SQL.Text:= 'CREATE TABLE usuarios (' +
        'id varchar(100) NOT NULL,' +
        'nombre varchar(150) NOT NULL,' +
        'apellido_paterno varchar(50) NOT NULL,' +
        'apellido_materno varchar(50) NOT NULL,' +
        'correo varchar(100) NOT NULL,' +
        'clave varchar(256) NOT NULL,' +
        'edad varchar(3) NOT NULL,' +
        'estatus int(1) NOT NULL,' +
        'foto mediumblob)';
        Qry2.ExecSQL;

        Qry2.SQL.Text:= 'ALTER TABLE usuarios ADD UNIQUE KEY id (id)';
        Qry2.ExecSQL;
      end;
    except on E: Exception do
      begin
        Qry.Close;
        Qry2.Close;
        EscribirLog('DBActions.CrearTablas: Error al crear tablas: ' + E.Message, 2);
      end;
    end;
  finally
    Qry.Close;
    Qry2.Close;
    FreeAndNil(Qry);
    FreeAndNil(Qry2);
  end;
end;

class function TDBActions.EliminarLibro(const Conexion: TFDConnection; const Id: string): Boolean;
var
  Qry: TFDQuery;
begin
  Qry:= TFDQuery.Create(nil);
  Qry.Connection:= Conexion;
  Qry.SQL.Clear;
  try
    try
      Conexion.Connected:= True;
      Qry.SQL.Text:= 'DELETE FROM libros WHERE id = :id';
      Qry.ParamByName('id').AsString:= Id;
      Qry.ExecSQL;
      Result:= True;
    except on E: Exception do
      begin
        EscribirLog('DBActions.EliminarLibro: ' + E.Message);
        Result:= False;
      end;
    end;
  finally
    Qry.Close;
    FreeAndNil(Qry);
    Conexion.Connected:= False;
  end;
end;

class function TDBActions.EliminarUsuario(const Conexion: TFDConnection;
  const ID: string): Boolean;
var
  Qry: TFDQuery;
begin
  Result:= False;
  Qry:= TFDQuery.Create(nil);
  Qry.Connection:= Conexion;
  try
    try
      Qry.SQL.Text:= 'DELETE FROM usuarios WHERE id = :id';
      Qry.ParamByName('id').AsString:= ID;
      Qry.ExecSQL;
      Result:= True;
    except on E: Exception do
      EscribirLog('TDBActions.EliminarUsuario: ' + E.Message, 2);
    end;
  finally
    Qry.Close;
    FreeAndNil(Qry);
    Conexion.Connected:= False;
  end;
end;

class function TDBActions.GenerarID_Libro: string;
var
  idLibro: TGUID;
begin
  try
    if CreateGUID(idLibro) = 0 then
      Result:= GUIDToString(idLibro).Replace('{', string.Empty).Replace('}', string.Empty)
    else
      Result:= string.Empty;
  except on E: Exception do
    begin
      EscribirLog('DBActions.GenerarID_Libro: No fue posible generar ID: ' +
      E.Message, 2);
      Result:= string.Empty;
    end;
  end;
end;

class procedure TDBActions.InsertarCategorias(const Conexion: TFDConnection);
var
  Qry, Qry2: TFDQuery;
  Categorias: TStringList;
  FileName: string;
  i: Integer;
begin
  FileName:= ExtractFileDir(ParamStr(0)) + PathDelim + 'categorias.txt';
  if not TFile.Exists(FileName) then
  begin
    EscribirLog('DBActions.InsertarCategorias: No existe el archivo "categorias.txt"');
    Exit;
  end;

  Categorias:= TStringList.Create;
  Categorias.LoadFromFile(FileName, TUTF8Encoding.UTF8);
  Qry:= TFDQuery.Create(nil);
  Qry.Connection:= Conexion;
  Qry.SQL.Clear;

  Qry2:= TFDQuery.Create(nil);
  Qry2.Connection:= Conexion;
  Qry2.SQL.Clear;
  try
    try
      Qry.SQL.Text:= 'SELECT * FROM categorias';
      Qry.Open;

      (*
        Para EVITAR saber cuál categoría se ha eliminado o cuál se agregó,
        al momento de haber diferencias de las categorías de la base de datos
        contra el archivo de texto, se eliminan las categorías de la bd
        y se insertan las que hay en el archivo de texto.
      *)

      if (Categorias.IndexOf('Todas') > -1) then
      begin
        if (Categorias.IndexOf('Todas') <> 0) then
        begin
          Categorias.Delete(Categorias.IndexOf('Todas'));
          Categorias.Insert(0, 'Todas');
          Categorias.SaveToFile(FileName);
        end;
      end else
      begin
        Categorias.Insert(0, 'Todas');
        Categorias.SaveToFile(FileName);
      end;

      if (Qry.RecordCount <> Categorias.Count) and (Categorias.Count > 0) then
      begin
        Qry2.SQL.Text:= 'TRUNCATE categorias';
        Qry2.ExecSQL;

        Qry2.SQL.Clear;
        Qry2.SQL.Add('INSERT INTO categorias (descripcion) VALUES ');
        for i:= 0 to Categorias.Count - 1 do
        begin
          if i < (Categorias.Count - 1) then
            Qry2.SQL.Add('(:descripcion' + IntToStr(i) + '),') else

          if i = (Categorias.Count - 1) then
            Qry2.SQL.Add('(:descripcion' + IntToStr(i) + ')');

          Qry2.ParamByName('descripcion' + IntToStr(i)).AsString:= Categorias[i];
        end;

        Qry2.ExecSQL;
      end;
    except on E: Exception do
      begin
        EscribirLog('DBActions.InsertarCategorias: ' + E.Message, 2);
      end;
    end;
  finally
    Qry.Close;
    FreeAndNil(Qry);
    Qry2.Close;
    FreeAndNil(Qry2);
    Categorias.Clear;
    FreeAndNil(Categorias);
  end;
end;

class function TDBActions.InsertarLibro(const Conexion: TFDConnection; const Nombre, Descripcion, Autor: string; const Fecha: TDateTime;
  const Estatus: Integer; const Portada, Archivo, Usuario: string;
  const ID_Categoria: Integer): Integer;
var
  StoredProc: TFDStoredProc;
  MSPortada, MSArchivo: TMemoryStream;
  //Qry: TFDQuery;
  //i: Integer;
begin
  (*
    0= Excepción 1= Correcto -1= Libro ya existe
  *)

  StoredProc:= TFDStoredProc.Create(nil);
  try
    try
      StoredProc.Connection:= Conexion;
      Conexion.Connected:= True;
      StoredProc.StoredProcName:= 'insertar_libro';
      StoredProc.Prepare;
      StoredProc.ParamByName('p_id').AsString:= GenerarID_Libro;
      StoredProc.ParamByName('p_nombre').AsString:= Nombre;
      StoredProc.ParamByName('p_descripcion').AsString:= Descripcion;
      StoredProc.ParamByName('p_autor').AsString:= Autor;
      StoredProc.ParamByName('p_fechahora').AsDateTime:= Fecha;
      StoredProc.ParamByName('p_estatus').AsInteger:= Estatus;

      MSPortada:= Base64StringToMemoryStream(Portada);
      MSArchivo:= Base64StringToMemoryStream(Archivo);
      try
        StoredProc.ParamByName('p_portada').LoadFromStream(MSPortada, ftBlob);
        StoredProc.ParamByName('p_archivo').LoadFromStream(MSArchivo, ftBlob);
        StoredProc.ParamByName('p_hash_md5').AsString:= CalcularHashMD5(MSArchivo);
      finally
        if MSPortada <> nil then
          FreeAndNil(MSPortada);

        if MSArchivo <> nil then
          FreeAndNil(MSArchivo);
      end;
      StoredProc.ParamByName('p_usuario').AsString:= Usuario;
      StoredProc.ParamByName('p_id_categoria').AsInteger:= ID_Categoria;
      StoredProc.ExecProc;

      Result:= StoredProc.ParamByName('resultado').AsInteger;
    except on E: Exception do
      begin
        EscribirLog('DBActions.InsertarLibro: ' + E.Message);
        Result:= 0;
      end;
    end;
  finally
    StoredProc.Close;
    FreeAndNil(StoredProc);
    Conexion.Connected:= False;
  end;
end;

class function TDBActions.ModificarLibro(const Conexion: TFDConnection;
const Id, Nombre, Descripcion, Autor: string; const IdCategoria: Integer): Boolean;
var
  Qry: TFDQuery;
begin
  Qry:= TFDQuery.Create(nil);
  Qry.Connection:= Conexion;
  try
    try
      Conexion.Connected:= True;
      Qry.SQL.Clear;
      Qry.SQL.Text:= 'UPDATE libros SET nombre = :nombre, descripcion = :descripcion, ' +
      'autor = :autor, id_categoria = :id_categoria WHERE id = :id';

      Qry.ParamByName('id').AsString:= Id;
      Qry.ParamByName('nombre').AsString:= Nombre;
      Qry.ParamByName('descripcion').AsString:= Descripcion;
      Qry.ParamByName('autor').AsString:= Autor;
      Qry.ParamByName('id_categoria').AsInteger:= IdCategoria;
      Qry.ExecSQL;
      Result:= True;
    except on E: Exception do
      begin
        EscribirLog('DBActions.ModificarLibro: ' + E.Message);
        Result:= False;
      end;
    end;
  finally
    Qry.Close;
    FreeAndNil(Qry);
    Conexion.Connected:= False;
  end;
end;

class function TDBActions.ObtenerArchivoLibro(const Conexion: TFDConnection;
const ID: string): TMemoryStream;
var 
  Qry: TFDQuery;
  BlobStream: TStream;
begin
  Result:= nil;
  Qry:= TFDQuery.Create(nil);
  Qry.Connection:= Conexion;
  try   
    try   	
      Conexion.Connected:= True;
      Qry.SQL.Text:= 'SELECT archivo FROM libros WHERE id = :id';
      Qry.ParamByName('id').AsString:= ID;
      Qry.Open;
      
      if Qry.RecordCount > 0 then 
      begin
        Qry.First;
        BlobStream:= Qry.CreateBlobStream(Qry.FieldByName('archivo'), bmRead);
        try   
          Result:= TMemoryStream.Create;
          Result.CopyFrom(BlobStream, 0);
          Result.Position:= 0;
        finally
          FreeAndNil(BlobStream);
        end;
      end;
    except on E: Exception do 
      EscribirLog('TDBActions.ObtenerArchivoLibro: ' + E.Message);
    end;
  finally
    Qry.Close;
    FreeAndNil(Qry);
    Conexion.Connected:= False;
  end;
end;

class function TDBActions.ObtenerCategorias(const Conexion: TFDConnection): TArray<rCategoria>;
var
  Qry: TFDQuery;
begin
  SetLength(Result, 0);
  Qry:= TFDQuery.Create(nil);
  Qry.Connection:= Conexion;
  Qry.SQL.Clear;
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
        EscribirLog('DBActions.ObtenerCategorias: ' + E.Message, 2);
        SetLength(Result, 0);
      end;
    end;
  finally
    Qry.Close;
    FreeAndNil(Qry);
    Conexion.Connected:= False;
  end;
end;

class function TDBActions.ObtenerCoincidenciasLibros(const Conexion: TFDConnection;
  const PalabraClave: string): TArray<rLibro>;
var
  Qry: TFDQuery;
begin
  Qry:= TFDQuery.Create(nil);
  Qry.Connection:= Conexion;
  Qry.SQL.Clear;
  try
    try
      Conexion.Connected:= True;
      Qry.SQL.Text:= 'SELECT id, nombre, descripcion, autor, id_categoria FROM libros WHERE ' +
      'INSTR(nombre, :nombre) > 0 OR INSTR(descripcion, :descripcion) > 0 OR ' +
      'INSTR(autor, :autor) > 0 LIMIT 10';
      Qry.ParamByName('nombre').AsString:= PalabraClave;
      Qry.ParamByName('descripcion').AsString:= PalabraClave;
      Qry.ParamByName('autor').AsString:= PalabraClave;
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
          Result[High(Result)].Id_Categoria:= Qry.FieldByName('id_categoria').AsInteger;
          Qry.Next;
        end;
      end else SetLength(Result, 0);
    except on E: Exception do
      begin
        EscribirLog('DBActions.ObtenerCoincidenciasLibros: ' + E.Message, 2);
        SetLength(Result, 0);
      end;
    end;
  finally
    Qry.Close;
    FreeAndNil(Qry);
    Conexion.Connected:= False;
  end;
end;

class function TDBActions.ObtenerFotoUsuarioPorID(const Conexion: TFDConnection;
  const ID: string): TMemoryStream;
var
  Qry: TFDQuery;
  BlobStream: TStream;
begin
  Result:= nil;
  Qry:= TFDQuery.Create(nil);
  Qry.Connection:= Conexion;
  try
    try
      Qry.SQL.Text:= 'SELECT foto FROM usuarios WHERE id = :id';
      Qry.ParamByName('id').AsString:= ID;
      Qry.Open;
      if Qry.RecordCount > 0 then
      begin
        Qry.First;
        if not Qry.FieldByName('foto').IsNull then
        begin
          BlobStream:= Qry.CreateBlobStream(Qry.FieldByName('foto'), bmRead);
          try
            Result:= TMemoryStream.Create;
            Result.CopyFrom(BlobStream, 0);
            Result.Position:= 0;
          finally
            FreeAndNil(BlobStream);
          end;
        end;
      end;
    except on E: Exception do
      EscribirLog('DBActions.ObtenerFotoUsuarioPorID: ' + E.Message, 2);
    end;
  finally
    Qry.Close;
    FreeAndNil(Qry);
    Conexion.Connected:= False;
  end;
end;

class function TDBActions.ObtenerLibroPorId(const Conexion: TFDConnection;
  const Id: string; const Portada, Archivo: Boolean): rLibro;
var
  Qry: TFDQuery;
  StrmPortada: TStream;
  StrmArchivo: TStream;
begin
  Result:= Default(rLibro);
  Qry:= TFDQuery.Create(nil);
  Qry.Connection:= Conexion;
  try
    try
      Conexion.Connected:= True;
      Qry.SQL.Clear;

      if (Portada = True) and (Archivo = True) then
        Qry.SQL.Text:= 'SELECT * FROM libros WHERE id = :id'
      else
      if (Portada = True) and (Archivo = False) then
        Qry.SQL.Text:= 'SELECT id, nombre, descripcion, autor, fechahora, estatus, ' +
        'portada, usuario, id_categoria FROM libros WHERE id = :id'
      else
      if (Portada = False) and (Archivo = True) then
        Qry.SQL.Text:= 'SELECT id, nombre, descripcion, autor, fechahora, estatus, ' +
        'archivo, usuario, id_categoria FROM libros WHERE id = :id'
      else
        Qry.SQL.Text:= 'SELECT id, nombre, descripcion, autor, fechahora, estatus, ' +
        'usuario, id_categoria FROM libros WHERE id = :id';

      Qry.ParamByName('id').AsString:= Id;
      Qry.Open;

      if Qry.RecordCount > 0 then
      begin
        Qry.First;
        Result.Id:= Qry.FieldByName('id').AsString;
        Result.Nombre:= Qry.FieldByName('nombre').AsString;
        Result.Descripcion:= Qry.FieldByName('descripcion').AsString;
        Result.Autor:= Qry.FieldByName('autor').AsString;
        Result.Fechahora:= Qry.FieldByName('fechahora').AsString;
        Result.Estatus:= Qry.FieldByName('estatus').AsInteger;

        if Portada = True then
        begin
          if not Qry.FieldByName('portada').IsNull then
          begin
            StrmPortada:= Qry.CreateBlobStream(Qry.FieldByName('portada'), bmRead);
            try
              Result.Portada:= StreamToBase64String(StrmPortada);
            finally
              FreeAndNil(StrmPortada);
            end;
          end;
        end;

        if Archivo = True then
        begin
          if not Qry.FieldByName('archivo').IsNull then
          begin
            StrmArchivo:= Qry.CreateBlobStream(Qry.FieldByName('archivo'), bmRead);
            try
              Result.Archivo:= StreamToBase64String(StrmArchivo);
            finally
              FreeAndNil(StrmArchivo);
            end;
          end;
        end;

        Result.Usuario:= Qry.FieldByName('usuario').AsString;
        Result.Id_Categoria:= Qry.FieldByName('id_categoria').AsInteger;
      end else Result:= Default(rLibro);
    except on E: Exception do
      begin
        EscribirLog('DBActions.ObtenerLibroPorID: ' + E.Message);
        Result:= Default(rLibro);
      end;
    end;
  finally
    Qry.Close;
    FreeAndNil(Qry);
    Conexion.Close;
  end;
end;

class function TDBActions.ObtenerLibros(const Conexion: TFDConnection;
const id_categoria: Integer; getBLOBS: Boolean;
const Filtro: Integer): TArray<rLibro>;
var
  Qry: TFDQuery;
  Portada, Archivo: TStream;
begin
  //NOTA, IMPLEMENTAR UN STORED PROCEDURE QUE OBTENGA EL ID_USUARIO COMO
  //EL NOMBRE COMPLETO CUANDO EL ID_USUARIO SEA DIFERENTE DE "admin"
  SetLength(Result, 0);
  Qry:= TFDQuery.Create(nil);
  Qry.Connection:= Conexion;
  Qry.SQL.Clear;
  try
    try
      Conexion.Connected:= True;
      case id_categoria of
        0:
        begin
          if getBLOBS then
            Qry.SQL.Text:= 'SELECT * FROM libros'
          else
            Qry.SQL.Text:= 'SELECT id, nombre, descripcion, autor, fechahora, estatus, ' +
            'usuario, id_categoria FROM libros';
        end;

        else
        begin
          if getBLOBS then
            Qry.SQL.Text:= 'SELECT * FROM libros WHERE id_categoria = :id_categoria'
          else
            Qry.SQL.Text:= 'SELECT id, nombre, descripcion, autor, fechahora, estatus, ' +
            'usuario, id_categoria FROM libros WHERE id_categoria = :id_categoria';

          Qry.ParamByName('id_categoria').AsInteger:= id_categoria;
        end;
      end;


      //0 = Desde el más reciente 1= Desde el más antiguo
      case Filtro of
        0:  Qry.SQL.Text:= Qry.SQL.Text + ' ORDER BY fechahora DESC, id DESC';

        1:  Qry.SQL.Text:= Qry.SQL.Text + ' ORDER BY fechahora ASC, id ASC';
      end;

      Qry.Open;

      if Qry.RecordCount > 0 then
      begin
        Qry.First;

        if getBLOBS then
        begin
          while not Qry.Eof do
          begin
            SetLength(Result, Length(Result) + 1);
            Result[High(Result)].Id:= Qry.FieldByName('id').AsString;
            Result[High(Result)].Nombre:= Qry.FieldByName('nombre').AsString;
            Result[High(Result)].Descripcion:= Qry.FieldByName('descripcion').AsString;
            Result[High(Result)].Autor:= Qry.FieldByName('autor').AsString;
            Result[High(Result)].Fechahora:= Qry.FieldByName('fechahora').AsString;
            Result[High(Result)].Estatus:= Qry.FieldByName('estatus').AsInteger;

            if not Qry.FieldByName('portada').IsNull then
            begin
              Portada:= Qry.CreateBlobStream(Qry.FieldByName('portada'), bmRead);
              try
                Result[High(Result)].Portada:= StreamToBase64String(Portada);
              finally
                FreeAndNil(Portada);
              end;
            end
            else
              Result[High(Result)].Portada:= string.Empty;

            if not Qry.FieldByName('archivo').IsNull then
            begin
              Archivo:= Qry.CreateBlobStream(Qry.FieldByName('archivo'), bmRead);
              try
                Result[High(Result)].Archivo:= StreamToBase64String(Archivo);
              finally
                FreeAndNil(Archivo);
              end;
            end
            else
              Result[High(Result)].Archivo:= string.Empty;

            Result[High(Result)].Usuario:= Qry.FieldByName('usuario').AsString;
            Result[High(Result)].Id_Categoria:= Qry.FieldByName('id_categoria').AsInteger;
            Qry.Next;
          end;
        end else
        begin
          while not Qry.Eof do
          begin
            SetLength(Result, Length(Result) + 1);
            Result[High(Result)].Id:= Qry.FieldByName('id').AsString;
            Result[High(Result)].Nombre:= Qry.FieldByName('nombre').AsString;
            Result[High(Result)].Descripcion:= Qry.FieldByName('descripcion').AsString;
            Result[High(Result)].Autor:= Qry.FieldByName('autor').AsString;
            Result[High(Result)].Fechahora:= Qry.FieldByName('fechahora').AsString;
            Result[High(Result)].Estatus:= Qry.FieldByName('estatus').AsInteger;
            Result[High(Result)].Portada:= string.Empty;
            Result[High(Result)].Archivo:= string.Empty;
            Result[High(Result)].Usuario:= Qry.FieldByName('usuario').AsString;
            Result[High(Result)].Id_Categoria:= Qry.FieldByName('id_categoria').AsInteger;
            Qry.Next;
          end;
        end;
      end;
    except on E: Exception do
      begin
        EscribirLog('DBActions.ObtenerLibros: ' + E.Message, 2);
        SetLength(Result, 0);
      end;
    end;
  finally
    Qry.Close;
    FreeAndNil(Qry);
    Conexion.Connected:= False;
  end;
end;

class function TDBActions.ObtenerPortadaLibroPorID(
const Conexion: TFDConnection; const ID: string): TMemoryStream;
var
  Qry: TFDQuery;
  BlobStream: TStream;
begin
  Result:= nil;
  Qry:= TFDQuery.Create(nil);
  Qry.Connection:= Conexion;
  try
    try
      Conexion.Connected:= True;
      Qry.SQL.Text:= 'SELECT portada FROM libros WHERE id = :id';
      Qry.ParamByName('id').AsString:= ID;
      Qry.Open;
      if Qry.RecordCount > 0 then
      begin
        Qry.First;
        if not Qry.FieldByName('portada').IsNull then
        begin
          BlobStream:= Qry.CreateBlobStream(Qry.FieldByName('portada'), bmRead);
          try
            Result:= TMemoryStream.Create;
            Result.CopyFrom(BlobStream, 0);
            Result.Position:= 0;
          finally
            FreeAndNil(BlobStream);
          end;
        end;
      end;
    except on E: Exception do
      EscribirLog('DBActions.ObtenerPortadaLibroPorID: ' + E.Message, 2);
    end;
  finally
    Qry.Close;
    FreeAndNil(Qry);
    Conexion.Connected:= False;
  end;
end;

class function TDBActions.ObtenerUsuarioPorID(const Conexion: TFDConnection;
  const ID: string; const Foto: Boolean): rUsuario;
var
  Qry: TFDQuery;
  SQL: string;
  StreamFoto: TStream;
begin
  Result:= Default(rUsuario);
  Qry:= TFDQuery.Create(nil);
  Qry.Connection:= Conexion;
  try
    try
      if Foto = True then
        SQL:= 'SELECT nombre, apellido_paterno, apellido_materno, ' +
        'edad, correo, estatus, foto FROM usuarios WHERE id = :id'
      else
        SQL:= 'SELECT nombre, apellido_paterno, apellido_materno, ' +
        'edad, correo, estatus FROM usuarios WHERE id = :id';

      Qry.SQL.Text:= SQL;
      Qry.ParamByName('id').AsString:= ID;
      Qry.Open;
      if Qry.RecordCount > 0 then
      begin
        Qry.First;
        Result.id:= ID;
        Result.Nombre:= Qry.FieldByName('nombre').AsString;
        Result.Apellido_P:= Qry.FieldByName('apellido_paterno').AsString;
        Result.Apellido_M:= Qry.FieldByName('apellido_materno').AsString;
        Result.Correo:= Qry.FieldByName('correo').AsString;
        Result.Edad:= Qry.FieldByName('edad').AsString;
        Result.Estatus:= Qry.FieldByName('estatus').AsInteger;
        if Foto = True then
        begin
          if not Qry.FieldByName('foto').IsNull then
          begin
            StreamFoto:= Qry.CreateBlobStream(Qry.FieldByName('foto'), bmRead);
            try
              Result.Foto:= StreamToBase64String(StreamFoto);
            finally
              FreeAndNil(StreamFoto);
            end;
          end
          else
            Result.Foto:= string.Empty;
        end;
      end;
    except on E: Exception do
    end;
  finally
    Qry.Close;
    FreeAndNil(Qry);
    Conexion.Connected:= False;
  end;
end;

class function TDBActions.ObtenerUsuarios(
  const Conexion: TFDConnection; const Filtro: Integer): TArray<rUsuario>;
var
  Qry: TFDQuery;
  SQL: string;
begin
  SetLength(Result, 0);
  Qry:= TFDQuery.Create(nil);
  Qry.Connection:= Conexion;
  try
    try
      Conexion.Connected:= True;

      SQL:= 'SELECT id, nombre, apellido_paterno, apellido_materno, ' +
      'edad, correo, estatus FROM usuarios';

      case Filtro of
        2: SQL:= SQL + ' WHERE estatus = 1';

        3: SQL:= SQL + ' WHERE estatus = 0';
      end;

      Qry.SQL.Text:= SQL;
      Qry.Open;
      if Qry.RecordCount > 0 then
      begin
        Qry.First;
        while not Qry.Eof do
        begin
          SetLength(Result, Length(Result) + 1);
          Result[High(Result)].id:= Qry.FieldByName('id').AsString;
          Result[High(Result)].Nombre:= Qry.FieldByName('nombre').AsString;
          Result[High(Result)].Apellido_P:= Qry.FieldByName('apellido_paterno').AsString;
          Result[High(Result)].Apellido_M:= Qry.FieldByName('apellido_materno').AsString;
          Result[High(Result)].Edad:= Qry.FieldByName('edad').AsString;
          Result[High(Result)].Correo:= Qry.FieldByName('correo').AsString;
          Result[High(Result)].Estatus:= Qry.FieldByName('estatus').AsInteger;
          Qry.Next;
        end;
      end;
    except on E: Exception do
      EscribirLog('DBActions.ObtenerUsuarios: ' + E.Message, 2);
    end;
  finally
    Qry.Close;
    FreeAndNil(Qry);
    Conexion.Connected:= False;
  end;
end;

class function TDBActions.ValidarConfiguraciones: Boolean;
var
  StrServidor, StrUser, StrPassword: string;
  Resultado: Boolean;
  MySQLCnfg_FileName: string;
  Ini: TIniFile;
  RestartMySQL: TStringList;
  max_allowed_packet: string;
  NeedToRestart: Boolean;
  BATFileName: string;
  InfoEjecucion: TShellExecuteInfo;
begin
  (*
    PARA EL CORRECTO FUNCIONAMIENTO DE ESTA FUNCIÓN SE DEBEN CUMPLIR LOS
    SIGUIENTES CRITERIOS:
      -TENER INSTALADO XAMPP
      -TENER INSTALADO MYSQL COMO UN SERVICIO WINDOWS
      -EJECUTAR LANBRARY COMO ADMINISTRADOR
  *)
  MySQLCnfg_FileName:= XAMPP_PATH + PathDelim + 'mysql' + PathDelim + 'bin' + PathDelim + 'my.ini';
  if not TFile.Exists(MySQLCnfg_FileName) then
  begin
    EscribirLog('DBActions.ValidarConfiguraciones: Al parecer XAMPP no se encuentra instalado');
    ShowMessage('XAMPP no se encuentra instalado');
    Exit(False);
  end;

  NeedToRestart:= False;
  Ini:= TIniFile.Create(MySQLCnfg_FileName);
  try
    try
      max_allowed_packet:= Ini.ReadString('mysqld', 'max_allowed_packet', string.Empty).Trim;
      if not max_allowed_packet.Equals('1024M') then
      begin
        Ini.WriteString('mysqld', 'max_allowed_packet', '1024M');
        Ini.UpdateFile;
        NeedToRestart:= True;
      end;

      max_allowed_packet:= Ini.ReadString('mysqldump', 'max_allowed_packet', string.Empty).Trim;
      if not max_allowed_packet.Equals('1024M') then
      begin
        Ini.WriteString('mysqldump', 'max_allowed_packet', '1024M');
        Ini.UpdateFile;
        NeedToRestart:= True;
      end;

      if NeedToRestart then
      begin
        BATFileName:= ExtractFileDir(ParamStr(0)) + PathDelim + 'restartMySQL.bat';
        RestartMySQL:= TStringList.Create;
        RestartMySQL.Text:=
        '@echo off' + sLineBreak +
        'net stop mysql' + sLineBreak +
        'net start mysql';
        RestartMySQL.SaveToFile(BATFileName);

        FillChar(InfoEjecucion, SizeOf(InfoEjecucion), 0);
        InfoEjecucion.cbSize := SizeOf(InfoEjecucion);
        InfoEjecucion.fMask := SEE_MASK_NOCLOSEPROCESS;
        InfoEjecucion.Wnd := 0;
        InfoEjecucion.lpVerb := 'open';
        InfoEjecucion.lpFile := PChar(BATFileName);
        InfoEjecucion.nShow := SW_HIDE; // Ocultar ventana
        if ShellExecuteEx(@InfoEjecucion) then
        begin
          (*
            DRH 24/10/2025
            -ESPERAR 15 SEGUNDOS A QUE SE REINICIE EL SERVICIO
            ES LO MAS ADECUADO; YA QUE USAR "INFINITE" PUEDE SER
            BASTANTE PELIGROSO.
          *)
          WaitForSingleObject(InfoEjecucion.hProcess, 15000);
          CloseHandle(InfoEjecucion.hProcess);

          if TFile.Exists(BATFileName) then
            TFile.Delete(BATFileName);
        end else Exit(False);
      end;
    except on E: Exception do
      begin
        EscribirLog('DBActions.ValidarConfiguraciones: ' + E.Message);
        Exit(False);
      end;
    end;
  finally
    FreeAndNil(Ini);
    if Assigned(RestartMySQL) then
      FreeAndNil(RestartMySQL);
  end;

  StrServidor:= LeerConfigIni('DB', 'host');
  StrUser:= LeerConfigIni('DB', 'user');
  StrPassword:= LeerConfigIni('DB', 'pass');

  if (StrUser.IsEmpty) or (StrServidor.IsEmpty) then
  begin
    TDialogService.InputQuery('Conexión con la Base de Datos', ['Servidor:',
    'Usuario:', 'Contraseña:'], ['localhost', 'root', ''],
    procedure(const AResult: TModalResult;
    const AValues: array of string)
    var
      Conexion: TFDConnection;
    begin
      StrServidor:= AValues[0].Trim;
      StrUser:= AValues[1].Trim;
      StrPassword:= AValues[2].Trim;
      case AResult of
        mrOk:
        begin
          Conexion:= TFDConnection.Create(nil);
          Conexion.LoginPrompt:= False;
          Conexion.DriverName:= 'MySQL';
          Conexion.Params.Values['DriverID']:= 'MySQL';
          Conexion.Params.Values['User_Name']:= StrUser;
          Conexion.Params.Values['Password']:= StrPassword;
          Conexion.Params.Values['Server']:= StrServidor;
          Conexion.Params.Values['Port']:= DB_PORT;
          try
            try
              Conexion.Connected:= True;
              DB_HOSTNAME:= StrServidor;
              DB_USER:= StrUser;
              DB_PASSWORD:= StrPassword;
              EscribirConfigIni('DB', 'host', DB_HOSTNAME);
              EscribirConfigIni('DB', 'user', DB_USER);
              EscribirConfigIni('DB', 'pass', DB_PASSWORD);
              Resultado:= True;
            except
              Resultado:= False;
            end;
          finally
            Conexion.Connected:= False;
            FreeAndNil(Conexion);
          end;
        end;

        else Resultado:=  False;
      end;
    end);
  end else
  begin
    DB_HOSTNAME:= StrServidor;
    DB_USER:= StrUser;
    DB_PASSWORD:= StrPassword;
    Resultado:= True;
  end;
  Result:= Resultado;
end;

end.

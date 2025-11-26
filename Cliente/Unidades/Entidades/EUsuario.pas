unit EUsuario;

interface
uses
  System.Classes, System.Types, System.SysConst, System.SysUtils,
  System.StrUtils;

type rUsuario = record
  private
  public
    //503 = error interno 204 = Correo/Clave incorrectos 200 = ok
    Respuesta: Integer;
    id: string;
    Nombre: string;
    Apellido_P: string;
    Apellido_M: string;
    Correo: string;
    Edad: string;
    //1 = activo 0 = bloqueado
    Estatus: Integer;
    Foto: string;
end;

implementation

end.

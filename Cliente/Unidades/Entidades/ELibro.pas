unit ELibro;

interface
uses
  System.Classes, System.Types, System.SysConst, System.SysUtils,
  System.StrUtils;

type rLibro = record
  private
  public
    Id: string;
    Nombre: string;
    Descripcion: string;
    Autor: string;
    Fechahora: string;
    Estatus: Integer;
    Portada: string;
    Archivo: string;
    Usuario: string;
    Id_Categoria: Integer;
end;

implementation

end.

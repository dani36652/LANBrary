unit PasswordHashing;

interface

uses
  System.SysUtils,
  System.NetEncoding,
  System.Classes,
  System.StrUtils,
  HlpHashFactory,
  HlpIHash,
  HlpIHashInfo,
  HlpIHashResult,
  HlpConverters,
  HlpArrayUtils,
  HlpHashLibTypes;

type
  /// Helper simple para PBKDF2-HMAC (SHA-512 por defecto) con gestión segura de memoria
  TPasswordHasherPBKDF2 = class
  private
    const
      DEFAULT_ITERATIONS = 35000; //310000; // recomendado OWASP 2025
      DEFAULT_HASHLEN    = 32; //64;     // 64 bytes = 512 bits (SHA-512)
  private
    //class function BytesEqualConstTime(const A, B: THashLibByteArray): Boolean; static;
    class procedure ZeroAndNil(var Arr: THashLibByteArray); static;
  public
    /// Genera salt (Base64) a partir de un GUID (128 bits)
    class function GenerateSaltFromGUID: string; static;

    /// Hashea la contraseña con PBKDF2-HMAC-SHA512. Devuelve: saltBase64$hashBase64
    /// (Interfaz simple para uso: solo contraseña)
    class function HashPassword(const PlainPassword: string): string; static;

    /// Verifica la contraseña usando el string guardado (saltBase64$hashBase64)
    class function VerifyPassword(const PlainPassword, Stored: string): Boolean; static;
  end;

implementation

{ TPasswordHasherPBKDF2 }

class procedure TPasswordHasherPBKDF2.ZeroAndNil(var Arr: THashLibByteArray);
begin
  if (Arr <> nil) and (Length(Arr) > 0) then
  begin
    // TArrayUtils.ZeroFill está en HlpArrayUtils (HashLib4Pascal)
    TArrayUtils.ZeroFill(Arr);
    Arr := nil; // libera la referencia
  end;
end;

class function TPasswordHasherPBKDF2.GenerateSaltFromGUID: string;
var
  G: TGUID;
  RandomBytes: TBytes;
  Mix: THashLibByteArray;
  i: Integer;
  Hash: IHash;
begin
  // 1 Generar GUID base (128 bits)
  if CreateGUID(G) <> S_OK then
    raise Exception.Create('No se pudo generar GUID para salt.');

  // 2 Generar bytes aleatorios adicionales
  SetLength(RandomBytes, 16);
  for i := 0 to High(RandomBytes) do
    RandomBytes[i] := Byte(Random(256));

  //3 Combinar GUID + bytes aleatorios
  SetLength(Mix, SizeOf(TGUID) + Length(RandomBytes));
  Move(G, Mix[0], SizeOf(TGUID));
  Move(RandomBytes[0], Mix[SizeOf(TGUID)], Length(RandomBytes));

  //4 Aplicar SHA-512 sobre la mezcla entropía fuerte y uniforme
  Hash := THashFactory.TCrypto.CreateSHA2_512();
  Mix := Hash.ComputeBytes(Mix).GetBytes();

  //5 Recortar a 32 bytes (256 bits de entropía efectiva)
  SetLength(Mix, 32);

  //6 Codificar en Base64
  try
    Result := TNetEncoding.Base64.EncodeBytesToString(Mix);
  finally
    ZeroAndNil(Mix);
    Hash:= nil;
  end;
end;

(*class function TPasswordHasherPBKDF2.BytesEqualConstTime(const A, B: THashLibByteArray): Boolean;
var
  i: Integer;
  x: Cardinal;
begin
  // comparación en tiempo constante (dependiente solo de la longitud)
  if Length(A) <> Length(B) then
    Exit(False);

  x := 0;
  for i := 0 to High(A) do
    x := x or (Cardinal(A[i]) xor Cardinal(B[i]));

  Result := x = 0;
end;*)

class function TPasswordHasherPBKDF2.HashPassword(const PlainPassword: string): string;
var
  SaltB64: string;
  SaltBytes, PwdBytes, DerivedKey: THashLibByteArray;
  PBKDF2Inst: IPBKDF2_HMAC;
  EncHash: string;
begin
  SaltB64 := string.Empty;
  SaltBytes := nil;
  PwdBytes := nil;
  DerivedKey := nil;
  PBKDF2Inst := nil;

  // Generar salt (GUID -> Base64)
  SaltB64 := GenerateSaltFromGUID;
  SaltBytes := TNetEncoding.Base64.DecodeStringToBytes(SaltB64);

  // Convertir password a THashLibByteArray (UTF-8)
  PwdBytes := TConverters.ConvertStringToBytes(PlainPassword, TEncoding.UTF8);

  try
    // Crear instancia PBKDF2-HMAC con SHA-512
    PBKDF2Inst := TKDF.TPBKDF2_HMAC.CreatePBKDF2_HMAC(
                    THashFactory.TCrypto.CreateSHA2_512(),
                    PwdBytes,
                    SaltBytes,
                    DEFAULT_ITERATIONS);

    // Obtener derived key
    DerivedKey := PBKDF2Inst.GetBytes(DEFAULT_HASHLEN);

    // Codificar y devolver
    EncHash := TNetEncoding.Base64.EncodeBytesToString(DerivedKey);
    Result := Format('%s$%s', [SaltB64, EncHash]);
  finally
    // Limpieza segura en orden: limpiar datos sensibles y liberar instancia
    // Primero limpiar bytes derivados y password/salt
    ZeroAndNil(DerivedKey);
    ZeroAndNil(PwdBytes);
    ZeroAndNil(SaltBytes);

    // Liberar instancia (interfaces se liberan al nil)
    PBKDF2Inst := nil;
  end;
end;

class function TPasswordHasherPBKDF2.VerifyPassword(const PlainPassword,
  Stored: string): Boolean;
var
  Parts: TArray<string>;
  SaltB64, HashB64: string;
  SaltBytes, PwdBytes, StoredKey, ComputedKey: THashLibByteArray;
  PBKDF2Inst: IPBKDF2_HMAC;
begin
  Result := False;
  Parts := Stored.Split(['$']);
  if Length(Parts) <> 2 then
    Exit;

  SaltB64 := Parts[0];
  HashB64 := Parts[1];

  SaltBytes := nil;
  PwdBytes := nil;
  StoredKey := nil;
  ComputedKey := nil;
  PBKDF2Inst := nil;

  // Decodificar salt y hash almacenado
  SaltBytes := TNetEncoding.Base64.DecodeStringToBytes(SaltB64);
  StoredKey := TNetEncoding.Base64.DecodeStringToBytes(HashB64);

  // Convertir password
  PwdBytes := TConverters.ConvertStringToBytes(PlainPassword, TEncoding.UTF8);

  try
    // Reconstruir PBKDF2 con los mismos parámetros
    PBKDF2Inst := TKDF.TPBKDF2_HMAC.CreatePBKDF2_HMAC(
                    THashFactory.TCrypto.CreateSHA2_512(),
                    PwdBytes,
                    SaltBytes,
                    DEFAULT_ITERATIONS);

    // Generar computed key
    ComputedKey := PBKDF2Inst.GetBytes(DEFAULT_HASHLEN);

    // Comparación segura
    Result := TArrayUtils.ConstantTimeAreEqual(ComputedKey, StoredKey);
    //BytesEqualConstTime(ComputedKey, StoredKey);
  finally
    // Limpieza segura
    ZeroAndNil(ComputedKey);
    ZeroAndNil(StoredKey);
    ZeroAndNil(PwdBytes);
    ZeroAndNil(SaltBytes);

    // Liberar instancia
    PBKDF2Inst := nil;
  end;
end;

end.


object Scripts: TScripts
  Height = 480
  Width = 640
  object StoredProcedures: TFDScript
    SQLScripts = <
      item
        Name = 'insertar_libro'
        SQL.Strings = (
          'DELIMITER //'
          ''
          'CREATE PROCEDURE insertar_libro('
          '    IN p_id VARCHAR(100),'
          '    IN p_nombre VARCHAR(256),'
          '    IN p_descripcion VARCHAR(256),'
          '    IN p_autor VARCHAR(256),'
          '    IN p_fechahora DATETIME,'
          '    IN p_estatus INT,'
          '    IN p_portada MEDIUMBLOB,'
          '    IN p_archivo LONGBLOB,'
          
            '    IN p_hash_md5 VARCHAR(32), -- Hash MD5 precalculado como nue' +
            'vo par'#225'metro'
          '    IN p_usuario VARCHAR(256),'
          '    IN p_id_categoria INT,    '
          '    OUT resultado INT'
          ')'
          'BEGIN'
          '    -- Verificar si ya existe un archivo con el mismo hash'
          '    IF EXISTS ('
          '        SELECT 1 FROM libros'
          '        WHERE hash_archivo = p_hash_md5'
          '    ) THEN'
          '        SET resultado = -1; -- Ya existe, no insertar'
          '    ELSE'
          '        -- Insertar nuevo registro con el hash'
          '        INSERT INTO libros ('
          '            id, nombre, descripcion, autor, fechahora,'
          
            '            estatus, portada, archivo, usuario, id_categoria, ha' +
            'sh_archivo'
          '        ) VALUES ('
          '            p_id, p_nombre, p_descripcion, p_autor, p_fechahora,'
          
            '            p_estatus, p_portada, p_archivo, p_usuario, p_id_cat' +
            'egoria, p_hash_md5'
          '        );'
          '        SET resultado = 1; -- Insertado con '#233'xito'
          '    END IF;'
          'END;'
          '//'
          ''
          'DELIMITER ;')
      end>
    Params = <>
    Macros = <>
    Left = 40
    Top = 32
  end
end

object WebServer: TWebServer
  Actions = <
    item
      Default = True
      Name = 'DefaultHandler'
      PathInfo = '/'
      OnAction = WebModule1DefaultHandlerAction
    end
    item
      MethodType = mtPost
      Name = 'RegistrarUsuario'
      PathInfo = '/registrar_usr'
      OnAction = WebServerRegistrarUsuarioAction
    end
    item
      MethodType = mtPost
      Name = 'Login'
      PathInfo = '/login'
      OnAction = WebServerLoginAction
    end
    item
      MethodType = mtPut
      Name = 'CambiarClave'
      PathInfo = '/editpassword'
      OnAction = WebServerCambiarClaveAction
    end
    item
      MethodType = mtPut
      Name = 'CambiarFotoPerfil'
      PathInfo = '/editprofilepic'
      OnAction = WebServerCambiarFotoPerfilAction
    end
    item
      MethodType = mtGet
      Name = 'ObtenerCategorias'
      PathInfo = '/categorias'
      OnAction = WebServerObtenerCategoriasAction
    end
    item
      MethodType = mtGet
      Name = 'ObtenerLibros'
      PathInfo = '/books'
      OnAction = WebServerObtenerLibrosAction
    end
    item
      MethodType = mtPost
      Name = 'ObtenerLibros2'
      PathInfo = '/books/scrolling'
      OnAction = WebServerObtenerLibros2Action
    end
    item
      MethodType = mtPost
      Name = 'BuscarLibros'
      PathInfo = '/search/books'
      OnAction = WebServerBuscarLibrosAction
    end
    item
      MethodType = mtPost
      Name = 'BuscarLibros2'
      PathInfo = '/search/books2'
      OnAction = WebServerBuscarLibros2Action
    end
    item
      MethodType = mtGet
      Name = 'DescargarLibro'
      PathInfo = '/books/download'
      OnAction = WebServerDescargarLibroAction
    end>
  Height = 230
  Width = 415
end

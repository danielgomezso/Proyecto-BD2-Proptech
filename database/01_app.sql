USE ProptechDB;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.app_Ingresar
@terminal VARCHAR(128), @ip VARCHAR(50)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 DECLARE @rol VARCHAR(30) = CASE WHEN IS_ROLEMEMBER('db_Administrador')=1 THEN 'Administrador'
 WHEN IS_ROLEMEMBER('db_Digitador')=1 THEN 'Digitador' WHEN IS_ROLEMEMBER('db_Consulta')=1 THEN 'Consulta' END;
 IF @rol IS NULL THROW 51003, 'El usuario no tiene un rol de la aplicación.', 1;
 INSERT dbo.BitacoraAccesos(nombre_usuario,nombre_terminal,direccion_ip,fecha_hora_ingreso)
 VALUES(ORIGINAL_LOGIN(),@terminal,@ip,GETDATE());
 SELECT CONVERT(INT,SCOPE_IDENTITY()) cod_acceso, ORIGINAL_LOGIN() usuario, @rol rol;
END;
GO

CREATE OR ALTER PROCEDURE dbo.app_Salir
@id INT
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 UPDATE dbo.BitacoraAccesos SET fecha_hora_salida=GETDATE()
 WHERE cod_acceso=@id AND nombre_usuario=ORIGINAL_LOGIN() AND fecha_hora_salida IS NULL;
END;
GO

CREATE OR ALTER PROCEDURE dbo.app_Accesos

AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 SELECT * FROM dbo.BitacoraAccesos ORDER BY cod_acceso DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.app_ImpuestosListar

AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 SELECT cod_tipo_impuesto,descripcion,porcentaje,tarifa,estado FROM dbo.TiposImpuesto ORDER BY cod_tipo_impuesto DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.app_ImpuestosGuardar
@json NVARCHAR(MAX)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 IF ISJSON(@json)<>1 THROW 51010, 'Datos inválidos.',1;
 DECLARE @id INT=TRY_CONVERT(INT,JSON_VALUE(@json,'$.cod_tipo_impuesto'));
 DECLARE @descripcion VARCHAR(150);
 DECLARE @porcentaje DECIMAL(5,2);
 DECLARE @tarifa DECIMAL(18,2);
 DECLARE @estado CHAR(1);
 SELECT @descripcion=descripcion,@porcentaje=porcentaje,@tarifa=tarifa,@estado=estado FROM OPENJSON(@json) WITH (descripcion VARCHAR(150),porcentaje DECIMAL(5,2),tarifa DECIMAL(18,2),estado CHAR(1));
 IF @descripcion IS NULL OR LEN(LTRIM(RTRIM(@descripcion)))=0 OR LEN(JSON_VALUE(@json,'$.descripcion'))>150 OR @porcentaje IS NULL OR @tarifa IS NULL OR @estado IS NULL OR LEN(LTRIM(RTRIM(@estado)))=0 OR LEN(JSON_VALUE(@json,'$.estado'))>1 THROW 51010, 'Completa todos los campos y respeta las longitudes permitidas.', 1;
 IF @porcentaje<0 OR @porcentaje>100 OR @tarifa<0 THROW 51011, 'Porcentaje entre 0 y 100; tarifa no negativa.',1;
 IF @estado NOT IN ('A','I') THROW 51011, 'Estado inválido.',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 IF @id IS NULL
 BEGIN
 INSERT dbo.TiposImpuesto(descripcion,porcentaje,tarifa,estado) VALUES(@descripcion,@porcentaje,@tarifa,@estado);
 SET @id=SCOPE_IDENTITY();
 END
 ELSE BEGIN
 UPDATE dbo.TiposImpuesto SET descripcion=@descripcion,porcentaje=@porcentaje,tarifa=@tarifa,estado=@estado WHERE cod_tipo_impuesto=@id;
 IF @@ROWCOUNT=0 THROW 51004, 'El registro ya no existe.',1;
 END
 COMMIT;
 SELECT @id AS id;
 END TRY
 BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW;
 END CATCH
END;
GO

CREATE OR ALTER PROCEDURE dbo.app_ImpuestosEliminar
@id INT
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 DELETE dbo.TiposImpuesto WHERE cod_tipo_impuesto=@id;
 IF @@ROWCOUNT=0 THROW 51004, 'El registro ya no existe.',1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.app_ProductosListar

AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 SELECT cod_cabys,descripcion,unidad_medida,precio,cod_tipo_impuesto,estado FROM dbo.ProductosServicios ORDER BY cod_cabys DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.app_ProductosGuardar
@json NVARCHAR(MAX)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 IF ISJSON(@json)<>1 THROW 51010, 'Datos inválidos.',1;
 DECLARE @id VARCHAR(20)=TRY_CONVERT(VARCHAR(20),JSON_VALUE(@json,'$.cod_cabys'));
 DECLARE @descripcion VARCHAR(255);
 DECLARE @unidad_medida VARCHAR(50);
 DECLARE @precio DECIMAL(18,2);
 DECLARE @cod_tipo_impuesto INT;
 DECLARE @estado CHAR(1);
 SELECT @descripcion=descripcion,@unidad_medida=unidad_medida,@precio=precio,@cod_tipo_impuesto=cod_tipo_impuesto,@estado=estado FROM OPENJSON(@json) WITH (descripcion VARCHAR(255),unidad_medida VARCHAR(50),precio DECIMAL(18,2),cod_tipo_impuesto INT,estado CHAR(1));
 IF @descripcion IS NULL OR LEN(LTRIM(RTRIM(@descripcion)))=0 OR LEN(JSON_VALUE(@json,'$.descripcion'))>255 OR @unidad_medida IS NULL OR LEN(LTRIM(RTRIM(@unidad_medida)))=0 OR LEN(JSON_VALUE(@json,'$.unidad_medida'))>50 OR @precio IS NULL OR @cod_tipo_impuesto IS NULL OR @estado IS NULL OR LEN(LTRIM(RTRIM(@estado)))=0 OR LEN(JSON_VALUE(@json,'$.estado'))>1 THROW 51010, 'Completa todos los campos y respeta las longitudes permitidas.', 1;
 IF @id IS NULL OR LEN(@id)=0 OR LEN(JSON_VALUE(@json,'$.cod_cabys'))>20 OR @precio<0 THROW 51011, 'Revisa CABYS y precio.',1;
 IF @estado NOT IN ('A','I') THROW 51011, 'Estado inválido.',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 IF COALESCE(JSON_VALUE(@json,'$.nuevo'),'false')='true'
 BEGIN
 INSERT dbo.ProductosServicios(cod_cabys,descripcion,unidad_medida,precio,cod_tipo_impuesto,estado) VALUES(@id,@descripcion,@unidad_medida,@precio,@cod_tipo_impuesto,@estado);
 END
 ELSE BEGIN
 UPDATE dbo.ProductosServicios SET descripcion=@descripcion,unidad_medida=@unidad_medida,precio=@precio,cod_tipo_impuesto=@cod_tipo_impuesto,estado=@estado WHERE cod_cabys=@id;
 IF @@ROWCOUNT=0 THROW 51004, 'El registro ya no existe.',1;
 END
 COMMIT;
 SELECT @id AS id;
 END TRY
 BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW;
 END CATCH
END;
GO

CREATE OR ALTER PROCEDURE dbo.app_ProductosEliminar
@id VARCHAR(20)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 DELETE dbo.ProductosServicios WHERE cod_cabys=@id;
 IF @@ROWCOUNT=0 THROW 51004, 'El registro ya no existe.',1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.app_ClientesListar

AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
 OPEN SYMMETRIC KEY SymKey_Proptech DECRYPTION BY CERTIFICATE Cert_Proptech;
 SELECT cod_cliente,nombre,tipo_identificacion,CONVERT(VARCHAR(255),DECRYPTBYKEY(num_identificacion)) AS num_identificacion,CONVERT(VARCHAR(255),DECRYPTBYKEY(telefono)) AS telefono,CONVERT(VARCHAR(255),DECRYPTBYKEY(correo_electronico)) AS correo_electronico,provincia,canton,distrito,barrio,profesion_oficio,actividad_economica,estado,fecha_registro FROM dbo.Clientes ORDER BY cod_cliente DESC;
 CLOSE SYMMETRIC KEY SymKey_Proptech;
 END TRY
 BEGIN CATCH
 IF EXISTS(SELECT 1 FROM sys.openkeys WHERE key_name='SymKey_Proptech') CLOSE SYMMETRIC KEY SymKey_Proptech;
 THROW;
 END CATCH
END;
GO

CREATE OR ALTER PROCEDURE dbo.app_ClientesGuardar
@json NVARCHAR(MAX)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 IF ISJSON(@json)<>1 THROW 51010, 'Datos inválidos.',1;
 DECLARE @id INT=TRY_CONVERT(INT,JSON_VALUE(@json,'$.cod_cliente'));
 DECLARE @nombre VARCHAR(150);
 DECLARE @tipo_identificacion VARCHAR(50);
 DECLARE @num_identificacion VARCHAR(255);
 DECLARE @telefono VARCHAR(255);
 DECLARE @correo_electronico VARCHAR(255);
 DECLARE @provincia VARCHAR(50);
 DECLARE @canton VARCHAR(50);
 DECLARE @distrito VARCHAR(50);
 DECLARE @barrio VARCHAR(50);
 DECLARE @profesion_oficio VARCHAR(150);
 DECLARE @actividad_economica VARCHAR(150);
 DECLARE @estado CHAR(1);
 SELECT @nombre=nombre,@tipo_identificacion=tipo_identificacion,@num_identificacion=num_identificacion,@telefono=telefono,@correo_electronico=correo_electronico,@provincia=provincia,@canton=canton,@distrito=distrito,@barrio=barrio,@profesion_oficio=profesion_oficio,@actividad_economica=actividad_economica,@estado=estado FROM OPENJSON(@json) WITH (nombre VARCHAR(150),tipo_identificacion VARCHAR(50),num_identificacion VARCHAR(255),telefono VARCHAR(255),correo_electronico VARCHAR(255),provincia VARCHAR(50),canton VARCHAR(50),distrito VARCHAR(50),barrio VARCHAR(50),profesion_oficio VARCHAR(150),actividad_economica VARCHAR(150),estado CHAR(1));
 IF @nombre IS NULL OR LEN(LTRIM(RTRIM(@nombre)))=0 OR LEN(JSON_VALUE(@json,'$.nombre'))>150 OR @tipo_identificacion IS NULL OR LEN(LTRIM(RTRIM(@tipo_identificacion)))=0 OR LEN(JSON_VALUE(@json,'$.tipo_identificacion'))>50 OR @num_identificacion IS NULL OR LEN(LTRIM(RTRIM(@num_identificacion)))=0 OR LEN(JSON_VALUE(@json,'$.num_identificacion'))>255 OR @telefono IS NULL OR LEN(LTRIM(RTRIM(@telefono)))=0 OR LEN(JSON_VALUE(@json,'$.telefono'))>255 OR @correo_electronico IS NULL OR LEN(LTRIM(RTRIM(@correo_electronico)))=0 OR LEN(JSON_VALUE(@json,'$.correo_electronico'))>255 OR @provincia IS NULL OR LEN(LTRIM(RTRIM(@provincia)))=0 OR LEN(JSON_VALUE(@json,'$.provincia'))>50 OR @canton IS NULL OR LEN(LTRIM(RTRIM(@canton)))=0 OR LEN(JSON_VALUE(@json,'$.canton'))>50 OR @distrito IS NULL OR LEN(LTRIM(RTRIM(@distrito)))=0 OR LEN(JSON_VALUE(@json,'$.distrito'))>50 OR @barrio IS NULL OR LEN(LTRIM(RTRIM(@barrio)))=0 OR LEN(JSON_VALUE(@json,'$.barrio'))>50 OR @profesion_oficio IS NULL OR LEN(LTRIM(RTRIM(@profesion_oficio)))=0 OR LEN(JSON_VALUE(@json,'$.profesion_oficio'))>150 OR @actividad_economica IS NULL OR LEN(LTRIM(RTRIM(@actividad_economica)))=0 OR LEN(JSON_VALUE(@json,'$.actividad_economica'))>150 OR @estado IS NULL OR LEN(LTRIM(RTRIM(@estado)))=0 OR LEN(JSON_VALUE(@json,'$.estado'))>1 THROW 51010, 'Completa todos los campos y respeta las longitudes permitidas.', 1;
 IF @estado NOT IN ('A','I') THROW 51011, 'Estado inválido.',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 OPEN SYMMETRIC KEY SymKey_Proptech DECRYPTION BY CERTIFICATE Cert_Proptech;
 IF @id IS NULL
 BEGIN
 INSERT dbo.Clientes(nombre,tipo_identificacion,num_identificacion,telefono,correo_electronico,provincia,canton,distrito,barrio,profesion_oficio,actividad_economica,estado) VALUES(@nombre,@tipo_identificacion,ENCRYPTBYKEY(KEY_GUID('SymKey_Proptech'),@num_identificacion),ENCRYPTBYKEY(KEY_GUID('SymKey_Proptech'),@telefono),ENCRYPTBYKEY(KEY_GUID('SymKey_Proptech'),@correo_electronico),@provincia,@canton,@distrito,@barrio,@profesion_oficio,@actividad_economica,@estado);
 SET @id=SCOPE_IDENTITY();
 END
 ELSE BEGIN
 UPDATE dbo.Clientes SET nombre=@nombre,tipo_identificacion=@tipo_identificacion,num_identificacion=ENCRYPTBYKEY(KEY_GUID('SymKey_Proptech'),@num_identificacion),telefono=ENCRYPTBYKEY(KEY_GUID('SymKey_Proptech'),@telefono),correo_electronico=ENCRYPTBYKEY(KEY_GUID('SymKey_Proptech'),@correo_electronico),provincia=@provincia,canton=@canton,distrito=@distrito,barrio=@barrio,profesion_oficio=@profesion_oficio,actividad_economica=@actividad_economica,estado=@estado WHERE cod_cliente=@id;
 IF @@ROWCOUNT=0 THROW 51004, 'El registro ya no existe.',1;
 END
 CLOSE SYMMETRIC KEY SymKey_Proptech;
 COMMIT;
 SELECT @id AS id;
 END TRY
 BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 IF EXISTS(SELECT 1 FROM sys.openkeys WHERE key_name='SymKey_Proptech') CLOSE SYMMETRIC KEY SymKey_Proptech;
 THROW;
 END CATCH
END;
GO

CREATE OR ALTER PROCEDURE dbo.app_ClientesEliminar
@id INT
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 DELETE dbo.Clientes WHERE cod_cliente=@id;
 IF @@ROWCOUNT=0 THROW 51004, 'El registro ya no existe.',1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.app_NotasListar

AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 SELECT cod_nota,cod_factura,tipo,motivo,fecha FROM dbo.NotasCreditoDebito ORDER BY cod_nota DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.app_NotasGuardar
@json NVARCHAR(MAX)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 IF ISJSON(@json)<>1 THROW 51010, 'Datos inválidos.',1;
 DECLARE @id INT=TRY_CONVERT(INT,JSON_VALUE(@json,'$.cod_nota'));
 DECLARE @cod_factura INT;
 DECLARE @tipo CHAR(1);
 DECLARE @motivo VARCHAR(255);
 SELECT @cod_factura=cod_factura,@tipo=tipo,@motivo=motivo FROM OPENJSON(@json) WITH (cod_factura INT,tipo CHAR(1),motivo VARCHAR(255));
 IF @cod_factura IS NULL OR @tipo IS NULL OR LEN(LTRIM(RTRIM(@tipo)))=0 OR LEN(JSON_VALUE(@json,'$.tipo'))>1 OR @motivo IS NULL OR LEN(LTRIM(RTRIM(@motivo)))=0 OR LEN(JSON_VALUE(@json,'$.motivo'))>255 THROW 51010, 'Completa todos los campos y respeta las longitudes permitidas.', 1;
 IF @tipo NOT IN ('C','D') THROW 51011, 'Tipo de nota inválido.',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 IF @id IS NULL
 BEGIN
 INSERT dbo.NotasCreditoDebito(cod_factura,tipo,motivo) VALUES(@cod_factura,@tipo,@motivo);
 SET @id=SCOPE_IDENTITY();
 END
 ELSE BEGIN
 UPDATE dbo.NotasCreditoDebito SET cod_factura=@cod_factura,tipo=@tipo,motivo=@motivo WHERE cod_nota=@id;
 IF @@ROWCOUNT=0 THROW 51004, 'El registro ya no existe.',1;
 END
 COMMIT;
 SELECT @id AS id;
 END TRY
 BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW;
 END CATCH
END;
GO

CREATE OR ALTER PROCEDURE dbo.app_NotasEliminar
@id INT
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 DELETE dbo.NotasCreditoDebito WHERE cod_nota=@id;
 IF @@ROWCOUNT=0 THROW 51004, 'El registro ya no existe.',1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.app_FacturasListar

AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 SELECT f.*, c.nombre AS cliente FROM dbo.Facturas f JOIN dbo.Clientes c ON c.cod_cliente=f.cod_cliente ORDER BY f.cod_factura DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.app_FacturaDetalle
@id INT
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 SELECT d.*, p.descripcion FROM dbo.FacturasDetalle d JOIN dbo.ProductosServicios p ON p.cod_cabys=d.cod_cabys WHERE cod_factura=@id;
END;
GO

CREATE OR ALTER PROCEDURE dbo.app_FacturasGuardar
@json NVARCHAR(MAX)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 IF ISJSON(@json)<>1 THROW 51010, 'Datos inválidos.',1;
 DECLARE @id INT, @cliente INT, @condicion VARCHAR(20), @pago VARCHAR(50), @moneda VARCHAR(10), @cambio DECIMAL(18,4), @obs VARCHAR(500);
 SELECT @id=cod_factura,@cliente=cod_cliente,@condicion=condicion_venta,@pago=medio_pago,@moneda=moneda,@cambio=tipo_cambio,@obs=observaciones
 FROM OPENJSON(@json) WITH(cod_factura INT,cod_cliente INT,condicion_venta VARCHAR(20),medio_pago VARCHAR(50),moneda VARCHAR(10),tipo_cambio DECIMAL(18,4),observaciones VARCHAR(500));
 IF @cliente IS NULL OR @condicion IS NULL OR @condicion NOT IN ('CREDITO','CONTADO') OR @pago IS NULL OR @pago NOT IN ('EFECTIVO','TARJETA','CHEQUE','TRANSFERENCIA','SINPE MOVIL','OTROS')
 OR @moneda IS NULL OR @moneda NOT IN ('CRC','USD') OR @cambio IS NULL OR @cambio<=0 OR (@moneda='CRC' AND @cambio<>1)
 OR LEN(JSON_VALUE(@json,'$.observaciones'))>500 THROW 51011, 'Revisa cliente, pago, moneda y tipo de cambio (CRC = 1).',1;
 DECLARE @lineas TABLE(cod_cabys VARCHAR(20),cantidad DECIMAL(18,2),monto DECIMAL(18,2),impuesto DECIMAL(18,2));
 INSERT @lineas(cod_cabys,cantidad) SELECT cod_cabys,cantidad FROM OPENJSON(@json,'$.detalles') WITH(cod_cabys VARCHAR(20),cantidad DECIMAL(18,2));
 IF NOT EXISTS(SELECT 1 FROM @lineas) OR EXISTS(SELECT 1 FROM @lineas WHERE cantidad IS NULL OR cantidad<=0 OR cod_cabys IS NULL)
 THROW 51012, 'Agrega al menos un producto con cantidad positiva.',1;
 IF EXISTS(SELECT cod_cabys FROM @lineas GROUP BY cod_cabys HAVING COUNT(*)>1) THROW 51012, 'No repitas productos en la factura.',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 IF NOT EXISTS(SELECT 1 FROM dbo.Clientes WITH(UPDLOCK,HOLDLOCK) WHERE cod_cliente=@cliente AND estado='A') THROW 51012, 'Selecciona un cliente activo.',1;
 IF EXISTS(SELECT 1 FROM @lineas l LEFT JOIN dbo.ProductosServicios p WITH(UPDLOCK,HOLDLOCK) ON p.cod_cabys=l.cod_cabys
 LEFT JOIN dbo.TiposImpuesto t WITH(UPDLOCK,HOLDLOCK) ON t.cod_tipo_impuesto=p.cod_tipo_impuesto
 WHERE p.cod_cabys IS NULL OR p.estado<>'A' OR t.estado<>'A') THROW 51012, 'Hay productos o impuestos inexistentes o inactivos.',1;
 UPDATE l SET monto=ROUND(l.cantidad*p.precio/@cambio,2),
 impuesto=ROUND(ROUND(l.cantidad*p.precio/@cambio,2)*t.porcentaje/100+l.cantidad*t.tarifa/@cambio,2)
 FROM @lineas l JOIN dbo.ProductosServicios p ON p.cod_cabys=l.cod_cabys JOIN dbo.TiposImpuesto t ON t.cod_tipo_impuesto=p.cod_tipo_impuesto;
 DECLARE @subtotal DECIMAL(18,2),@impuestos DECIMAL(18,2);
 SELECT @subtotal=SUM(monto),@impuestos=SUM(impuesto) FROM @lineas;
 IF @id IS NULL BEGIN
 INSERT dbo.Facturas(cod_cliente,condicion_venta,medio_pago,moneda,tipo_cambio,observaciones,subtotal,total_impuestos,monto_total)
 VALUES(@cliente,@condicion,@pago,@moneda,@cambio,@obs,@subtotal,@impuestos,@subtotal+@impuestos);
 SET @id=SCOPE_IDENTITY();
 END
 ELSE BEGIN
 UPDATE dbo.Facturas SET cod_cliente=@cliente,condicion_venta=@condicion,medio_pago=@pago,moneda=@moneda,tipo_cambio=@cambio,observaciones=@obs,
 subtotal=@subtotal,total_impuestos=@impuestos,monto_total=@subtotal+@impuestos WHERE cod_factura=@id;
 IF @@ROWCOUNT=0 THROW 51004, 'La factura ya no existe.',1;
 DELETE dbo.FacturasDetalle WHERE cod_factura=@id;
 END
 INSERT dbo.FacturasDetalle(cod_factura,cod_cabys,cantidad,monto_linea) SELECT @id,cod_cabys,cantidad,monto FROM @lineas;
 COMMIT;
 SELECT @id id;
 END TRY
 BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW;
 END CATCH
END;
GO

CREATE OR ALTER PROCEDURE dbo.app_FacturasEliminar
@id INT
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
 BEGIN TRANSACTION;
 IF EXISTS(SELECT 1 FROM dbo.NotasCreditoDebito WITH(UPDLOCK,HOLDLOCK) WHERE cod_factura=@id) THROW 51012, 'Elimina primero las notas asociadas a esta factura.',1;
 DELETE dbo.FacturasDetalle WHERE cod_factura=@id;
 DELETE dbo.Facturas WHERE cod_factura=@id;
 IF @@ROWCOUNT=0 THROW 51004, 'La factura ya no existe.',1;
 COMMIT;
 END TRY
 BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW;
 END CATCH
END;
GO

GRANT EXECUTE ON dbo.app_Ingresar TO db_Administrador;

GRANT EXECUTE ON dbo.app_Salir TO db_Administrador;

GRANT EXECUTE ON dbo.app_Ingresar TO db_Digitador;

GRANT EXECUTE ON dbo.app_Salir TO db_Digitador;

GRANT EXECUTE ON dbo.app_Ingresar TO db_Consulta;

GRANT EXECUTE ON dbo.app_Salir TO db_Consulta;

GRANT EXECUTE ON dbo.app_ImpuestosListar TO db_Administrador;

GRANT EXECUTE ON dbo.app_ImpuestosListar TO db_Digitador;

DENY EXECUTE ON dbo.app_ImpuestosListar TO db_Consulta;

GRANT EXECUTE ON dbo.app_ImpuestosGuardar TO db_Administrador;

DENY EXECUTE ON dbo.app_ImpuestosGuardar TO db_Digitador;

DENY EXECUTE ON dbo.app_ImpuestosGuardar TO db_Consulta;

GRANT EXECUTE ON dbo.app_ImpuestosEliminar TO db_Administrador;

DENY EXECUTE ON dbo.app_ImpuestosEliminar TO db_Digitador;

DENY EXECUTE ON dbo.app_ImpuestosEliminar TO db_Consulta;

GRANT EXECUTE ON dbo.app_NotasListar TO db_Administrador;

GRANT EXECUTE ON dbo.app_NotasListar TO db_Digitador;

DENY EXECUTE ON dbo.app_NotasListar TO db_Consulta;

GRANT EXECUTE ON dbo.app_NotasGuardar TO db_Administrador;

GRANT EXECUTE ON dbo.app_NotasGuardar TO db_Digitador;

DENY EXECUTE ON dbo.app_NotasGuardar TO db_Consulta;

GRANT EXECUTE ON dbo.app_NotasEliminar TO db_Administrador;

DENY EXECUTE ON dbo.app_NotasEliminar TO db_Digitador;

DENY EXECUTE ON dbo.app_NotasEliminar TO db_Consulta;

GRANT EXECUTE ON dbo.app_FacturasListar TO db_Administrador;

GRANT EXECUTE ON dbo.app_FacturasListar TO db_Digitador;

DENY EXECUTE ON dbo.app_FacturasListar TO db_Consulta;

GRANT EXECUTE ON dbo.app_FacturasGuardar TO db_Administrador;

GRANT EXECUTE ON dbo.app_FacturasGuardar TO db_Digitador;

DENY EXECUTE ON dbo.app_FacturasGuardar TO db_Consulta;

GRANT EXECUTE ON dbo.app_FacturasEliminar TO db_Administrador;

DENY EXECUTE ON dbo.app_FacturasEliminar TO db_Digitador;

DENY EXECUTE ON dbo.app_FacturasEliminar TO db_Consulta;

GRANT EXECUTE ON dbo.app_ProductosListar TO db_Administrador;

GRANT EXECUTE ON dbo.app_ProductosListar TO db_Digitador;

DENY EXECUTE ON dbo.app_ProductosListar TO db_Consulta;

GRANT EXECUTE ON dbo.app_ProductosGuardar TO db_Administrador;

DENY EXECUTE ON dbo.app_ProductosGuardar TO db_Digitador;

DENY EXECUTE ON dbo.app_ProductosGuardar TO db_Consulta;

GRANT EXECUTE ON dbo.app_ProductosEliminar TO db_Administrador;

DENY EXECUTE ON dbo.app_ProductosEliminar TO db_Digitador;

DENY EXECUTE ON dbo.app_ProductosEliminar TO db_Consulta;

GRANT EXECUTE ON dbo.app_ClientesListar TO db_Administrador;

GRANT EXECUTE ON dbo.app_ClientesListar TO db_Digitador;

DENY EXECUTE ON dbo.app_ClientesListar TO db_Consulta;

GRANT EXECUTE ON dbo.app_ClientesGuardar TO db_Administrador;

GRANT EXECUTE ON dbo.app_ClientesGuardar TO db_Digitador;

DENY EXECUTE ON dbo.app_ClientesGuardar TO db_Consulta;

GRANT EXECUTE ON dbo.app_ClientesEliminar TO db_Administrador;

DENY EXECUTE ON dbo.app_ClientesEliminar TO db_Digitador;

DENY EXECUTE ON dbo.app_ClientesEliminar TO db_Consulta;

GRANT EXECUTE ON dbo.app_FacturaDetalle TO db_Administrador;

GRANT EXECUTE ON dbo.app_FacturaDetalle TO db_Digitador;

GRANT EXECUTE ON dbo.app_Accesos TO db_Administrador;

GRANT EXECUTE ON dbo.app_Accesos TO db_Consulta;

GRANT EXECUTE ON dbo.usp_InsertarCliente TO db_Digitador;

GO

CREATE OR ALTER PROCEDURE dbo.usp_ReporteFacturas
    @FechaDesde DATE,
    @FechaHasta DATE
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF @FechaDesde IS NULL OR @FechaHasta IS NULL THROW 51005, 'Debe indicar las dos fechas.', 1;
        IF @FechaDesde > @FechaHasta THROW 51006, 'La fecha inicial no puede superar la final.', 1;
            
        OPEN SYMMETRIC KEY SymKey_Proptech DECRYPTION BY CERTIFICATE Cert_Proptech;

        SELECT
            c.nombre AS nombre_cliente,
            CONVERT(VARCHAR(255), DECRYPTBYKEY(c.num_identificacion)) AS num_identificacion,
            c.actividad_economica,
            f.cod_factura AS numero_factura,
            f.fecha,
            f.moneda,
            f.subtotal,
            f.total_impuestos,
            f.monto_total AS total_factura
        FROM dbo.Facturas f
        INNER JOIN dbo.Clientes c ON f.cod_cliente = c.cod_cliente
        WHERE f.fecha >= @FechaDesde
          AND f.fecha < DATEADD(DAY, 1, @FechaHasta)
        ORDER BY f.fecha;

        CLOSE SYMMETRIC KEY SymKey_Proptech;
    END TRY
    BEGIN CATCH
        IF EXISTS (SELECT 1 FROM sys.openkeys WHERE key_name = 'SymKey_Proptech') 
            CLOSE SYMMETRIC KEY SymKey_Proptech;
        THROW;
    END CATCH
END;
GO

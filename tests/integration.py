import json, re, urllib.request, urllib.error, http.cookiejar, os
from pathlib import Path
source=Path(os.environ.get('PROPTECH_SEED_SCRIPT',r'D:/temporada 4/Bases 2/Proyecto/Script Proyecto BDII.sql')).read_text(encoding='utf-8-sig')
credentials=dict(re.findall(r"CREATE LOGIN (\w+) WITH PASSWORD = '([^']+)'",source))
class Client:
 def __init__(self):
  self.http=urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()));self.csrf=''
  self.csrf=self.call('/auth/me')['csrf']
 def call(self,path,method='GET',data=None,status=200,csrf=True):
  request=urllib.request.Request('http://127.0.0.1:8080/api'+path,data=None if data is None else json.dumps(data).encode(),method=method,headers={'Content-Type':'application/json',**({'X-CSRF-Token':self.csrf} if csrf else {})})
  try:
   with self.http.open(request) as r: code=r.status; body=json.load(r)
  except urllib.error.HTTPError as e: code=e.code;body=json.load(e)
  assert code==status,(path,code,body)
  return body
 def login(self,name):
  response=self.call('/auth/login','POST',{'username':name,'password':credentials[name],'terminal':'PRUEBA-APP'});self.csrf=response['csrf'];return response
admin=Client();admin.call('/datos/clientes',status=401)
admin.call('/auth/login','POST',{},status=403,csrf=False)
admin.call('/auth/login','POST',{'username':'LoginAdmin','password':'incorrecta','terminal':'TEST'},status=401)
assert admin.login('LoginAdmin')['role']=='Administrador'
digit=Client();assert digit.login('LoginDigitador')['role']=='Digitador'
reader=Client();assert reader.login('LoginConsulta')['role']=='Consulta'
created=[]
def save(entity,data,client=admin):return client.call('/datos/'+entity,'POST',data)[0]['id']
try:
 tax=save('impuestos',{'descripcion':'PRUEBA APP','porcentaje':13,'tarifa':0,'estado':'A'});created.append(('impuestos',tax))
 product={'cod_cabys':'TEST-APP-2026','descripcion':'Prueba de integracion','unidad_medida':'Unidad','precio':100,'cod_tipo_impuesto':tax,'estado':'A','nuevo':True}
 save('productos',product);created.append(('productos',product['cod_cabys']))
 product.update(nuevo=False,descripcion='Producto actualizado');save('productos',product)
 save('impuestos',{'cod_tipo_impuesto':tax,'descripcion':'Impuesto actualizado','porcentaje':13,'tarifa':0,'estado':'A'})
 customer={'nombre':"Prueba O'Brien '; DROP TABLE Clientes;--",'tipo_identificacion':'Física','num_identificacion':'1-TEST','telefono':'8888-0000','correo_electronico':'test@example.com','provincia':'San José','canton':'Central','distrito':'Carmen','barrio':'Prueba','profesion_oficio':'QA','actividad_economica':'Pruebas','estado':'A'}
 cid=save('clientes',customer,digit);created.append(('clientes',cid));customer['cod_cliente']=cid
 found=next(r for r in admin.call('/datos/clientes') if r['cod_cliente']==cid)
 assert found['num_identificacion']==customer['num_identificacion'] and found['nombre']==customer['nombre']
 customer['nombre']='Prueba actualizada';save('clientes',customer,digit)
 invoice={'cod_cliente':cid,'condicion_venta':'CONTADO','medio_pago':'SINPE MOVIL','moneda':'CRC','tipo_cambio':1,'observaciones':'Prueba automatizada','detalles':[{'cod_cabys':product['cod_cabys'],'cantidad':2}]}
 fid=save('facturas',invoice,digit);created.append(('facturas',fid));invoice['cod_factura']=fid
 found=next(r for r in admin.call('/datos/facturas') if r['cod_factura']==fid)
 assert found['subtotal']==200 and found['total_impuestos']==26 and found['monto_total']==226,found
 invoice['detalles'][0]['cantidad']=3;save('facturas',invoice,digit)
 assert digit.call(f'/facturas/{fid}/detalle')[0]['cantidad']==3
 invoice['detalles'][0]['cantidad']=-1;digit.call('/datos/facturas','POST',invoice,status=400)
 assert digit.call(f'/facturas/{fid}/detalle')[0]['cantidad']==3
 invoice['detalles'][0]['cantidad']=3;invoice['detalles'].append(invoice['detalles'][0].copy());digit.call('/datos/facturas','POST',invoice,status=400)
 invoice['detalles']=invoice['detalles'][:1];invoice.update(moneda='USD',tipo_cambio=500);save('facturas',invoice,digit)
 usd=next(r for r in reader.call('/reportes/facturas?desde=2020-01-01&hasta=2030-12-31') if r['numero_factura']==fid)
 assert usd['moneda']=='USD' and usd['total_factura']==0.68,usd
 note={'cod_factura':fid,'tipo':'C','motivo':'Prueba'};nid=save('notas',note,digit);created.append(('notas',nid));note.update(cod_nota=nid,motivo='Prueba editada');save('notas',note,digit)
 admin.call(f'/datos/facturas/{fid}','DELETE',status=400)
 digit.call(f'/datos/clientes/{cid}','DELETE',status=403)
 digit.call('/datos/impuestos','POST',{},status=403)
 digit.call('/reportes/seguridad',status=403)
 reader.call('/datos/clientes',status=403)
 reader.call('/datos/notas','POST',note,status=403)
 for report in ['clientes','facturas','auditoria','seguridad','accesos']:
  assert isinstance(reader.call('/reportes/'+report+'?desde=2020-01-01&hasta=2030-12-31'),list)
 for client in [digit,reader]:client.call('/auth/logout','POST');client.call('/datos/facturas',status=401)
 entries=admin.call('/reportes/accesos')
 assert all(next(r for r in entries if r['nombre_usuario']==user)['fecha_hora_salida'] for user in ['LoginDigitador','LoginConsulta'])
 print('PASS: SQL login, CSRF, all CRUD modules, encrypted client roundtrip, invoice totals and detail update, invalid data rollback, duplicate lines, FK protection, three SQL roles, five reports, logout and access log.')
finally:
 for entity,id in reversed(created):admin.call(f'/datos/{entity}/{id}','DELETE')
 for client in [digit,reader,admin]:
  try:client.call('/auth/logout','POST')
  except Exception:pass

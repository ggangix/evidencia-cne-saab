# Evidencia: registros en el REP de la consulta popular del CNE

Respuestas del API oficial `consultapopular.cne.gob.ve` para dos cédulas venezolanas:

| Cédula | Persona |
|---|---|
| V-21.495.350 | Alex Saab |
| V-36.893.134 | Camila Fabri |

Cada carpeta en `capturas/<fecha UTC>/` tiene:

- `V<cedula>.json`: respuesta tal cual la devolvió el servidor
- `V<cedula>.headers`: cabeceras HTTP de la respuesta, incluida la fecha del servidor (`Date`)
- `V<cedula>.curl-trace.txt`: traza de la conexión: petición enviada, TLS y tiempos
- `token.json` / `token.headers`: token de sesión emitido por el propio API para la consulta
- `tls-cadena.pem.txt` / `tls-resumen.txt`: certificado que presentó el servidor
- `SHA256SUMS` (+ `SHA256SUMS.ots`): hashes de todo lo anterior, sellados en Bitcoin con OpenTimestamps

## Cómo verificar

```sh
cd capturas/<fecha>
shasum -a 256 -c SHA256SUMS      # los archivos no cambiaron
ots verify SHA256SUMS.ots        # existían en la fecha que indica el sello
```

El sello OpenTimestamps prueba que estos archivos existían en esa fecha. Para repetir la consulta,
usa `./capturar.sh` o el formulario de consultapopular.cne.gob.ve.

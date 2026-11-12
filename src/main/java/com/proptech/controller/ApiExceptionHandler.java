package com.proptech.controller;

import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import java.sql.SQLException;
import java.util.Map;

@RestControllerAdvice
public class ApiExceptionHandler {
    @ExceptionHandler(SQLException.class)
    public ResponseEntity<Map<String, String>> sql(SQLException error) {
        int code = error.getErrorCode();
        HttpStatus status = HttpStatus.BAD_REQUEST;
        String message;
        if (code == 18456) { status = HttpStatus.UNAUTHORIZED; message = "Usuario o contraseña incorrectos."; }
        else if (code == 229 || code == 230 || code == 51003) { status = HttpStatus.FORBIDDEN; message = "Tu rol no permite esta operación."; }
        else if (code == 547) { status = HttpStatus.CONFLICT; message = "El registro tiene relaciones o una referencia inválida. Revisa sus datos; puedes desactivarlo si está en uso."; }
        else if (code == 2627 || code == 2601) message = "Ya existe un registro con ese código.";
        else if (code >= 51000 && code < 52000) message = error.getMessage();
        else if (code == 2812) message = "Falta instalar database/01_app.sql en ProptechDB.";
        else if (code == 0) { status = HttpStatus.SERVICE_UNAVAILABLE; message = "No se pudo conectar con SQL Server. Verifica la instancia y vuelve a iniciar sesión."; }
        else message = "No se pudo guardar o consultar. Revisa campos, longitudes y valores numéricos.";
        return ResponseEntity.status(status).body(Map.of("message", message));
    }

    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<Map<String, String>> status(ResponseStatusException error) {
        return ResponseEntity.status(error.getStatusCode()).body(Map.of("message", error.getReason() == null ? "Solicitud inválida." : error.getReason()));
    }

}

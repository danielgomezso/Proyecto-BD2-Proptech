package com.proptech.service;

import com.proptech.model.SqlSession;
import com.proptech.repository.ProcedureRepository;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;
import java.sql.SQLException;
import java.util.*;

@Service
public class BillingService {
    private static final Map<String, String> ENTITIES = Map.of("clientes", "Clientes", "impuestos", "Impuestos",
            "productos", "Productos", "facturas", "Facturas", "notas", "Notas");
    private final ProcedureRepository repository;
    public BillingService(ProcedureRepository repository) { this.repository = repository; }

    public List<Map<String, Object>> crud(SqlSession user, String entity, String action, Object... args) throws SQLException {
        String name = ENTITIES.get(entity);
        if (name == null) throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Módulo inexistente.");
        return repository.execute(user, "app_" + name + action, args);
    }

    public List<Map<String, Object>> detail(SqlSession user, int id) throws SQLException {
        return repository.execute(user, "app_FacturaDetalle", id);
    }

    public List<Map<String, Object>> report(SqlSession user, String report, String from, String to, String filter) throws SQLException {
        return switch (report) {
            case "clientes" -> repository.execute(user, "usp_ReporteClientesResumido", from, to, filter);
            case "facturas" -> repository.execute(user, "usp_ReporteFacturas", from, to);
            case "auditoria" -> repository.execute(user, "usp_ReportePistasAuditoria", from, to, filter);
            case "seguridad" -> repository.execute(user, "usp_ReporteConfigSeguridad", filter);
            case "accesos" -> repository.execute(user, "app_Accesos");
            default -> throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Reporte inexistente.");
        };
    }
}

package com.proptech.controller;

import com.proptech.model.SqlSession;
import com.proptech.service.BillingService;
import org.springframework.web.bind.annotation.*;
import java.sql.SQLException;
import java.util.*;

@RestController
@RequestMapping("/api")
public class BillingController {
    private final BillingService service;
    public BillingController(BillingService service) { this.service = service; }

    @GetMapping("/datos/{entity}")
    public List<Map<String, Object>> list(@SessionAttribute("user") SqlSession user, @PathVariable String entity) throws SQLException {
        return service.crud(user, entity, "Listar");
    }

    @PostMapping("/datos/{entity}")
    public List<Map<String, Object>> save(@SessionAttribute("user") SqlSession user, @PathVariable String entity,
                                        @RequestBody String json) throws SQLException {
        return service.crud(user, entity, "Guardar", json);
    }

    @DeleteMapping("/datos/{entity}/{id}")
    public List<Map<String, Object>> delete(@SessionAttribute("user") SqlSession user, @PathVariable String entity,
                                          @PathVariable String id) throws SQLException {
        return service.crud(user, entity, "Eliminar", id);
    }

    @GetMapping("/facturas/{id}/detalle")
    public List<Map<String, Object>> detail(@SessionAttribute("user") SqlSession user, @PathVariable int id) throws SQLException {
        return service.detail(user, id);
    }

    @GetMapping("/reportes/{report}")
    public List<Map<String, Object>> report(@SessionAttribute("user") SqlSession user, @PathVariable String report,
                @RequestParam(required = false) String desde, @RequestParam(required = false) String hasta,
                @RequestParam(required = false) String filtro) throws SQLException {
        return service.report(user, report, desde, hasta, filtro == null || filtro.isBlank() ? null : filtro);
    }
}

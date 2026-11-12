package com.proptech.service;

import com.proptech.model.SqlSession;
import com.proptech.repository.ProcedureRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;
import java.sql.*;
import java.util.Properties;

@Service
public class AuthService {
    private final String url;
    private final ProcedureRepository repository;

    public AuthService(@Value("${spring.datasource.url}") String url, ProcedureRepository repository) {
        this.url = url;
        this.repository = repository;
    }

    public SqlSession login(String username, String password, String terminal, String ip) throws SQLException {
        if (username == null || username.isBlank() || password == null || password.isBlank()
                || terminal == null || terminal.isBlank() || terminal.length() > 128 || username.length() > 128) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Completa usuario, contraseña y terminal.");
        }
        Properties properties = new Properties();
        properties.setProperty("user", username);
        properties.setProperty("password", password);
        properties.setProperty("workstationID", terminal);
        Connection connection = DriverManager.getConnection(url, properties);
        try {
            var result = repository.execute(connection, "app_Ingresar", terminal, ip).getFirst();
            return new SqlSession(connection, result.get("usuario").toString(), result.get("rol").toString(),
                    ((Number) result.get("cod_acceso")).intValue());
        } catch (Exception e) {
            connection.close();
            throw e;
        }
    }
}

package com.proptech.model;

import jakarta.servlet.http.HttpSessionBindingEvent;
import jakarta.servlet.http.HttpSessionBindingListener;
import java.sql.Connection;
import java.sql.SQLException;
import org.slf4j.LoggerFactory;

public class SqlSession implements HttpSessionBindingListener {
    private final Connection connection;
    private final String username;
    private final String role;
    private final int accessId;

    public SqlSession(Connection connection, String username, String role, int accessId) {
        this.connection = connection;
        this.username = username;
        this.role = role;
        this.accessId = accessId;
    }

    public Connection connection() { return connection; }
    public String username() { return username; }
    public String role() { return role; }

    @Override
    public synchronized void valueUnbound(HttpSessionBindingEvent event) {
        try (var statement = connection.prepareCall("{call dbo.app_Salir(?)}")) {
            statement.setInt(1, accessId);
            statement.execute();
        } catch (SQLException e) {
            LoggerFactory.getLogger(SqlSession.class).error("No se pudo registrar la salida del acceso {}", accessId, e);
        } finally {
            try { connection.close(); } catch (SQLException ignored) { }
        }
    }
}

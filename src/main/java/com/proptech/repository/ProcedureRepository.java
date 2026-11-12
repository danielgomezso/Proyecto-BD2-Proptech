package com.proptech.repository;

import com.proptech.model.SqlSession;
import org.springframework.stereotype.Repository;
import java.sql.*;
import java.util.*;

@Repository
public class ProcedureRepository {
    public List<Map<String, Object>> execute(SqlSession session, String procedure, Object... arguments) throws SQLException {
        synchronized (session) {
            return execute(session.connection(), procedure, arguments);
        }
    }

    public List<Map<String, Object>> execute(Connection connection, String procedure, Object... arguments) throws SQLException {
        String placeholders = String.join(",", Collections.nCopies(arguments.length, "?"));
        try (var statement = connection.prepareCall("{call dbo." + procedure + "(" + placeholders + ")}")) {
            for (int i = 0; i < arguments.length; i++) statement.setObject(i + 1, arguments[i]);
            boolean result = statement.execute();
            while (!result && statement.getUpdateCount() != -1) result = statement.getMoreResults();
            List<Map<String, Object>> rows = new ArrayList<>();
            if (result) try (var rs = statement.getResultSet()) {
                var metadata = rs.getMetaData();
                while (rs.next()) {
                    Map<String, Object> row = new LinkedHashMap<>();
                    for (int i = 1; i <= metadata.getColumnCount(); i++) {
                        Object value = rs.getObject(i);
                        if (value instanceof Timestamp date) value = date.toLocalDateTime().toString();
                        row.put(metadata.getColumnLabel(i), value);
                    }
                    rows.add(row);
                }
            }
            return rows;
        }
    }
}

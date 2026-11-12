package com.proptech;

import com.proptech.model.SqlSession;
import org.junit.jupiter.api.Test;
import java.sql.Connection;
import java.sql.CallableStatement;
import java.sql.SQLException;
import static org.mockito.Mockito.*;

class SqlSessionTests {
    @Test
    void expirationRecordsDepartureAndClosesConnection() throws Exception {
        Connection connection = mock(Connection.class);
        CallableStatement statement = mock(CallableStatement.class);
        when(connection.prepareCall("{call dbo.app_Salir(?)}")).thenReturn(statement);
        new SqlSession(connection, "LoginDigitador", "Digitador", 42).valueUnbound(null);
        verify(statement).setInt(1, 42);
        verify(statement).execute();
        verify(connection).close();
    }

    @Test
    void failedDepartureStillReleasesConnection() throws Exception {
        Connection connection = mock(Connection.class);
        when(connection.prepareCall(anyString())).thenThrow(new SQLException("Conexión perdida"));
        new SqlSession(connection, "LoginDigitador", "Digitador", 42).valueUnbound(null);
        verify(connection).close();
    }
}

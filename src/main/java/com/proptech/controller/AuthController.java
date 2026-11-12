package com.proptech.controller;

import com.proptech.config.SessionConfig;
import com.proptech.model.SqlSession;
import com.proptech.service.AuthService;
import jakarta.servlet.http.*;
import org.springframework.web.bind.annotation.*;
import java.sql.SQLException;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {
    private final AuthService auth;
    public AuthController(AuthService auth) { this.auth = auth; }
    public record Login(String username, String password, String terminal) { }

    @GetMapping("/me")
    public Map<String, Object> me(HttpSession session) {
        SqlSession user = (SqlSession) session.getAttribute("user");
        return Map.of("authenticated", user != null, "username", user == null ? "" : user.username(),
                "role", user == null ? "" : user.role(), "csrf", SessionConfig.csrf(session));
    }

    @PostMapping("/login")
    public Map<String, Object> login(@RequestBody Login input, HttpServletRequest request) throws SQLException {
        SqlSession user = auth.login(input.username(), input.password(), input.terminal(), request.getRemoteAddr());
        request.getSession().invalidate();
        HttpSession session = request.getSession(true);
        session.setAttribute("user", user);
        return me(session);
    }

    @PostMapping("/logout")
    public Map<String, Object> logout(HttpSession session) {
        session.invalidate();
        return Map.of("ok", true);
    }
}

package com.proptech.config;

import jakarta.servlet.http.*;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.HandlerInterceptor;
import org.springframework.web.servlet.config.annotation.*;
import java.util.UUID;

@Configuration
public class SessionConfig implements WebMvcConfigurer {
    public static String csrf(HttpSession session) {
        if (session.getAttribute("csrf") == null) session.setAttribute("csrf", UUID.randomUUID().toString());
        return session.getAttribute("csrf").toString();
    }

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(new HandlerInterceptor() {
            @Override
            public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
                response.setHeader("Cache-Control", "no-store");
                response.setHeader("X-Content-Type-Options", "nosniff");
                response.setHeader("X-Frame-Options", "DENY");
                HttpSession session = request.getSession(false);
                if (!request.getMethod().equals("GET") && (session == null || !csrf(session).equals(request.getHeader("X-CSRF-Token")))) {
                    response.sendError(403, "La sesión de seguridad expiró. Recarga la página.");
                    return false;
                }
                if (!request.getRequestURI().startsWith("/api/auth/") && (session == null || session.getAttribute("user") == null)) {
                    response.sendError(401);
                    return false;
                }
                return true;
            }
        }).addPathPatterns("/api/**");
    }
}

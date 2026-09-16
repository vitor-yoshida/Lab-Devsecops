package br.com.labdevsecops.controlador;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import javax.sql.DataSource;

import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * VULNERABILIDADE 1 de 5: SQL INJECTION
 *
 * O que acontece aqui: o texto digitado pelo usuário é colado (concatenado)
 * dentro do comando SQL. Quem digita, portanto, consegue reescrever a
 * consulta do banco de dados.
 *
 * Quem detecta isso no laboratório:
 *   - SpotBugs + FindSecBugs (estágio 1 - SAST) -> regra SQL_INJECTION_JDBC
 *   - Wapiti (estágio 4 - DAST) -> testando a rota com aspas e "OR 1=1"
 */
@RestController
public class ControladorUsuario {

    private final DataSource fonteDeDados;

    public ControladorUsuario(DataSource fonteDeDados) {
        this.fonteDeDados = fonteDeDados;
    }

    @GetMapping(value = "/usuario", produces = MediaType.TEXT_HTML_VALUE)
    public String buscarUsuario(@RequestParam(defaultValue = "1") String id) {

        // VULNERÁVEL: o valor de "id" vem do navegador e entra direto na SQL.
        // Se alguém enviar id = 1 OR 1=1, a consulta vira
        // "SELECT ... WHERE id = 1 OR 1=1" e devolve TODOS os usuários.
        String consulta = "SELECT id, nome, email FROM usuarios WHERE id = " + id;

        StringBuilder resposta = new StringBuilder("<h2>Resultado da consulta</h2>");
        resposta.append("<p>SQL executada: <code>").append(consulta).append("</code></p><ul>");

        try (Connection conexao = fonteDeDados.getConnection();
             Statement comando = conexao.createStatement();
             ResultSet resultado = comando.executeQuery(consulta)) {

            while (resultado.next()) {
                resposta.append("<li>#").append(resultado.getInt("id"))
                        .append(" - ").append(resultado.getString("nome"))
                        .append(" - ").append(resultado.getString("email"))
                        .append("</li>");
            }

        } catch (SQLException erro) {
            // VULNERÁVEL (bônus): mostrar o erro do banco na tela entrega
            // detalhes internos para o atacante. É também o rastro que o
            // Wapiti procura para confirmar o SQL Injection.
            return "<h2>Erro de SQL</h2><pre>" + erro.getMessage() + "</pre>";
        }

        return resposta.append("</ul><p><a href='/'>Voltar</a></p>").toString();
    }
}

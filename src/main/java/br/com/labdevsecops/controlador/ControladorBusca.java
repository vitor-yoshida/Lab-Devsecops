package br.com.labdevsecops.controlador;

import java.io.IOException;
import java.io.PrintWriter;

import javax.servlet.http.HttpServletResponse;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * VULNERABILIDADE 2 de 5: XSS REFLETIDO (Cross-Site Scripting)
 *
 * O que acontece aqui: o texto digitado é devolvido na página como HTML,
 * sem nenhum tratamento. Se a pessoa digitar uma tag de script, o navegador
 * da vítima executa esse script como se fosse do nosso site.
 *
 * Quem detecta isso no laboratório:
 *   - SpotBugs + FindSecBugs (estágio 1 - SAST) -> regra XSS_SERVLET
 *   - Wapiti (estágio 4 - DAST) -> injetando tags e vendo se voltam intactas
 */
@RestController
public class ControladorBusca {

    @GetMapping("/busca")
    public void buscarProduto(@RequestParam(defaultValue = "camiseta") String termo,
                              HttpServletResponse resposta) throws IOException {

        resposta.setContentType("text/html;charset=UTF-8");
        PrintWriter escritor = resposta.getWriter();

        escritor.println("<h2>Busca de produtos</h2>");

        // VULNERÁVEL: o termo digitado é escrito direto no HTML da página.
        // Digitar <script>alert(1)</script> faz o navegador executar o código.
        escritor.println("<p>Nenhum produto encontrado para: " + termo + "</p>");

        escritor.println("<p><a href='/'>Voltar</a></p>");
        escritor.flush();
    }
}

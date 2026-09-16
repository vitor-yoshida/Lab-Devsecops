package br.com.labdevsecops.controlador;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * VULNERABILIDADE 3 de 5: PATH TRAVERSAL (travessia de diretórios)
 *
 * O que acontece aqui: o nome do arquivo pedido pelo usuário é colado no
 * caminho da pasta. Usando "../" a pessoa consegue subir de pasta e ler
 * arquivos do sistema, como /etc/passwd.
 *
 * Quem detecta isso no laboratório:
 *   - SpotBugs + FindSecBugs (estágio 1 - SAST) -> regra PATH_TRAVERSAL_IN
 *   - Wapiti (estágio 4 - DAST) -> módulo "file handling"
 */
@RestController
public class ControladorArquivo {

    /** Pasta onde ficam os arquivos que PODEM ser lidos. */
    private static final String PASTA_PUBLICA = "/app/arquivos/";

    @GetMapping(value = "/arquivo", produces = MediaType.TEXT_HTML_VALUE)
    public String lerArquivo(@RequestParam(defaultValue = "publico.txt") String nome) {

        // VULNERÁVEL: nunca verificamos se "nome" contém "../".
        // Com nome = ../../etc/passwd o caminho final sai da pasta pública.
        String caminhoCompleto = PASTA_PUBLICA + nome;

        try (InputStream entrada = new FileInputStream(caminhoCompleto)) {

            String conteudo = new String(entrada.readAllBytes(), StandardCharsets.UTF_8);
            return "<h2>Conteúdo de " + caminhoCompleto + "</h2>"
                 + "<pre>" + conteudo + "</pre>"
                 + "<p><a href=\"/\">Voltar</a></p>";

        } catch (IOException erro) {
            return "<h2>Não foi possível abrir o arquivo</h2>"
                 + "<pre>" + erro.getMessage() + "</pre>"
                 + "<p><a href=\"/\">Voltar</a></p>";
        }
    }
}

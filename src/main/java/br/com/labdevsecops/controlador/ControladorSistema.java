package br.com.labdevsecops.controlador;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;

import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * VULNERABILIDADE 4 de 5: COMMAND INJECTION (injeção de comando)
 *
 * O que acontece aqui: montamos um comando de terminal juntando texto do
 * usuário e mandamos o sistema operacional executar. Como usamos o shell
 * (/bin/sh -c), o caractere ponto-e-vírgula permite emendar QUALQUER outro
 * comando.
 *
 * Exemplo: host = 127.0.0.1;id  ->  o servidor executa o comando "id".
 *
 * Quem detecta isso no laboratório:
 *   - SpotBugs + FindSecBugs (estágio 1 - SAST) -> regra COMMAND_INJECTION
 *   - Wapiti (estágio 4 - DAST) -> módulo "exec"
 */
@RestController
public class ControladorSistema {

    @GetMapping(value = "/ping", produces = MediaType.TEXT_HTML_VALUE)
    public String pingar(@RequestParam(defaultValue = "127.0.0.1") String host) {

        // VULNERÁVEL: o endereço digitado entra direto na linha de comando.
        String comando = "ping -c 1 " + host;

        StringBuilder saida = new StringBuilder();
        saida.append("<h2>Teste de conectividade</h2>");
        saida.append("<p>Comando executado: <code>").append(comando).append("</code></p><pre>");

        try {
            Process processo = Runtime.getRuntime().exec(new String[] {"/bin/sh", "-c", comando});

            try (BufferedReader leitor = new BufferedReader(
                    new InputStreamReader(processo.getInputStream(), StandardCharsets.UTF_8))) {
                String linha;
                while ((linha = leitor.readLine()) != null) {
                    saida.append(linha).append(System.lineSeparator());
                }
            }

            processo.waitFor();

        } catch (IOException erro) {
            saida.append("Erro ao executar: ").append(erro.getMessage());
        } catch (InterruptedException erro) {
            Thread.currentThread().interrupt();
            saida.append("Execução interrompida.");
        }

        return saida.append("</pre><p><a href=\"/\">Voltar</a></p>").toString();
    }
}

package br.com.labdevsecops.controlador;

import br.com.labdevsecops.servico.ServicoSenha;

import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Rota que expõe as falhas de criptografia da classe ServicoSenha.
 * Serve para a plateia ver, na prática, o token fraco sendo gerado.
 */
@RestController
public class ControladorToken {

    private final ServicoSenha servicoSenha = new ServicoSenha();

    @GetMapping(value = "/token", produces = MediaType.TEXT_HTML_VALUE)
    public String gerarToken() {
        return "<h2>Token de sessão gerado</h2>"
             + "<p>Token: <code>" + servicoSenha.gerarTokenDeSessao() + "</code></p>"
             + "<p>A senha admin virou o hash MD5: <code>"
             + servicoSenha.calcularHashDaSenha("admin") + "</code></p>"
             + "<p>Recarregue a página algumas vezes e repare como o token é previsível.</p>"
             + "<p><a href=\"/\">Voltar</a></p>";
    }
}

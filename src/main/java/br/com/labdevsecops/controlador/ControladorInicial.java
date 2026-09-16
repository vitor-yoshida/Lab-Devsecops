package br.com.labdevsecops.controlador;

import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Página inicial do laboratório.
 *
 * Esta tela não tem nenhuma vulnerabilidade: ela existe para dois motivos.
 *
 * 1) Dar um menu visual para a plateia clicar durante a apresentação.
 * 2) Servir de "isca" para o Wapiti (estágio 4 - DAST). O Wapiti funciona
 *    como um robô que navega no site clicando em tudo. Se as rotas não
 *    estiverem linkadas aqui, ele simplesmente não as encontra e o
 *    relatório vem vazio.
 */
@RestController
public class ControladorInicial {

    @GetMapping(value = "/", produces = MediaType.TEXT_HTML_VALUE)
    public String paginaInicial() {
        return "<!DOCTYPE html>"
             + "<html lang='pt-BR'><head><meta charset='UTF-8'>"
             + "<title>Lab DevSecOps - Aplicacao Vulneravel</title></head><body>"
             + "<h1>Laboratório DevSecOps</h1>"
             + "<p><strong>Aplicação insegura de propósito.</strong> "
             + "Cada link abaixo esconde uma falha de segurança diferente.</p>"

             + "<h2>1. Consultar usuário (SQL Injection)</h2>"
             + "<form action='/usuario' method='get'>"
             + "  <input type='text' name='id' value='1'>"
             + "  <input type='submit' value='Consultar'>"
             + "</form>"
             + "<p>Exemplo de ataque: <a href=\"/usuario?id=1 OR 1=1\">/usuario?id=1 OR 1=1</a></p>"

             + "<h2>2. Buscar produtos (XSS Refletido)</h2>"
             + "<form action='/busca' method='get'>"
             + "  <input type='text' name='termo' value='camiseta'>"
             + "  <input type='submit' value='Buscar'>"
             + "</form>"
             + "<p>Exemplo de ataque: <a href='/busca?termo=teste'>/busca?termo=...</a></p>"

             + "<h2>3. Ler arquivo (Path Traversal)</h2>"
             + "<form action='/arquivo' method='get'>"
             + "  <input type='text' name='nome' value='publico.txt'>"
             + "  <input type='submit' value='Abrir'>"
             + "</form>"
             + "<p>Exemplo de ataque: <a href='/arquivo?nome=../../etc/passwd'>/arquivo?nome=../../etc/passwd</a></p>"

             + "<h2>4. Testar conectividade (Command Injection)</h2>"
             + "<form action='/ping' method='get'>"
             + "  <input type='text' name='host' value='127.0.0.1'>"
             + "  <input type='submit' value='Pingar'>"
             + "</form>"
             + "<p>Exemplo de ataque: <a href='/ping?host=127.0.0.1;id'>/ping?host=127.0.0.1;id</a></p>"

             + "<h2>5. Gerar token de sessão (Criptografia fraca)</h2>"
             + "<p><a href='/token'>/token</a> - usa MD5 e número aleatório previsível</p>"

             + "<hr><p><small>Laboratório educacional. Não exponha esta aplicação na internet.</small></p>"
             + "</body></html>";
    }
}

package br.com.labdevsecops.servico;

import java.math.BigInteger;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Random;

/**
 * VULNERABILIDADE 5 de 5: CRIPTOGRAFIA FRACA E SEGREDO NO CÓDIGO
 *
 * Esta classe concentra três erros clássicos de segurança:
 *   a) Guardar senha escrita dentro do código-fonte;
 *   b) Usar MD5 para proteger senhas (algoritmo quebrado desde 2004);
 *   c) Usar java.util.Random para gerar token de sessão (é previsível).
 *
 * Quem detecta isso no laboratório:
 *   - SpotBugs + FindSecBugs (estágio 1 - SAST), regras:
 *       HARD_CODE_PASSWORD, WEAK_MESSAGE_DIGEST_MD5, PREDICTABLE_RANDOM
 */
public class ServicoSenha {

    // VULNERÁVEL: senha do banco escrita no código. Qualquer pessoa com
    // acesso ao repositório (ou ao arquivo .jar) lê esse valor em segundos.
    private static final String URL_BANCO = "jdbc:h2:mem:labdb";
    private static final String USUARIO_BANCO = "sa";
    private static final String SENHA_BANCO = "SenhaSuperSecreta123";

    /**
     * Abre uma conexão administrativa usando as credenciais fixas acima.
     */
    public Connection conectarComoAdministrador() throws SQLException {
        // VULNERÁVEL: credencial fixa entregue direto para o driver JDBC.
        return DriverManager.getConnection(URL_BANCO, USUARIO_BANCO, SENHA_BANCO);
    }

    /**
     * Transforma a senha em hash para guardar no banco.
     */
    public String calcularHashDaSenha(String senhaEmTextoPuro) {
        try {
            // VULNERÁVEL: MD5 é rápido e quebrado. Hoje se usa BCrypt,
            // SCrypt ou Argon2 para proteger senhas.
            MessageDigest algoritmo = MessageDigest.getInstance("MD5");
            byte[] resumo = algoritmo.digest(senhaEmTextoPuro.getBytes(StandardCharsets.UTF_8));
            return String.format("%032x", new BigInteger(1, resumo));

        } catch (NoSuchAlgorithmException erro) {
            throw new IllegalStateException("Algoritmo de hash indisponível", erro);
        }
    }

    /**
     * Cria o identificador da sessão do usuário logado.
     */
    public String gerarTokenDeSessao() {
        // VULNERÁVEL: java.util.Random é previsível. Conhecendo alguns
        // tokens, um atacante calcula os próximos e sequestra sessões.
        // O correto seria java.security.SecureRandom.
        Random geradorFraco = new Random();
        return Long.toHexString(geradorFraco.nextLong());
    }
}

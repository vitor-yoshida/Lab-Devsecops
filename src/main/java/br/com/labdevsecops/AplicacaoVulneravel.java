package br.com.labdevsecops;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Ponto de partida da aplicação.
 *
 * Esta é a classe que "liga" o servidor web. Quando você roda o programa,
 * o Java começa a execução pelo método main() aqui embaixo.
 *
 * ATENÇÃO: esta aplicação é INSEGURA DE PROPÓSITO. Ela serve de cobaia
 * para as ferramentas de segurança do laboratório. Nunca coloque algo
 * parecido na internet.
 */
@SpringBootApplication
public class AplicacaoVulneravel {

    public static void main(String[] argumentos) {
        SpringApplication.run(AplicacaoVulneravel.class, argumentos);
    }
}

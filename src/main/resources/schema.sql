-- Cria a tabela de usuarios usada pela rota /usuario
DROP TABLE IF EXISTS usuarios;

CREATE TABLE usuarios (
    id    INT PRIMARY KEY,
    nome  VARCHAR(100),
    email VARCHAR(100)
);

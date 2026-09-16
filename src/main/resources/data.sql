-- Dados de exemplo. Repare que o usuario 3 e o administrador:
-- com SQL Injection (id=1 OR 1=1) ele aparece sem precisar de senha.
INSERT INTO usuarios (id, nome, email) VALUES (1, 'Ana Souza',     'ana@exemplo.com.br');
INSERT INTO usuarios (id, nome, email) VALUES (2, 'Bruno Lima',    'bruno@exemplo.com.br');
INSERT INTO usuarios (id, nome, email) VALUES (3, 'ADMIN DO LAB',  'admin@exemplo.com.br');

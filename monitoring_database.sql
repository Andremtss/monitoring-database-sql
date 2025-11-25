/* ---------------------------------------------------------
   Projeto: Banco de Dados de Monitoramento (SRE/Infra)
   Autor: Andrpe Martins
   Descrição: Banco de dados SQL para monitoramento de infraestrutura. Inclui tabelas de hosts, métricas (CPU, RAM, disco) e logs de eventos, além de consultas avançadas com CTEs, Window Functions e detecção de alertas. Projeto ideal para demonstrar domínio técnico em SQL aplicado a SRE/Infra
   Banco de dados para armazenar informações de hosts,
   métricas de CPU/RAM/Disco e logs de eventos.

---------------------------------------------------------- */

/* ===============================
     1. Criar banco de dados
================================= */
CREATE DATABASE IF NOT EXISTS monitoring;
USE monitoring;

/* ===============================
     2. Tabela HOSTS
================================= */
CREATE TABLE hosts (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    hostname VARCHAR(100) NOT NULL,
    ip_address VARCHAR(20) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

/* ===============================
     3. Tabela METRICS
================================= */
CREATE TABLE metrics (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    host_id INT UNSIGNED NOT NULL,
    cpu_usage DECIMAL(5,2),
    ram_usage DECIMAL(5,2),
    disk_usage DECIMAL(5,2),
    collected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    FOREIGN KEY (host_id) REFERENCES hosts(id)
);

/* ===============================
     4. Tabela LOGS
================================= */
CREATE TABLE logs (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    host_id INT UNSIGNED NOT NULL,
    event_type VARCHAR(50),
    message TEXT,
    event_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    FOREIGN KEY (host_id) REFERENCES hosts(id)
);

/* ===============================
     5. Inserir dados 
================================= */

INSERT INTO hosts (hostname, ip_address)
VALUES
('server-app-01', '192.168.0.10'),
('server-app-02', '192.168.0.11'),
('db-prod-01', '192.168.0.20'),
('cache-prod-01', '192.168.0.30'),
('api-gateway-01', '192.168.0.40');


/* Inserindo métricas de teste */

INSERT INTO metrics (host_id, cpu_usage, ram_usage, disk_usage)
VALUES
(1, 65, 70, 80),
(1, 82, 90, 85),
(1, 91, 78, 82),

(2, 35, 40, 50),
(2, 55, 50, 60),
(2, 75, 70, 72),

(3, 95, 85, 90),
(3, 88, 92, 93),

(4, 20, 30, 40),
(4, 25, 35, 38),

(5, 50, 60, 45),
(5, 78, 82, 70);

/* Logs */

INSERT INTO logs (host_id, event_type, message)
VALUES
(1, 'WARNING', 'CPU ultrapassou 80%'),
(1, 'INFO', 'Deploy realizado com sucesso'),
(3, 'ERROR', 'Banco de dados reiniciado inesperadamente'),
(4, 'INFO', 'Cache limpo automaticamente'),
(5, 'WARNING', 'RAM acima de 80%');

/* ===============================
     6. CONSULTAS AVANÇADAS
================================= */

/* ------------------------------
   TOP 10 hosts por CPU média
-------------------------------- */
SELECT h.hostname,
       ROUND(AVG(m.cpu_usage), 2) AS cpu_media
FROM metrics m
JOIN hosts h ON h.id = m.host_id
GROUP BY h.hostname
ORDER BY cpu_media DESC
LIMIT 10;

/* ------------------------------
   Hosts que ficaram acima de 80% da RAM o maior número de vezes
-------------------------------- */
SELECT h.hostname,
       COUNT(*) AS vezes_acima_80
FROM metrics m
JOIN hosts h ON h.id = m.host_id
WHERE m.ram_usage > 80
GROUP BY h.hostname
ORDER BY vezes_acima_80 DESC;

/* ------------------------------
   Alertas por nível de CPU
-------------------------------- */
SELECT h.hostname,
       m.cpu_usage,
       CASE
           WHEN cpu_usage >= 90 THEN 'CRÍTICO'
           WHEN cpu_usage >= 75 THEN 'ALTO'
           ELSE 'NORMAL'
       END AS nivel_alerta
FROM metrics m
JOIN hosts h ON h.id = m.host_id;

/* ------------------------------
   Média móvel de CPU (window function)
-------------------------------- */
SELECT h.hostname,
       m.cpu_usage,
       m.collected_at,
       AVG(m.cpu_usage) OVER (
           PARTITION BY m.host_id
           ORDER BY m.collected_at
           ROWS BETWEEN 5 PRECEDING AND CURRENT ROW
       ) AS media_movel
FROM metrics m
JOIN hosts h ON h.id = m.host_id;

/* ------------------------------
   Tendência semanal (CTE)
-------------------------------- */
WITH semanas AS (
   SELECT host_id,
          DATE_FORMAT(collected_at, '%Y-%u') AS semana,
          AVG(cpu_usage) AS cpu_media
   FROM metrics
   GROUP BY host_id, semana
)
SELECT h.hostname, semana, cpu_media
FROM semanas s
JOIN hosts h ON h.id = s.host_id
ORDER BY semana DESC, cpu_media DESC;


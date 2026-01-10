CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

INSERT INTO users (name) VALUES ('Sem Van Broekhoven')
ON CONFLICT DO NOTHING;

DO $$
BEGIN
    RAISE NOTICE 'SVB Webstack database initialized successfully!';
END $$;

-- 🚀 Dchat - SQL Permanente para Chatwoot Enterprise
-- Este script cria triggers que forçam configurações enterprise permanentemente

-- 1. Função que força valores enterprise
CREATE OR REPLACE FUNCTION force_enterprise_installation_configs()
RETURNS TRIGGER AS $$
BEGIN
    -- Força INSTALLATION_PRICING_PLAN como 'enterprise'
    IF NEW.name = 'INSTALLATION_PRICING_PLAN' THEN
        NEW.serialized_value = to_jsonb('--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess\nvalue: enterprise\n');
        NEW.locked = true;
    END IF;

    -- Força INSTALLATION_PRICING_PLAN_QUANTITY como 9999999
    IF NEW.name = 'INSTALLATION_PRICING_PLAN_QUANTITY' THEN
        NEW.serialized_value = to_jsonb('--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess\nvalue: 9999999\n');
        NEW.locked = true;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Remove trigger anterior se existir
DROP TRIGGER IF EXISTS trg_force_enterprise_configs ON installation_configs;

-- 3. Cria trigger que intercepta INSERT e UPDATE
CREATE TRIGGER trg_force_enterprise_configs
BEFORE INSERT OR UPDATE ON installation_configs
FOR EACH ROW
EXECUTE FUNCTION force_enterprise_installation_configs();

-- 4. Atualiza registros existentes
INSERT INTO installation_configs (name, serialized_value, locked, created_at, updated_at)
VALUES
    ('INSTALLATION_PRICING_PLAN', to_jsonb('--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess\nvalue: enterprise\n'), true, NOW(), NOW()),
    ('INSTALLATION_PRICING_PLAN_QUANTITY', to_jsonb('--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess\nvalue: 9999999\n'), true, NOW(), NOW())
ON CONFLICT (name)
DO UPDATE SET
    serialized_value = EXCLUDED.serialized_value,
    locked = true,
    updated_at = NOW();

-- 5. Verifica se foi aplicado corretamente
SELECT name, serialized_value, locked FROM installation_configs
WHERE name IN ('INSTALLATION_PRICING_PLAN', 'INSTALLATION_PRICING_PLAN_QUANTITY');

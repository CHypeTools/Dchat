# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Dchat unlocks Chatwoot Enterprise features using **permanent PostgreSQL triggers** and configuration modifications. The solution is designed for Docker/Portainer deployments and ensures configurations persist across restarts and updates.

## Project Files

- **`unlock_permanent.rb`** - Main Ruby script (creates triggers + updates configs + patches files)
- **`unlock_permanent.sql`** - Pure SQL alternative (creates triggers only)
- **`docker-unlock.sh`** - Bash helper for Docker environments (auto-detects containers)
- **`DOCKER.md`** - Complete Docker/Portainer guide
- **`README.md`** - Main documentation

## Core Functionality

The permanent unlock solution (`unlock_permanent.rb`) performs three operations:

1. **PostgreSQL Trigger Creation** (Permanent Protection)
   - Creates function `force_enterprise_installation_configs()`
   - Creates trigger `trg_force_enterprise_configs` on `installation_configs` table
   - Intercepts INSERT/UPDATE operations and forces enterprise values
   - Marks configs as `locked = true`

2. **Database Configuration Updates**
   - Sets `INSTALLATION_PRICING_PLAN` to `'enterprise'`
   - Sets `INSTALLATION_PRICING_PLAN_QUANTITY` to `9999999`
   - Clears Redis alert flags via `Redis::Alfred.delete()`

3. **Fallback Value Patching**
   - Locates `lib/chatwoot_hub.rb` in various possible paths
   - Creates timestamped backup before modification
   - Updates hardcoded fallback values using regex substitution:
     - Changes `|| 'community'` to `|| 'enterprise'`
     - Changes `|| 0` to `|| 9999999`

## Execution Context

**Primary Method (Docker/Portainer):**
```bash
curl -sL https://raw.githubusercontent.com/LuizBranco-ClickHype/Dchat/main/docker-unlock.sh | bash
```

**Manual Execution:**
```bash
docker exec -it <container> bash -c "wget -qO- https://raw.githubusercontent.com/LuizBranco-ClickHype/Dchat/main/unlock_permanent.rb | bundle exec rails runner -"
```

**Key Dependencies:**
- Rails environment with `InstallationConfig` model
- PostgreSQL database with trigger support
- Optional: `Redis::Alfred` for cache clearing
- File system access to Chatwoot installation directory

## File Search Logic

The script searches for `chatwoot_hub.rb` in multiple locations:
- `/app/lib/chatwoot_hub.rb`
- `/chatwoot/lib/chatwoot_hub.rb`
- `Rails.root/lib/chatwoot_hub.rb`
- `./lib/chatwoot_hub.rb`

## Error Handling

The script uses defensive error handling with `begin/rescue` blocks to ensure partial success. If database updates fail, it continues with file patching. If file patching fails, database configurations remain applied.

## Trigger Mechanism (Key Feature)

The PostgreSQL trigger ensures **permanent** protection:

```sql
CREATE TRIGGER trg_force_enterprise_configs
BEFORE INSERT OR UPDATE ON installation_configs
FOR EACH ROW
EXECUTE FUNCTION force_enterprise_installation_configs();
```

This trigger intercepts any attempt to modify `INSTALLATION_PRICING_PLAN` or `INSTALLATION_PRICING_PLAN_QUANTITY` and forces them back to enterprise values **before** the change is committed.

## Docker/Portainer Deployment

The `docker-unlock.sh` script automates container detection:
1. Searches for Chatwoot container by name patterns
2. Searches by image name (`chatwoot/chatwoot`)
3. Executes the unlock script inside the detected container
4. Provides restart instructions

## Important Notes

- This modifies commercial licensing restrictions - use in accordance with Chatwoot's license terms
- All file modifications create automatic backups: `chatwoot_hub.rb.backup.YYYYMMDD_HHMMSS`
- Triggers persist across restarts, updates, and container recreations
- Only recreating the PostgreSQL database from scratch will remove triggers
- Container restart required after execution for full effect

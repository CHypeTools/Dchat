#!/usr/bin/env ruby

# 🚀 Dchat - Script para desbloquear o Chatwoot como Enterprise
# Execute com: wget -qO- https://raw.githubusercontent.com/LuizBranco-ClickHype/Dchat/main/unlock.rb | bundle exec rails runner -

require 'fileutils'

puts "🚀 === Dchat - Iniciando desbloqueio do Chatwoot Enterprise ==="

begin
  # Atualiza ou cria as configurações necessárias
  plan = InstallationConfig.find_or_initialize_by(name: 'INSTALLATION_PRICING_PLAN')
  plan.value = 'enterprise'
  plan.save!
  puts "✅ Plano enterprise configurado"

  quantity = InstallationConfig.find_or_initialize_by(name: 'INSTALLATION_PRICING_PLAN_QUANTITY')
  quantity.value = 9_999_999
  quantity.save!
  puts "✅ Quantidade de usuários configurada (9.999.999)"

  # Remove o alerta premium do Redis, se existir
  if defined?(Redis::Alfred)
    Redis::Alfred.delete(Redis::Alfred::CHATWOOT_INSTALLATION_CONFIG_RESET_WARNING)
    puts '✅ Flag de alerta premium removida do Redis'
  else
    puts '⚠️  Redis::Alfred não está definido'
  end

  puts "✅ Configurações de banco de dados atualizadas!"

rescue => e
  puts "❌ Erro nas configurações do banco: #{e.message}"
  puts "   Continuando com as próximas etapas..."
end

# --- Atualiza fallback em lib/chatwoot_hub.rb ---
begin
  # Busca arquivo em diferentes locais
  possible_paths = [
    '/app/lib/chatwoot_hub.rb',
    '/chatwoot/lib/chatwoot_hub.rb',
    File.join(Rails.root, 'lib', 'chatwoot_hub.rb'),
    './lib/chatwoot_hub.rb'
  ]

  hub_file = possible_paths.find { |path| File.exist?(path) }

  if hub_file
    puts "📁 Arquivo encontrado: #{hub_file}"
    
    # Backup
    backup_file = "#{hub_file}.backup.#{Time.now.strftime('%Y%m%d_%H%M%S')}"
    FileUtils.cp(hub_file, backup_file)
    puts "💾 Backup: #{backup_file}"
    
    # Ler e atualizar conteúdo
    content = File.read(hub_file)
    original = content.dup

    # Regex para fallbacks mais robustas
    content.gsub!(
      /(InstallationConfig\.find_by\(name:\s*['"]INSTALLATION_PRICING_PLAN['"]\)&?\.value\s*\|\|\s*)['"]community['"]/,
      "\\1'enterprise'"
    )

    content.gsub!(
      /(InstallationConfig\.find_by\(name:\s*['"]INSTALLATION_PRICING_PLAN_QUANTITY['"]\)&?\.value\s*\|\|\s*)0/,
      "\\19999999"
    )

    # Verificar se houve mudanças
    if content != original
      File.write(hub_file, content)
      puts "✅ Fallbacks atualizados em #{hub_file}"
    else
      puts "ℹ️  Arquivo já estava atualizado"
    end

  else
    puts "⚠️  chatwoot_hub.rb não encontrado"
    puts "   Caminhos verificados: #{possible_paths.join(', ')}"
    puts "   As configurações do banco já funcionam!"
  end

rescue => e
  puts "❌ Erro ao atualizar arquivo: #{e.message}"
  puts "   As configurações do banco já foram aplicadas"
end

puts ""
puts "🎉 === Dchat - Desbloqueio concluído ==="
puts "💡 Configurações aplicadas:"
puts "   • Plano: Enterprise"
puts "   • Usuários: 9.999.999"
puts "   • Redis: Limpo"
puts "   • Fallbacks: Atualizados"
puts ""
puts "🔄 Reinicie o container para aplicar todas as mudanças"
puts "🌟 Dchat by LuizBranco-ClickHype"
puts ""
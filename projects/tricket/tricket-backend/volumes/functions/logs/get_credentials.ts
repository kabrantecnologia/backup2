#!/usr/bin/env deno run --allow-net --allow-read

/**
 * Script utilitário para buscar credenciais de contas Asaas
 * 
 * USO:
 * deno run --allow-net --allow-read get_credentials.ts <profile_id|asaas_account_id>
 * 
 * Exemplos:
 * deno run --allow-net --allow-read get_credentials.ts c0e54584-5691-4f96-879f-c98cd41239b1
 * deno run --allow-net --allow-read get_credentials.ts asaas_123456789
 */

import { getAccountCredentials, listAllCredentials } from './account_creation_logger.ts';

// Configuração - ajustar conforme necessário
const CONFIG = {
  supabaseUrl: Deno.env.get('SUPABASE_URL') || 'http://localhost:54321',
  supabaseServiceRoleKey: Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || 'your-service-role-key'
};

async function main() {
  const args = Deno.args;
  
  if (args.length === 0) {
    console.log('📋 Listando todas as credenciais (últimas 10):');
    const allCredentials = await listAllCredentials(CONFIG, 10);
    
    if (allCredentials.length === 0) {
      console.log('❌ Nenhuma credencial encontrada');
      return;
    }
    
    allCredentials.forEach((cred, index) => {
      console.log(`\n${index + 1}. Conta: ${cred.name || cred.asaas_account_id}`);
      console.log(`   Profile ID: ${cred.profile_id}`);
      console.log(`   Asaas ID: ${cred.asaas_account_id}`);
      console.log(`   Webhook Token: ${cred.webhook_token}`);
      console.log(`   Wallet ID: ${cred.wallet_id}`);
      console.log(`   API Key: ${cred.api_key.substring(0, 8)}...`);
      console.log(`   Criado em: ${new Date(cred.created_at).toLocaleString('pt-BR')}`);
    });
    return;
  }

  const identifier = args[0];
  console.log(`🔍 Buscando credenciais para: ${identifier}`);
  
  const credentials = await getAccountCredentials(CONFIG, identifier);
  
  if (!credentials) {
    console.log('❌ Credenciais não encontradas');
    return;
  }

  console.log('\n✅ Credenciais encontradas:');
  console.log(`📊 Profile ID: ${credentials.profile_id}`);
  console.log(`🏦 Asaas Account ID: ${credentials.asaas_account_id}`);
  console.log(`🔑 Webhook Token: ${credentials.webhook_token}`);
  console.log(`💰 Wallet ID: ${credentials.wallet_id}`);
  console.log(`🔐 API Key: ${credentials.api_key}`);
  console.log(`🌍 Environment: ${credentials.environment}`);
  console.log(`📅 Criado em: ${new Date(credentials.created_at).toLocaleString('pt-BR')}`);
  
  // Formato copiável para configuração manual
  console.log('\n📋 Formato copiável para configuração:');
  console.log(`Webhook Token: ${credentials.webhook_token}`);
  console.log(`API Key: ${credentials.api_key}`);
  console.log(`Wallet ID: ${credentials.wallet_id}`);
}

// Executar se for chamado diretamente
if (import.meta.main) {
  main().catch(console.error);
}

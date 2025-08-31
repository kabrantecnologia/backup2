// supabase/functions/gs1_brasil/index.ts

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const GS1_API_URL = 'https://api.gs1br.org'

// Cache em memória para o token de acesso da GS1
let cachedTokenMemory: { accessToken: string; expiresAt: Date } | null = null

// Função para obter/renovar o token de acesso da API GS1
async function getAccessToken(
  gs1ClientId: string,
  gs1ClientSecret: string,
  gs1UserEmail: string,
  gs1Password: string
): Promise<string> {
  if (cachedTokenMemory && cachedTokenMemory.expiresAt > new Date()) {
    console.info('[gs1_brasil] Using cached GS1 access token.')
    return cachedTokenMemory.accessToken
  }

  console.info('[gs1_brasil] Cached token is invalid or expired. Fetching a new one.')

  const basicAuth = btoa(`${gs1ClientId}:${gs1ClientSecret}`)

  const body = {
    grant_type: 'password',
    username: gs1UserEmail,
    password: gs1Password,
  }

  const response = await fetch(`${GS1_API_URL}/oauth/access-token`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'User-Agent': 'Supabase Edge Function/1.0',
      Authorization: `Basic ${basicAuth}`,
    },
    body: JSON.stringify(body),
  })

  if (!response.ok) {
    const errorBody = await response.text()
    throw new Error(`Erro ao obter token de acesso da GS1: ${response.status} ${errorBody}`)
  }

  const newAuthData = await response.json()
  const expiresAt = new Date()
  expiresAt.setSeconds(expiresAt.getSeconds() + newAuthData.expires_in - 60)

  cachedTokenMemory = {
    accessToken: newAuthData.access_token,
    expiresAt: new Date(new Date().getTime() + newAuthData.expires_in * 1000),
  }
  console.info(`[gs1_brasil] New GS1 access token obtained. Expires at: ${cachedTokenMemory.expiresAt.toISOString()}`)
  return cachedTokenMemory.accessToken
}

serve(async (req) => {
  console.info(`[gs1_brasil] Function invoked with method: ${req.method}`)
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Log para verificar as variáveis de ambiente
    const gs1ClientIdLog = Deno.env.get('GS1_CLIENT_ID') ?? ''
    const gs1ClientSecretLog = Deno.env.get('GS1_CLIENT_SECRET') ?? ''
    const gs1UserEmailLog = Deno.env.get('GS1_USER_EMAIL') ?? ''
    const gs1PasswordLog = Deno.env.get('GS1_PASSWORD') ?? ''
    const gs1SubscriptionKeyLog = Deno.env.get('GS1_SUBSCRIPTION_KEY') ?? ''

    console.info(`[gs1_brasil] Env Var Check - GS1_CLIENT_ID: ${gs1ClientIdLog.substring(0, 4)}...`)
    console.info(`[gs1_brasil] Env Var Check - GS1_CLIENT_SECRET: ${gs1ClientSecretLog ? 'Loaded' : 'MISSING'}`)
    console.info(`[gs1_brasil] Env Var Check - GS1_USER_EMAIL: ${gs1UserEmailLog}`)
    console.info(`[gs1_brasil] Env Var Check - GS1_PASSWORD: ${gs1PasswordLog ? 'Loaded' : 'MISSING'}`)
    console.info(`[gs1_brasil] Env Var Check - GS1_SUBSCRIPTION_KEY: ${gs1SubscriptionKeyLog.substring(0, 4)}...`)

    const payload = await req.json()
    console.info(`[gs1_brasil] Received payload: ${JSON.stringify(payload)}`)

    // Renomeia as chaves do payload para as variáveis internas e garante que gtins seja um array
    const { p_gtins, p_profile_id: user_id } = payload
    const gtins = Array.isArray(p_gtins) ? p_gtins : [p_gtins]

    if (!gtins || gtins.length === 0 || !gtins[0]) {
      return new Response(JSON.stringify({ error: 'O parâmetro gtins deve ser um array e não pode estar vazio.' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 1. Obter segredos e token diretamente do ambiente
    const gs1ClientId = Deno.env.get('GS1_CLIENT_ID')
    const gs1ClientSecret = Deno.env.get('GS1_CLIENT_SECRET')
    const gs1UserEmail = Deno.env.get('GS1_USER_EMAIL')
    const gs1Password = Deno.env.get('GS1_PASSWORD')

    if (!gs1ClientId || !gs1ClientSecret || !gs1UserEmail || !gs1Password) {
      throw new Error('As variáveis de ambiente da GS1 não estão configuradas.')
    }

    const accessToken = await getAccessToken(
      gs1ClientId,
      gs1ClientSecret,
      gs1UserEmail,
      gs1Password
    )

    // 2. Processar todos os GTINs em paralelo para evitar timeout
    console.info('[gs1_brasil] Starting to process each GTIN.')
    const apiPromises = gtins.map(async (gtin: string) => {
      try {
        console.info(`[gs1_brasil] Processing GTIN: ${gtin}`)
        const response = await fetch(
          `${GS1_API_URL}/provider/v2/verified?gtin=${gtin}`,
          {
            method: 'GET',
            headers: {
              'Client_id': gs1ClientId,
              'Access_Token': accessToken,
            },
          }
        )

        if (!response.ok) {
          throw new Error(`API GS1 respondeu com status ${response.status} para o GTIN ${gtin}`)
        }

        const productData = await response.json()

        if (!Array.isArray(productData) || productData.length === 0) {
          console.warn(`[gs1_brasil] Nenhum dado de produto retornado pela API GS1 para o GTIN ${gtin}.`)
          return null
        }

        console.log(`[gs1_brasil] Resposta da API GS1 para o GTIN ${gtin}:`, JSON.stringify(productData[0], null, 2))

        const { data: newResponse, error: insertError } = await supabaseAdmin
          .from('gs1_api_responses')
          .insert({
            gtin: gtin,
            raw_response: productData[0], // Inserindo o primeiro objeto do array
            status: 'PENDING',
            created_by_user_id: user_id,
          })
          .select('id')
          .single()

        if (insertError) {
          const errorDetails = JSON.stringify(insertError, null, 2)
          console.error(`[gs1_brasil] Erro detalhado do Supabase para GTIN ${gtin}: ${errorDetails}`)
          throw new Error(`Erro ao salvar resposta para o GTIN ${gtin}: ${insertError.message}`)
        }

        return newResponse.id
      } catch (error) {
        console.error(`Falha ao processar GTIN ${gtin}: ${error.message}`)
        return null // Retorna nulo em caso de erro, será filtrado
      }
    })

    const settledResults = await Promise.all(apiPromises)
    const responseIds = settledResults.filter((id) => id !== null) as string[]

    // 4. Disparar a função de processamento em lote
    if (responseIds.length > 0) {
      console.info(`[gs1_brasil] Invoking 'gs1_process_response' for ${responseIds.length} new responses.`)
      const { data: processResult, error: processError } = await supabaseAdmin.functions.invoke('gs1_process_response', {
        body: { response_ids: responseIds },
      })

      if (processError) {
        console.error(`[gs1_brasil] Erro no processamento: ${processError.message}`)
        return new Response(JSON.stringify({ 
          success: false, 
          error: 'Erro no processamento dos produtos',
          details: processError.message
        }), {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      console.info(`[gs1_brasil] Processing completed successfully.`)
      return new Response(JSON.stringify({ 
        success: true, 
        message: 'Produtos processados com sucesso',
        processed_count: responseIds.length
      }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    console.warn(`[gs1_brasil] No valid responses to process.`)
    return new Response(JSON.stringify({ 
      success: false,
      error: 'Nenhum produto válido foi encontrado para processamento'
    }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (error) {
    console.error('Erro na função gs1_brasil:', error)
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    })
  }
})
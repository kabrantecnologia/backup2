// supabase/functions/gs1_brasil/index.ts

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const GS1_API_URL = 'https://api.gs1br.org'

// Função auxiliar para buscar segredos específicos da GS1 via RPC
async function getGs1Secrets(supabase: any): Promise<Record<string, string>> {
  const requiredKeys = ['GS1_CLIENT_ID', 'GS1_CLIENT_SECRET', 'GS1_USER_EMAIL', 'GS1_PASSWORD']
  const secrets: Record<string, string> = {}
  const missingKeys: string[] = []

  await Promise.all(
    requiredKeys.map(async (keyName) => {
      const { data, error } = await supabase.rpc('get_key', { p_key_name: keyName })
      if (error || !data) {
        console.error(`Erro ao buscar a chave do vault: ${keyName}`, error)
        missingKeys.push(keyName)
      } else {
        secrets[keyName] = data
      }
    })
  )

  if (missingKeys.length > 0) {
    throw new Error(`Segredos ausentes no Vault: ${missingKeys.join(', ')}`)
  }

  return secrets
}

// Cache em memória para o token de acesso da GS1
let cachedTokenMemory: { accessToken: string; expiresAt: Date } | null = null

// Função para obter/renovar o token de acesso da API GS1
async function getAccessToken(
  supabase: any,
  gs1ClientId: string,
  gs1ClientSecret: string,
  gs1UserEmail: string,
  gs1Password: string
): Promise<string> {
  if (cachedTokenMemory && cachedTokenMemory.expiresAt > new Date()) {
    return cachedTokenMemory.accessToken
  }

  const basicAuth = btoa(`${gs1ClientId}:${gs1ClientSecret}`)
  const response = await fetch(`${GS1_API_URL}/oauth/access-token`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: `Basic ${basicAuth}` },
    body: JSON.stringify({ grant_type: 'password', username: gs1UserEmail, password: gs1Password }),
  })

  if (!response.ok) {
    const errorBody = await response.text()
    throw new Error(`Erro ao obter token de acesso da GS1: ${response.status} ${errorBody}`)
  }

  const newAuthData = await response.json()
  const expiresAt = new Date()
  expiresAt.setSeconds(expiresAt.getSeconds() + newAuthData.expires_in - 60)

  cachedTokenMemory = { accessToken: newAuthData.access_token, expiresAt: expiresAt }
  return cachedTokenMemory.accessToken
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { p_gtins, p_profile_id: profile_id } = await req.json()

    if (!Array.isArray(p_gtins) || p_gtins.length === 0) {
      return new Response(JSON.stringify({ error: 'O parâmetro p_gtins deve ser um array e não pode estar vazio.' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    if (!profile_id) {
      return new Response(JSON.stringify({ error: 'O parâmetro p_profile_id é obrigatório.' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 1. Obter segredos e token (MÉTODO CORRETO RESTAURADO)
    const gs1Secrets = await getGs1Secrets(supabaseAdmin)
    const accessToken = await getAccessToken(
      supabaseAdmin,
      gs1Secrets.GS1_CLIENT_ID,
      gs1Secrets.GS1_CLIENT_SECRET,
      gs1Secrets.GS1_USER_EMAIL,
      gs1Secrets.GS1_PASSWORD
    )

    // 2. Processar todos os GTINs em paralelo para evitar timeout
    const promises = p_gtins.map(async (gtin) => {
      try {
        const productResponse = await fetch(`${GS1_API_URL}/provider/v2/verified?gtin=${gtin}`, {
          headers: {
            Client_id: gs1Secrets.GS1_CLIENT_ID,
            Access_Token: accessToken,
          },
        })

        if (!productResponse.ok) {
          throw new Error(`API GS1 respondeu com status ${productResponse.status} para o GTIN ${gtin}`)
        }

        const productData = await productResponse.json()

        if (!Array.isArray(productData) || productData.length === 0) {
          console.warn(`Nenhum dado de produto retornado pela API GS1 para o GTIN ${gtin}.`)
          return null // Retorna nulo para GTINs sem dados, será filtrado depois
        }

        const { data: newResponse, error: insertError } = await supabaseAdmin
          .from('gs1_api_responses')
          .insert({
            gtin: gtin,
            raw_response: productData[0],
            status: 'PENDING',
            created_by_user_id: profile_id,
          })
          .select('id')
          .single()

        if (insertError) {
          throw new Error(`Erro ao salvar resposta para o GTIN ${gtin}: ${insertError.message}`)
        }

        return newResponse.id
      } catch (error) {
        console.error(`Falha ao processar GTIN ${gtin}: ${error.message}`)
        return null // Retorna nulo em caso de erro, será filtrado
      }
    })

    const settledResults = await Promise.all(promises)
    const responseIds = settledResults.filter((id) => id !== null) as string[]

    // 4. Disparar a função de processamento em lote
    if (responseIds.length > 0) {
      console.log(`Disparando processamento em lote para ${responseIds.length} respostas.`)
      await supabaseAdmin.functions.invoke('gs1_process_response', {
        body: { response_ids: responseIds },
      })
    }

    return new Response(JSON.stringify({ success: true, processed_gtins: responseIds.length }), {
      status: 200,
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
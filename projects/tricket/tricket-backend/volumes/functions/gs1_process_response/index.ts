// supabase/functions/process-gs1-response/index.ts

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const slugify = (text: string): string => {
  return text.toString().toLowerCase().trim().replace(/\s+/g, '-').replace(/[^\w\-]+/g, '').replace(/\-\-+/g, '-')
}

const findClassification = (classifications: any[] | undefined, code: string) =>
  classifications?.find((c: any) => c.additionalTradeItemClassificationSystemCode === code)?.additionalTradeItemClassificationCodeValue

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Modificado para aceitar um array de IDs de resposta
    const { response_ids } = await req.json()

    if (!Array.isArray(response_ids) || response_ids.length === 0) {
      return new Response(JSON.stringify({ error: 'O parâmetro response_ids deve ser um array e não pode estar vazio.' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Busca a URL pública a partir das variáveis de ambiente
    const publicSupabaseUrl = Deno.env.get('API_EXTERNAL_URL')

    if (!publicSupabaseUrl) {
      console.warn(`A variável de ambiente API_EXTERNAL_URL não está definida. O processamento de imagens será pulado.`)
    }
      

    // Processa todas as respostas em paralelo para evitar timeouts
    const processPromises = response_ids.map(async (responseId) => {
      try {
        const { data: responseData, error: responseError } = await supabaseAdmin
          .from('gs1_api_responses')
          .select('*')
          .eq('id', responseId)
          .single()

        if (responseError) {
          throw new Error(`Erro ao buscar resposta ${responseId}: ${responseError.message}`)
        }

        const raw_response = responseData.raw_response
        const gtin = raw_response.gtin

        // Se os dados detalhados do produto não estiverem disponíveis
        if (!raw_response.dadosNacionais?.product) {
          const message = raw_response.dadosNacionais?.message || 'Dados do produto não disponíveis.'
          const companyName = raw_response.dadosInternacionais?.gs1Licence?.licenseeName

          console.warn(`AVISO para GTIN ${gtin}: ${message}`)

          await supabaseAdmin
            .from('gs1_api_responses')
            .update({ status: 'ERROR', error_message: message })
            .eq('id', responseId)

          if (companyName) {
            await supabaseAdmin.from('marketplace_brands').upsert({ name: companyName }, { onConflict: 'name' })
            console.log(
              `Marca '${companyName}' garantida para o GTIN ${gtin}. O produto não será criado por falta de dados detalhados.`,
            )
          }
          return null // Retorna nulo pois não há imagem para processar
        }

        // Se chegou aqui, temos dados do produto para processar
        const nationalData = raw_response.dadosNacionais.product
        const dadosInternacionais = raw_response.dadosInternacionais
        const productName = nationalData.tradeItemDescriptionInformationLang?.[0]?.tradeItemDescription || 'Sem nome'

        // 1. Garantir que a marca (brand) exista
        const brandName = nationalData.brandNameInformationLang[0]?.brandName || dadosInternacionais.gs1Licence?.licenseeName || 'Marca não informada'

        const { data: brand, error: brandError } = await supabaseAdmin
          .from('marketplace_brands')
          .upsert({ name: brandName }, { onConflict: 'name' })
          .select('id')
          .single()

        if (brandError) throw new Error(`Erro ao garantir a marca: ${brandError.message}`)

        // 2. Mapeamento de Categoria GPC
        const gpc = nationalData.tradeItemClassification
        let subCategoryId = null
        if (gpc?.gpcCategoryCode) {
          // 1. Garante que o registro de mapeamento exista (cria se for novo)
          await supabaseAdmin
            .from('marketplace_gpc_to_tricket_category_mapping')
            .upsert(
              {
                gpc_category_code: gpc.gpcCategoryCode,
                gpc_category_name: gpc.gpcCategoryName || 'Nome não informado',
              },
              { onConflict: 'gpc_category_code', ignoreDuplicates: true } // Não faz nada se já existir
            )

          // 2. Busca o mapeamento para verificar o status
          const { data: mapping } = await supabaseAdmin
            .from('marketplace_gpc_to_tricket_category_mapping')
            .select('tricket_sub_category_id, status')
            .eq('gpc_category_code', gpc.gpcCategoryCode)
            .single()

          // 3. Se o mapeamento estiver completo, usa a subcategoria
          if (mapping && mapping.status === 'COMPLETED' && mapping.tricket_sub_category_id) {
            subCategoryId = mapping.tricket_sub_category_id
            console.log(`Mapeamento GPC encontrado. Produto GTIN ${gtin} será associado à subcategoria: ${subCategoryId}`)
          }
        }

        const findClassification = (code: string) => {
          return (
            nationalData.tradeItemClassification?.additionalTradeItemClassifications
              ?.find((c: any) => c.additionalTradeItemClassificationSystemCode === code)
              ?.additionalTradeItemClassificationCodeValue || null
          )
        }

        // Validar se o usuário existe antes de usar o created_by_user_id
        let validUserId = null
        if (responseData.created_by_user_id) {
          const { data: userExists } = await supabaseAdmin.auth.admin.getUserById(responseData.created_by_user_id)
          if (userExists?.user) {
            validUserId = responseData.created_by_user_id
            console.log(`Usuário ${validUserId} validado para produto GTIN ${gtin}`)
          } else {
            console.warn(`Usuário ${responseData.created_by_user_id} não encontrado. Produto GTIN ${gtin} será criado sem created_by_user_id.`)
          }
        }

        const productInsertData = {
          created_by_user_id: validUserId,
          brand_id: brand.id,
          sub_category_id: subCategoryId,
          name: productName,
          description: productName,
          status: 'ACTIVE',
          gtin: gtin,
          gpc_category_code: gpc?.gpcCategoryCode || null,
          ncm_code: findClassification('NCM'),
          cest_code: findClassification('CEST'),
          net_content: nationalData.tradeItemMeasurements?.netContent?.value || null,
          net_content_unit: nationalData.tradeItemMeasurements?.netContent?.measurementUnitCode || null,
          gross_weight: nationalData.tradeItemWeight?.grossWeight?.value || null,
          weight_unit: nationalData.tradeItemWeight?.grossWeight?.measurementUnitCode || null,
          country_of_origin_code: dadosInternacionais.countryOfSaleCode?.[0]?.alpha2 || null,
          gs1_company_name: dadosInternacionais.gs1Licence?.licenseeName || null,
        }

        const { data: newProduct, error: upsertError } = await supabaseAdmin
          .from('marketplace_products')
          .upsert(productInsertData, { onConflict: 'gtin' })
          .select('id')
          .single()

        if (upsertError) {
          throw new Error(`Erro ao salvar produto GTIN ${gtin}: ${upsertError.message}`)
        }

        await supabaseAdmin.from('gs1_api_responses').update({ status: 'PROCESSED' }).eq('id', responseId)

        // Prepara o payload para a função de imagem
        return {
          response_id: responseId,
          product_id: newProduct.id,
          gtin: gtin,
          image_urls: nationalData.referencedFileInformations
            ?.filter((file) => file.referencedFileTypeCode === 'PRODUCT_IMAGE')
            .map((file) => file.uniformResourceIdentifier) || [],
          created_by_user_id: validUserId,
        }
      } catch (error) {
        console.error(`Falha ao processar resposta ${responseId}: ${error.message}`)
        // Atualiza o status para erro em caso de falha inesperada no processamento
        await supabaseAdmin.from('gs1_api_responses').update({ status: 'ERROR', error_message: error.message }).eq('id', responseId)
        return null
      }
    })

    const settledResults = await Promise.all(processPromises)
    const validProducts = settledResults.filter((p) => p !== null)
    const productImagePayloads = validProducts.filter((p) => p.image_urls.length > 0)

    console.info(`[gs1_process_response] Produtos válidos: ${validProducts.length}, Com imagens: ${productImagePayloads.length}`)

    // Verifica se há produtos válidos com imagens
    if (productImagePayloads.length === 0) {
      const errorMessage = validProducts.length === 0 
        ? 'Nenhum produto válido foi processado'
        : 'Produtos processados mas nenhum possui imagens válidas'
      
      console.error(`[gs1_process_response] ${errorMessage}`)
      return new Response(JSON.stringify({ 
        error: errorMessage,
        processed_count: validProducts.length,
        with_images_count: productImagePayloads.length
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      })
    }

    // 4. Disparar a função de processamento de imagens em lote
    console.info(`[gs1_process_response] Processando imagens para ${productImagePayloads.length} produtos`)
    const { data: imageResult, error: imageError } = await supabaseAdmin.functions.invoke('gs1_process-product-images', {
      body: { productImagePayloads, public_supabase_url: publicSupabaseUrl },
    })

    if (imageError) {
      console.error(`[gs1_process_response] Erro no processamento de imagens: ${imageError.message}`)
      return new Response(JSON.stringify({ 
        error: 'Erro no processamento de imagens dos produtos',
        details: imageError.message
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      })
    }

    console.info(`[gs1_process_response] Processamento concluído com sucesso`)
    return new Response(JSON.stringify({ 
      success: true,
      message: `Processamento de ${response_ids.length} respostas concluído com sucesso`,
      processed_count: validProducts.length,
      with_images_count: productImagePayloads.length
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    })
  }
})

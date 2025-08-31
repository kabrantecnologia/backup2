// supabase/functions/process-product-images/index.ts

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.43.4'
// Importa a biblioteca de processamento de imagem
import { Image } from 'https://deno.land/x/imagescript@1.2.15/mod.ts'

// Headers CORS definidos localmente para tornar a função autocontida e evitar erros de import.
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // O payload agora é `productImagePayloads`, enviado pela função anterior
    const { productImagePayloads, public_supabase_url } = await req.json()

    if (!Array.isArray(productImagePayloads) || productImagePayloads.length === 0 || !public_supabase_url) {
      return new Response(
        JSON.stringify({ error: 'productImagePayloads (array não vazio) e public_supabase_url são obrigatórios.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const supabaseAdmin = createClient(public_supabase_url, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '')

    // --- LÓGICA DE PROCESSAMENTO TOTALMENTE PARALELA ---
    // 1. Cria uma promessa para CADA produto no payload
    const allProductsPromises = productImagePayloads.map(async (payload) => {
      const { product_id, image_urls, created_by_user_id } = payload

      if (!image_urls || image_urls.length === 0) {
        return // Pula este produto
      }

      const { data: product } = await supabaseAdmin.from('marketplace_products').select('name').eq('id', product_id).single()
      const altText = product?.name || 'Imagem do produto'

      // 2. Para cada produto, cria promessas para processar TODAS as suas imagens em paralelo
      const processImagePromises = image_urls.map(async (imageUrl, index) => {
        try {
          const imageResponse = await fetch(imageUrl)
          if (!imageResponse.ok) throw new Error(`Status ${imageResponse.status} ao baixar imagem`)

          const imageBuffer = await imageResponse.arrayBuffer()

          // Extrai a extensão da URL para determinar o Content-Type corretamente
          const urlParts = imageUrl.split('.')
          const extension = urlParts[urlParts.length - 1].split('?')[0].toLowerCase()

          let contentType = 'image/jpeg' // Default
          if (extension === 'png') {
            contentType = 'image/png'
          } else if (extension === 'gif') {
            contentType = 'image/gif'
          } else if (extension === 'webp') {
            contentType = 'image/webp'
          }

          const filePath = `${product_id}/${product_id}-${Date.now()}-${index}.${extension}`

          const { error: uploadError } = await supabaseAdmin.storage
            .from('product-images')
            .upload(filePath, imageBuffer, { contentType, upsert: true })
          if (uploadError) throw uploadError

          const { data: publicUrlData } = supabaseAdmin.storage.from('product-images').getPublicUrl(filePath)

          return {
            product_id: product_id,
            image_url: publicUrlData.publicUrl,
            alt_text: altText,
            sort_order: index,
          }
        } catch (e) {
          console.error(`Erro ao processar a imagem ${imageUrl} para o produto ${product_id}:`, e.message)
          return null
        }
      })

      const imageRecords = (await Promise.all(processImagePromises)).filter(Boolean)

      if (imageRecords.length > 0) {
        const { error: insertError } = await supabaseAdmin.from('marketplace_product_images').insert(imageRecords)
        if (insertError) {
          // Loga o erro mas não para o processamento dos outros produtos
          console.error(`Erro ao inserir registros de imagem para o produto ${product_id}:`, insertError)
        }
      }
    })

    // 3. Executa todas as promessas de todos os produtos em paralelo
    await Promise.all(allProductsPromises)

    console.log(`Processamento de imagens concluído para ${productImagePayloads.length} produtos.`)

    return new Response(JSON.stringify({ success: true, processed_products: productImagePayloads.length }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (error) {
    console.error('Erro inesperado na função gs1_process-product-images:', error)
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})

import asyncio
import os
import re
import csv
import logging
import time
from datetime import datetime
from pathlib import Path
from xml.etree import ElementTree as ET
import requests
from playwright.async_api import async_playwright, TimeoutError as PlaywrightTimeoutError

# Configuração de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('scraper.log')
    ]
)
logger = logging.getLogger(__name__)

# Configurações
SITEMAP_URL = os.getenv('SITEMAP_URL', 'https://b2c.meggadistribuidora.com.br/sitemap-produtos-13.xml')
OUTPUT_DIR = os.getenv('OUTPUT_DIR', 'data')
OUTPUT_FILE = os.path.join(OUTPUT_DIR, 'barcodes_robust.csv')
REQUEST_TIMEOUT = int(os.getenv('REQUEST_TIMEOUT', '30000'))  # 30 segundos
MAX_RETRIES = 3
DELAY_BETWEEN_REQUESTS = 1  # segundos

def get_product_urls(sitemap_url):
    """Fetches and parses the sitemap to extract product URLs."""
    urls = []
    try:
        logger.info(f"Buscando sitemap em: {sitemap_url}")
        
        # Configura headers para parecer um navegador
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'pt-BR,pt;q=0.8,en-US;q=0.5,en;q=0.3',
            'Connection': 'keep-alive',
            'Upgrade-Insecure-Requests': '1'
        }
        
        # Faz a requisição com verificação SSL desabilitada
        session = requests.Session()
        session.verify = False
        response = session.get(sitemap_url, headers=headers, timeout=30)
        
        # Verifica o status da resposta
        logger.info(f"Status code: {response.status_code}")
        logger.info(f"Headers da resposta: {response.headers}")
        
        # Verifica se a resposta foi bem-sucedida
        response.raise_for_status()
        
        # Obtém o conteúdo da resposta
        content = response.text.strip()
        
        # Salva o conteúdo em um arquivo para análise
        with open('sitemap_content.xml', 'w', encoding='utf-8') as f:
            f.write(content)
        
        # Verifica se o conteúdo parece ser XML
        if not content.startswith('<?xml') and not content.startswith('<urlset'):
            logger.error("O sitemap não retornou um XML válido")
            logger.error(f"Início do conteúdo recebido: {content[:500]}")
            return urls
        
        # Se chegou aqui, o conteúdo parece ser XML
        logger.info("Conteúdo XML recebido com sucesso!")
        
        # Tenta extrair URLs usando expressão regular primeiro
        import re
        url_matches = re.findall(r'<loc>(https?://[^<]+)</loc>', content)
        if url_matches:
            urls = [url for url in url_matches if 'meggaatacadista.com.br' in url]
            logger.info(f"Encontradas {len(urls)} URLs usando expressão regular")
            
            # Retorna todas as URLs encontradas
            return urls
        
        # Se não encontrou URLs com regex, tenta parsear o XML
        logger.info("Tentando fazer o parse do XML...")
        
        # Tenta com diferentes codificações
        for encoding in ['utf-8', 'iso-8859-1', 'windows-1252']:
            try:
                root = ET.fromstring(content.encode(encoding))
                logger.info(f"Parse do XML bem-sucedido com codificação {encoding}!")
                break
            except Exception as e:
                logger.warning(f"Falha ao fazer parse com codificação {encoding}: {e}")
        else:
            logger.error("Não foi possível fazer o parse do XML com nenhuma codificação")
            return urls
        
        # Tenta encontrar URLs no XML parseado
        namespaces = {
            'sitemap': 'http://www.sitemaps.org/schemas/sitemap/0.9',
            'image': 'http://www.google.com/schemas/sitemap-image/1.1'
        }
        
        # Tenta diferentes formas de encontrar as URLs
        for xpath in ['.//url/loc', './/sitemap:url/sitemap:loc', '//loc', '//sitemap:loc']:
            try:
                elements = root.findall(xpath, namespaces)
                if elements:
                    logger.info(f"Encontrados {len(elements)} elementos com XPath: {xpath}")
                    for elem in elements:
                        if elem.text and 'meggaatacadista.com.br' in elem.text:
                            urls.append(elem.text.strip())
                    
                    if urls:
                        logger.info(f"Encontradas {len(urls)} URLs válidas")
                        return urls  # Retorna todas as URLs encontradas
            except Exception as e:
                logger.warning(f"Erro ao processar XPath {xpath}: {e}")
        
        logger.warning("Nenhuma URL encontrada no sitemap usando os métodos disponíveis")
        
    except requests.exceptions.SSLError as e:
        logger.error(f"Erro de SSL ao acessar o sitemap: {e}")
    except requests.exceptions.RequestException as e:
        logger.error(f"Erro ao buscar sitemap: {e}", exc_info=True)
    except Exception as e:
        logger.error(f"Erro inesperado ao processar sitemap: {e}", exc_info=True)
    
    # Registra algumas URLs para debug
    if urls:
        logger.info(f"Primeiras 3 URLs encontradas: {urls[:3]}")
    else:
        logger.warning("Nenhuma URL de produto encontrada no sitemap")
    
    return urls

async def extract_product_info(page, product_url, attempt=1, max_attempts=3):
    """Extracts product name and barcode from a product page using Playwright."""
    product_name = 'Nome não encontrado'
    barcode = 'Não encontrado'
    
    try:
        logger.debug(f"Tentativa {attempt} para {product_url}")
        
        # Configura um timeout maior para o carregamento da página
        navigation_timeout = 60000  # 60 segundos
        
        # Tenta navegar para a URL
        try:
            await page.goto(product_url, wait_until='domcontentloaded', timeout=navigation_timeout)
        except Exception as e:
            logger.warning(f"Erro ao acessar {product_url}: {e}")
            if attempt < max_attempts:
                await asyncio.sleep(5 * attempt)  # Espera progressivamente mais
                return await extract_product_info(page, product_url, attempt + 1, max_attempts)
            return product_name, f'Erro de navegação: {str(e)}'
        
        # Obtém o título da página
        try:
            product_name = (await page.title()).split('|')[0].strip() or 'Nome não encontrado'
        except:
            pass
        
        # Tenta encontrar o código de barras
        try:
            # Tenta localizar o elemento do código de barras
            barcode_locator = page.locator('text=/Código de Barras do Produto:/')
            if await barcode_locator.count() > 0:
                await barcode_locator.first.wait_for(timeout=10000)
                full_text = await barcode_locator.inner_text()
                barcode_match = re.search(r'(\d{8,14})', full_text)
                if barcode_match:
                    barcode = barcode_match.group(1).strip()
        except Exception as e:
            logger.debug(f"Erro ao extrair código de barras: {e}")
        
        return product_name, barcode
        
    except Exception as e:
        error_msg = f"Erro inesperado ao processar {product_url}: {str(e)}"
        logger.error(error_msg, exc_info=True)
        return product_name, f'Erro: {str(e)[:50]}...'

async def is_url_processed(csv_file, url):
    """Verifica se uma URL já foi processada no arquivo CSV."""
    if not os.path.exists(csv_file):
        return False
        
    try:
        with open(csv_file, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                if row.get('URL') == url:
                    return True
    except Exception as e:
        logger.error(f"Erro ao verificar URL processada: {e}")
        
    return False

async def process_urls(browser, urls, output_file, fieldnames, file_exists):
    """Processa um lote de URLs e salva os resultados."""
    # Cria um novo contexto para este lote
    context = await browser.new_context(
        viewport={'width': 1920, 'height': 1080},
        user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        java_script_enabled=True,
        ignore_https_errors=True
    )
    
    try:
        # Cria uma nova página para este lote
        page = await context.new_page()
        
        # Abre o arquivo CSV para escrita em modo de adição
        with open(output_file, 'a' if file_exists else 'w', newline='', encoding='utf-8') as csvfile:
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            
            # Escreve o cabeçalho se for um novo arquivo
            if not file_exists or os.path.getsize(output_file) == 0:
                writer.writeheader()
            
            # Processa cada URL
            for i, url in enumerate(urls, 1):
                try:
                    logger.info(f"Processando {i}/{len(urls)}: {url}")
                    
                    # Verifica se a URL já foi processada
                    if await is_url_processed(output_file, url):
                        logger.info("URL já processada, pulando...")
                        continue
                    
                    # Extrai as informações do produto com até 3 tentativas
                    max_attempts = 3
                    for attempt in range(1, max_attempts + 1):
                        try:
                            # Cria uma nova página para cada tentativa
                            if attempt > 1:
                                await page.close()
                                page = await context.new_page()
                                
                            name, barcode = await extract_product_info(page, url, attempt, max_attempts)
                            break
                        except Exception as e:
                            if attempt == max_attempts:
                                raise
                            wait_time = 5 * attempt  # Aumenta o tempo de espera a cada tentativa
                            logger.warning(f"Tentativa {attempt} falhou. Tentando novamente em {wait_time} segundos...")
                            await asyncio.sleep(wait_time)
                    
                    # Prepara os dados para salvar
                    row = {
                        'URL': url,
                        'Nome do Produto': name,
                        'Codigo de Barras': barcode,
                        'Data da Coleta': datetime.now().isoformat()
                    }
                    
                    # Escreve no CSV
                    writer.writerow(row)
                    csvfile.flush()  # Garante que os dados são escritos imediatamente
                    
                    logger.info(f"Salvo: {name} - {barcode}")
                    
                    # Pequena pausa entre requisições para evitar sobrecarga
                    if i < len(urls):  # Não espera após o último item
                        await asyncio.sleep(DELAY_BETWEEN_REQUESTS)
                    
                except Exception as e:
                    logger.error(f"Erro ao processar {url}: {e}", exc_info=True)
                    # Salva a URL com erro para tentar novamente depois
                    with open(os.path.join(OUTPUT_DIR, 'erros.txt'), 'a', encoding='utf-8') as f:
                        f.write(f"{url}\t{str(e)}\n")
                    continue
    finally:
        # Fecha o contexto e a página
        await context.close()

async def main():
    """Função principal para executar o scraping."""
    start_time = time.time()
    logger.info("Iniciando o processo de coleta de códigos de barras...")
    
    # Cria o diretório de saída se não existir
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    # Cabeçalhos do CSV
    fieldnames = ['URL', 'Nome do Produto', 'Codigo de Barras', 'Data da Coleta']
    
    # Verifica se o arquivo já existe para continuar de onde parou
    file_exists = os.path.exists(OUTPUT_FILE)
    
    # Obtém as URLs dos produtos
    logger.info(f"Obtendo URLs do sitemap: {SITEMAP_URL}")
    product_urls = get_product_urls(SITEMAP_URL)
    
    if not product_urls:
        logger.error("Nenhuma URL de produto encontrada. Verifique o sitemap e a conexão com a internet.")
        return
    
    logger.info(f"Total de URLs encontradas: {len(product_urls)}")
    
    # Configurações do navegador
    browser_args = [
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-dev-shm-usage',
        '--disable-accelerated-2d-canvas',
        '--no-first-run',
        '--no-zygote',
        '--single-process',
        '--disable-gpu',
        '--disable-blink-features=AutomationControlled',
        '--disable-infobars',
        '--window-size=1920,1080'
    ]
    
    # Inicializa o Playwright
    p = await async_playwright().start()
    
    try:
        # Processa as URLs em lotes para evitar sobrecarga
        batch_size = 20  # Reduzido para 20 URLs por lote
        total_batches = (len(product_urls) + batch_size - 1) // batch_size
        
        for batch_num in range(total_batches):
            start_idx = batch_num * batch_size
            end_idx = min((batch_num + 1) * batch_size, len(product_urls))
            batch_urls = product_urls[start_idx:end_idx]
            
            logger.info(f"Processando lote {batch_num + 1}/{total_batches} (URLs {start_idx + 1}-{end_idx})")
            
            # Cria um novo navegador para cada lote
            logger.info("Iniciando novo navegador...")
            browser = await p.chromium.launch(
                headless=True,
                args=browser_args,
                timeout=60000  # 60 segundos de timeout
            )
            
            try:
                # Processa o lote atual
                await process_urls(browser, batch_urls, OUTPUT_FILE, fieldnames, file_exists)
                file_exists = True  # Após o primeiro lote, o arquivo já existe
                
                # Pequena pausa entre lotes
                if batch_num < total_batches - 1:
                    logger.info("Aguardando 10 segundos antes do próximo lote...")
                    await asyncio.sleep(10)
                    
            except Exception as e:
                logger.error(f"Erro ao processar lote {batch_num + 1}: {e}", exc_info=True)
                # Tenta continuar com o próximo lote mesmo em caso de erro
                continue
                
            finally:
                # Fecha o navegador após cada lote
                if browser:
                    await browser.close()
        
        logger.info("Processo de coleta concluído com sucesso!")
        
    except Exception as e:
        logger.error(f"Erro durante a execução: {e}", exc_info=True)
    finally:
        # Fecha o Playwright
        await p.stop()
    
    # Exibe o tempo total de execução
    total_time = time.time() - start_time
    logger.info(f"Tempo total de execução: {total_time:.2f} segundos")
    logger.info(f"Arquivo de saída salvo em: {os.path.abspath(OUTPUT_FILE)}")

if __name__ == '__main__':
    asyncio.run(main())

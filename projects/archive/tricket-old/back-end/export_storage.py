#!/usr/bin/env python3
"""
Script para exportar arquivos do storage do Supabase self-hosted
Criado por: GitHub Copilot
Data: 2025-08-06
"""

import os
import shutil
import argparse
from pathlib import Path
from typing import Dict, List
import re

def get_file_extension_from_path(file_path: str) -> str:
    """Extrai a extensão do arquivo baseada no nome do diretório pai"""
    # O nome do arquivo está no diretório pai
    parent_dir = os.path.basename(os.path.dirname(file_path))
    
    # Extrair extensão do nome do arquivo
    if '.' in parent_dir:
        return parent_dir.split('.')[-1].lower()
    return ''

def organize_files_by_type(source_dir: str, destination_dir: str, preserve_structure: bool = False):
    """
    Organiza os arquivos do storage por tipo
    
    Args:
        source_dir: Diretório source do storage
        destination_dir: Diretório de destino
        preserve_structure: Se True, mantém a estrutura original de diretórios
    """
    
    source_path = Path(source_dir)
    dest_path = Path(destination_dir)
    
    # Criar diretório de destino
    dest_path.mkdir(parents=True, exist_ok=True)
    
    # Contadores
    copied_files = 0
    file_types = {}
    errors = []
    
    print(f"🔍 Iniciando exportação de {source_dir}")
    print(f"📁 Destino: {destination_dir}")
    print(f"🏗️  Preservar estrutura: {preserve_structure}")
    print("-" * 50)
    
    # Percorrer todos os arquivos
    for file_path in source_path.rglob('*'):
        if file_path.is_file():
            try:
                # Obter extensão do arquivo
                extension = get_file_extension_from_path(str(file_path))
                
                if not extension:
                    extension = 'unknown'
                
                # Contar tipos de arquivo
                file_types[extension] = file_types.get(extension, 0) + 1
                
                if preserve_structure:
                    # Manter estrutura original
                    relative_path = file_path.relative_to(source_path)
                    dest_file_path = dest_path / relative_path
                    dest_file_path.parent.mkdir(parents=True, exist_ok=True)
                else:
                    # Organizar por tipo de arquivo
                    type_dir = dest_path / extension
                    type_dir.mkdir(exist_ok=True)
                    
                    # Nome do arquivo será o nome do diretório pai + extensão
                    parent_dir_name = os.path.basename(os.path.dirname(str(file_path)))
                    if '.' not in parent_dir_name and extension != 'unknown':
                        file_name = f"{parent_dir_name}.{extension}"
                    else:
                        file_name = parent_dir_name
                    
                    dest_file_path = type_dir / file_name
                    
                    # Se arquivo já existe, adicionar contador
                    counter = 1
                    base_name = dest_file_path.stem
                    ext = dest_file_path.suffix
                    while dest_file_path.exists():
                        dest_file_path = type_dir / f"{base_name}_{counter}{ext}"
                        counter += 1
                
                # Copiar arquivo
                shutil.copy2(file_path, dest_file_path)
                copied_files += 1
                
                if copied_files % 50 == 0:
                    print(f"📄 Copiados: {copied_files} arquivos...")
                    
            except Exception as e:
                error_msg = f"Erro ao copiar {file_path}: {str(e)}"
                errors.append(error_msg)
                print(f"❌ {error_msg}")
    
    # Relatório final
    print("\n" + "=" * 50)
    print("📊 RELATÓRIO DE EXPORTAÇÃO")
    print("=" * 50)
    print(f"✅ Total de arquivos copiados: {copied_files}")
    print(f"❌ Total de erros: {len(errors)}")
    print("\n📁 Tipos de arquivo encontrados:")
    
    for file_type, count in sorted(file_types.items()):
        print(f"   {file_type.upper()}: {count} arquivos")
    
    if errors:
        print(f"\n❌ Erros encontrados:")
        for error in errors[:10]:  # Mostrar apenas os primeiros 10 erros
            print(f"   {error}")
        if len(errors) > 10:
            print(f"   ... e mais {len(errors) - 10} erros")
    
    print(f"\n📁 Arquivos exportados para: {destination_dir}")

def export_bucket(source_dir: str, bucket_name: str, destination_dir: str):
    """
    Exporta um bucket específico
    
    Args:
        source_dir: Diretório raiz do storage
        bucket_name: Nome do bucket (ex: 'product-images', 'app-images')
        destination_dir: Diretório de destino
    """
    
    bucket_path = Path(source_dir) / "stub" / "stub" / bucket_name
    
    if not bucket_path.exists():
        print(f"❌ Bucket '{bucket_name}' não encontrado em {bucket_path}")
        return
    
    print(f"🪣 Exportando bucket: {bucket_name}")
    organize_files_by_type(str(bucket_path), destination_dir, preserve_structure=False)

def create_archive(source_dir: str, archive_name: str):
    """
    Cria um arquivo compactado com todos os arquivos
    
    Args:
        source_dir: Diretório source
        archive_name: Nome do arquivo (sem extensão)
    """
    
    print(f"📦 Criando arquivo compactado: {archive_name}")
    
    # Criar arquivo tar.gz
    import tarfile
    
    with tarfile.open(f"{archive_name}.tar.gz", "w:gz") as tar:
        tar.add(source_dir, arcname=os.path.basename(source_dir))
    
    print(f"✅ Arquivo criado: {archive_name}.tar.gz")

def main():
    parser = argparse.ArgumentParser(description="Exportar arquivos do storage do Supabase self-hosted")
    parser.add_argument("--source", "-s", required=True, help="Diretório source do storage")
    parser.add_argument("--destination", "-d", required=True, help="Diretório de destino")
    parser.add_argument("--bucket", "-b", help="Nome específico do bucket para exportar")
    parser.add_argument("--preserve-structure", "-p", action="store_true", help="Preservar estrutura original de diretórios")
    parser.add_argument("--create-archive", "-a", action="store_true", help="Criar arquivo compactado")
    parser.add_argument("--archive-name", help="Nome do arquivo compactado (padrão: supabase-storage-export)")
    
    args = parser.parse_args()
    
    source_dir = args.source
    destination_dir = args.destination
    
    # Verificar se diretório source existe
    if not os.path.exists(source_dir):
        print(f"❌ Diretório source não encontrado: {source_dir}")
        return
    
    if args.bucket:
        # Exportar bucket específico
        export_bucket(source_dir, args.bucket, destination_dir)
    else:
        # Exportar tudo
        organize_files_by_type(source_dir, destination_dir, args.preserve_structure)
    
    if args.create_archive:
        archive_name = args.archive_name or "supabase-storage-export"
        create_archive(destination_dir, archive_name)

if __name__ == "__main__":
    main()

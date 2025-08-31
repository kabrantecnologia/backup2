from sqlalchemy import create_engine, inspect
from sqlalchemy.orm import sessionmaker
from .models import Base, create_indexes
from .connection import get_database_url
from config.logging import get_logger
from typing import List, Dict, Any

logger = get_logger(__name__)


class DatabaseMigrator:
    """
    Database migration manager for schema changes
    """
    
    def __init__(self, database_url: str = None):
        self.database_url = database_url or get_database_url()
        self.engine = create_engine(self.database_url, echo=False)
        self.session_factory = sessionmaker(bind=self.engine)
    
    def get_current_tables(self) -> List[str]:
        """Get list of existing tables in database"""
        inspector = inspect(self.engine)
        return inspector.get_table_names()
    
    def get_table_columns(self, table_name: str) -> List[Dict[str, Any]]:
        """Get columns for a specific table"""
        inspector = inspect(self.engine)
        return inspector.get_columns(table_name)
    
    def create_all_tables(self) -> bool:
        """
        Create all tables defined in models
        
        Returns:
            True if successful, False otherwise
        """
        try:
            logger.info("Creating database tables...")
            Base.metadata.create_all(bind=self.engine)
            
            # Create indexes
            create_indexes(self.engine)
            
            logger.info("Database tables created successfully")
            return True
            
        except Exception as e:
            logger.error(f"Failed to create database tables: {str(e)}")
            return False
    
    def drop_all_tables(self) -> bool:
        """
        Drop all tables (DANGEROUS - use only for testing)
        
        Returns:
            True if successful, False otherwise
        """
        try:
            logger.warning("Dropping all database tables...")
            Base.metadata.drop_all(bind=self.engine)
            logger.warning("All database tables dropped")
            return True
            
        except Exception as e:
            logger.error(f"Failed to drop database tables: {str(e)}")
            return False
    
    def check_migration_needed(self) -> Dict[str, Any]:
        """
        Check what migrations are needed
        
        Returns:
            Dictionary with migration status
        """
        existing_tables = set(self.get_current_tables())
        expected_tables = set(Base.metadata.tables.keys())
        
        missing_tables = expected_tables - existing_tables
        extra_tables = existing_tables - expected_tables
        
        migration_info = {
            "migration_needed": bool(missing_tables or extra_tables),
            "existing_tables": list(existing_tables),
            "expected_tables": list(expected_tables),
            "missing_tables": list(missing_tables),
            "extra_tables": list(extra_tables),
            "column_changes": {}
        }
        
        # Check for column changes in existing tables
        for table_name in existing_tables.intersection(expected_tables):
            try:
                existing_columns = {col['name']: col for col in self.get_table_columns(table_name)}
                # This is a simplified check - in production you'd want more sophisticated column comparison
                migration_info["column_changes"][table_name] = {
                    "existing_columns": list(existing_columns.keys()),
                    "needs_column_analysis": True
                }
            except Exception as e:
                logger.warning(f"Could not analyze columns for table {table_name}: {str(e)}")
        
        return migration_info
    
    def run_migration(self, force: bool = False) -> bool:
        """
        Run database migration
        
        Args:
            force: Force migration even if data might be lost
            
        Returns:
            True if successful, False otherwise
        """
        try:
            migration_info = self.check_migration_needed()
            
            if not migration_info["migration_needed"]:
                logger.info("No migration needed - database is up to date")
                return True
            
            logger.info(f"Migration needed: {migration_info}")
            
            if migration_info["missing_tables"]:
                logger.info(f"Creating missing tables: {migration_info['missing_tables']}")
                # Create only missing tables
                for table_name in migration_info["missing_tables"]:
                    if table_name in Base.metadata.tables:
                        table = Base.metadata.tables[table_name]
                        table.create(bind=self.engine)
                        logger.info(f"Created table: {table_name}")
            
            if migration_info["extra_tables"] and force:
                logger.warning(f"Dropping extra tables: {migration_info['extra_tables']}")
                for table_name in migration_info["extra_tables"]:
                    self.engine.execute(f"DROP TABLE IF EXISTS {table_name}")
                    logger.warning(f"Dropped table: {table_name}")
            
            # Create indexes
            create_indexes(self.engine)
            
            logger.info("Database migration completed successfully")
            return True
            
        except Exception as e:
            logger.error(f"Database migration failed: {str(e)}")
            return False
    
    def seed_default_data(self) -> bool:
        """
        Seed database with default data
        
        Returns:
            True if successful, False otherwise
        """
        try:
            with self.session_factory() as session:
                from .models import MerchantPlanDB, ResellerDB
                from app.services.reseller_service import ResellerService
                from config.settings import settings
                
                # Create default reseller if it doesn't exist
                reseller_service = ResellerService(session)
                existing_reseller = reseller_service.get_reseller_by_document(settings.RESELLER_DOCUMENT)
                
                if not existing_reseller:
                    default_reseller = reseller_service.create_default_reseller(
                        api_token=settings.CAPPTA_API_TOKEN,
                        document=settings.RESELLER_DOCUMENT
                    )
                    logger.info(f"Created default reseller: {default_reseller.reseller_id}")
                    
                    # Create default merchant plans for the reseller
                    from app.services.merchant_plan_service import MerchantPlanService
                    plan_service = MerchantPlanService(session)
                    default_plans = plan_service.create_default_plans(default_reseller.reseller_id)
                    logger.info(f"Created default plans: {len(default_plans)} plans")
                
                # Check if default plan exists
                default_plan = session.query(MerchantPlanDB).filter(
                    MerchantPlanDB.is_default == True
                ).first()
                
                if not default_plan:
                    # Create default merchant plan
                    default_plan = MerchantPlanDB(
                        plan_id="default-plan",
                        plan_name="Plano Padrão",
                        description="Plano de taxas padrão do simulador",
                        is_default=True,
                        fee_structure={
                            "credit": {
                                "percentage": 3.0,
                                "fixed": 30  # R$ 0,30
                            },
                            "debit": {
                                "percentage": 2.0,
                                "fixed": 20  # R$ 0,20
                            },
                            "pix": {
                                "percentage": 0.0,
                                "fixed": 10  # R$ 0,10
                            },
                            "installment_fee": {
                                "percentage": 0.5  # 0.5% por parcela adicional
                            }
                        }
                    )
                    session.add(default_plan)
                    session.commit()
                    logger.info("Created default merchant plan")
                
                logger.info("Database seeding completed")
                return True
                
        except Exception as e:
            logger.error(f"Database seeding failed: {str(e)}")
            return False
    
    def backup_database(self, backup_path: str) -> bool:
        """
        Create a backup of the database (SQLite only)
        
        Args:
            backup_path: Path to backup file
            
        Returns:
            True if successful, False otherwise
        """
        try:
            if not self.database_url.startswith("sqlite"):
                logger.warning("Backup only supported for SQLite databases")
                return False
            
            import shutil
            import os
            
            # Extract database file path from URL
            db_path = self.database_url.replace("sqlite:///", "")
            
            if os.path.exists(db_path):
                shutil.copy2(db_path, backup_path)
                logger.info(f"Database backed up to: {backup_path}")
                return True
            else:
                logger.error(f"Database file not found: {db_path}")
                return False
                
        except Exception as e:
            logger.error(f"Database backup failed: {str(e)}")
            return False
    
    def restore_database(self, backup_path: str) -> bool:
        """
        Restore database from backup (SQLite only)
        
        Args:
            backup_path: Path to backup file
            
        Returns:
            True if successful, False otherwise
        """
        try:
            if not self.database_url.startswith("sqlite"):
                logger.warning("Restore only supported for SQLite databases")
                return False
            
            import shutil
            import os
            
            # Extract database file path from URL
            db_path = self.database_url.replace("sqlite:///", "")
            
            if os.path.exists(backup_path):
                shutil.copy2(backup_path, db_path)
                logger.info(f"Database restored from: {backup_path}")
                return True
            else:
                logger.error(f"Backup file not found: {backup_path}")
                return False
                
        except Exception as e:
            logger.error(f"Database restore failed: {str(e)}")
            return False


# Global migrator instance
migrator = DatabaseMigrator()


def init_database() -> bool:
    """
    Initialize database with all tables and default data
    
    Returns:
        True if successful, False otherwise
    """
    logger.info("Initializing database...")
    
    # Run migration
    if not migrator.run_migration():
        return False
    
    # Seed default data
    if not migrator.seed_default_data():
        return False
    
    logger.info("Database initialization completed")
    return True


def reset_database() -> bool:
    """
    Reset database (drop and recreate all tables)
    
    Returns:
        True if successful, False otherwise
    """
    logger.warning("Resetting database...")
    
    # Drop all tables
    if not migrator.drop_all_tables():
        return False
    
    # Recreate all tables
    if not migrator.create_all_tables():
        return False
    
    # Seed default data
    if not migrator.seed_default_data():
        return False
    
    logger.info("Database reset completed")
    return True
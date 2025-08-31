from fastapi import APIRouter, HTTPException, Depends, Query, status
from sqlalchemy.orm import Session
from typing import Optional

from app.database.connection import get_db_session
from app.services.merchant_plan_service import MerchantPlanService
from app.models.merchant_plan import (
    MerchantPlanCreate, MerchantPlanUpdate, MerchantPlanResponse, MerchantPlanListResponse,
    MerchantPlanAssociation, MerchantPlanAssociationResponse, PlanCalculation,
    PlanFilter, PlanSort, PlanStatus, PaymentMethod
)
from app.middleware.reseller_auth import require_reseller, ResellerAuth
from config.logging import get_logger

logger = get_logger(__name__)

router = APIRouter()

@router.post("/", response_model=MerchantPlanResponse, status_code=status.HTTP_201_CREATED)
async def create_merchant_plan(
    plan_data: MerchantPlanCreate,
    reseller: ResellerAuth = Depends(require_reseller),
    db: Session = Depends(get_db_session)
):
    """
    Criar um novo plano de merchant
    
    Define estrutura de taxas para diferentes métodos de pagamento:
    - **plan_name**: Nome do plano
    - **description**: Descrição opcional
    - **fee_structure**: Estrutura completa de taxas
      - **credit**: Taxas para cartão de crédito (percentage + fixed)
      - **debit**: Taxas para cartão de débito (percentage + fixed)
      - **pix**: Taxas para PIX (geralmente apenas fixed)
      - **installments**: Configuração de parcelamento
    - **is_default**: Se é o plano padrão (apenas um por reseller)
    
    As taxas são validadas contra limites de negócio antes da criação.
    """
    try:
        plan_service = MerchantPlanService(db)
        plan = plan_service.create_plan(plan_data, reseller.reseller_id)
        
        logger.info(f"Merchant plan created via API", extra={
            "plan_id": plan.plan_id,
            "plan_name": plan.plan_name,
            "is_default": plan.is_default,
            "reseller_id": reseller.reseller_id
        })
        
        return plan
        
    except ValueError as e:
        logger.warning(f"Merchant plan creation validation error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Merchant plan creation error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error while creating merchant plan"
        )

@router.get("/", response_model=MerchantPlanListResponse)
async def list_merchant_plans(
    # Filtering parameters
    status_filter: Optional[PlanStatus] = Query(None, alias="status", description="Filtrar por status do plano"),
    is_default: Optional[bool] = Query(None, description="Filtrar apenas planos padrão"),
    has_merchants: Optional[bool] = Query(None, description="Filtrar planos com/sem merchants"),
    
    # Sorting parameters
    sort: PlanSort = Query(PlanSort.CREATED_DESC, description="Ordenação dos resultados"),
    
    # Pagination parameters
    page: int = Query(1, ge=1, description="Número da página"),
    per_page: int = Query(20, ge=1, le=100, description="Itens por página"),
    
    reseller: ResellerAuth = Depends(require_reseller),
    db: Session = Depends(get_db_session)
):
    """
    Listar planos de merchant do reseller
    
    Permite filtrar por:
    - Status do plano (active/inactive/draft)
    - Se é plano padrão
    - Se possui merchants associados
    
    Retorna informações completas incluindo:
    - Estrutura de taxas
    - Contagem de merchants usando o plano
    - Estatísticas de uso (transações e volume)
    """
    try:
        plan_service = MerchantPlanService(db)
        
        filters = PlanFilter(
            status=status_filter,
            is_default=is_default,
            has_merchants=has_merchants
        )
        
        plans = plan_service.list_plans(
            reseller_id=reseller.reseller_id,
            filters=filters,
            sort=sort,
            page=page,
            per_page=per_page
        )
        
        logger.info(f"Merchant plans listed via API", extra={
            "reseller_id": reseller.reseller_id,
            "total_found": plans.total,
            "page": page,
            "filters": filters.model_dump(exclude_unset=True)
        })
        
        return plans
        
    except Exception as e:
        logger.error(f"Error listing merchant plans: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error while listing merchant plans"
        )

@router.get("/{plan_id}", response_model=MerchantPlanResponse)
async def get_merchant_plan(
    plan_id: str,
    reseller: ResellerAuth = Depends(require_reseller),
    db: Session = Depends(get_db_session)
):
    """
    Buscar um plano de merchant específico por ID
    
    Retorna informações completas do plano incluindo:
    - Estrutura detalhada de taxas
    - Contagem de merchants usando o plano
    - Estatísticas de transações processadas
    - Histórico de criação e modificações
    """
    try:
        plan_service = MerchantPlanService(db)
        plan = plan_service.get_plan_by_id(plan_id, reseller.reseller_id)
        
        if not plan:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Merchant plan {plan_id} not found"
            )
        
        logger.info(f"Merchant plan retrieved via API", extra={
            "plan_id": plan_id,
            "plan_name": plan.plan_name,
            "reseller_id": reseller.reseller_id
        })
        
        return plan
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving merchant plan {plan_id}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error while retrieving merchant plan"
        )

@router.put("/{plan_id}", response_model=MerchantPlanResponse)
async def update_merchant_plan(
    plan_id: str,
    update_data: MerchantPlanUpdate,
    reseller: ResellerAuth = Depends(require_reseller),
    db: Session = Depends(get_db_session)
):
    """
    Atualizar dados de um plano de merchant
    
    Permite atualizar:
    - Nome e descrição do plano
    - Estrutura de taxas (validada contra limites)
    - Status do plano (ativo/inativo)
    - Se é plano padrão
    
    Nota: Mudanças na estrutura de taxas não afetam transações já processadas,
    apenas transações futuras usando este plano.
    """
    try:
        plan_service = MerchantPlanService(db)
        plan = plan_service.update_plan(plan_id, update_data, reseller.reseller_id)
        
        if not plan:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Merchant plan {plan_id} not found"
            )
        
        logger.info(f"Merchant plan updated via API", extra={
            "plan_id": plan_id,
            "plan_name": plan.plan_name,
            "updated_fields": update_data.model_dump(exclude_unset=True).keys(),
            "reseller_id": reseller.reseller_id
        })
        
        return plan
        
    except ValueError as e:
        logger.warning(f"Merchant plan update validation error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating merchant plan {plan_id}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error while updating merchant plan"
        )

@router.post("/merchants/{merchant_id}/plan", response_model=MerchantPlanAssociationResponse)
async def associate_plan_to_merchant(
    merchant_id: str,
    association: MerchantPlanAssociation,
    reseller: ResellerAuth = Depends(require_reseller),
    db: Session = Depends(get_db_session)
):
    """
    Associar um plano a um merchant
    
    - **merchant_id**: ID do merchant que receberá o plano
    - **plan_id**: ID do plano a ser associado
    - **effective_date**: Data de início da vigência (opcional - padrão: agora)
    - **metadata**: Metadata adicional da associação
    
    A associação substitui o plano anterior (se houver) e afeta
    apenas transações futuras. O plano deve estar ativo.
    """
    try:
        plan_service = MerchantPlanService(db)
        association_response = plan_service.associate_plan_to_merchant(
            merchant_id, association, reseller.reseller_id
        )
        
        if not association_response:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Merchant {merchant_id} or plan {association.plan_id} not found"
            )
        
        logger.info(f"Plan associated to merchant via API", extra={
            "merchant_id": merchant_id,
            "plan_id": association.plan_id,
            "previous_plan_id": association_response.previous_plan_id,
            "reseller_id": reseller.reseller_id
        })
        
        return association_response
        
    except ValueError as e:
        logger.warning(f"Plan association validation error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error associating plan to merchant: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error while associating plan to merchant"
        )

@router.post("/{plan_id}/calculate", response_model=PlanCalculation)
async def calculate_transaction_fees(
    plan_id: str,
    transaction_amount: int = Query(..., gt=0, description="Valor da transação em centavos"),
    payment_method: PaymentMethod = Query(..., description="Método de pagamento"),
    installments: int = Query(1, ge=1, le=24, description="Número de parcelas"),
    reseller: ResellerAuth = Depends(require_reseller),
    db: Session = Depends(get_db_session)
):
    """
    Calcular taxas para uma transação usando um plano específico
    
    Calcula as taxas que seriam aplicadas a uma transação:
    - **transaction_amount**: Valor em centavos (ex: 10000 = R$ 100,00)
    - **payment_method**: credit, debit ou pix
    - **installments**: Número de parcelas (apenas para crédito)
    
    Retorna breakdown detalhado:
    - Taxa percentual calculada
    - Taxa fixa aplicada
    - Taxa adicional de parcelamento (se aplicável)
    - Valor líquido que o merchant receberá
    
    Útil para simular taxas antes de processar transações.
    """
    try:
        plan_service = MerchantPlanService(db)
        calculation = plan_service.calculate_transaction_fees(
            plan_id, transaction_amount, payment_method, installments, reseller.reseller_id
        )
        
        if not calculation:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Merchant plan {plan_id} not found"
            )
        
        logger.info(f"Transaction fees calculated via API", extra={
            "plan_id": plan_id,
            "transaction_amount": transaction_amount,
            "payment_method": payment_method,
            "installments": installments,
            "total_fee": calculation.total_fee,
            "reseller_id": reseller.reseller_id
        })
        
        return calculation
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error calculating transaction fees: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error while calculating transaction fees"
        )

@router.post("/create-defaults", response_model=List[MerchantPlanResponse])
async def create_default_plans(
    reseller: ResellerAuth = Depends(require_reseller),
    db: Session = Depends(get_db_session)
):
    """
    Criar planos padrão para o reseller
    
    Cria um conjunto de planos pré-configurados:
    - **Plano Iniciante**: Taxas básicas para novos merchants
    - **Plano Profissional**: Taxas intermediárias para médio volume
    - **Plano Empresarial**: Taxas premium para alto volume
    
    Apenas cria planos que ainda não existem (por nome).
    Útil para setup inicial de um novo reseller.
    """
    try:
        plan_service = MerchantPlanService(db)
        plans = plan_service.create_default_plans(reseller.reseller_id)
        
        logger.info(f"Default plans created via API", extra={
            "reseller_id": reseller.reseller_id,
            "plans_created": len(plans)
        })
        
        return plans
        
    except Exception as e:
        logger.error(f"Error creating default plans: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error while creating default plans"
        )

@router.delete("/{plan_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_merchant_plan(
    plan_id: str,
    reseller: ResellerAuth = Depends(require_reseller),
    db: Session = Depends(get_db_session)
):
    """
    Excluir ou desativar um plano de merchant
    
    Comportamento:
    - Se o plano tem merchants associados: **soft delete** (desativa o plano)
    - Se o plano não tem merchants: **hard delete** (remove completamente)
    
    Planos desativados permanecem visíveis para auditoria mas não podem
    ser associados a novos merchants.
    """
    try:
        plan_service = MerchantPlanService(db)
        success = plan_service.delete_plan(plan_id, reseller.reseller_id)
        
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Merchant plan {plan_id} not found"
            )
        
        logger.info(f"Merchant plan deleted via API", extra={
            "plan_id": plan_id,
            "reseller_id": reseller.reseller_id
        })
        
        # 204 No Content - no response body
        return
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting merchant plan {plan_id}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error while deleting merchant plan"
        )
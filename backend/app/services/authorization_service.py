from app.repositories import baby_user_repository

ALL_ROLES = {"adm", "tutor", "visualizador"}

# Papéis que podem escrever na rotina (mamada/soneca/fralda) de um bebê.
# 'visualizador' fica de fora — só leitura.
ROLES_CAN_EDIT_ROUTINE = {"adm", "tutor"}

# Só 'adm' edita/exclui o bebê em si ou gerencia quem tem acesso a ele.
ROLES_CAN_MANAGE_BABY = {"adm"}


def require_role(baby_id: int, user_id: int, allowed_roles: set[str]) -> str:
    """Levanta baby_not_found se o usuário não tem NENHUM acesso ao bebê
    (evita vazar que o recurso existe), ou forbidden se tem acesso mas o
    papel não é suficiente pra essa ação (aqui sim a pessoa já sabe que o
    bebê existe, então 403 é a resposta correta, não 404)."""
    role = baby_user_repository.find_role(baby_id, user_id)
    if role is None:
        raise ValueError("baby_not_found")
    if role not in allowed_roles:
        raise ValueError("forbidden")
    return role

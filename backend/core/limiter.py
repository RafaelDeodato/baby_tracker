from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

# Em memória, por instância — sem infraestrutura externa (Redis). Não é
# perfeitamente preciso com múltiplas instâncias do Cloud Run rodando em
# paralelo (cada uma tem seu próprio contador), mas é suficiente pro
# estágio atual. Ver docs/v2-compartilhamento-e-seguranca.md.
limiter = Limiter(key_func=get_remote_address)

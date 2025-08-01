# 🤝 Contribuindo para Setup New VM

Obrigado por considerar contribuir para este projeto! Este documento fornece diretrizes para contribuições.

## 🚀 Como Contribuir

### 1. Fork do Repositório
1. Faça um fork do repositório no GitHub
2. Clone seu fork localmente:
   ```bash
   git clone https://github.com/seu-usuario/setup-new-vm.git
   cd setup-new-vm
   ```

### 2. Criar uma Branch
Crie uma branch para sua feature ou correção:
```bash
git checkout -b feature/nova-funcionalidade
# ou
git checkout -b fix/correcao-bug
```

### 3. Fazer Alterações
- Faça suas alterações no código
- Teste localmente antes de commitar
- Siga as convenções de código do projeto

### 4. Commitar Alterações
Use commits descritivos:
```bash
git add .
git commit -m "feat: adiciona suporte para MongoDB"
git commit -m "fix: corrige problema de conectividade SSH"
git commit -m "docs: atualiza documentação de instalação"
```

### 5. Push e Pull Request
```bash
git push origin feature/nova-funcionalidade
```
Depois, crie um Pull Request no GitHub.

## 📝 Convenções de Commit

Use o padrão [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` - Nova funcionalidade
- `fix:` - Correção de bug
- `docs:` - Documentação
- `style:` - Formatação de código
- `refactor:` - Refatoração
- `test:` - Testes
- `chore:` - Tarefas de manutenção

## 🧪 Testando

### Teste Local
1. Configure uma VM de teste
2. Execute o script SSH:
   ```bash
   sudo ./scripts/setup-ssh-keys.sh [VM_IP] [VM_USER] [JENKINS_USER]
   ```
3. Teste o pipeline no Jenkins

### Teste de Conectividade
```bash
# Teste SSH
ssh -i /var/lib/jenkins/.ssh/id_rsa [VM_USER]@[VM_IP]

# Teste containers
docker ps
docker exec postgres-app pg_isready
docker exec redis-app redis-cli ping
```

## 📋 Checklist para Pull Requests

- [ ] Código segue as convenções do projeto
- [ ] Testes foram executados localmente
- [ ] Documentação foi atualizada
- [ ] Commits seguem o padrão Conventional Commits
- [ ] Não há conflitos de merge

## 🐛 Reportando Bugs

Use o template de issue do GitHub e inclua:

1. **Descrição do problema**
2. **Passos para reproduzir**
3. **Comportamento esperado**
4. **Comportamento atual**
5. **Informações do ambiente:**
   - Sistema operacional
   - Versão do Jenkins
   - Versão do Docker
   - Logs de erro

## 💡 Sugerindo Melhorias

Para novas funcionalidades:

1. **Descreva a funcionalidade**
2. **Explique o benefício**
3. **Forneça exemplos de uso**
4. **Considere impactos na segurança**

## 📞 Suporte

- **Issues:** Use o GitHub Issues
- **Discussões:** Use o GitHub Discussions
- **Documentação:** Consulte o README.md

## 🏷️ Releases

Releases seguem [Semantic Versioning](https://semver.org/):

- **MAJOR.MINOR.PATCH**
- Exemplo: `1.2.3`

---

Obrigado por contribuir! 🎉

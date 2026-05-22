# Diagrama Entidade-Relacionamento (DER)
## Plataforma Simulador ENEM

```
┌─────────────────────┐
│    users (Auth)     │
│  ─────────────────  │
│  id (PK, UUID)      │
│  email              │
│  created_at         │
└──────────┬──────────┘
           │ 1:1
           │
┌──────────▼──────────────┐
│   user_profiles         │
│  ────────────────────── │
│  id (PK, UUID)          │
│  user_id (FK, UUID)     │
│  full_name              │
│  role (ENUM)            │
│  created_at             │
│  updated_at             │
└──────────┬──────────────┘
           │ 1:N
           │
    ┌──────┴──────┐
    │             │
┌───▼────┐  ┌────▼──────────┐
│ Alunos │  │ Admin Escolar │
└────────┘  └───────────────┘


┌──────────────────┐
│     schools      │
│  ──────────────  │
│  id (PK, UUID)   │
│  name            │
│  cnpj (UNIQUE)   │
│  admin_id (FK)   │
│  created_at      │
└────────┬─────────┘
         │ 1:N
         │
┌────────▼─────────────────┐
│   enrollments            │
│  ────────────────────    │
│  id (PK, UUID)           │
│  student_id (FK, UUID)   │
│  school_id (FK, UUID)    │
│  enrollment_date         │
│  UNIQUE(student_id,      │
│         school_id)       │
└──────────────────────────┘


┌──────────────────────┐
│     questions        │
│  ──────────────────  │
│  id (PK, UUID)       │
│  question_number     │
│  statement (JSONB)   │
│  alternatives (JSON) │
│  correct_answer      │
│  subject             │
│  created_at          │
└────────┬─────────────┘
         │ 1:N
         │
┌────────▼──────────────────┐
│   exam_sessions           │
│  ───────────────────────  │
│  id (PK, UUID)            │
│  student_id (FK, UUID)    │
│  started_at               │
│  finished_at              │
│  status (em_andamento,    │
│          concluida)       │
│  total_questions          │
│  correct_answers          │
│  updated_at               │
└────────┬──────────────────┘
         │ 1:N
         │
┌────────▼─────────────────────┐
│   answers                    │
│  ──────────────────────────  │
│  id (PK, UUID)               │
│  session_id (FK, UUID)       │
│  question_id (FK, UUID)      │
│  chosen_alternative (INT)    │
│  is_correct (BOOLEAN)        │
│  answered_at                 │
│  UNIQUE(session_id,          │
│         question_id)         │
└──────────────────────────────┘
```

## Relacionamentos Principais

| Entidade | Relacionamento | Cardinalidade | Observações |
|----------|---|---|---|
| users ↔ user_profiles | 1:1 obrigatório | Um usuário = um perfil | Autenticação nativa |
| user_profiles ↔ schools | 1:N (admin) | Admin gerencia escola | Admin é obrigatório |
| users ↔ enrollments | 1:N | Um aluno, múltiplas escolas | |
| schools ↔ enrollments | 1:N | Uma escola, múltiplos alunos | UNIQUE(student, school) |
| questions ↔ answers | 1:N com integridade | Questão deletada = respostas apagadas | Cascade delete |
| exam_sessions ↔ answers | 1:N | Uma sessão, múltiplas respostas | UNIQUE(session, question) |
| users ↔ exam_sessions | 1:N | Um aluno, múltiplas sessões | |

## Constraints Importantes

 **Chaves Primárias:** Todas UUID (gerado automaticamente)

 **UNIQUE:** CNPJ escola, (student_id, school_id), (session_id, question_id)

 **CHECK:** Status sessão ∈ {em_andamento, concluida}

 **JSON/JSONB:** Enunciado e alternativas de questões

 **RLS:** Isolamento por tenant (escola)

 **Triggers:** Auto-criação de perfil, cascade delete de respostas

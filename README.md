# GTech Garçom

SaaS de atendimento para restaurantes: um único app Flutter (Master Admin GTech,
Admin do Restaurante, Garçom) mais uma PWA pública para o cliente, acessada por
QR Code/NFC. Backend 100% Supabase (Auth, Postgres + RLS, Realtime, Edge Functions).

## Rodando localmente

O app precisa da URL e da publishable key do Supabase em tempo de build — sem
isso a tela fica em branco (o app mostra uma tela de erro explicando o motivo).

1. Copie `config/env.example.json` para `config/env.local.json` (já está no
   `.gitignore` — nunca é commitado) e preencha `SUPABASE_URL` e
   `SUPABASE_PUBLISHABLE_KEY`.
2. Rode com:
   ```bash
   flutter run --dart-define-from-file=config/env.local.json
   ```
   No VS Code, use uma das configurações de "Run and Debug" em
   `.vscode/launch.json` ("GTech Garçom (Chrome)" etc.) — elas já passam essa
   flag automaticamente.

## Estrutura

```
lib/
 ├── core/            # config, router, erros
 ├── design_system/   # tokens, tema, widgets reutilizáveis
 ├── shared/          # widgets/utilitários genéricos
 ├── services/        # cliente Supabase
 └── features/        # auth, calls, client, menu, tables, staff,
                       # waiter, admin, gtech, companies, dashboard
                       # (cada uma com domain/data/presentation)
supabase/
 ├── migrations/       # schema + RLS, aplicadas via Supabase MCP/CLI
 └── functions/        # Edge Functions (invite-user, bootstrap-master-admin)
```

## Backend

Schema, RLS e Edge Functions vivem em `supabase/`. O acesso do cliente
(`/r/{empresaId}/m/{mesaId}`) é público e não usa login — QR Code e NFC
apontam para exatamente a mesma URL.

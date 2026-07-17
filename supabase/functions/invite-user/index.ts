// invite-user — creates staff accounts with the service role.
//
// Account creation can't be done from the Flutter app directly (it would
// require shipping the service-role key), so it lives here. Authorization:
//   * master_admin → may create 'admin' or 'waiter' for any company
//   * admin        → may create 'waiter' for their own company only
// The created auth user carries role/company_id/full_name in user_metadata;
// the `handle_new_user` DB trigger turns that into the profile row.
import { createClient } from "npm:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json(405, { error: "Método não permitido." });

  try {
    const admin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const jwt = (req.headers.get("Authorization") ?? "").replace("Bearer ", "");
    const { data: userData, error: userErr } = await admin.auth.getUser(jwt);
    if (userErr || !userData.user) return json(401, { error: "Não autenticado." });

    const { data: caller } = await admin
      .from("profiles")
      .select("role, company_id")
      .eq("id", userData.user.id)
      .single();
    if (!caller) return json(403, { error: "Perfil não encontrado." });

    const { email, password, full_name, role, company_id } = await req.json();
    if (!email || !password || !full_name) {
      return json(400, { error: "Campos obrigatórios: email, password, full_name." });
    }
    if (password.length < 8) {
      return json(400, { error: "A senha deve ter pelo menos 8 caracteres." });
    }

    let targetRole: string;
    let targetCompany: string;

    if (caller.role === "master_admin") {
      if (role !== "admin" && role !== "waiter") {
        return json(400, { error: "Role inválida (use admin ou waiter)." });
      }
      if (!company_id) return json(400, { error: "company_id é obrigatório." });
      targetRole = role;
      targetCompany = company_id;
    } else if (caller.role === "admin") {
      targetRole = "waiter";
      targetCompany = caller.company_id;
    } else {
      return json(403, { error: "Sem permissão para criar usuários." });
    }

    const { data: company } = await admin
      .from("companies")
      .select("id")
      .eq("id", targetCompany)
      .single();
    if (!company) return json(404, { error: "Empresa não encontrada." });

    const { data: created, error: createErr } = await admin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: {
        role: targetRole,
        company_id: targetCompany,
        full_name,
      },
    });
    if (createErr) return json(400, { error: createErr.message });

    return json(200, { user_id: created.user?.id });
  } catch (e) {
    return json(500, { error: String(e) });
  }
});

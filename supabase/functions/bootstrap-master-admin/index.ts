// bootstrap-master-admin — one-shot creation of the very first GTech user.
//
// Self-disabling: refuses with 409 as soon as any master_admin profile
// exists, so it's only usable on a virgin project. All subsequent staff
// creation goes through `invite-user` (which requires an authenticated
// master_admin/admin caller).
import { createClient } from "npm:@supabase/supabase-js@2";

const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

Deno.serve(async (req) => {
  if (req.method !== "POST") return json(405, { error: "Método não permitido." });

  try {
    const admin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { count } = await admin
      .from("profiles")
      .select("*", { count: "exact", head: true })
      .eq("role", "master_admin");
    if ((count ?? 0) > 0) {
      return json(409, { error: "Master admin já existe — use invite-user." });
    }

    const { email, password, full_name } = await req.json();
    if (!email || !password || password.length < 12) {
      return json(400, { error: "email e password (mín. 12 caracteres) são obrigatórios." });
    }

    const { data: created, error } = await admin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { role: "master_admin", full_name: full_name ?? "GTech" },
    });
    if (error) return json(400, { error: error.message });

    return json(200, { user_id: created.user?.id });
  } catch (e) {
    return json(500, { error: String(e) });
  }
});

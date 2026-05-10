import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

const groqEndpoint = "https://api.groq.com/openai/v1/chat/completions"

function createSupabaseClient(req: Request) {
  const authHeader = req.headers.get("Authorization")

  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    {
      global: {
        headers: authHeader ? { Authorization: authHeader } : {},
      },
      auth: {
        persistSession: false,
      },
    },
  )
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  try {
    if (req.method !== "POST") {
      return new Response(
        JSON.stringify({ error: "Method not allowed" }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 405,
        },
      )
    }

    const groqApiKey = Deno.env.get("GROQ_API_KEY")
    if (!groqApiKey) throw new Error("AI service is not configured")
    
    const model = Deno.env.get("GROQ_MODEL") || "llama-3.1-8b-instant"

    const supabase = createSupabaseClient(req)
    const authHeader = req.headers.get("Authorization")
    const token = authHeader ? authHeader.replace("Bearer ", "") : ""
    const { data: { user }, error: authError } = await supabase.auth.getUser(token)

    if (authError || !user) {
      throw new Error("Unauthorized user")
    }

    let body;
    try {
      body = await req.json()
    } catch (e) {
      throw new Error("Invalid JSON payload")
    }
    
    const prompt = typeof body.prompt === "string" ? body.prompt.trim() : ""
    const temperature = typeof body.temperature === "number" ? body.temperature : 0.2

    if (!prompt) throw new Error("Missing prompt")

    const groqResponse = await fetch(groqEndpoint, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${groqApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model,
        messages: [
          {
            role: "system",
            content: "You are a teacher explaining to a beginner. Be clear and direct.",
          },
          {
            role: "user",
            content: prompt,
          },
        ],
        temperature,
      }),
    })

    if (!groqResponse.ok) {
      return new Response(
        JSON.stringify({ error: "AI service failed" }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 502,
        },
      )
    }

    const data = await groqResponse.json()
    const rawOutput = data?.choices?.[0]?.message?.content
    const output = typeof rawOutput === "string" ? rawOutput.trim() : ""

    if (!output) throw new Error("AI returned an empty response")

    return new Response(
      JSON.stringify({ output }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      },
    )
  } catch (err) {
    const message = err instanceof Error ? err.message : "AI request failed"
    console.error("AI Service Error:", err)

    return new Response(
      JSON.stringify({ error: message }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      },
    )
  }
})